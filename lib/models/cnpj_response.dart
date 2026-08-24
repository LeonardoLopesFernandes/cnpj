int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

String? _toStr(dynamic v) {
  if (v is String) return v;
  if (v is int || v is double) return v.toString();
  return null;
}

class CnpjResponse {
  final String? cnpjRaiz;
  final String? razaoSocial;
  final String? capitalSocial;
  final String? responsavelFederativo;
  final String? atualizadoEm;
  final Porte? porte;
  final NaturezaJuridica? naturezaJuridica;
  final Qualificacao? qualificacaoResponsavel;
  final List<Socio>? socios;
  final Simples? simples;
  final EstabelecimentoCompleto? estabelecimento;

  CnpjResponse({
    this.cnpjRaiz,
    this.razaoSocial,
    this.capitalSocial,
    this.responsavelFederativo,
    this.atualizadoEm,
    this.porte,
    this.naturezaJuridica,
    this.qualificacaoResponsavel,
    this.socios,
    this.simples,
    this.estabelecimento,
  });

  factory CnpjResponse.fromJson(Map<String, dynamic> json) {
    return CnpjResponse(
      cnpjRaiz: _toStr(json['cnpj_raiz']),
      razaoSocial: _toStr(json['razao_social']),
      capitalSocial: _toStr(json['capital_social']),
      responsavelFederativo: _toStr(json['responsavel_federativo']),
      atualizadoEm: _toStr(json['atualizado_em']),
      porte: json['porte'] != null ? Porte.fromJson(json['porte']) : null,
      naturezaJuridica: json['natureza_juridica'] != null
          ? NaturezaJuridica.fromJson(json['natureza_juridica'])
          : null,
      qualificacaoResponsavel: json['qualificacao_do_responsavel'] != null
          ? Qualificacao.fromJson(json['qualificacao_do_responsavel'])
          : null,
      socios: json['socios'] != null
          ? (json['socios'] as List).map((e) => Socio.fromJson(e)).toList()
          : null,
      simples:
          json['simples'] != null ? Simples.fromJson(json['simples']) : null,
      estabelecimento: json['estabelecimento'] != null
          ? EstabelecimentoCompleto.fromJson(json['estabelecimento'])
          : null,
    );
  }

  bool get isSimples =>
      simples?.simples?.toLowerCase() == 'sim' || simples?.simples == 'S';

  bool get isMei => simples?.mei?.toLowerCase() == 'sim' || simples?.mei == 'S';
}

class Porte {
  final String? id;
  final String? descricao;

  Porte({this.id, this.descricao});

  factory Porte.fromJson(Map<String, dynamic> json) {
    return Porte(
      id: _toStr(json['id']),
      descricao: _toStr(json['descricao']),
    );
  }
}

class NaturezaJuridica {
  final String? id;
  final String? descricao;

  NaturezaJuridica({this.id, this.descricao});

  factory NaturezaJuridica.fromJson(Map<String, dynamic> json) {
    return NaturezaJuridica(
      id: _toStr(json['id']),
      descricao: _toStr(json['descricao']),
    );
  }
}

class Qualificacao {
  final int? id;
  final String? descricao;

  Qualificacao({this.id, this.descricao});

  factory Qualificacao.fromJson(Map<String, dynamic> json) {
    return Qualificacao(
      id: _toInt(json['id']),
      descricao: _toStr(json['descricao']),
    );
  }
}

class Socio {
  final String? cpfCnpjSocio;
  final String? nome;
  final String? tipo;
  final String? dataEntrada;
  final String? cpfRepresentanteLegal;
  final String? nomeRepresentante;
  final String? faixaEtaria;
  final String? paisId;
  final Qualificacao? qualificacaoSocio;
  final String? qualificacaoRepresentante;
  final Pais? pais;

  Socio({
    this.cpfCnpjSocio,
    this.nome,
    this.tipo,
    this.dataEntrada,
    this.cpfRepresentanteLegal,
    this.nomeRepresentante,
    this.faixaEtaria,
    this.paisId,
    this.qualificacaoSocio,
    this.qualificacaoRepresentante,
    this.pais,
  });

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      cpfCnpjSocio: _toStr(json['cpf_cnpj_socio']),
      nome: _toStr(json['nome']),
      tipo: _toStr(json['tipo']),
      dataEntrada: _toStr(json['data_entrada']),
      cpfRepresentanteLegal: _toStr(json['cpf_representante_legal']),
      nomeRepresentante: _toStr(json['nome_representante']),
      faixaEtaria: _toStr(json['faixa_etaria']),
      paisId: _toStr(json['pais_id']),
      qualificacaoSocio: json['qualificacao_socio'] != null
          ? Qualificacao.fromJson(json['qualificacao_socio'])
          : null,
      qualificacaoRepresentante: _toStr(json['qualificacao_representante']),
      pais: json['pais'] != null ? Pais.fromJson(json['pais']) : null,
    );
  }
}

class Pais {
  final String? id;
  final String? iso2;
  final String? iso3;
  final String? nome;
  final String? comexId;

  Pais({this.id, this.iso2, this.iso3, this.nome, this.comexId});

  factory Pais.fromJson(Map<String, dynamic> json) {
    return Pais(
      id: _toStr(json['id']),
      iso2: _toStr(json['iso2']),
      iso3: _toStr(json['iso3']),
      nome: _toStr(json['nome']),
      comexId: _toStr(json['comex_id']),
    );
  }
}

class Simples {
  final String? simples;
  final String? dataOpcaoSimples;
  final String? dataExclusaoSimples;
  final String? mei;
  final String? dataOpcaoMei;
  final String? dataExclusaoMei;
  final String? atualizadoEm;

  Simples({
    this.simples,
    this.dataOpcaoSimples,
    this.dataExclusaoSimples,
    this.mei,
    this.dataOpcaoMei,
    this.dataExclusaoMei,
    this.atualizadoEm,
  });

  factory Simples.fromJson(Map<String, dynamic> json) {
    return Simples(
      simples: _toStr(json['simples']),
      dataOpcaoSimples: _toStr(json['data_opcao_simples']),
      dataExclusaoSimples: _toStr(json['data_exclusao_simples']),
      mei: _toStr(json['mei']),
      dataOpcaoMei: _toStr(json['data_opcao_mei']),
      dataExclusaoMei: _toStr(json['data_exclusao_mei']),
      atualizadoEm: _toStr(json['atualizado_em']),
    );
  }
}

class EstabelecimentoCompleto {
  final String? cnpj;
  final String? cnpjRaiz;
  final String? cnpjOrdem;
  final String? cnpjDigitoVerificador;
  final String? tipo;
  final String? nomeFantasia;
  final String? situacaoCadastral;
  final String? dataSituacaoCadastral;
  final String? dataInicioAtividade;
  final String? nomeCidadeExterior;
  final String? tipoLogradouro;
  final String? logradouro;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cep;
  final String? ddd1;
  final String? telefone1;
  final String? ddd2;
  final String? telefone2;
  final String? dddFax;
  final String? fax;
  final String? email;
  final String? situacaoEspecial;
  final String? dataSituacaoEspecial;
  final String? atualizadoEm;
  final Atividade? atividadePrincipal;
  final List<Atividade>? atividadesSecundarias;
  final Pais? pais;
  final Estado? estado;
  final Cidade? cidade;
  final String? motivoSituacaoCadastral;
  final List<InscricaoEstadualCompleta>? inscricoesEstaduais;

  EstabelecimentoCompleto({
    this.cnpj,
    this.cnpjRaiz,
    this.cnpjOrdem,
    this.cnpjDigitoVerificador,
    this.tipo,
    this.nomeFantasia,
    this.situacaoCadastral,
    this.dataSituacaoCadastral,
    this.dataInicioAtividade,
    this.nomeCidadeExterior,
    this.tipoLogradouro,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cep,
    this.ddd1,
    this.telefone1,
    this.ddd2,
    this.telefone2,
    this.dddFax,
    this.fax,
    this.email,
    this.situacaoEspecial,
    this.dataSituacaoEspecial,
    this.atualizadoEm,
    this.atividadePrincipal,
    this.atividadesSecundarias,
    this.pais,
    this.estado,
    this.cidade,
    this.motivoSituacaoCadastral,
    this.inscricoesEstaduais,
  });

  factory EstabelecimentoCompleto.fromJson(Map<String, dynamic> json) {
    return EstabelecimentoCompleto(
      cnpj: _toStr(json['cnpj']),
      cnpjRaiz: _toStr(json['cnpj_raiz']),
      cnpjOrdem: _toStr(json['cnpj_ordem']),
      cnpjDigitoVerificador: _toStr(json['cnpj_digito_verificador']),
      tipo: _toStr(json['tipo']),
      nomeFantasia: _toStr(json['nome_fantasia']),
      situacaoCadastral: _toStr(json['situacao_cadastral']),
      dataSituacaoCadastral: _toStr(json['data_situacao_cadastral']),
      dataInicioAtividade: _toStr(json['data_inicio_atividade']),
      nomeCidadeExterior: _toStr(json['nome_cidade_exterior']),
      tipoLogradouro: _toStr(json['tipo_logradouro']),
      logradouro: _toStr(json['logradouro']),
      numero: _toStr(json['numero']),
      complemento: _toStr(json['complemento']),
      bairro: _toStr(json['bairro']),
      cep: _toStr(json['cep']),
      ddd1: _toStr(json['ddd1']),
      telefone1: _toStr(json['telefone1']),
      ddd2: _toStr(json['ddd2']),
      telefone2: _toStr(json['telefone2']),
      dddFax: _toStr(json['ddd_fax']),
      fax: _toStr(json['fax']),
      email: _toStr(json['email']),
      situacaoEspecial: _toStr(json['situacao_especial']),
      dataSituacaoEspecial: _toStr(json['data_situacao_especial']),
      atualizadoEm: _toStr(json['atualizado_em']),
      atividadePrincipal: json['atividade_principal'] != null
          ? Atividade.fromJson(json['atividade_principal'])
          : null,
      atividadesSecundarias: json['atividades_secundarias'] != null
          ? (json['atividades_secundarias'] as List)
              .map((e) => Atividade.fromJson(e))
              .toList()
          : null,
      pais: json['pais'] != null ? Pais.fromJson(json['pais']) : null,
      estado: json['estado'] != null ? Estado.fromJson(json['estado']) : null,
      cidade: json['cidade'] != null ? Cidade.fromJson(json['cidade']) : null,
      motivoSituacaoCadastral: _toStr(json['motivo_situacao_cadastral']),
      inscricoesEstaduais: json['inscricoes_estaduais'] != null
          ? (json['inscricoes_estaduais'] as List)
              .map((e) => InscricaoEstadualCompleta.fromJson(e))
              .toList()
          : null,
    );
  }
}

class Atividade {
  final String? id;
  final String? secao;
  final String? divisao;
  final String? grupo;
  final String? classe;
  final String? subclasse;
  final String? descricao;

  Atividade({
    this.id,
    this.secao,
    this.divisao,
    this.grupo,
    this.classe,
    this.subclasse,
    this.descricao,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: _toStr(json['id']),
      secao: _toStr(json['secao']),
      divisao: _toStr(json['divisao']),
      grupo: _toStr(json['grupo']),
      classe: _toStr(json['classe']),
      subclasse: _toStr(json['subclasse']),
      descricao: _toStr(json['descricao']),
    );
  }
}

class Estado {
  final int? id;
  final String? nome;
  final String? sigla;
  final int? ibgeId;

  Estado({this.id, this.nome, this.sigla, this.ibgeId});

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      id: _toInt(json['id']),
      nome: _toStr(json['nome']),
      sigla: _toStr(json['sigla']),
      ibgeId: _toInt(json['ibge_id']),
    );
  }
}

class Cidade {
  final int? id;
  final String? nome;
  final int? ibgeId;
  final int? siafiId;

  Cidade({this.id, this.nome, this.ibgeId, this.siafiId});

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: _toInt(json['id']),
      nome: _toStr(json['nome']),
      ibgeId: _toInt(json['ibge_id']),
      siafiId: _toInt(json['siafi_id']),
    );
  }
}

class InscricaoEstadualCompleta {
  final String? inscricaoEstadual;
  final bool? ativo;
  final String? atualizadoEm;
  final Estado? estado;

  InscricaoEstadualCompleta({
    this.inscricaoEstadual,
    this.ativo,
    this.atualizadoEm,
    this.estado,
  });

  factory InscricaoEstadualCompleta.fromJson(Map<String, dynamic> json) {
    return InscricaoEstadualCompleta(
      inscricaoEstadual: _toStr(json['inscricao_estadual']),
      ativo: json['ativo'] as bool?,
      atualizadoEm: _toStr(json['atualizado_em']),
      estado:
          json['estado'] != null ? Estado.fromJson(json['estado']) : null,
    );
  }
}
