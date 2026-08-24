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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cnpjController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = CnpjApiService();
  final _storage = StorageService();
  final _resultKey = GlobalKey();

  bool _loading = false;
  CnpjResponse? _result;
  String? _errorMessage;
  bool _isFavorite = false;

  @override
  void dispose() {
    _cnpjController.dispose();
    super.dispose();
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
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
    );
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
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        title: const Text(
          'Consulta CNPJ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF161b22),
        foregroundColor: const Color(0xFFe6edf3),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(
            height: 1,
            color: const Color(0xFF30363d),
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFe6edf3)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchCard(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: Color(0xFF2f81f7)),
              ),
            if (_errorMessage != null)
              _buildErrorCard(),
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF161b22),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF30363d)),
              ),
            ),
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF161b22)),
              accountName: const Text(
                'Consulta CNPJ',
                style: TextStyle(
                    color: Color(0xFFe6edf3), fontWeight: FontWeight.w600),
              ),
              accountEmail: const Text(
                'Versão 3.0',
                style: TextStyle(color: Color(0xFF8b949e), fontSize: 13),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFF21262d),
                child: Icon(Icons.business, color: Colors.grey[400], size: 28),
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
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8b949e)),
      title: Text(title,
          style: const TextStyle(color: Color(0xFFe6edf3), fontSize: 15)),
      onTap: onTap,
    );
  }

  Future<bool> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Sair',
            style: TextStyle(color: Color(0xFFe6edf3), fontSize: 16)),
        content: const Text(
          'Deseja realmente sair?',
          style: TextStyle(color: Color(0xFF8b949e), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF8b949e))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair',
                style: TextStyle(color: Color(0xFFf85149))),
          ),
        ],
      ),
    ).then((v) => v ?? false);
  }

  Widget _buildSearchCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _cnpjController,
              style: const TextStyle(
                  color: Color(0xFFe6edf3), fontSize: 16, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.number,
              maxLength: 18,
              decoration: InputDecoration(
                counterText: '',
                hintText: '00.000.000/0000-00',
                hintStyle: const TextStyle(
                    color: Color(0xFF484f58), fontSize: 16, fontWeight: FontWeight.w500),
                filled: true,
                fillColor: const Color(0xFF21262d),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363d)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363d)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2f81f7), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Icon(Icons.search,
                      color: Color(0xFF8b949e), size: 20),
                ),
              ),
              onChanged: _onCnpjChange,
              onFieldSubmitted: (_) => _consultar(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF238636),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _consultar,
                      child: const Text('CONSULTAR',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21262d),
                        foregroundColor: const Color(0xFFc9d1d9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFF30363d)),
                        elevation: 0,
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
                      child: const Text('HISTÓRICO',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFf85149), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFe6edf3), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final est = _result!.estabelecimento;
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
                          style: const TextStyle(
                              color: Color(0xFFe6edf3), fontSize: 13)),
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

  Widget _dataCard(IconData icon, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF58a6ff)),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF58a6ff),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _dataItem(String label, String? value, {Widget? trailing}) {
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
                  style: const TextStyle(
                    color: Color(0xFF8b949e),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                trailing ??
                    Text(
                      value?.isNotEmpty == true ? value! : 'Não informado',
                      style: TextStyle(
                        color: value?.isNotEmpty == true
                            ? const Color(0xFFe6edf3)
                            : const Color(0xFF484f58),
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
    return Container(
      height: 1,
      color: const Color(0xFF21262d),
      margin: const EdgeInsets.symmetric(vertical: 6),
    );
  }

  Color _statusColor(String? status) {
    if (status == null) return const Color(0xFF8b949e);
    final s = status.toLowerCase();
    if (s == 'ativo' || s == 'at') return const Color(0xFF3fb950);
    if (s == 'suspenso' || s == 'sp') return const Color(0xFFd29922);
    if (s == 'inapto' || s == 'in') return const Color(0xFFf85149);
    return const Color(0xFF8b949e);
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1f2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF374151)),
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
                    style: const TextStyle(
                      color: Color(0xFFe6edf3),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cnpjFormat(est?.cnpj),
                    style: const TextStyle(
                      color: Color(0xFF58a6ff),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 16, color: Color(0xFF58a6ff)),
              const SizedBox(width: 8),
              const Text(
                'INSCRIÇÃO ESTADUAL',
                style: TextStyle(
                  color: Color(0xFF58a6ff),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...inscricoes.map((ie) {
            final ativo = ie.ativo == true;
            final cor = ativo
                ? const Color(0xFF3fb950)
                : const Color(0xFFf85149);
            final texto = ativo ? 'Ativo' : 'Inativo';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF21262d),
                border: Border.all(color: const Color(0xFF30363d)),
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
                            color: Color(0xFFe6edf3),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (ie.estado?.sigla != null)
                          Text(
                            '${ie.estado!.nome} (${ie.estado!.sigla})',
                            style: const TextStyle(
                              color: Color(0xFF8b949e),
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
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        border: Border.all(color: const Color(0xFF30363d)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                onPressed: _shareImage,
                child: const Text('COMPARTILHAR',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1f6feb),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                onPressed: _generatePdf,
                child: const Text('GERAR PDF',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFavorite
                      ? const Color(0xFF21262d)
                      : const Color(0xFF21262d),
                  foregroundColor: _isFavorite
                      ? const Color(0xFFd29922)
                      : const Color(0xFFc9d1d9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFF30363d)),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  size: 14,
                ),
                label: Text(
                  _isFavorite ? 'FAVORITADO' : 'FAVORITAR',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600),
                ),
                onPressed: _toggleFavorite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
