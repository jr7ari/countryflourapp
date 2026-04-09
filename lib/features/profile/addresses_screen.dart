import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/address_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../presentation/providers/orders_provider.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        title: Text('My Addresses', style: AppTextStyles.headingXL),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressSheet(context, ref),
        backgroundColor: AppColors.primaryBrown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Address',
            style: AppTextStyles.buttonM.copyWith(color: Colors.white)),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBrown,
        onRefresh: () async {
          ref.invalidate(addressesProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: addressesAsync.when(
          data: (addresses) => addresses.isEmpty
              ? const _EmptyAddresses()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: addresses.length,
                  itemBuilder: (_, i) => _AddressCard(
                    address: addresses[i],
                  ).animate().fadeIn(delay: (i * 60).ms),
                ),
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (_, __) => const ListTileShimmer(),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Failed to load addresses',
                    style: AppTextStyles.headingM),
                const SizedBox(height: 6),
                Text(e.toString(),
                    style: AppTextStyles.bodyS, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(addressesProvider),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAddressSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAddressSheet(onSaved: () {
        ref.invalidate(addressesProvider);
      }),
    );
  }
}

// ─── Address Card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});
  final Address address;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                size: 20, color: AppColors.primaryGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.name, style: AppTextStyles.headingS),
                const SizedBox(height: 2),
                Text(address.phone,
                    style: AppTextStyles.labelM
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  address.fullAddress,
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded,
              size: 64, color: AppColors.primaryGold.withAlpha(100)),
          const SizedBox(height: 16),
          Text('No addresses yet', style: AppTextStyles.headingM),
          const SizedBox(height: 6),
          Text('Tap "+ Add Address" to save your first address',
              style:
                  AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Add Address Bottom Sheet ─────────────────────────────────────────────────

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _addressLine = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _landmark = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _addressLine.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final address = await ref.read(createAddressProvider.notifier).create(
          AddressRequest(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            addressLine: _addressLine.text.trim(),
            city: _city.text.trim(),
            state: _state.text.trim(),
            pincode: _pincode.text.trim(),
            landmark: _landmark.text.trim().isEmpty
                ? null
                : _landmark.text.trim(),
          ),
        );

    if (!mounted) return;

    if (address != null) {
      widget.onSaved();
      Navigator.of(context).pop();
    } else {
      final err = ref.read(createAddressProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.hasError ? err.error.toString() : 'Failed to save address'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createAddressProvider).isLoading;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Add New Address', style: AppTextStyles.headingL),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _Field(controller: _name, label: 'Full Name', hint: 'John Doe'),
                    _Field(
                      controller: _phone,
                      label: 'Phone',
                      hint: '9876543210',
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v != null && v.trim().length == 10 ? null : 'Enter valid 10-digit number',
                    ),
                    _Field(
                      controller: _addressLine,
                      label: 'Address',
                      hint: '123 Main Street',
                      maxLines: 2,
                    ),
                    Row(
                      children: [
                        Expanded(child: _Field(controller: _city, label: 'City', hint: 'Mumbai')),
                        const SizedBox(width: 12),
                        Expanded(child: _Field(controller: _state, label: 'State', hint: 'Maharashtra')),
                      ],
                    ),
                    _Field(
                      controller: _pincode,
                      label: 'Pincode',
                      hint: '400001',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v != null && v.trim().length == 6 ? null : 'Enter valid 6-digit pincode',
                    ),
                    _Field(
                      controller: _landmark,
                      label: 'Landmark (optional)',
                      hint: 'Near Bus Stop',
                      required: false,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrown,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Save Address',
                                style: AppTextStyles.buttonM
                                    .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Form Field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTextStyles.bodyM,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: AppTextStyles.labelL,
          hintStyle:
              AppTextStyles.bodyM.copyWith(color: AppColors.textHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryBrown, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: validator ??
            (required
                ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
                : null),
      ),
    );
  }
}
