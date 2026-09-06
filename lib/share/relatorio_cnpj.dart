import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/cnpj_response.dart';

const azulReceita = Color(0xFF0A5091);
const cinzaBorda = Color(0xFFD4D4D4);
const cinzaRotulo = Color(0xFF808080);
const textoEscuro = Color(0xFF1A1A1A);

class ItemRelatorio {
  final String rotulo;
  final String valor;
  const ItemRelatorio(this.rotulo, this.valor);
}

class SecaoRelatorio {
  final String titulo;
  final List<ItemRelatorio> grade;
  final String? subRotuloLista;
  final List<String> lista;
  const SecaoRelatorio({
    required this.titulo,
    this.grade = const [],
    this.subRotuloLista,
    this.lista = const [],
  });
}

class RelatorioCnpj {
  final String nome;
  final String cnpj;
  final List<SecaoRelatorio> secoes;
  const RelatorioCnpj({
    required this.nome,
    required this.cnpj,
    required this.secoes,
  });
}

String _v(String? s) =>
    (s == null || s.trim().isEmpty) ? 'Não informado' : s.trim();

String _cnpjFmt(String? cnpj) {
  final c = (cnpj ?? '').replaceAll(RegExp(r'\D'), '');
  if (c.length != 14) return cnpj ?? '';
  return '${c.substring(0, 2)}.${c.substring(2, 5)}.'
      '${c.substring(5, 8)}/${c.substring(8, 12)}-${c.substring(12)}';
}

String _tel(String? ddd, String? numero) {
  if (ddd == null || ddd.isEmpty || numero == null || numero.isEmpty) return '';
  final n = numero.length == 8
      ? '${numero.substring(0, 4)}-${numero.substring(4)}'
      : (numero.length > 8
          ? '${numero.substring(0, numero.length - 4)}-${numero.substring(numero.length - 4)}'
          : numero);
  return '($ddd) $n';
}

RelatorioCnpj montarRelatorio(CnpjResponse d) {
  final est = d.estabelecimento;
  final endereco =
      '${_v(est?.tipoLogradouro == null || est?.tipoLogradouro?.isEmpty == true ? null : est?.tipoLogradouro)} ${_v(est?.logradouro)}'
          .trim();
  final enderecoFull = [
    '$endereco, ${est?.numero ?? 'S/N'}',
    if ((est?.complemento ?? '').isNotEmpty) est!.complemento!,
    '${_v(est?.bairro)} - CEP: ${_v(est?.cep)}',
    '${_v(est?.cidade?.nome)}/${_v(est?.estado?.sigla)}',
  ].join(' - ');
  final tel1 = _tel(est?.ddd1, est?.telefone1);
  final tel2 = _tel(est?.ddd2, est?.telefone2);
  final nat = d.naturezaJuridica;
  final natureza = nat == null
      ? 'Não informado'
      : '${nat.id ?? ''} - ${nat.descricao ?? ''}'.trim().replaceAll(
          RegExp(r'^-\s*|\s*-$'), '');
  final atv = est?.atividadePrincipal;
  final principal = atv == null
      ? 'Não informado'
      : '${atv.subclasse ?? atv.id ?? ''} - ${atv.descricao ?? ''}';
  final secundarias = (est?.atividadesSecundarias ?? [])
      .map((a) => '${a.subclasse ?? a.id ?? ''} - ${a.descricao ?? ''}')
      .toList();
  final socios = (d.socios ?? [])
      .map((s) {
        final q = s.qualificacaoSocio?.descricao;
        return q != null && q.isNotEmpty
            ? '${s.nome ?? '-'} — $q'
            : (s.nome ?? '-');
      })
      .toList();

  return RelatorioCnpj(
    nome: _v(d.razaoSocial),
    cnpj: _cnpjFmt(est?.cnpj),
    secoes: [
      SecaoRelatorio(
        titulo: 'Identificação',
        grade: [
          ItemRelatorio('CNPJ/CPF', _cnpjFmt(est?.cnpj)),
          ItemRelatorio('Razão Social', _v(d.razaoSocial)),
          ItemRelatorio('Nome Fantasia', _v(est?.nomeFantasia)),
          ItemRelatorio('Natureza Jurídica', natureza),
          ItemRelatorio('Porte', _v(d.porte?.descricao)),
          ItemRelatorio('Capital Social', _v(d.capitalSocial)),
          ItemRelatorio('Abertura', _v(est?.dataInicioAtividade)),
          ItemRelatorio('Tipo', _v(est?.tipo)),
          ItemRelatorio('Situação Cadastral', _v(est?.situacaoCadastral)),
          ItemRelatorio(
              'Data Situação', _v(est?.dataSituacaoCadastral)),
        ],
      ),
      SecaoRelatorio(
        titulo: 'Contato',
        grade: [
          ItemRelatorio('Endereço do Estabelecimento', enderecoFull),
          ItemRelatorio('E-mail', _v(est?.email)),
          ItemRelatorio('Telefone', tel1.isEmpty ? 'Não informado' : tel1),
          ItemRelatorio('Telefone 2', tel2.isEmpty ? 'Não informado' : tel2),
        ],
      ),
      SecaoRelatorio(
        titulo: 'Informações Complementares',
        grade: [
          ItemRelatorio('Atividade Econômica (CNAE) Principal', principal),
        ],
        subRotuloLista: 'Atividade(s) Econômica(s) CNAE Secundária(s)',
        lista: secundarias.isEmpty ? ['Nenhuma informada'] : secundarias,
      ),
      SecaoRelatorio(
        titulo: 'Situação Cadastral',
        grade: [
          ItemRelatorio('Situação Cadastral', _v(est?.situacaoCadastral)),
          ItemRelatorio('Simples Nacional', d.isSimples ? 'Sim' : 'Não'),
          ItemRelatorio('MEI', d.isMei ? 'Sim' : 'Não'),
          ItemRelatorio('Atualizado em', _v(d.atualizadoEm)),
        ],
      ),
      if (socios.isNotEmpty)
        SecaoRelatorio(
          titulo: 'Quadro Societário',
          lista: socios,
        ),
    ],
  );
}

// ---------------- IMAGEM ----------------

TextPainter _tp(String texto, double maxW, double size, Color cor,
    {bool bold = false, bool center = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontSize: size,
        color: cor,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: center ? TextAlign.center : TextAlign.start,
  );
  tp.layout(maxWidth: maxW);
  return tp;
}

double _alturaCelula(
    ItemRelatorio item, double larguraCelula, double padInterno) {
  final rot = _tp(item.rotulo, larguraCelula, 20, cinzaRotulo);
  final val = _tp(item.valor, larguraCelula, 24, textoEscuro, bold: true);
  rot.dispose();
  val.dispose();
  return rot.height + 8 + val.height + padInterno * 2;
}

Future<String?> gerarImagemRelatorio(CnpjResponse d) async {
  try {
    final rel = montarRelatorio(d);
    const largura = 1080.0;
    const escala = 2.5;
    const pad = 48.0;
    const largConteudo = largura - pad * 2;
    const largCol = (largConteudo - 2) / 2;
    const padCel = 20.0;

    // Pré-medir para calcular altura
    double altura = 150; // faixa título
    final nomeTp = _tp(rel.nome, largConteudo, 36, textoEscuro,
        bold: true, center: true);
    final cnpjTp = _tp(rel.cnpj, largConteudo, 26, cinzaRotulo, center: true);
    altura += nomeTp.height + 12 + cnpjTp.height + 48;
    nomeTp.dispose();
    cnpjTp.dispose();

    final alturasSecoes = <double>[];
    for (final secao in rel.secoes) {
      double h = 72 + 24; // cabeçalho + respiro
      // grade em pares
      final grade = List<ItemRelatorio>.from(secao.grade);
      if (grade.length.isOdd) grade.add(const ItemRelatorio('', ''));
      for (var i = 0; i < grade.length; i += 2) {
        final ha = grade[i].rotulo.isEmpty && grade[i].valor.isEmpty
            ? padCel * 2
            : _alturaCelula(grade[i], largCol - padCel * 2, padCel);
        final hb = grade[i + 1].rotulo.isEmpty && grade[i + 1].valor.isEmpty
            ? padCel * 2
            : _alturaCelula(grade[i + 1], largCol - padCel * 2, padCel);
        h += ha > hb ? ha : hb;
      }
      if (secao.lista.isNotEmpty) {
        h += 12;
        if (secao.subRotuloLista != null) h += 30 + 10;
        for (final item in secao.lista) {
          final tp = _tp(item, largConteudo - padCel * 2, 23, textoEscuro);
          h += tp.height + 12;
          tp.dispose();
        }
        h += 12;
      }
      h += 40; // espaço após seção
      alturasSecoes.add(h);
      altura += h;
    }
    altura += 90; // rodapé

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(escala);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, largura, altura),
      Paint()..color = Colors.white,
    );

    void texto(String t, double x, double y, double maxW, double size,
        Color cor,
        {bool bold = false, bool center = false}) {
      final tp = _tp(t, maxW, size, cor, bold: bold, center: center);
      tp.paint(canvas, Offset(x, y));
      tp.dispose();
    }

    double y = 0;
    // faixa título
    canvas.drawRect(
        Rect.fromLTWH(0, 0, largura, 150), Paint()..color = azulReceita);
    texto('CONSULTA CNPJ', 0, 48, largura, 44, Colors.white,
        bold: true, center: true);
    y = 150 + 36;
    // nome + cnpj centralizados
    {
      final n = _tp(rel.nome, largConteudo, 36, textoEscuro,
          bold: true, center: true);
      n.paint(canvas, Offset(pad, y));
      y += n.height + 12;
      n.dispose();
      final c = _tp(rel.cnpj, largConteudo, 26, cinzaRotulo, center: true);
      c.paint(canvas, Offset(pad, y));
      y += c.height + 48;
      c.dispose();
    }

    final tintaBorda = Paint()
      ..color = cinzaBorda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var s = 0; s < rel.secoes.length; s++) {
      final secao = rel.secoes[s];
      // cabeçalho azul
      canvas.drawRect(
          Rect.fromLTWH(pad, y, largConteudo, 72),
          Paint()..color = azulReceita);
      texto(secao.titulo, pad + 24, y + 18, largConteudo - 48, 26,
          Colors.white,
          bold: true);
      y += 72;
      final topoCaixa = y;

      final grade = List<ItemRelatorio>.from(secao.grade);
      if (grade.length.isOdd) grade.add(const ItemRelatorio('', ''));
      for (var i = 0; i < grade.length; i += 2) {
        final a = grade[i];
        final b = grade[i + 1];
        final ha = a.rotulo.isEmpty && a.valor.isEmpty
            ? padCel * 2
            : _alturaCelula(a, largCol - padCel * 2, padCel);
        final hb = b.rotulo.isEmpty && b.valor.isEmpty
            ? padCel * 2
            : _alturaCelula(b, largCol - padCel * 2, padCel);
        final hLinha = ha > hb ? ha : hb;
        if (i > 0) {
          canvas.drawLine(Offset(pad, y), Offset(pad + largConteudo, y),
              tintaBorda);
        }
        // divisor vertical
        canvas.drawLine(Offset(pad + largCol + 1, y),
            Offset(pad + largCol + 1, y + hLinha), tintaBorda);
        if (a.rotulo.isNotEmpty || a.valor.isNotEmpty) {
          texto(a.rotulo, pad + padCel, y + padCel, largCol - padCel * 2, 20,
              cinzaRotulo);
          final lr = _tp(a.rotulo, largCol - padCel * 2, 20, cinzaRotulo);
          final ay = y + padCel + lr.height + 8;
          lr.dispose();
          texto(a.valor, pad + padCel, ay, largCol - padCel * 2, 24,
              textoEscuro,
              bold: true);
        }
        if (b.rotulo.isNotEmpty || b.valor.isNotEmpty) {
          final bx = pad + largCol + 2 + padCel;
          texto(b.rotulo, bx, y + padCel, largCol - padCel * 2, 20,
              cinzaRotulo);
          final lr = _tp(b.rotulo, largCol - padCel * 2, 20, cinzaRotulo);
          final by = y + padCel + lr.height + 8;
          lr.dispose();
          texto(b.valor, bx, by, largCol - padCel * 2, 24, textoEscuro,
              bold: true);
        }
        y += hLinha;
      }

      if (secao.lista.isNotEmpty) {
        if (secao.grade.isNotEmpty) {
          canvas.drawLine(Offset(pad, y), Offset(pad + largConteudo, y),
              tintaBorda);
        }
        y += 12;
        if (secao.subRotuloLista != null) {
          texto(secao.subRotuloLista!, pad + padCel, y,
              largConteudo - padCel * 2, 20, cinzaRotulo);
          y += 30 + 10;
        }
        for (final item in secao.lista) {
          final tp = _tp(item, largConteudo - padCel * 2, 23, textoEscuro);
          tp.paint(canvas, Offset(pad + padCel, y));
          y += tp.height + 12;
          tp.dispose();
        }
        y += 12;
      }

      // borda externa
      canvas.drawRect(
          Rect.fromLTWH(pad, topoCaixa, largConteudo, y - topoCaixa),
          tintaBorda);
      y += 40;
    }

    final agora = DateTime.now();
    final dataFmt =
        '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year} ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';
    texto('Gerado pelo app Consulta CNPJ • $dataFmt', 0, y + 10, largura, 20,
        cinzaRotulo,
        center: true);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (largura * escala).round(),
      (altura * escala).round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir =
        Directory('${(await getTemporaryDirectory()).path}/compartilhamento');
    await dir.create(recursive: true);
    final digitos = rel.cnpj.replaceAll(RegExp(r'\D'), '');
    final file = File('${dir.path}/cnpj_$digitos.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file.path;
  } catch (_) {
    return null;
  }
}

// ---------------- PDF ----------------

PdfColor _pdf(int v) => PdfColor.fromInt(v);

Future<String?> gerarPdfRelatorio(CnpjResponse d) async {
  try {
    final rel = montarRelatorio(d);
    const azul = 0xFF0A5091;
    const borda = 0xFFD4D4D4;
    const rotulo = 0xFF808080;
    const escuro = 0xFF1A1A1A;
    final doc = pw.Document();

    pw.Widget celula(ItemRelatorio item) {
      if (item.rotulo.isEmpty && item.valor.isEmpty) {
        return pw.Container();
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(item.rotulo,
                style: pw.TextStyle(color: _pdf(rotulo), fontSize: 9)),
            pw.SizedBox(height: 3),
            pw.Text(item.valor,
                style: pw.TextStyle(
                    color: _pdf(escuro),
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) {
          final widgets = <pw.Widget>[];
          widgets.add(pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            color: _pdf(azul),
            child: pw.Center(
              child: pw.Text('CONSULTA CNPJ',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ));
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Center(
            child: pw.Text(rel.nome,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    color: _pdf(escuro),
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold)),
          ));
          widgets.add(pw.SizedBox(height: 2));
          widgets.add(pw.Center(
            child: pw.Text(rel.cnpj,
                style:
                    pw.TextStyle(color: _pdf(rotulo), fontSize: 12)),
          ));
          widgets.add(pw.SizedBox(height: 12));

          for (final secao in rel.secoes) {
            widgets.add(pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 7, horizontal: 10),
              color: _pdf(azul),
              child: pw.Text(secao.titulo,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold)),
            ));
            final grade = List<ItemRelatorio>.from(secao.grade);
            if (grade.length.isOdd) {
              grade.add(const ItemRelatorio('', ''));
            }
            final linhas = <pw.TableRow>[];
            for (var i = 0; i < grade.length; i += 2) {
              linhas.add(pw.TableRow(children: [
                celula(grade[i]),
                celula(grade[i + 1]),
              ]));
            }
            final corpo = <pw.Widget>[];
            if (linhas.isNotEmpty) {
              corpo.add(pw.Table(
                border: pw.TableBorder.all(
                    color: _pdf(borda), width: 0.8),
                children: linhas,
              ));
            }
            if (secao.lista.isNotEmpty) {
              final itens = <pw.Widget>[];
              if (secao.subRotuloLista != null) {
                itens.add(pw.Text(secao.subRotuloLista!,
                    style: pw.TextStyle(
                        color: _pdf(rotulo), fontSize: 9)));
                itens.add(pw.SizedBox(height: 4));
              }
              for (final item in secao.lista) {
                itens.add(pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(item,
                      style: pw.TextStyle(
                          color: _pdf(escuro), fontSize: 10)),
                ));
              }
              corpo.add(pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        color: _pdf(borda), width: 0.8)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: itens),
              ));
            }
            if (corpo.isNotEmpty) widgets.add(pw.Column(children: corpo));
            widgets.add(pw.SizedBox(height: 12));
          }

          final agora = DateTime.now();
          widgets.add(pw.Center(
            child: pw.Text(
                'Gerado pelo app Consulta CNPJ • ${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year}',
                style: pw.TextStyle(
                    color: _pdf(rotulo), fontSize: 9)),
          ));
          return widgets;
        },
      ),
    );

    final dir =
        Directory('${(await getTemporaryDirectory()).path}/compartilhamento');
    await dir.create(recursive: true);
    final digitos = rel.cnpj.replaceAll(RegExp(r'\D'), '');
    final file = File('${dir.path}/cnpj_$digitos.pdf');
    await file.writeAsBytes(await doc.save());
    return file.path;
  } catch (_) {
    return null;
  }
}

Future<void> compartilharImagemRelatorio(
    BuildContext context, CnpjResponse data) async {
  final caminho = await gerarImagemRelatorio(data);
  if (caminho == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar a imagem.')),
      );
    }
    return;
  }
  await Share.shareXFiles([XFile(caminho, mimeType: 'image/png')],
      subject: 'Consulta CNPJ');
}

Future<void> compartilharPdfRelatorio(
    BuildContext context, CnpjResponse data) async {
  final caminho = await gerarPdfRelatorio(data);
  if (caminho == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar o PDF.')),
      );
    }
    return;
  }
  await Share.shareXFiles([XFile(caminho, mimeType: 'application/pdf')],
      subject: 'Consulta CNPJ');
}
