#!/usr/bin/env bash
set -Eeuo pipefail

# Run under reactivecircus/android-emulator-runner with a debug Android app.
# Each crash invocation must reach a durable checkpoint before the host sends
# an actual Android force-stop. Flutter drive failing after the stop is expected.
PACKAGE="cz.vycetka.vycetka"
MARKER="app_flutter/cash_tally_android_it_checkpoint.txt"
LOG_DIR="${RUNNER_TEMP:-/tmp}/cash-tally-android-recovery"
mkdir -p "$LOG_DIR"

adb wait-for-device

drive_case() {
  local mode="$1"
  local checkpoint="${2:-}"
  flutter drive \
    --no-pub \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/android_backup_recovery_test.dart \
    "--dart-define=CASH_TALLY_IT_MODE=$mode" \
    "--dart-define=CASH_TALLY_IT_CHECKPOINT=$checkpoint"
}

crash_at_checkpoint() {
  local checkpoint="$1"
  local log="$LOG_DIR/crash-$checkpoint.log"
  echo "==> Android forced termination after: $checkpoint"

  # The timeout also protects the runner if Flutter never attaches to VM service.
  timeout --signal=TERM --kill-after=10s 600s \
    flutter drive \
      --no-pub \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/android_backup_recovery_test.dart \
      "--dart-define=CASH_TALLY_IT_MODE=crash" \
      "--dart-define=CASH_TALLY_IT_CHECKPOINT=$checkpoint" \
      >"$log" 2>&1 &
  local driver_pid="$!"
  local ready=0
  local observed

  # A marker is created only AFTER the journal/record write was confirmed and
  # flushed on the Android sandbox. A crashed build that never reached the
  # desired stage cannot accidentally count as a successful kill.
  for _ in $(seq 1 240); do
    observed="$(adb shell run-as "$PACKAGE" cat "$MARKER" 2>/dev/null | tr -d '\r\n' || true)"
    if [[ "$observed" == "$checkpoint" ]]; then
      ready=1
      break
    fi
    if ! kill -0 "$driver_pid" 2>/dev/null; then
      break
    fi
    sleep 2
  done

  if [[ "$ready" -ne 1 ]]; then
    echo "ERROR: checkpoint '$checkpoint' was never reached" >&2
    tail -n 100 "$log" >&2 || true
    kill "$driver_pid" 2>/dev/null || true
    wait "$driver_pid" 2>/dev/null || true
    return 1
  fi

  # This is a real process termination, not tester.restartAndRestore() and
  # not a thrown exception inside Dart. Android app data must remain intact.
  adb shell am force-stop "$PACKAGE"
  echo "Force-stopped $PACKAGE at $checkpoint"

  # flutter drive normally exits non-zero because the VM/service vanished.
  # Some versions may wait instead; clean up the host process after 30 seconds.
  for _ in $(seq 1 30); do
    if ! kill -0 "$driver_pid" 2>/dev/null; then break; fi
    sleep 1
  done
  if kill -0 "$driver_pid" 2>/dev/null; then
    echo "Driver did not exit after Android force-stop; terminating host runner."
    kill "$driver_pid" 2>/dev/null || true
  fi
  local status=0
  wait "$driver_pid" || status="$status" # overwritten below by explicit check
  # The authoritative success criteria are the durable marker and the next
  # independent process passing all data-integrity assertions.
  observed="$(adb shell run-as "$PACKAGE" cat "$MARKER" 2>/dev/null | tr -d '\r\n' || true)"
  if [[ "$observed" != "$checkpoint" ]]; then
    echo "ERROR: checkpoint marker disappeared after force-stop" >&2
    tail -n 100 "$log" >&2 || true
    return 1
  fi
  echo "Android stopped at the verified '$checkpoint' checkpoint"
}

echo "==> Baseline: encrypted backup, wrong password, and full reload"
drive_case roundtrip

for checkpoint in journal sessions templates custom hidden; do
  crash_at_checkpoint "$checkpoint"
  echo "==> Cold start: recover complete data after '$checkpoint'"
  drive_case verify "$checkpoint"
done

# Destructive corrupted-history checks must run last.
echo "==> History recovery from .bak and fail-closed on double corruption"
drive_case history

echo "Android recovery suite passed."
