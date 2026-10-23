import 'package:flutter/material.dart'; 
import 'package:flutter_svg/flutter_svg.dart'; 
import '../../theme/app_colors.dart'; 

// Cabeçalho de Marca
// Logo (ícone do dente num círculo) + o bloco de texto "SUA AGENDA CHEIA".
// Usado no topo das telas de autenticação (login, redefinir senha, nova
// senha) pra manter a mesma identidade visual em todas elas.
//
// Antes desse widget existir, esse mesmo bloco de ~65 linhas estava
// duplicado dentro de 3 arquivos diferentes (telaLogin.dart,
// telaRedefinirSenha.dart, telaNovaSenha.dart). Agora existe uma única
// vez aqui, e cada tela só chama `const CabecalhoMarca()`.


// StatelessWidget porque esse widget nunca muda depois de criado — não
// tem nenhum dado que varia com interação do usuário, então não precisa
// de estado (State) nem de setState.
class CabecalhoMarca extends StatelessWidget {
  // Construtor padrão. `super.key` repassa a chave (usada internamente
  // pelo Flutter pra identificar o widget na árvore) pra classe pai.
  // Não recebe nenhum parâmetro próprio porque o conteúdo é sempre igual.
  const CabecalhoMarca({super.key});

  // Todo widget precisa sobrescrever build(), que descreve o que deve
  // ser desenhado na tela. É chamado pelo Flutter sempre que o widget
  // precisa ser (re)desenhado.
  @override
  Widget build(BuildContext context) {
    // Row organiza os filhos lado a lado, na horizontal (logo à esquerda,
    // texto à direita).
    return Row(
      // Centraliza o conteúdo da Row no eixo principal (horizontal),
      // já que o cabeçalho fica centralizado na tela, não colado à borda.
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ---- Círculo do logo ----
        Container(
          width: 60, // largura fixa do círculo
          height: 60, // altura fixa (igual à largura, pra ficar redondo)
          decoration: BoxDecoration(
            color: Colors.white, // fundo branco do círculo
            shape: BoxShape
                .circle, // força o Container a ser desenhado como círculo
            border: Border.all(
              color: const Color(0xFFD0E2FF), // azul bem clarinho na borda
              width: 2, // espessura da borda
            ),
          ),
          // Center garante que o ícone SVG fique perfeitamente no meio
          // do círculo, mesmo que o ícone seja menor que o Container.
          child: Center(
            child: SvgPicture.asset(
              // Caminho do arquivo SVG dentro da pasta de assets do projeto.
              'assets/icons/tooth-svgrepo-com.svg',
              width:
                  32, // largura do ícone (menor que o círculo de 60, sobra espaço nas bordas)
              height: 32, // altura do ícone
              // colorFilter recolore o SVG inteiro pra uma cor sólida.
              // Sem isso, o SVG usaria as cores originais do arquivo.
              colorFilter: const ColorFilter.mode(
                AppColors.azulPrimario, // cor azul principal da marca
                BlendMode
                    .srcIn, // modo de mescla que substitui a cor do desenho mantendo a transparência
              ),
            ),
          ),
        ),

        // Espaço vazio de 12px entre o círculo do logo e o bloco de texto.
        const SizedBox(width: 12),

        // ---- Bloco de texto "SUA AGENDA CHEIA" ----
        // Column empilha os textos verticalmente (um embaixo do outro).
        const Column(
          // Alinha todo o texto à esquerda dentro da coluna (em vez de
          // centralizado), já que o bloco de texto fica ao lado do logo,
          // não sozinho no meio da tela.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primeira linha: "SUA", pequena, em verde-água, com letras
            // um pouco espaçadas (letterSpacing) pra dar destaque visual.
            Text(
              'SUA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600, // semi-negrito
                color: Color(0xFF00C1A2), // verde-água
                letterSpacing: 1.2, // espaço extra entre as letras
              ),
            ),
            // Segunda linha: "AGENDA", a maior e mais chamativa do bloco.
            Text(
              'AGENDA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight
                    .w900, // extra-negrito (o mais pesado do Material)
                color: Color(0xFF1C2434), // azul-escuro quase preto
                // height reduz o espaçamento vertical da linha, aproximando
                // ela da linha de cima ("SUA") e de baixo ("CHEIA"), pra
                // o bloco parecer mais compacto/colado.
                height: 0.9,
              ),
            ),
            // Terceira linha: "CHEIA", mesma cor escura, um pouco menor
            // que "AGENDA".
            Text(
              'CHEIA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C2434),
              ),
            ),
            // Quarta linha: o texto miudinho de identificação da marca,
            // em cinza, tamanho bem pequeno (6px) — funciona quase como
            // um "rodapé" do logo.
            Text(
              'CLÍNICAS ODONTOLÓGICAS - AGENDAMENTO ONLINE',
              style: TextStyle(fontSize: 6, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
