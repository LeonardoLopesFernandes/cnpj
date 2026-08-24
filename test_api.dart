import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final r = await http.get(
      Uri.parse('https://publica.cnpj.ws/cnpj/43674690000177'),
      headers: {'Accept': 'application/json'},
    );
    print('Status: ${r.statusCode}');
    if (r.statusCode == 200) {
      final json = jsonDecode(r.body) as Map<String, dynamic>;
      print('Keys: ${json.keys.join(", ")}');
      print('razaoSocial: ${json['razaoSocial']}');
      print('capitalSocial: ${json['capitalSocial']}');
      print('estabelecimento keys: ${(json['estabelecimento'] as Map<String, dynamic>).keys.join(", ")}');
      print('');
      print('Full JSON:');
      final encoded = const JsonEncoder.withIndent('  ').convert(json);
      print(encoded.length > 3000 ? '${encoded.substring(0, 3000)}...' : encoded);
    } else {
      print('Body: ${r.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
