import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/resumo_painel.dart';
import '../../theme/app_colors.dart';
import 'cartao_indicador.dart';

final NumberFormat _reais =
    NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 0);
final NumberFormat _numero = NumberFormat.decimalPattern('pt_BR');

/// "R$ 8.450" (sem centavos), usado nos cartões e no gráfico.
String formatarReaisInteiro(double valor) => _reais.format(valor);

/// Gráfico "Desempenho dos últimos meses" (prejuízo evitado em R$).
///
/// Feito só com widgets do Flutter (sem pacote de gráficos).
///  • desktop: barras verticais com linhas de grade;
///  • celular: barras horizontais, mês mais recente em cima.
class GraficoDesempenho extends StatelessWidget {
  final List<MesDesempenho> dados;
  final bool celular;

  const GraficoDesempenho({
    super.key,
    required this.dados,
    required this.celular,
  });

  @override
  Widget build(BuildContext context) {
    final vazio = dados.every((m) => m.valor <= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desempenho dos últimos meses',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textoEscuro,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Prejuízo evitado em R\$',
          style: TextStyle(fontSize: 11, color: AppColors.textoCinza),
        ),
        const SizedBox(height: 12),
        if (vazio) ...[
          const TextoSemDados(),
        ] else if (celular)
          _BarrasHorizontais(dados: dados)
        else
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.fundoCartao,
              borderRadius: BorderRadius.circular(16),
              boxShadow: sombraCartaoPainel,
            ),
            child: _BarrasVerticais(dados: dados),
          ),
      ],
    );
  }
}

/// Mensagem quando ainda não há dados para o gráfico.
class TextoSemDados extends StatelessWidget {
  const TextoSemDados({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Ainda não há dados para mostrar. Assim que você recuperar horários, '
        'o desempenho aparece aqui.',
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: AppColors.textoCinza,
        ),
      ),
    );
  }
}

/// Maior valor "redondo" do eixo (ex.: 2500 -> 3000), para as linhas de grade
/// caírem em números bonitos.
double _maximoDoEixo(List<MesDesempenho> dados) {
  final maior = dados.map((m) => m.valor).fold<double>(0, math.max);
  if (maior <= 0) return 1;
  final magnitude = math.pow(10, (math.log(maior) / math.ln10).floor());
  final passo = magnitude / 2; // 1000 -> 500
  return (maior / passo).ceil() * passo.toDouble();
}

// ───────────────────────── barras verticais (desktop) ─────────────────────────

class _BarrasVerticais extends StatelessWidget {
  final List<MesDesempenho> dados;
  const _BarrasVerticais({required this.dados});

  static const double _altura = 240;
  static const double _margemTopo = 22; // espaço para o rótulo da maior barra
  static const double _alturaMes = 24; // faixa dos nomes dos meses
  static const double _larguraEixo = 52;
  static const int _linhas = 4;

  @override
  Widget build(BuildContext context) {
    final maximo = _maximoDoEixo(dados);
    final alturaUtil = _altura - _margemTopo - _alturaMes;

    return SizedBox(
      height: _altura,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Linhas de grade + números do eixo Y.
          for (int i = 0; i <= _linhas; i++) ...[
            Positioned(
              left: 0,
              width: _larguraEixo - 8,
              bottom: _alturaMes + alturaUtil * i / _linhas - 7,
              child: Text(
                _numero.format(maximo * i / _linhas),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textoCinza,
                ),
              ),
            ),
            Positioned(
              left: _larguraEixo,
              right: 0,
              bottom: _alturaMes + alturaUtil * i / _linhas,
              child: Container(height: 1, color: AppColors.bordaCampo),
            ),
          ],
          // Barras.
          Positioned.fill(
            left: _larguraEixo,
            child: Row(
              children: [
                for (final mes in dados)
                  Expanded(
                    child: _BarraVertical(
                      mes: mes,
                      altura: alturaUtil * (mes.valor / maximo),
                      alturaMes: _alturaMes,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraVertical extends StatelessWidget {
  final MesDesempenho mes;
  final double altura;
  final double alturaMes;

  const _BarraVertical({
    required this.mes,
    required this.altura,
    required this.alturaMes,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${mes.rotulo}: ${formatarReaisInteiro(mes.valor)}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Barra.
          Positioned(
            left: 0,
            right: 0,
            bottom: alturaMes,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.62,
                child: Container(
                  height: altura,
                  decoration: const BoxDecoration(
                    color: AppColors.painelTeal,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
            ),
          ),
          // Valor acima da barra.
          Positioned(
            left: 0,
            right: 0,
            bottom: alturaMes + altura + 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatarReaisInteiro(mes.valor),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textoEscuro,
                ),
              ),
            ),
          ),
          // Nome do mês.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: alturaMes,
            child: Center(
              child: Text(
                mes.rotulo,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textoCinza,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── barras horizontais (celular) ─────────────────────────

class _BarrasHorizontais extends StatelessWidget {
  final List<MesDesempenho> dados;
  const _BarrasHorizontais({required this.dados});

  static const double _larguraMes = 36;
  static const double _larguraValor = 64;

  @override
  Widget build(BuildContext context) {
    final maximo = dados.map((m) => m.valor).fold<double>(0, math.max);
    final maisRecentesPrimeiro = dados.reversed.toList();

    return LayoutBuilder(
      builder: (context, restricoes) {
        final larguraMaxBarra =
            math.max(0.0, restricoes.maxWidth - _larguraMes - _larguraValor);
        return Column(
          children: [
            for (final mes in maisRecentesPrimeiro)
              Semantics(
                label: '${mes.rotulo}: ${formatarReaisInteiro(mes.valor)}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: _larguraMes,
                        child: Text(
                          mes.rotulo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textoCinza,
                          ),
                        ),
                      ),
                      Container(
                        width: larguraMaxBarra * (mes.valor / maximo),
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.painelTeal,
                          borderRadius:
                              BorderRadius.horizontal(right: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatarReaisInteiro(mes.valor),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textoEscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
