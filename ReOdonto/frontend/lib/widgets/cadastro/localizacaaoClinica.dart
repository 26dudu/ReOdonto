import 'package:flutter/material.dart';
import '../label_text.dart';
import '../../utils/mascaras.dart';
import '../../services/api_service.dart';

class AddressInfoFields extends StatefulWidget {
  final TextEditingController controladorCpf;
  final TextEditingController controladorCep;
  final TextEditingController controladorRua;
  final TextEditingController controladorBairro;
  final TextEditingController controladorNumero;

  const AddressInfoFields({
    super.key,
    required this.controladorCpf,
    required this.controladorCep,
    required this.controladorRua,
    required this.controladorBairro,
    required this.controladorNumero,
  });

  @override
  State<AddressInfoFields> createState() => _AddressInfoFieldsState();
}

class _AddressInfoFieldsState extends State<AddressInfoFields> {
  bool _buscandoCep = false;
  String? _erroCep;

  @override
  void initState() {
    super.initState();
    // Escuta mudanças no campo CEP
    widget.controladorCep.addListener(_aoMudarCep);
  }

  @override
  void dispose() {
    widget.controladorCep.removeListener(_aoMudarCep);
    super.dispose();
  }

  void _aoMudarCep() {
    final cep = widget.controladorCep.text;
    // CEP com máscara tem 9 chars: "30150-380"
    // CEP sem máscara tem 8 dígitos
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      _buscarEndereco(cep);
    }
  }

  Future<void> _buscarEndereco(String cep) async {
    if (_buscandoCep) return;

    setState(() {
      _buscandoCep = true;
      _erroCep = null;
    });

    final resultado = await ApiService.buscarCep(cep);

    if (!mounted) return;

    setState(() => _buscandoCep = false);

    if (resultado.temErro) {
      setState(() => _erroCep = resultado.erro);
      return;
    }

    final dados = resultado.dados!;

    // Preenche os campos automaticamente
    widget.controladorRua.text = dados['logradouro'] ?? '';
    widget.controladorBairro.text = dados['bairro'] ?? '';

    // Move o foco para o campo Número após preencher
    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext contexto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledTextField(
          rotulo: 'CPF',
          textoAjuda: '123.456.789-10',
          icone: Icons.badge_outlined,
          controlador: widget.controladorCpf,
          tipoTeclado: TextInputType.number,
          inputFormatters: [MascaraCpf()],
        ),
        const SizedBox(height: 16),

        // CEP com indicador de carregamento
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledTextField(
              rotulo: 'CEP',
              textoAjuda: '30150-380',
              icone: _buscandoCep
                  ? Icons.hourglass_top_outlined
                  : Icons.location_on_outlined,
              controlador: widget.controladorCep,
              tipoTeclado: TextInputType.number,
              inputFormatters: [MascaraCep()],
            ),
            if (_buscandoCep)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Buscando endereço...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            if (_erroCep != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _erroCep!,
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        LabeledTextField(
          rotulo: 'Rua',
          textoAjuda: 'Preenchido automaticamente',
          icone: Icons.signpost_outlined,
          controlador: widget.controladorRua,
          somenteLeitura: true,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          rotulo: 'Bairro',
          textoAjuda: 'Preenchido automaticamente',
          icone: Icons.map_outlined,
          controlador: widget.controladorBairro,
          somenteLeitura: true,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          rotulo: 'Número',
          textoAjuda: 'Ex: 129',
          icone: Icons.numbers_outlined,
          controlador: widget.controladorNumero,
          tipoTeclado: TextInputType.number,
        ),
      ],
    );
  }
}
