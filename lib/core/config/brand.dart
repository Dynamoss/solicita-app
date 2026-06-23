import 'package:flutter/material.dart';

/// A whitelabel brand definition. Everything visually distinctive about a
/// tenant is data here — no per-brand code paths — so adding a new client is a
/// matter of appending one entry to [Brands.all].
@immutable
class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.tagline,
    required this.seedColor,
    required this.logoEmoji,
  });

  final String id;
  final String name;
  final String tagline;

  /// Drives the entire [ColorScheme] via [ColorScheme.fromSeed], so a single
  /// color produces a coherent light/dark palette per brand.
  final Color seedColor;

  /// Lightweight stand-in for a real logo asset (keeps the repo asset-free).
  final String logoEmoji;
}

/// The catalogue of available brands. In a real product this would come from a
/// remote config / build flavor; here it is static so the demo can switch live.
abstract final class Brands {
  static const saude = Brand(
    id: 'saude',
    name: 'CuidarApp',
    tagline: 'Cuidar das pessoas, levando acesso à saúde de qualidade.',
    seedColor: Color(0xFF00897B),
    logoEmoji: '🩺',
  );

  static const corporate = Brand(
    id: 'corporate',
    name: 'AtendePro',
    tagline: 'Gestão inteligente de chamados corporativos.',
    seedColor: Color(0xFF1565C0),
    logoEmoji: '🏢',
  );

  static const sunset = Brand(
    id: 'sunset',
    name: 'HelpDesk+',
    tagline: 'Suporte ágil, do abrir ao resolver.',
    seedColor: Color(0xFFE65100),
    logoEmoji: '🛟',
  );

  static const List<Brand> all = [saude, corporate, sunset];

  static Brand byId(String? id) =>
      all.firstWhere((b) => b.id == id, orElse: () => saude);
}
