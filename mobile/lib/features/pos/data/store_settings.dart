import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/providers.dart';

class StoreSettings {
  const StoreSettings({
    this.name = 'Bagimu Negriku Market (BN Mart)',
    this.address = 'Jl. Raya Bagimu Negriku No. 1',
    this.phone = '0812-3456-7890',
    this.footerNote = 'Terima kasih atas kunjungan Anda di BN Mart!\nBarang yang sudah dibeli tidak dapat ditukar.',
    this.paperSizeMm = 58,
  });

  final String name;
  final String address;
  final String phone;
  final String footerNote;
  final int paperSizeMm;

  StoreSettings copyWith({
    String? name,
    String? address,
    String? phone,
    String? footerNote,
    int? paperSizeMm,
  }) {
    return StoreSettings(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      footerNote: footerNote ?? this.footerNote,
      paperSizeMm: paperSizeMm ?? this.paperSizeMm,
    );
  }
}

final storeSettingsProvider =
    NotifierProvider<StoreSettingsNotifier, StoreSettings>(StoreSettingsNotifier.new);

class StoreSettingsNotifier extends Notifier<StoreSettings> {
  static const _keyPrefix = 'pos_store_';
  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  StoreSettings build() {
    Future<void>.microtask(_loadSettings);
    return const StoreSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final name = await _storage.read(key: '${_keyPrefix}name');
      final address = await _storage.read(key: '${_keyPrefix}address');
      final phone = await _storage.read(key: '${_keyPrefix}phone');
      final footerNote = await _storage.read(key: '${_keyPrefix}footer');
      final paperSizeStr = await _storage.read(key: '${_keyPrefix}paper');

      state = StoreSettings(
        name: (name != null && name.trim().isNotEmpty) ? name : 'Bagimu Negriku Market (BN Mart)',
        address: (address != null && address.trim().isNotEmpty) ? address : 'Jl. Raya Bagimu Negriku No. 1',
        phone: (phone != null && phone.trim().isNotEmpty) ? phone : '0812-3456-7890',
        footerNote: (footerNote != null && footerNote.trim().isNotEmpty)
            ? footerNote
            : 'Terima kasih atas kunjungan Anda di BN Mart!\nBarang yang sudah dibeli tidak dapat ditukar.',
        paperSizeMm: int.tryParse(paperSizeStr ?? '58') ?? 58,
      );
    } catch (_) {
      // Keep default on read error
    }
  }

  Future<void> update({
    required String name,
    required String address,
    required String phone,
    required String footerNote,
    int? paperSizeMm,
  }) async {
    state = state.copyWith(
      name: name.trim(),
      address: address.trim(),
      phone: phone.trim(),
      footerNote: footerNote.trim(),
      paperSizeMm: paperSizeMm,
    );

    try {
      await _storage.write(key: '${_keyPrefix}name', value: state.name);
      await _storage.write(key: '${_keyPrefix}address', value: state.address);
      await _storage.write(key: '${_keyPrefix}phone', value: state.phone);
      await _storage.write(key: '${_keyPrefix}footer', value: state.footerNote);
      await _storage.write(key: '${_keyPrefix}paper', value: state.paperSizeMm.toString());
    } catch (_) {}
  }
}
