part of '../main.dart';

String _formatSiteAddress(Map<String, dynamic> site) {
  final addressLine1 = site['addressLine1'] as String? ?? '';
  final city = site['city'] as String? ?? '';
  final state =
      (site['state'] as String?) ?? (site['stateCode'] as String?) ?? '';
  final postalCode =
      (site['postalCode'] as String?) ?? (site['zipCode'] as String?) ?? '';
  final cityStateZip = [city, state, postalCode]
      .where((part) => part.trim().isNotEmpty)
      .join(' ');
  return [addressLine1, cityStateZip]
      .where((part) => part.trim().isNotEmpty)
      .join(', ');
}

