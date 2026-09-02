import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cnpj_response.dart';

class DetailScreen extends StatelessWidget {
  final CnpjResponse data;

  const DetailScreen({super.key, required this.data});

  // Theme colors
  static const Color bg = Color(0xFF0F1724);
  static const Color card = Color(0xFF162033);
  static const Color border = Color(0xFF1E3A5F);
  static const Color primary = Color(0xFF1A4C89);
  static const Color highlight = Color(0xFF2563EB);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF4A5568);

  static Color _statusColor(String? status) {
    if (status == null) return textSecondary;
    final s = status.toLowerCase();
    if (s == 'ativo' || s == 'at') return success;
    if (s == 'suspenso' || s == 'sp') return warning;
    if (s == 'inapto' || s == 'in') return error;
    return textSecondary;
  }

  static String _statusText(String? status) {
    if (status == null) return '';
    final s = status.toLowerCase();
    if (s == 'at' || s == 'ativo') return 'Ativo';
    if (s == 'sp' || s == 'suspenso') return 'Suspenso';
    if (s == 'in' || s == 'inapto') return 'Inapto';
    return status;
  }

  String _cnpjFormat(String? cnpj) {
    final c = cnpj ?? '';
    if (c.length != 14) return c;
    return '${c.substring(0, 2)}.${c.substring(2, 5)}.'
        '${c.substring(5, 8)}/${c.substring(8, 12)}-${c.substring(12)}';
  }

  String formatTelefone(String? ddd, String? numero) {
    if (ddd == null || numero == null) return '';
    final n = numero.length == 8
        ? '${numero.substring(0, 4)}-${numero.substring(4)}'
        : '${numero.substring(0, 5)}-${numero.substring(5)}';
    return '($ddd) $n';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado!'),
        backgroundColor: success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final est = data.estabelecimento;
    final socios = data.socios;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          data.razaoSocial ?? 'Detalhes',
          style: const TextStyle(fontSize: 16, color: textPrimary),
        ),
        backgroundColor: card,
        foregroundColor: textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Divider(height: 1, color: border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copiar dados',
            onPressed: () {
              final text = _buildShareText();
              _copyToClipboard(context, text, 'Dados');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Compartilhar',
            onPressed: () {
              final text = _buildShareText();
              Share.share(text);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildSection('Dados da Empresa', [
              _row('Razão Social', data.razaoSocial),
              _row('Nome Fantasia', est?.nomeFantasia),
              _row('Porte', data.porte?.descricao),
              _row('Capital Social', data.capitalSocial),
              _row('Abertura', est?.dataInicioAtividade),
              _row('Situação', _statusText(est?.situacaoCadastral),
                  _statusBadge(est?.situacaoCadastral)),
              _row('Natureza Jurídica', data.naturezaJuridica?.descricao),
              _row('Atividade Principal', est?.atividadePrincipal?.descricao),
            ]),
            const SizedBox(height: 12),
            _buildSection('Localização', [
              _row('Endereço',
                  '${est?.tipoLogradouro ?? ''} ${est?.logradouro ?? ''} ${est?.numero ?? ''}'),
              _row('Bairro', est?.bairro),
              _row('CEP', est?.cep),
              _row(
                  'Cidade/UF',
                  '${est?.cidade?.nome ?? ''}/${est?.estado?.sigla ?? ''}'),
            ]),
            const SizedBox(height: 12),
            _buildSection('Contato', [
              _row('E-mail', est?.email),
              _row('Telefone', formatTelefone(est?.ddd1, est?.telefone1)),
            ]),
            if (socios != null && socios.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSection('Sócios (${socios.length})',
                  socios.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2538),
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nome ?? '-',
                              style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          if (s.qualificacaoSocio?.descricao != null)
                            Text(s.qualificacaoSocio!.descricao!,
                                style: const TextStyle(
                                    color: textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  )).toList()),
            ],
            if (est?.inscricoesEstaduais != null &&
                est!.inscricoesEstaduais!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSection('Inscrição Estadual',
                  est.inscricoesEstaduais!.map((ie) {
                final ativo = ie.ativo == true;
                final cor = ativo ? success : error;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2538),
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ie.inscricaoEstadual ?? "-",
                                style: const TextStyle(
                                    color: textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                              if (ie.estado?.sigla != null)
                                Text(
                                  '${ie.estado!.nome} (${ie.estado!.sigla})',
                                  style: const TextStyle(
                                      color: textSecondary, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cor.withAlpha(25),
                            border: Border.all(color: cor.withAlpha(80)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (ativo ? 'Ativo' : 'Inativo').toUpperCase(),
                            style: TextStyle(
                                color: cor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()),
            ],
            if (data.simples != null) ...[
              const SizedBox(height: 12),
              _buildSection('Simples Nacional / MEI', [
                _row('Simples Nacional',
                    data.isSimples ? 'Sim' : 'Não'),
                if (data.isSimples)
                  _row('Data Opção', data.simples!.dataOpcaoSimples),
                if (!data.isSimples &&
                    data.simples!.dataExclusaoSimples != null)
                  _row('Data Exclusão', data.simples!.dataExclusaoSimples),
                _row('MEI', data.isMei ? 'Sim' : 'Não'),
                if (data.isMei)
                  _row('Data Opção MEI', data.simples!.dataOpcaoMei),
                if (!data.isMei && data.simples!.dataExclusaoMei != null)
                  _row('Data Exclusão MEI', data.simples!.dataExclusaoMei),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cnpj = _cnpjFormat(data.estabelecimento?.cnpj);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162033), Color(0xFF0F1724)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            data.razaoSocial ?? 'Empresa Não Informada',
            style: const TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                cnpj,
                style: const TextStyle(
                  color: highlight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(context, cnpj, 'CNPJ'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: highlight.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: highlight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: highlight.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: highlight, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: highlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: highlight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String? value, [Widget? trailing]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: trailing ??
                Text(
                  value?.isNotEmpty == true ? value! : 'Não informado',
                  style: TextStyle(
                    color: value?.isNotEmpty == true
                        ? textPrimary
                        : textMuted,
                    fontSize: 13,
                    fontWeight: value?.isNotEmpty == true
                        ? FontWeight.w500
                        : FontWeight.w400,
                    fontStyle: value?.isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final cor = _statusColor(status);
    final texto = _statusText(status);
    if (texto.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _buildShareText() {
    final est = data.estabelecimento;
    final buf = StringBuffer();
    buf.writeln('*${data.razaoSocial ?? "Sem nome"}*');
    buf.writeln('CNPJ: ${_cnpjFormat(est?.cnpj)}');
    buf.writeln('');
    buf.writeln('*Dados da Empresa*');
    buf.writeln('Fantasia: ${est?.nomeFantasia ?? "-"}');
    buf.writeln('Porte: ${data.porte?.descricao ?? "-"}');
    buf.writeln('Capital Social: ${data.capitalSocial ?? "-"}');
    buf.writeln('Abertura: ${est?.dataInicioAtividade ?? "-"}');
    buf.writeln('');
    buf.writeln('*Contato*');
    buf.writeln('E-mail: ${est?.email ?? "-"}');
    if (est?.ddd1 != null) {
      buf.writeln('Tel: (${est!.ddd1}) ${est.telefone1}');
    }
    buf.writeln('');
    buf.writeln('Consulta CNPJ - App');
    return buf.toString();
  }
}
