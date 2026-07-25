/// The identifier the hosted agent keys a contact on (ADR-0015).
///
/// OWNER: P1 (@sharvel-irigoyen).
///
/// It is a **random per-install value**, generated once and kept in the app's
/// own key/value table. Deliberately not a hardware id, an advertising id or a
/// phone number: the agent needs to recognise the same conversation across
/// launches, and nothing more. A value we generated ourselves gives it exactly
/// that and dies with the app's data when the caregiver uninstalls.
library;

import 'dart:math';

import '../settings/key_value_store.dart';

/// The key this lives under, alongside the caregiver's name.
const String deviceReferenceKey = 'qonpania_device_reference';

/// Reads the device reference, generating and persisting one on first call.
///
/// Stable across launches, because the agent would otherwise open a new contact
/// every time the app starts.
Future<String> resolveDeviceReference(
  KeyValueStore store, {
  Random? random,
}) async {
  final existing = await store.read(deviceReferenceKey);
  if (existing != null && existing.isNotEmpty) return existing;

  final generated = newDeviceReference(random);
  await store.write(deviceReferenceKey, generated);
  return generated;
}

/// A fresh random reference, in UUID v4 shape.
///
/// The shape is cosmetic — the server treats it as an opaque string — but it
/// makes the value obvious for what it is in a log or a support panel.
String newDeviceReference([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
