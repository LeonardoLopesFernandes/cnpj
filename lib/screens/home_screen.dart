import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/cnpj_response.dart';
import '../models/empresa.dart';
import '../services/cnpj_api_service.dart';
import '../services/storage_service.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';

extension BuildContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _cnpjController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = CnpjApiService();
  final _storage = StorageService();
  final _resultKey = GlobalKey();

  bool _loading = false;
  CnpjResponse? _result;
  String? _errorMessage;
  bool _isFavorite = false;
  List<Empresa> _recentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadRecentHistory();
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentHistory() async {
    final history = await _storage.getHistory();
    if (mounted) {
      setState(() {
        _recentHistory = history.take(5).toList();
      });
    }
  }

  void _onCnpjChange(String value) {
    final digits = value.replaceAll(RegExp(r'[.\-/]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 14; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    if (formatted != value) {
      _cnpjController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String _cleanCnpj() {
    return _cnpjController.text.replaceAll(RegExp(r'[.\-/]'), '');
  }

  Future<void> _consultar() async {
    final cnpj = _cleanCnpj();
    if (cnpj.length != 14) {
      _showSnack('CNPJ inválido. Digite 14 dígitos.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _apiService.fetchCnpj(cnpj);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });

      final empresa = Empresa(
        razaoSocial: result.razaoSocial,
        cnpj: cnpj,
      );
      await _storage.addToHistory(empresa);
      _checkFavorite();
      _loadRecentHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _checkFavorite() async {
    if (_result == null) return;
    final cnpj = _cnpjController.text.replaceAll(RegExp(r'[.\-/]'), '');
    final fav = await _storage.isFavorite(cnpj);
    if (mounted) {
      setState(() => _isFavorite = fav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_result == null) return;
    final cnpj = _cleanCnpj();
    final empresa = Empresa(razaoSocial: _result!.razaoSocial, cnpj: cnpj);
    await _storage.toggleFavorite(empresa);
    _checkFavorite();
  }

  String _cnpjFormat(String? cnpj) {
    final c = cnpj ?? '';
    if (c.length != 14) return c;
    return '${c.substring(0, 2)}.${c.substring(2, 5)}.'
        '${c.substring(5, 8)}/${c.substring(8, 12)}-${c.substring(12)}';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1E3A5F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyCnpj() {
    final cnpj = _cnpjFormat(_result?.estabelecimento?.cnpj);
    if (cnpj.isEmpty) return;
    Clipboard.setData(ClipboardData(text: cnpj));
    _showSnack('CNPJ copiado!');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _clearSearch() {
    _cnpjController.clear();
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _shareImage() async {
    if (_result == null) return;
    _showSnack('Gerando imagem...');
    try {
      final bytes = await _renderShareImage(_result!);
      if (!mounted) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cnpj_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Consulta CNPJ',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro ao gerar imagem. Tente novamente.');
    }
  }

  Future<void> _generatePdf() async {
    if (_result == null) return;
    _showSnack('Gerando PDF...');
    try {
      final data = _result!;

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Emitido em ${_formatDate(DateTime.now())} - Consulta CNPJ',
              style: pw.TextStyle(
                  fontSize: 8, color: PdfColor.fromInt(0xFF555555)),
            ),
          ),
          build: (ctx) => [
            pw.Container(
              width: double.infinity,
              color: PdfColor.fromInt(0xFF1a5276),
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: pw.Text(
                'CONSULTA CNPJ - RELATÓRIO DE INSCRIÇÃO',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            for (final section in _documentSections(data))
              _pdfSection(section.$1, section.$2),
            pw.SizedBox(height: 20),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cnpj_report.pdf');
      await file.writeAsBytes(await doc.save());
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Relatório CNPJ',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro ao gerar PDF. Tente novamente.');
    }
  }

  pw.Widget _pdfSection(String title, List<(String, String)> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(height: 14),
        pw.Container(
          color: PdfColor.fromInt(0xFF1a5276),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFe0e0e0)),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(3),
          },
          children: [
            for (final r in rows)
              pw.TableRow(
                children: [
                  _pdfCell(r.$1, label: true),
                  _pdfCell(r.$2),
                ],
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool label = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: label
              ? PdfColor.fromInt(0xFF1a5276)
              : PdfColor.fromInt(0xFF000000),
          fontSize: 10,
          fontWeight: label ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  List<(String, List<(String, String)>)> _documentSections(CnpjResponse data) {
    final est = data.estabelecimento;
    final endereco = [
      est?.tipoLogradouro ?? '',
      est?.logradouro ?? '',
    ].where((p) => p.isNotEmpty).join(' ');
    final numero = est?.numero?.isNotEmpty == true ? est!.numero : null;
    final enderecoFinal =
        numero == null ? endereco : '$endereco, $numero';
    final cidadeUf = [
      est?.cidade?.nome,
      est?.estado?.sigla,
    ].whereType<String>().join('/');
    final tel1 = formatTelefone(est?.ddd1, est?.telefone1);
    final tel2 = formatTelefone(est?.ddd2, est?.telefone2);

    String orDash(String? v) =>
        v?.isNotEmpty == true ? v! : 'Não informado';

    return [
      (
        'Identificação',
        [
          ('Inscrição Estadual', _formatInscricoes(est?.inscricoesEstaduais)),
          ('CNPJ/CPF', orDash(est?.cnpj)),
          ('Razão Social', orDash(data.razaoSocial)),
          ('Nome Fantasia', orDash(est?.nomeFantasia)),
          ('Natureza Jurídica', orDash(data.naturezaJuridica?.descricao)),
          ('Porte da Empresa', orDash(data.porte?.descricao)),
          ('Capital Social', orDash(data.capitalSocial)),
          ('Data de Abertura', orDash(est?.dataInicioAtividade)),
          ('Atividade Econômica (CNAE)',
              _formatCnae(est?.atividadePrincipal)),
        ],
      ),
      (
        'Contato',
        [
          ('Endereço', orDash(enderecoFinal)),
          ('Bairro', orDash(est?.bairro)),
          ('CEP', orDash(est?.cep)),
          ('Cidade/UF', orDash(cidadeUf.isEmpty ? null : cidadeUf)),
          ('Telefone', orDash(tel1.isEmpty ? null : tel1)),
          if (est?.ddd2 != null) ('Telefone 2', orDash(tel2.isEmpty ? null : tel2)),
          ('E-mail', orDash(est?.email)),
        ],
      ),
      (
        'Informações Complementares',
        [
          ('Situação Cadastral', orDash(est?.situacaoCadastral)),
          ('Qualificação do Responsável',
              orDash(data.qualificacaoResponsavel?.descricao)),
          ('Sócios', _formatSocios(data.socios)),
          ('Simples Nacional', data.isSimples ? 'Sim' : 'Não'),
          if (data.simples != null && data.isSimples)
            ('Data Opção Simples', orDash(data.simples!.dataOpcaoSimples)),
          if (data.simples != null &&
              !data.isSimples &&
              data.simples!.dataExclusaoSimples != null)
            ('Data Exclusão Simples',
                orDash(data.simples!.dataExclusaoSimples)),
          ('MEI', data.isMei ? 'Sim' : 'Não'),
          if (data.simples != null && data.isMei)
            ('Data Opção MEI', orDash(data.simples!.dataOpcaoMei)),
          if (data.simples != null &&
              !data.isMei &&
              data.simples!.dataExclusaoMei != null)
            ('Data Exclusão MEI', orDash(data.simples!.dataExclusaoMei)),
          ('Atividades Secundárias',
              _formatSecundarias(est?.atividadesSecundarias)),
        ],
      ),
    ];
  }

  String _formatCnae(Atividade? a) {
    if (a == null) return 'Não informado';
    final parts = [a.id, a.descricao].whereType<String>().toList();
    return parts.isEmpty ? 'Não informado' : parts.join(' - ');
  }

  String _formatSecundarias(List<Atividade>? list) {
    if (list == null || list.isEmpty) return 'Não informado';
    return list
        .map((a) => [a.id, a.descricao].whereType<String>().join(' - '))
        .join('\n');
  }

  String _formatSocios(List<Socio>? list) {
    if (list == null || list.isEmpty) return 'Não informado';
    return list
        .map((s) => [
              s.nome,
              s.qualificacaoSocio?.descricao ?? s.tipo,
            ].whereType<String>().join(' - '))
        .join('\n');
  }

  String _formatInscricoes(List<InscricaoEstadualCompleta>? list) {
    if (list == null || list.isEmpty) return 'Não informado';
    return list
        .map((ie) => [
              ie.inscricaoEstadual,
              ie.estado?.sigla,
              ie.ativo == true ? 'Ativo' : 'Inativo',
            ].whereType<String>().join(' - '))
        .join('\n');
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  Future<Uint8List> _renderShareImage(CnpjResponse data) async {
    const double scale = 3.0;
    const double width = 1080;
    const double padding = 40;
    const double labelW = 400;
    const Color bg = Color(0xFFFFFFFF);
    const Color blue = Color(0xFF1a5276);
    const Color borderC = Color(0xFFe0e0e0);
    const Color valueC = Color(0xFF000000);
    const Color footerC = Color(0xFF555555);
    const Color titleBarC = Color(0xFF1a5276);

    TextPainter buildText(String text, TextStyle style, {double? maxWidth}) {
      final t = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth ?? double.infinity);
      return t;
    }

    final title = buildText(
      'CONSULTA CNPJ - RELATÓRIO DE INSCRIÇÃO',
      const TextStyle(
          color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
      maxWidth: width - padding * 2,
    );

    final sectionPainters = <(TextPainter, List<(TextPainter, TextPainter)>)>[];
    for (final s in _documentSections(data)) {
      final header = buildText(
        s.$1.toUpperCase(),
        const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        maxWidth: width - padding * 2,
      );
      final rows = <(TextPainter, TextPainter)>[];
      for (final r in s.$2) {
        final l = buildText(
          r.$1,
          const TextStyle(
              color: blue, fontSize: 24, fontWeight: FontWeight.bold),
          maxWidth: labelW,
        );
        final v = buildText(
          r.$2,
          const TextStyle(color: valueC, fontSize: 24),
          maxWidth: width - padding * 2 - labelW,
        );
        rows.add((l, v));
      }
      sectionPainters.add((header, rows));
    }

    final footer = buildText(
      'Emitido em ${_formatDate(DateTime.now())} - Consulta CNPJ',
      const TextStyle(color: footerC, fontSize: 20),
    );

    const titleBarH = 110.0;
    const headerH = 58.0;
    const rowGap = 20.0;
    const secGap = 26.0;

    double y = padding + titleBarH + secGap;
    for (final (_, rows) in sectionPainters) {
      y += headerH + 4;
      for (final (l, v) in rows) {
        y += (l.height > v.height ? l.height : v.height) + rowGap;
      }
      y += secGap;
    }
    y += footer.height + padding;
    final height = y.ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height.toDouble()),
      Paint()..color = bg,
    );

    canvas.drawRect(Rect.fromLTWH(0, 0, width, titleBarH), Paint()..color = titleBarC);
    title.paint(
      canvas,
      Offset((width - title.width) / 2, (titleBarH - title.height) / 2),
    );

    double yy = padding + titleBarH + secGap;
    for (final (header, rows) in sectionPainters) {
      canvas.drawRect(Rect.fromLTWH(0, yy, width, headerH), Paint()..color = blue);
      header.paint(
        canvas,
        Offset(padding, yy + (headerH - header.height) / 2),
      );
      yy += headerH + 4;
      for (final (l, v) in rows) {
        l.paint(canvas, Offset(padding, yy));
        v.paint(canvas, Offset(padding + labelW, yy));
        final rowH = l.height > v.height ? l.height : v.height;
        yy += rowH + rowGap;
        canvas.drawLine(
          Offset(padding, yy),
          Offset(width - padding, yy),
          Paint()
            ..color = borderC
            ..strokeWidth = 2,
        );
      }
      yy += secGap;
    }

    footer.paint(canvas, Offset((width - footer.width) / 2, yy));

    final picture = recorder.endRecording();
    final image =
        await picture.toImage((width * scale).toInt(), (height * scale).toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('Falha ao gerar imagem');
    return byteData.buffer.asUint8List();
  }

  void _openDetail() {
    if (_result == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(data: _result!),
      ),
    );
  }

  String formatTelefone(String? ddd, String? numero) {
    if (ddd == null || numero == null) return '';
    final n = numero.length == 8
        ? '${numero.substring(0, 4)}-${numero.substring(4)}'
        : '${numero.substring(0, 5)}-${numero.substring(5)}';
    return '($ddd) $n';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final surfaceColor = theme.scaffoldBackgroundColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;
    final accentBlue = theme.colorScheme.secondary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await _showExitDialog();
        if (confirm && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          title: const Text(
            'Consulta CNPJ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          backgroundColor: cardColor,
          foregroundColor: textPrimary,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
              height: 1,
              color: borderColor,
            ),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: textPrimary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_result == null && !_loading && _errorMessage == null)
                _buildWelcomeSection(),
              _buildSearchCard(),
              const SizedBox(height: 16),
              if (_result == null && !_loading && _errorMessage == null && _recentHistory.isNotEmpty)
                _buildRecentSearches(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              if (_errorMessage != null)
                _buildErrorCard(),
              if (_result == null && !_loading && _errorMessage != null)
                _buildEmptyState(),
              if (_result != null && !_loading)
                RepaintBoundary(
                  key: _resultKey,
                  child: _buildResultCard(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final theme = context.theme;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withOpacity(0.15),
            primaryBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icons/cnpj_logo.png',
              width: 48,
              height: 48,
              errorBuilder: (_, __, ___) => Icon(
                Icons.business,
                size: 48,
                color: primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _getGreeting(),
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Consulta CNPJ',
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Consulte informações de empresas pelo CNPJ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;

    if (_recentHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Buscas recentes',
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentHistory.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final empresa = _recentHistory[index];
              final cnpj = empresa.cnpj ?? '';
              final display = cnpj.length == 14 ? _cnpjFormat(cnpj) : cnpj;
              return ActionChip(
                label: Text(
                  empresa.razaoSocial?.isNotEmpty == true
                      ? empresa.razaoSocial!
                      : display,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12,
                  ),
                ),
                avatar: Icon(Icons.history, size: 16, color: primaryBlue),
                backgroundColor: cardColor,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  _cnpjController.text = _formatCnpjForInput(cnpj);
                  _consultar();
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Consulta não encontrada',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verifique o CNPJ e tente novamente',
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;

    return Drawer(
      backgroundColor: cardColor,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: cardColor),
              accountName: Text(
                'Consulta CNPJ',
                style: TextStyle(
                    color: textPrimary, fontWeight: FontWeight.w600),
              ),
              accountEmail: Text(
                'Versão 3.0',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryBlue.withOpacity(0.3),
                      primaryBlue.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/icons/cnpj_logo.png',
                    width: 64,
                    height: 64,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.business,
                      size: 28,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _drawerItem(Icons.home, 'Inicio', () {
            Navigator.pop(context);
          }),
          _drawerItem(Icons.favorite_border, 'Favoritos', () async {
            Navigator.pop(context);
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            );
            if (result != null) {
              _cnpjController.text = _formatCnpjForInput(result);
              _consultar();
            }
          }),
          _drawerItem(Icons.history, 'Histórico', () async {
            Navigator.pop(context);
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
            if (result != null) {
              _cnpjController.text = _formatCnpjForInput(result);
              _consultar();
            }
          }),
          _drawerItem(Icons.share, 'Compartilhar App', () {
            Navigator.pop(context);
            Share.share('Confira o aplicativo Consulta CNPJ!');
          }),
          const Spacer(),
          _drawerItem(Icons.exit_to_app, 'Sair', () async {
            Navigator.pop(context);
            final confirm = await _showExitDialog();
            if (confirm && context.mounted) {
              SystemNavigator.pop();
            }
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatCnpjForInput(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.'
        '${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12)}';
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    final theme = context.theme;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);

    return ListTile(
      leading: Icon(icon, color: textSecondary),
      title: Text(title,
          style: TextStyle(color: textPrimary, fontSize: 15)),
      onTap: onTap,
    );
  }

  Future<bool> _showExitDialog() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/icons/cnpj_logo.png',
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.business,
                  size: 40,
                  color: primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Deseja sair do app?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Você tem certeza que deseja encerrar o aplicativo?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text('Sair', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).then((v) => v ?? false);
  }

  Widget _buildSearchCard() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;
    final accentBlue = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _cnpjController,
              style: TextStyle(
                  color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.number,
              maxLength: 18,
              decoration: InputDecoration(
                counterText: '',
                hintText: '00.000.000/0000-00',
                hintStyle: TextStyle(
                    color: textSecondary.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w500),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? borderColor.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryBlue, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Icon(Icons.search,
                      color: textSecondary, size: 20),
                ),
                suffixIcon: _cnpjController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: textSecondary, size: 20),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: _onCnpjChange,
              onFieldSubmitted: (_) => _consultar(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _consultar,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search, size: 18),
                      child: const Text('CONSULTAR',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: borderColor),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
                      );
                      if (result != null) {
                        _cnpjController.text =
                            _formatCnpjForInput(result);
                        _consultar();
                      }
                    },
                    child: Icon(Icons.history, color: textSecondary, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFEF4444), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final est = _result!.estabelecimento;
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          _buildCompanyHeader(),
          const SizedBox(height: 12),
          _buildCopyCnpjButton(),
          const SizedBox(height: 12),
          _dataCard(Icons.info_outline, 'Informações da Empresa', [
            _dataItem('Nome Fantasia', est?.nomeFantasia),
            _divider(),
            _dataItem('Porte', _result!.porte?.descricao),
            _divider(),
            _dataItem('Capital Social', _result!.capitalSocial),
            _divider(),
            _dataItem('Natureza Jurídica', _result!.naturezaJuridica?.descricao),
            _divider(),
            _dataItem('Atividade Principal', est?.atividadePrincipal?.descricao),
            _divider(),
            _dataItem('Data Abertura', est?.dataInicioAtividade),
            _divider(),
            _dataItem('Situação Cadastral', est?.situacaoCadastral,
                trailing: _statusBadge(est?.situacaoCadastral)),
            if (_result!.qualificacaoResponsavel?.descricao != null) ...[
              _divider(),
              _dataItem('Qualificação Resp.',
                  _result!.qualificacaoResponsavel?.descricao),
            ],
          ]),
          const SizedBox(height: 12),
          _dataCard(Icons.location_on_outlined, 'Localização', [
            _dataItem('Endereço',
                '${est?.tipoLogradouro ?? ''} ${est?.logradouro ?? ''}, ${est?.numero ?? ''}${est?.complemento != null ? ' - ${est?.complemento}' : ''}'),
            _divider(),
            _dataItem('Bairro', est?.bairro),
            _divider(),
            _dataItem('CEP', est?.cep),
            _divider(),
            _dataItem('Cidade/UF',
                '${est?.cidade?.nome ?? ''}/${est?.estado?.sigla ?? ''}'),
            _divider(),
            _dataItem('País', est?.pais?.nome),
          ]),
          const SizedBox(height: 12),
          _dataCard(Icons.phone_outlined, 'Contato', [
            _dataItem('E-mail', est?.email),
            _divider(),
            _dataItem('Telefone',
                formatTelefone(est?.ddd1, est?.telefone1)),
            if (est?.ddd2 != null) ...[
              _divider(),
              _dataItem('Telefone 2',
                  formatTelefone(est?.ddd2, est?.telefone2)),
            ],
          ]),
          if (_result!.socios != null && _result!.socios!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _dataCard(Icons.people_outline, 'Sócios (${_result!.socios!.length})',
                _result!.socios!.map((s) {
              return _dataItem(s.nome ?? '-',
                  s.qualificacaoSocio?.descricao ?? s.tipo);
            }).toList()),
          ],
          if (est?.atividadesSecundarias != null &&
              est!.atividadesSecundarias!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _dataCard(
              Icons.work_outline,
              'Atividades Secundárias',
              est.atividadesSecundarias!
                  .take(3)
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(a.descricao ?? '-',
                            style: TextStyle(
                                color: textPrimary, fontSize: 13)),
                      ))
                  .toList(),
            ),
          ],
          if (est?.inscricoesEstaduais != null &&
              est!.inscricoesEstaduais!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInscricaoEstadualCard(est.inscricoesEstaduais!),
          ],
          if (_result!.simples != null) ...[
            const SizedBox(height: 12),
            _dataCard(Icons.receipt_outlined, 'Simples Nacional / MEI', [
              _dataItem('Simples Nacional',
                  _result!.isSimples ? 'Sim' : 'Não'),
              if (_result!.isSimples)
                _dataItem('Data Opção', _result!.simples!.dataOpcaoSimples),
              if (!_result!.isSimples &&
                  _result!.simples!.dataExclusaoSimples != null)
                _dataItem('Data Exclusão', _result!.simples!.dataExclusaoSimples),
              _divider(),
              _dataItem('MEI', _result!.isMei ? 'Sim' : 'Não'),
              if (_result!.isMei)
                _dataItem('Data Opção MEI', _result!.simples!.dataOpcaoMei),
              if (!_result!.isMei &&
                  _result!.simples!.dataExclusaoMei != null)
                _dataItem('Data Exclusão MEI', _result!.simples!.dataExclusaoMei),
            ]),
          ],
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCopyCnpjButton() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final primaryBlue = theme.primaryColor;

    final cnpj = _cnpjFormat(_result?.estabelecimento?.cnpj);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _copyCnpj,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.copy, size: 18, color: primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CNPJ',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        cnpj,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.content_copy, size: 16, color: theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dataCard(IconData icon, String title, List<Widget> children) {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final primaryBlue = theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: primaryBlue, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataItem(String label, String? value, {Widget? trailing}) {
    final theme = context.theme;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                trailing ??
                    Text(
                      value?.isNotEmpty == true ? value! : 'Não informado',
                      style: TextStyle(
                        color: value?.isNotEmpty == true
                            ? textPrimary
                            : textSecondary.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight:
                            value?.isNotEmpty == true ? FontWeight.w500 : FontWeight.w400,
                        fontStyle: value?.isNotEmpty == true
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    final theme = context.theme;
    final borderColor = theme.dividerColor;

    return Container(
      height: 1,
      color: borderColor.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 6),
    );
  }

  Color _statusColor(String? status) {
    if (status == null) return const Color(0xFF94A3B8);
    final s = status.toLowerCase();
    if (s == 'ativo' || s == 'at') return const Color(0xFF22C55E);
    if (s == 'suspenso' || s == 'sp') return const Color(0xFFF59E0B);
    if (s == 'inapto' || s == 'in') return const Color(0xFFEF4444);
    return const Color(0xFF94A3B8);
  }

  String _statusText(String? status) {
    if (status == null) return '';
    final s = status.toLowerCase();
    if (s == 'at' || s == 'ativo') return 'Ativo';
    if (s == 'sp' || s == 'suspenso') return 'Suspenso';
    if (s == 'in' || s == 'inapto') return 'Inapto';
    return status;
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

  Widget _buildCompanyHeader() {
    final est = _result!.estabelecimento;
    final status = est?.situacaoCadastral;
    final cor = _statusColor(status);
    final texto = _statusText(status);
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final primaryBlue = theme.primaryColor;
    final accentBlue = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue.withOpacity(0.15),
            cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: GestureDetector(
        onTap: _openDetail,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _result!.razaoSocial ?? 'Empresa Não Informada',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cnpjFormat(est?.cnpj),
                    style: TextStyle(
                      color: accentBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cor.withAlpha(25),
                  border: Border.all(color: cor.withAlpha(100)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  texto.toUpperCase(),
                  style: TextStyle(
                    color: cor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInscricaoEstadualCard(
      List<InscricaoEstadualCompleta> inscricoes) {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final textSecondary = theme.textTheme.bodySmall?.color ?? const Color(0xFF94A3B8);
    final primaryBlue = theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: primaryBlue, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.article_outlined, size: 16, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'INSCRIÇÃO ESTADUAL',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: inscricoes.map((ie) {
                final ativo = ie.ativo == true;
                final cor = ativo
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444);
                final texto = ativo ? 'Ativo' : 'Inativo';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.3),
                    border: Border.all(color: borderColor),
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
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (ie.estado?.sigla != null)
                              Text(
                                '${ie.estado!.nome} (${ie.estado!.sigla})',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
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
                          texto.toUpperCase(),
                          style: TextStyle(
                            color: cor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = context.theme;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFE2E8F0);
    final primaryBlue = theme.primaryColor;
    final accentBlue = theme.colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _shareImage,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('COMPARTILHAR IMAGEM',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _generatePdf,
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('GERAR PDF',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFavorite
                    ? const Color(0xFFF59E0B).withOpacity(0.15)
                    : cardColor,
                foregroundColor: _isFavorite
                    ? const Color(0xFFF59E0B)
                    : textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                    color: _isFavorite
                        ? const Color(0xFFF59E0B).withOpacity(0.4)
                        : borderColor),
                elevation: 0,
              ),
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                size: 18,
              ),
              label: Text(
                _isFavorite ? 'FAVORITADO' : 'FAVORITAR',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
