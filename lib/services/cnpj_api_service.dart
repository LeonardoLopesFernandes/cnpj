import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cnpj_response.dart';

class CnpjApiService {
  static const String _baseUrl = 'https://publica.cnpj.ws/cnpj/';

  Future<CnpjResponse> fetchCnpj(String cnpj, {int retries = 3}) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'[.\-/]'), '');

    for (int attempt = 0; attempt < retries; attempt++) {
      final response = await http.get(
        Uri.parse('$_baseUrl$cleanCnpj'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CnpjResponse.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('CNPJ não encontrado');
      } else if (response.statusCode == 429) {
        if (attempt < retries - 1) {
          await Future.delayed(Duration(seconds: 3));
          continue;
        }
        throw Exception('Limite de consultas atingido. Tente novamente em alguns instantes.');
      } else {
        throw Exception('Erro ao consultar CNPJ: ${response.statusCode}');
      }
    }

    throw Exception('Erro ao consultar CNPJ');
  }
}
