import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cnpj_response.dart';

class CnpjApiService {
  static const String _baseUrl = 'https://publica.cnpj.ws/cnpj/';

  Future<CnpjResponse> fetchCnpj(String cnpj) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'[.\-/]'), '');
    final response = await http.get(
      Uri.parse('$_baseUrl$cleanCnpj'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CnpjResponse.fromJson(json);
    } else if (response.statusCode == 404) {
      throw Exception('CNPJ não encontrado');
    } else {
      throw Exception('Erro ao consultar CNPJ: ${response.statusCode}');
    }
  }
}
