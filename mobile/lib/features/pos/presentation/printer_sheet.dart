import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/receipt_printer.dart';
import '../data/store_settings.dart';
import '../domain/sale.dart';
import 'store_settings_dialog.dart';

Future<void> showPrinterSheet(
  BuildContext context,
  Sale sale, {
  double? paidAmount,
  double? changeAmount,
}) {
  final width = MediaQuery.of(context).size.width;
  if (width > 600) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PrinterSheetContent(
              sale: sale,
              paidAmount: paidAmount,
              changeAmount: changeAmount,
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: PrinterSheetContent(
          sale: sale,
          paidAmount: paidAmount,
          changeAmount: changeAmount,
        ),
      ),
    ),
  );
}

class PrinterSheetContent extends ConsumerStatefulWidget {
  const PrinterSheetContent({
    required this.sale,
    this.paidAmount,
    this.changeAmount,
    super.key,
  });

  final Sale sale;
  final double? paidAmount;
  final double? changeAmount;

  @override
  ConsumerState<PrinterSheetContent> createState() => _PrinterSheetContentState();
}

class _PrinterSheetContentState extends ConsumerState<PrinterSheetContent> {
  bool _printing = false;
  String? _error;
  ConnectionType? _filterType;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(ref.read(receiptPrinterProvider).startScan);
  }

  @override
  void dispose() {
    ref.read(receiptPrinterProvider).stopScan();
    super.dispose();
  }

  void _printViaCable() {
    setState(() {
      _printing = true;
      _error = null;
    });

    try {
      ref.read(receiptPrinterProvider).printViaBrowser(
            widget.sale,
            paidAmount: widget.paidAmount,
            changeAmount: widget.changeAmount,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Perintah cetak dikirim ke printer thermal kabel USB!'),
              ],
            ),
            backgroundColor: Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Gagal mencetak: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _printDirectEscPos(Printer printer) async {
    setState(() {
      _printing = true;
      _error = null;
    });

    try {
      await ref.read(receiptPrinterProvider).printSale(
            printer,
            widget.sale,
            paidAmount: widget.paidAmount,
            changeAmount: widget.changeAmount,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Struk berhasil dicetak ke ${printer.name ?? 'Printer'}.'),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Gagal mencetak: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _simulatePrint() async {
    setState(() => _printing = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _printing = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Simulasi cetak struk ESC/POS BN Mart berhasil!'),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final printer = ref.watch(receiptPrinterProvider);
    final storeSettings = ref.watch(storeSettingsProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.print_rounded, color: Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cetak Struk BN Mart',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      'Kertas ${storeSettings.paperSizeMm} mm · Kabel USB (Utama) & Bluetooth',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Pindai Ulang Port & Printer',
                onPressed: () {
                  ref.read(receiptPrinterProvider).stopScan();
                  ref.read(receiptPrinterProvider).startScan();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_error != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: scheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Opsi Utama: Cetak Langsung Kabel USB
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.12),
                  const Color(0xFF0D9488).withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cable_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Cetak Kabel USB',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'UTAMA',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Langsung cetak ke printer thermal yang terhubung kabel USB ke PC/Laptop kasir.',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: _printing ? null : _printViaCable,
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Cetak'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Baris Header Filter Port Perangkat
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                'Perangkat Port / ESC-POS Langsung',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text('Semua', style: TextStyle(fontSize: 11)),
                    selected: _filterType == null,
                    onSelected: (_) => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    avatar: const Icon(Icons.cable_rounded, size: 12),
                    label: const Text('USB', style: TextStyle(fontSize: 11)),
                    selected: _filterType == ConnectionType.USB,
                    onSelected: (_) => setState(() => _filterType = ConnectionType.USB),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    avatar: const Icon(Icons.bluetooth_rounded, size: 12),
                    label: const Text('BLE', style: TextStyle(fontSize: 11)),
                    selected: _filterType == ConnectionType.BLE,
                    onSelected: (_) => setState(() => _filterType = ConnectionType.BLE),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Container Daftar Port & Perangkat
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: StreamBuilder<List<Printer>>(
              stream: printer.devices,
              initialData: const <Printer>[],
              builder: (context, snapshot) {
                final allDevices = snapshot.data ?? const <Printer>[];
                final devices = allDevices.where((d) {
                  if (_filterType == null) return true;
                  if (_filterType == ConnectionType.USB) {
                    return d.connectionType == ConnectionType.USB || d.queueName != null;
                  }
                  if (_filterType == ConnectionType.BLE) {
                    return d.connectionType == ConnectionType.BLE;
                  }
                  return true;
                }).toList();

                if (devices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.cable_rounded, color: Color(0xFF2E7D32), size: 30),
                          const SizedBox(height: 8),
                          Text(
                            'Printer kabel USB siap dicetak!',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gunakan tombol hijau "Cetak" pada banner Cetak Kabel USB di atas untuk mengirim struk langsung ke printer kabel Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: scheme.outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isUsb = device.connectionType == ConnectionType.USB || device.queueName != null;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUsb
                              ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                              : scheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isUsb ? Icons.cable_rounded : Icons.bluetooth_rounded,
                          color: isUsb ? const Color(0xFF0D9488) : scheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        device.name ?? (isUsb ? 'Printer Thermal USB' : 'Printer Bluetooth'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isUsb
                                  ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                                  : scheme.secondaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isUsb ? 'KABEL USB' : 'BLUETOOTH',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isUsb ? const Color(0xFF0D9488) : scheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              device.address ?? (isUsb ? 'Port USB Sistem' : 'BLE'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      trailing: _printing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton.tonal(
                              onPressed: () => _printDirectEscPos(device),
                              child: const Text('Cetak ESC/POS'),
                            ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Bantuan Bawah
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _printing ? null : _simulatePrint,
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Simulasi Cetak'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showStoreSettingsDialog(context);
                  },
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Ukuran Kertas'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
