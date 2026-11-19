import 'package:flutter/material.dart';

import '../app/game_api.dart';
import 'match_view.dart';
import 'rules.dart';

final gameConfig = GameConfig(
  gameId: 'game-009-number-match',
  title: const ['Sayı Eşleştir', 'Number Match', 'Zahlen-Match', 'Empareja Números', 'Nombres Assortis'],
  tagline: const [
    'Eşit ya da toplamı 10 olan çiftleri eşleştir!',
    'Match pairs that are equal or sum to 10!',
    'Finde gleiche Paare oder Summe 10!',
    '¡Empareja iguales o que sumen 10!',
    'Associez des paires égales ou de somme 10 !',
  ],
  seedColor: const Color(0xFF0277BD),
  icon: Icons.pin,
  rules: MatchRules(),
  buildPlay: (ctx) => MatchView(ctx: ctx),
  tutorial: const [
    TutorialStep(Icons.looks_two, [
      'Aynı iki sayıyı (5-5) ya da toplamı 10 olan iki sayıyı (3-7) seç.',
      'Pick two equal numbers (5-5) or two that sum to 10 (3-7).',
      'Wähle zwei gleiche Zahlen oder Summe 10.',
      'Elige dos iguales o que sumen 10.',
      'Choisissez deux nombres égaux ou de somme 10.',
    ]),
    TutorialStep(Icons.timeline, [
      'Sayılar yan yana, üst üste, çapraz ya da satır sonundan sonraki satırın başına bağlı olabilir; aradaki kareler boş olmalı.',
      'Pairs can be side by side, vertical, diagonal, or end of a row to start of the next - with only empty cells between.',
      'Nebeneinander, senkrecht, diagonal oder Zeilenende-Zeilenanfang.',
      'Lado a lado, vertical, diagonal o fin-inicio de fila.',
      'Côte à côte, vertical, diagonal ou fin-début de ligne.',
    ]),
    TutorialStep(Icons.playlist_add, [
      'Eşleşme kalmazsa "+" ile kalan sayıları sona ekle. Tahtayı tamamen temizle!',
      'No pairs left? Use "+" to append the remaining numbers. Clear the whole board!',
      'Keine Paare? Mit "+" Zahlen anhängen.',
      '¿Sin parejas? Usa "+" para añadir números.',
      'Plus de paires ? "+" ajoute les nombres.',
    ]),
  ],
);
