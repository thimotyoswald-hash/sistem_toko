import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/store_settings.dart';

Future<void> showStoreSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const StoreSettingsDialog(),
  );
}

class StoreSettingsDialog extends ConsumerStatefulWidget {
  const StoreSettingsDialog({super.key});

  @override
  ConsumerState<StoreSettingsDialog> createState() => _StoreSettingsDialogState();
}

class _StoreSettingsDialogState extends ConsumerState<StoreSettingsDialog> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _footer;
  late int _paperSize;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(storeSettingsProvider);
    _name = TextEditingController(text: settings.name);
    _address = TextEditingController(text: settings.address);
    _phone = TextEditingController(text: settings.phone);
    _footer = TextEditingController(text: settings.footerNote);
    _paperSize = settings.paperSizeMm;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _footer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(storeSettingsProvider.notifier).update(
          name: _name.text,
          address: _address.text,
          phone: _phone.text,
          footerNote: _footer.text,
          paperSizeMm: _paperSize,
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan toko & struk berhasil disimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.storefront_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Text(
            'Identitas Toko & Struk',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informasi ini akan tercetak di bagian atas dan bawah struk pembayaran.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Alamat Toko',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon / HP',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _footer,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pesan Kaki Struk (Footer)',
                  prefixIcon: Icon(Icons.notes_rounded),
                  hintText: 'Contoh: Terima kasih atas kunjungan Anda',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ukuran Kertas Thermal Printer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 58, label: Text('58 mm (Standar)'), icon: Icon(Icons.receipt_long_rounded)),
                  ButtonSegment<int>(value: 80, label: Text('80 mm (Lebar)'), icon: Icon(Icons.print_rounded)),
                ],
                selected: {_paperSize},
                onSelectionChanged: (val) => setState(() => _paperSize = val.first),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded),
          label: const Text('Simpan'),
        ),
      ],
    );
  }
}
