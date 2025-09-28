class Meta {
  int? id;
  String nome;
  String? descricao;
  double valorMeta;
  double valorAtual;
  String moeda; // 'EUR' ou 'BRL'
  bool ativa;
  DateTime dataCriacao;

  Meta({
    this.id,
    required this.nome,
    this.descricao,
    required this.valorMeta,
    this.valorAtual = 0.0,
    this.moeda = 'EUR',
    this.ativa = true,
    required this.dataCriacao,
  });

  // Converter para Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'valor_meta': valorMeta,
      'valor_atual': valorAtual,
      'moeda': moeda,
      'ativa': ativa ? 1 : 0,
      'data_criacao': dataCriacao.millisecondsSinceEpoch,
    };
  }

  // Criar a partir de um Map (recuperar do banco de dados)
  factory Meta.fromMap(Map<String, dynamic> map) {
    return Meta(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      valorMeta: map['valor_meta'],
      valorAtual: map['valor_atual'],
      moeda: map['moeda'] ?? 'EUR',
      ativa: map['ativa'] == 1,
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['data_criacao']),
    );
  }

  // Calcular porcentagem de progresso
  double get porcentagemProgresso {
    if (valorMeta <= 0) return 0.0;
    return (valorAtual / valorMeta).clamp(0.0, 1.0);
  }

  // Verificar se a meta foi atingida
  bool get foiAtingida {
    return valorAtual >= valorMeta;
  }

  // Valor restante para atingir a meta
  double get valorRestante {
    return (valorMeta - valorAtual).clamp(0.0, double.infinity);
  }

  // Status da meta
  String get status {
    if (!ativa) return 'Inativa';
    if (foiAtingida) return 'Atingida';
    return 'Em andamento';
  }

  // Símbolo da moeda
  String get simboloMoeda {
    return moeda == 'BRL' ? 'R\$' : '€';
  }
}