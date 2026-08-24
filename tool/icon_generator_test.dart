import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Color _bgColor = Color(0xFF1a5276);

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

void _drawContent(Canvas canvas, double size) {
  final cx = size / 2;
  final iconSize = size * 0.38;
  final textSize = size * 0.10;
  final gap = size * 0.035;

  final icon = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.business.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: 'MaterialIcons',
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final label = TextPainter(
    text: TextSpan(
      text: 'Consultar CNPJ',
      style: TextStyle(
        fontSize: textSize,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final total = icon.height + gap + label.height;
  var y = (size - total) / 2;

  icon.paint(canvas, Offset(cx - icon.width / 2, y));
  y += icon.height + gap;
  label.paint(canvas, Offset(cx - label.width / 2, y));
}

Future<Uint8List> _render(double size, {required bool full}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
  if (full) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size, size),
      Paint()..color = _bgColor,
    );
  }
  _drawContent(canvas, size);
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<Uint8List> _renderGlyph(int codePoint, {double size = 200}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: 'MaterialIcons',
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(0, (size - tp.height) / 2));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('generate ic_launcher icons', (tester) async {
    await tester.runAsync(() async {
      await _loadFont('Roboto',
          '/opt/flutter/3.38.5/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf');
      await _loadFont(
          'MaterialIcons',
          '/opt/flutter/3.38.5/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');

      // sanity: distinct Material icons must rasterize differently,
      // proving real glyphs loaded (not missing-glyph tofu boxes).
      final iconA = await _renderGlyph(Icons.business.codePoint);
      final iconB = await _renderGlyph(Icons.home.codePoint);
      if (iconA.length == iconB.length) {
        throw StateError('Material icons render identically - font not loaded');
      }

      final res = Directory('android/app/src/main/res');

      // legacy icons (full-bleed blue) per density.
      const sizes = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final e in sizes.entries) {
        final file = File('${res.path}/mipmap-${e.key}/ic_launcher.png');
        file.writeAsBytesSync(await _render(e.value.toDouble(), full: true));
        print('wrote ${file.path}');
      }

      // adaptive foreground: 108dp @ xxxhdpi = 432px, transparent.
      final fgDir = Directory('${res.path}/drawable-nodpi');
      if (!fgDir.existsSync()) fgDir.createSync(recursive: true);
      final fg = File('${fgDir.path}/ic_launcher_foreground.png');
      fg.writeAsBytesSync(await _render(432, full: false));
      print('wrote ${fg.path}');

      // preview for inspection
      final preview = File('${res.path}/drawable-nodpi/preview.png');
      preview.writeAsBytesSync(await _render(432, full: true));
      print('wrote ${preview.path}');
    });
  });
}