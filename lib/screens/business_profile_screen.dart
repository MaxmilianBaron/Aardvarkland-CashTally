import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../l10n/app_localizations.dart';
import '../models/business_profile.dart';
import '../state/app_scope.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  late final TextEditingController _businessName;
  late final TextEditingController _registrationId;
  late final TextEditingController _address;
  late final TextEditingController _locationName;
  late final TextEditingController _tillName;
  late final TextEditingController _cashierName;
  late final TextEditingController _managerName;
  late final TextEditingController _shiftName;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = AppScope.read(context).businessProfile;
    _businessName = TextEditingController(text: profile.businessName);
    _registrationId = TextEditingController(text: profile.registrationId);
    _address = TextEditingController(text: profile.address);
    _locationName = TextEditingController(text: profile.locationName);
    _tillName = TextEditingController(text: profile.tillName);
    _cashierName = TextEditingController(text: profile.cashierName);
    _managerName = TextEditingController(text: profile.managerName);
    _shiftName = TextEditingController(text: profile.shiftName);
  }

  @override
  void dispose() {
    _businessName.dispose();
    _registrationId.dispose();
    _address.dispose();
    _locationName.dispose();
    _tillName.dispose();
    _cashierName.dispose();
    _managerName.dispose();
    _shiftName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('businessProfile'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: <Widget>[
          Text(
            context.tr('businessProfileHelp'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _field(
            controller: _businessName,
            label: context.tr('businessName'),
            icon: Icons.business_outlined,
          ),
          _field(
            controller: _registrationId,
            label: context.tr('registrationId'),
            icon: Icons.badge_outlined,
            capitalize: false,
          ),
          _field(
            controller: _address,
            label: context.tr('businessAddress'),
            icon: Icons.location_on_outlined,
            lines: 2,
          ),
          _field(
            controller: _locationName,
            label: context.tr('locationName'),
            icon: Icons.store_outlined,
          ),
          _field(
            controller: _tillName,
            label: context.tr('tillName'),
            icon: Icons.point_of_sale_outlined,
          ),
          _field(
            controller: _cashierName,
            label: context.tr('cashierName'),
            icon: Icons.person_outline,
          ),
          _field(
            controller: _managerName,
            label: context.tr('managerName'),
            icon: Icons.supervisor_account_outlined,
          ),
          _field(
            controller: _shiftName,
            label: context.tr('shiftName'),
            icon: Icons.schedule_outlined,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(context.tr('save')),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int lines = 1,
    bool capitalize = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        textInputAction: lines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        textCapitalization: capitalize
            ? TextCapitalization.sentences
            : TextCapitalization.none,
        inputFormatters: capitalize
            ? const <TextInputFormatter>[SentenceCaseTextFormatter()]
            : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AppScope.read(context).saveBusinessProfile(
        BusinessProfile(
          businessName: _businessName.text.trim(),
          registrationId: _registrationId.text.trim(),
          address: _address.text.trim(),
          locationName: _locationName.text.trim(),
          tillName: _tillName.text.trim(),
          cashierName: _cashierName.text.trim(),
          managerName: _managerName.text.trim(),
          shiftName: _shiftName.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('profileSaved'))));
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('saveFailed'))));
    }
  }
}
