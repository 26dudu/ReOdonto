import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';

const String _locale = 'pt_BR';

final NumberFormat _moeda =
    NumberFormat.currency(locale: _locale, symbol: r'R$');
final DateFormat _dataCurta = DateFormat('dd/MM', _locale);
final DateFormat _dataCompleta = DateFormat('dd/MM/yyyy', _locale);
final DateFormat _hora = DateFormat('HH:mm', _locale);
final DateFormat _dataEHora = DateFormat("dd/MM/yyyy 'às' HH:mm", _locale);
final DateFormat _diaExtenso = DateFormat("EEEE, d 'de' MMMM", _locale);
final DateFormat _diaSemanaAbreviado = DateFormat('E', _locale);

String formatarMoeda(double valor) => _moeda.format(valor);

String formatarDataCurta(DateTime data) => _dataCurta.format(data);

String formatarDataCompleta(DateTime data) => _dataCompleta.format(data);

String formatarHora(DateTime data) => _hora.format(data);

String formatarDataEHora(DateTime data, TimeOfDay hora) {
  final junto = DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
  return _dataEHora.format(junto);
}

String formatarDiaExtenso(DateTime data) =>
    toBeginningOfSentenceCase(_diaExtenso.format(data), _locale) ?? '';

String formatarDiaSemanaAbreviado(DateTime data) =>
    toBeginningOfSentenceCase(
        _diaSemanaAbreviado.format(data).replaceAll('.', ''), _locale) ??
    '';

String formatarDuracao(int? minutos) {
  if (minutos == null || minutos <= 0) return '';
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  return resto == 0 ? '${horas}h' : '${horas}h${resto.toString().padLeft(2, '0')}';
}

DateTime apenasData(DateTime data) => DateTime(data.year, data.month, data.day);

bool mesmoDia(DateTime primeiraData, DateTime segundaData) =>
    primeiraData.year == segundaData.year && primeiraData.month == segundaData.month && primeiraData.day == segundaData.day;

bool ehHoje(DateTime data) => mesmoDia(data, DateTime.now());

String pluralizar(int quantidade, String singular, String plural) =>
    '$quantidade ${quantidade == 1 ? singular : plural}';
