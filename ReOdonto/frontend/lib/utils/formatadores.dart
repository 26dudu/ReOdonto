// Toda a formatação de datas, horas, moeda e duração (intl, pt-BR) fica aqui,
// para o formato ser igual no app inteiro.
// IMPORTANTE: o main.dart chama `initializeDateFormatting('pt_BR')` antes do
// runApp; sem isso o DateFormat em pt_BR lança erro (em testes, chame também).
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';

const String _locale = 'pt_BR';

// Os formatadores são "final" de nível superior: o Dart só os cria na primeira
// vez que são usados (lazy), ou seja, depois do initializeDateFormatting.
final NumberFormat _moeda =
    NumberFormat.currency(locale: _locale, symbol: r'R$');
final DateFormat _dataCurta = DateFormat('dd/MM', _locale);
final DateFormat _dataCompleta = DateFormat('dd/MM/yyyy', _locale);
final DateFormat _hora = DateFormat('HH:mm', _locale);
final DateFormat _dataEHora = DateFormat("dd/MM/yyyy 'às' HH:mm", _locale);
final DateFormat _diaExtenso = DateFormat("EEEE, d 'de' MMMM", _locale);
final DateFormat _diaSemanaAbreviado = DateFormat('E', _locale);

/// 200.0 -> "R$ 200,00"
String formatarMoeda(double valor) => _moeda.format(valor);

/// 2026-09-28 -> "28/09"
String formatarDataCurta(DateTime data) => _dataCurta.format(data);

/// 2026-09-28 -> "28/09/2026"
String formatarDataCompleta(DateTime data) => _dataCompleta.format(data);

/// 2026-09-28 14:30 -> "14:30"
String formatarHora(DateTime data) => _hora.format(data);

/// Data + TimeOfDay -> "28/09/2026 às 14:30" (usado no resumo do modal).
String formatarDataEHora(DateTime data, TimeOfDay hora) {
  final junto = DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
  return _dataEHora.format(junto);
}

/// 2026-09-28 -> "Segunda-feira, 28 de setembro" (título do seletor de dia).
String formatarDiaExtenso(DateTime data) =>
    toBeginningOfSentenceCase(_diaExtenso.format(data), _locale) ?? '';

/// 2026-09-28 -> "Seg" (faixa semanal). O intl devolve "seg." — tiramos o ponto.
String formatarDiaSemanaAbreviado(DateTime data) =>
    toBeginningOfSentenceCase(
        _diaSemanaAbreviado.format(data).replaceAll('.', ''), _locale) ??
    '';

/// 45 -> "45 min" | 60 -> "1h" | 90 -> "1h30". Sem duração -> "".
String formatarDuracao(int? minutos) {
  if (minutos == null || minutos <= 0) return '';
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  return resto == 0 ? '${horas}h' : '${horas}h${resto.toString().padLeft(2, '0')}';
}

// ---- Helpers de data (só dia/mês/ano, ignorando a hora) ---------------------

/// Zera a hora: 2026-09-28 14:30 -> 2026-09-28 00:00.
DateTime apenasData(DateTime data) => DateTime(data.year, data.month, data.day);

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool ehHoje(DateTime data) => mesmoDia(data, DateTime.now());
