import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/business_settings_model.dart';
import '../../../data/repositories/settings_repository.dart';

/// Settings page with Business Profile and Invoice Settings sections.
class SettingsPage extends StatefulWidget {
  /// Called after settings are saved so the sidebar can refresh.
  final VoidCallback? onSettingsSaved;

  const SettingsPage({super.key, this.onSettingsSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = SettingsRepository.instance;

  late TextEditingController _nameCtrl;
  late TextEditingController _descriptionCtrl;

  bool _showNameOnInvoice = true;
  bool _showDescriptionOnInvoice = true;
  String _descriptionPosition = 'top'; // 'top' | 'bottom'

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _repo.loadSettings();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = settings.businessName;
      _descriptionCtrl.text = settings.description;
      _showNameOnInvoice = settings.showNameOnInvoice;
      _showDescriptionOnInvoice = settings.showDescriptionOnInvoice;
      _descriptionPosition = settings.descriptionPosition;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final settings = BusinessSettingsModel(
      businessName: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      showNameOnInvoice: _showNameOnInvoice,
      showDescriptionOnInvoice: _showDescriptionOnInvoice,
      descriptionPosition: _descriptionPosition,
    );

    await _repo.saveSettings(settings);

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppStrings.settingsSaved),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    widget.onSettingsSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Header ─────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    AppStrings.settings,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Business Profile Section ────────────────────────
              _buildSectionCard(
                icon: Icons.store,
                title: AppStrings.businessProfile,
                children: [
                  _buildTextField(
                    controller: _nameCtrl,
                    label: AppStrings.businessName,
                    hint: AppStrings.businessNameHint,
                    icon: Icons.storefront,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionCtrl,
                    label: AppStrings.businessDescription,
                    hint: AppStrings.businessDescriptionHint,
                    icon: Icons.description_outlined,
                    maxLines: 5,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Invoice Settings Section ────────────────────────
              _buildSectionCard(
                icon: Icons.receipt_long,
                title: AppStrings.invoiceSettings,
                subtitle: AppStrings.invoiceSettingsSubtitle,
                children: [
                  _buildToggle(
                    label: AppStrings.showNameOnInvoice,
                    value: _showNameOnInvoice,
                    onChanged: (v) => setState(() => _showNameOnInvoice = v),
                    icon: Icons.badge_outlined,
                  ),
                  _buildToggle(
                    label: AppStrings.showDescriptionOnInvoice,
                    value: _showDescriptionOnInvoice,
                    onChanged: (v) => setState(() => _showDescriptionOnInvoice = v),
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 12),
                  // ── Description Position ───────────────────────
                  Row(
                    children: [
                      const Icon(Icons.swap_vert, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.descriptionPosition,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'top',
                              label: Text('ابتدای فاکتور'),
                              icon: Icon(Icons.vertical_align_top, size: 18),
                            ),
                            ButtonSegment(
                              value: 'bottom',
                              label: Text('انتهای فاکتور'),
                              icon: Icon(Icons.vertical_align_bottom, size: 18),
                            ),
                          ],
                          selected: {_descriptionPosition},
                          onSelectionChanged: (v) => setState(() => _descriptionPosition = v.first),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.primary.withValues(alpha: 0.2);
                              }
                              return AppColors.surfaceDark;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.primary;
                              }
                              return AppColors.textMuted;
                            }),
                            side: WidgetStateProperty.all(
                              const BorderSide(color: AppColors.dividerDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Save Button ─────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveSettings,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 20),
                    label: Text(
                      AppStrings.save,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: value ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.dividerDark,
          ),
        ],
      ),
    );
  }
}
