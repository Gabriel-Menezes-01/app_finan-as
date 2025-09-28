class Conta {
  int? id;
  String nome;
  String? descricao;
  double saldo;
  String tipo; // 'corrente', 'poupanca', 'cartao_credito'
  DateTime dataCriacao;
  bool ativo;

  Conta({
    this.id,
    required this.nome,
    this.descricao,
    required this.saldo,
    required this.tipo,
    required this.dataCriacao,
    this.ativo = true,
  });

  // Converter para Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'saldo': saldo,
      'tipo': tipo,
      'data_criacao': dataCriacao.toIso8601String(),
      'ativo': ativo ? 1 : 0,
    };
  }

  // Criar objeto a partir do Map (do banco de dados)
  factory Conta.fromMap(Map<String, dynamic> map) {
    return Conta(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'],
      saldo: map['saldo'].toDouble(),
      tipo: map['tipo'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      ativo: map['ativo'] == 1,
    );
  }

  // Método copy para atualizar dados
  Conta copyWith({
    int? id,
    String? nome,
    String? descricao,
    double? saldo,
    String? tipo,
    DateTime? dataCriacao,
    bool? ativo,
  }) {
    return Conta(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      saldo: saldo ?? this.saldo,
      tipo: tipo ?? this.tipo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() {
    return 'Conta{id: $id, nome: $nome, saldo: $saldo, tipo: $tipo}';
  }
}