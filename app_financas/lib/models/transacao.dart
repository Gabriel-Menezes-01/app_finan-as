class Transacao {
  int? id;
  String descricao;
  double valor;
  String tipo; // 'receita' ou 'despesa'
  String categoria;
  int contaId;
  DateTime data;
  DateTime dataCriacao;
  bool pago;
  String? observacoes;
  double? valorReal; // Valor convertido em R$ para transferências
  double? taxaCambio; // Taxa de câmbio EUR -> BRL

  Transacao({
    this.id,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.categoria,
    required this.contaId,
    required this.data,
    required this.dataCriacao,
    this.pago = false,
    this.observacoes,
    this.valorReal,
    this.taxaCambio,
  });

  // Converter para Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'categoria': categoria,
      'conta_id': contaId,
      'data': data.toIso8601String(),
      'data_criacao': dataCriacao.toIso8601String(),
      'pago': pago ? 1 : 0,
      'observacoes': observacoes,
      'valor_real': valorReal,
      'taxa_cambio': taxaCambio,
    };
  }

  // Criar objeto a partir do Map (do banco de dados)
  factory Transacao.fromMap(Map<String, dynamic> map) {
    return Transacao(
      id: map['id'],
      descricao: map['descricao'],
      valor: map['valor'].toDouble(),
      tipo: map['tipo'],
      categoria: map['categoria'],
      contaId: map['conta_id'],
      data: DateTime.parse(map['data']),
      dataCriacao: DateTime.parse(map['data_criacao']),
      pago: map['pago'] == 1,
      observacoes: map['observacoes'],
      valorReal: map['valor_real']?.toDouble(),
      taxaCambio: map['taxa_cambio']?.toDouble(),
    );
  }

  // Método copy para atualizar dados
  Transacao copyWith({
    int? id,
    String? descricao,
    double? valor,
    String? tipo,
    String? categoria,
    int? contaId,
    DateTime? data,
    DateTime? dataCriacao,
    bool? pago,
    String? observacoes,
    double? valorReal,
    double? taxaCambio,
  }) {
    return Transacao(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      contaId: contaId ?? this.contaId,
      data: data ?? this.data,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      pago: pago ?? this.pago,
      observacoes: observacoes ?? this.observacoes,
      valorReal: valorReal ?? this.valorReal,
      taxaCambio: taxaCambio ?? this.taxaCambio,
    );
  }

  @override
  String toString() {
    return 'Transacao{id: $id, descricao: $descricao, valor: $valor, tipo: $tipo, categoria: $categoria}';
  }
}