import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/app_config.dart';
import '../state/app_scope.dart';

class AdaptiveBannerAd extends StatefulWidget {
  const AdaptiveBannerAd({super.key});

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd> {
  BannerAd? _banner;
  bool _loading = false;
  bool _eligible = false;
  int? _requestedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final eligible = AppScope.of(context).shouldShowAds;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (!eligible) {
      _eligible = false;
      _disposeBanner();
      return;
    }
    _eligible = true;
    if (_banner == null && !_loading || _requestedWidth != width) {
      _disposeBanner();
      _requestedWidth = width;
      unawaited(_load(width));
    }
  }

  Future<void> _load(int width) async {
    if (!_eligible || _loading || width <= 0) {
      return;
    }
    _loading = true;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || !_eligible || size == null) {
      _loading = false;
      return;
    }
    final banner = BannerAd(
      adUnitId: AppConfig.bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !_eligible) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _loading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
          if (mounted) {
            setState(() => _loading = false);
          }
        },
      ),
    );
    await banner.load();
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_eligible || banner == null) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: SizedBox(
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }
}
