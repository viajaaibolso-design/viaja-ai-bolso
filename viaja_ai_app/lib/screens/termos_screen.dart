import 'package:flutter/material.dart';
import '../constants.dart';

/// RF07 — Tela própria com o conteúdo real dos Termos de Uso e da
/// Política de Privacidade (antes era só um texto estático no Cadastro,
/// sem tela e sem conteúdo de fato). Também atende à RNF14 (LGPD), ao
/// deixar explícito quais dados são coletados e para quê.
///
/// Aviso: este texto foi redigido para fins do projeto acadêmico
/// (TCC) do ViajAí Bolso. Antes de um lançamento real/comercial do app,
/// vale ter esse conteúdo revisado por um profissional da área jurídica.
class TermosScreen extends StatelessWidget {
  const TermosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Termos de Uso e Privacidade',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Secao(
              titulo: '1. Sobre o ViajAí Bolso',
              corpo:
                  'O ViajAí Bolso é um aplicativo para controle e gestão visual de gastos em '
                  'viagens, desenvolvido como Trabalho de Conclusão de Curso do curso de '
                  'Análise e Desenvolvimento de Sistemas. Ao criar uma conta, você concorda '
                  'com os termos descritos nesta página.',
            ),
            _Secao(
              titulo: '2. Cadastro e conta',
              corpo:
                  'Para usar o app, é necessário criar uma conta informando nome, e-mail e '
                  'senha. Você é responsável por manter a confidencialidade da sua senha e '
                  'por todas as atividades realizadas na sua conta. A senha é armazenada de '
                  'forma segura (com hashing) pelo provedor de autenticação utilizado pelo '
                  'app (Supabase) — o ViajAí Bolso nunca tem acesso à sua senha em texto '
                  'legível.',
            ),
            _Secao(
              titulo: '3. Quais dados coletamos',
              corpo:
                  'Coletamos apenas os dados necessários para o funcionamento do app: nome, '
                  'e-mail e, opcionalmente, uma foto de perfil; os dados das viagens que você '
                  'cadastra (nome, destino, datas, orçamento e foto de capa); e os dados das '
                  'despesas vinculadas a cada viagem (descrição, valor, data, categoria, '
                  'forma de pagamento e, quando anexado, a foto do comprovante).',
            ),
            _Secao(
              titulo: '4. Como usamos e protegemos seus dados',
              corpo:
                  'Seus dados são usados exclusivamente para exibir suas próprias viagens e '
                  'despesas dentro do app — nunca são vendidos ou compartilhados com '
                  'terceiros para fins de publicidade. Toda comunicação entre o app e o '
                  'servidor é feita via HTTPS. No banco de dados, regras de segurança em '
                  'nível de linha (Row Level Security) garantem que cada usuário só '
                  'consegue ler ou alterar os próprios dados — nem outros usuários do app '
                  'têm acesso a eles.',
            ),
            _Secao(
              titulo: '5. Seus direitos (LGPD)',
              corpo:
                  'Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), '
                  'você pode, a qualquer momento: consultar e editar seus dados de perfil '
                  'diretamente no app; excluir suas viagens e despesas; e solicitar a '
                  'exclusão completa da sua conta e dos dados associados, entrando em '
                  'contato pelo canal de Suporte.',
            ),
            _Secao(
              titulo: '6. Uso adequado do app',
              corpo:
                  'O ViajAí Bolso deve ser usado apenas para o controle pessoal de gastos de '
                  'viagem. Os valores e estimativas eventualmente sugeridos pelo app (como '
                  'conversões de câmbio) têm caráter informativo e podem não refletir com '
                  'exatidão valores praticados no momento da sua viagem.',
            ),
            _Secao(
              titulo: '7. Alterações destes termos',
              corpo:
                  'Como o app está em desenvolvimento contínuo (projeto acadêmico em '
                  'evolução), este documento pode ser atualizado conforme novas '
                  'funcionalidades forem adicionadas. A versão mais recente estará sempre '
                  'disponível nesta tela.',
            ),
            SizedBox(height: 8),
            Text(
              'Última atualização: setembro de 2026.',
              style: TextStyle(color: kTextGrey, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final String corpo;
  const _Secao({required this.titulo, required this.corpo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: kPrimaryColor)),
          const SizedBox(height: 6),
          Text(corpo,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.5, color: kTextDark)),
        ],
      ),
    );
  }
}
