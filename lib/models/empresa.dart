import 'dart:convert';

class Empresa {
  final String? razaoSocial;
  final String cnpj;

  Empresa({this.razaoSocial, required this.cnpj});

  Map<String, dynamic> toJson() => {
        'razaoSocial': razaoSocial,
        'cnpj': cnpj,
      };

  static Empresa fromJson(Map<String, dynamic> json) => Empresa(
        razaoSocial: json['razaoSocial'] as String?,
        cnpj: json['cnpj'] as String,
      );

  static String encodeList(List<Empresa> empresas) =>
      jsonEncode(empresas.map((e) => e.toJson()).toList());

  static List<Empresa> decodeList(String json) =>
      (jsonDecode(json) as List).map((e) => Empresa.fromJson(e)).toList();
}
