import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../data/repositories/customer_repository.dart';
import '../../../../features/customers/view/widgets/customer_form_dialog.dart';
import '../../cubit/invoice_cubit.dart';
import '../../cubit/invoice_state.dart';

/// Invoice header section: number, date, customer, status.
class InvoiceHeader extends StatelessWidget {
  const InvoiceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerDark),
          ),
          child: Row(
            children: [
              // Invoice Number
              Expanded(
                child: _buildField(
                  context,
                  label: AppStrings.invoiceNumber,
                  child: TextFormField(
                    initialValue: state.invoiceNumber,
                    onChanged: (v) => context.read<InvoiceCubit>().setInvoiceNumber(v),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Date Picker
              Expanded(
                child: _buildField(
                  context,
                  label: AppStrings.invoiceDate,
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        state.date.isNotEmpty
                            ? JalaliUtils.format(JalaliUtils.fromIso(state.date))
                            : '---',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Customer Search with Create
              Expanded(
                flex: 2,
                child: _buildField(
                  context,
                  label: AppStrings.selectCustomer,
                  child: _CustomerSearchField(
                    initialCustomer: state.selectedCustomer,
                    onSelected: (c) => context.read<InvoiceCubit>().setCustomer(c),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Status Dropdown
              Expanded(
                child: _buildField(
                  context,
                  label: AppStrings.invoiceStatus,
                  child: DropdownButtonFormField<String>(
                    value: state.status,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: AppStrings.invoiceStatuses.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.statusColor(s),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) context.read<InvoiceCubit>().setStatus(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(BuildContext context, {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<InvoiceCubit>();
    final currentJalali = cubit.state.date.isNotEmpty
        ? JalaliUtils.fromIso(cubit.state.date)
        : Jalali.now();

    final picked = await showPersianDatePicker(
      context: context,
      initialDate: currentJalali,
      firstDate: Jalali(1400),
      lastDate: Jalali(1430),
    );

    if (picked != null) {
      cubit.setDate(JalaliUtils.toIso(picked));
    }
  }
}

/// Customer search field that validates input and offers to create if not found.
class _CustomerSearchField extends StatefulWidget {
  final CustomerModel? initialCustomer;
  final ValueChanged<CustomerModel?> onSelected;

  const _CustomerSearchField({this.initialCustomer, required this.onSelected});

  @override
  State<_CustomerSearchField> createState() => _CustomerSearchFieldState();
}

class _CustomerSearchFieldState extends State<_CustomerSearchField> {
  final CustomerRepository _repo = CustomerRepository();
  final _focusNode = FocusNode();
  late final TextEditingController _controller;
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _suggestions = [];
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;
    _controller = TextEditingController(text: widget.initialCustomer?.name ?? '');
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _CustomerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCustomer != oldWidget.initialCustomer) {
      _selectedCustomer = widget.initialCustomer;
      _controller.text = widget.initialCustomer?.name ?? '';
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideOverlay();
      // Validate: if text doesn't match a selected customer, clear or offer create
      _validateAndResolve();
    }
  }

  Future<void> _validateAndResolve() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _selectedCustomer = null;
      widget.onSelected(null);
      return;
    }

    // If already selected and name matches, keep it
    if (_selectedCustomer != null && _selectedCustomer!.name == text) {
      return;
    }

    // Search for exact match
    final matches = await _repo.getAll(query: text);
    final exact = matches.where((c) => c.name == text).toList();
    if (exact.isNotEmpty) {
      _selectedCustomer = exact.first;
      widget.onSelected(_selectedCustomer);
      return;
    }

    // No exact match — offer to create
    if (mounted) {
      _showCreateCustomerDialog(text);
    }
  }

  Future<void> _showCreateCustomerDialog(String typedName) async {
    final nextCode = await _repo.nextCode();
    if (!mounted) return;

    final customer = await CustomerFormDialog.show(
      context,
      nextCode: nextCode,
      customer: CustomerModel(name: typedName, code: nextCode),
    );

    if (customer != null && mounted) {
      final newId = await _repo.insert(customer);
      final saved = CustomerModel(
        id: newId,
        code: customer.code,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        notes: customer.notes,
      );
      setState(() {
        _selectedCustomer = saved;
        _controller.text = saved.name;
      });
      widget.onSelected(saved);
    } else {
      // User cancelled — clear the field
      setState(() {
        _selectedCustomer = null;
        _controller.clear();
      });
      widget.onSelected(null);
    }
  }

  Future<void> _onTextChanged(String text) async {
    if (text.isEmpty) {
      _hideSuggestions();
      return;
    }
    _suggestions = await _repo.getAll(query: text);
    _showSuggestionsOverlay();
  }

  void _selectCustomer(CustomerModel customer) {
    _selectedCustomer = customer;
    _controller.text = customer.name;
    widget.onSelected(customer);
    _hideOverlay();
  }

  void _showSuggestionsOverlay() {
    _hideOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _suggestions = [];
    _hideOverlay();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    ..._suggestions.map((c) => ListTile(
                          dense: true,
                          title: Text(c.name),
                          subtitle: Text(c.phone ?? '', style: const TextStyle(fontSize: 11)),
                          leading: const Icon(Icons.person, size: 20),
                          onTap: () => _selectCustomer(c),
                        )),
                    // Always show "Create Customer" at the bottom
                    Divider(height: 1, color: AppColors.dividerDark),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.person_add, size: 20, color: AppColors.accent),
                      title: Text(
                        '${AppStrings.createNewCustomer}: «${_controller.text}»',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        _hideOverlay();
                        _showCreateCustomerDialog(_controller.text.trim());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onTextChanged,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintText: 'نام مشتری را تایپ کنید...',
          suffixIcon: _selectedCustomer != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    _selectedCustomer = null;
                    _controller.clear();
                    widget.onSelected(null);
                  },
                )
              : const Icon(Icons.person_search, size: 18),
        ),
      ),
    );
  }
}
