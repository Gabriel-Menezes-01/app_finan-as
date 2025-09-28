class Remessa {
  final int? id;
  final double valorEuro;
  final double? valorReal; // valor convertido recebido no Brasil
  final DateTime dataEnvio;
  final DateTime? dataRecebimento;
  final int contaOrigemId; // conta de onde sai o dinheiro
  final int? contaDestinoId; // conta no Brasil onde chega
  final String? observacoes;
  final String status; // 'enviado', 'recebido', 'cancelado'
  final double? taxaCambio; // taxa de conversão usada
  final String? codigoRastreamento;

  Remessa({
    this.id,
    required this.valorEuro,
    this.valorReal,
    required this.dataEnvio,
    this.dataRecebimento,
    required this.contaOrigemId,
    this.contaDestinoId,
    this.observacoes,
    this.status = 'enviado',
    this.taxaCambio,
    this.codigoRastreamento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valor_euro': valorEuro,
      'valor_real': valorReal,
      'data_envio': dataEnvio.toIso8601String(),
      'data_recebimento': dataRecebimento?.toIso8601String(),
      'conta_origem_id': contaOrigemId,
      'conta_destino_id': contaDestinoId,
      'observacoes': observacoes,
      'status': status,
      'taxa_cambio': taxaCambio,
      'codigo_rastreamento': codigoRastreamento,
    };
  }

  factory Remessa.fromMap(Map<String, dynamic> map) {
    return Remessa(
      id: map['id'],
      valorEuro: map['valor_euro'],
      valorReal: map['valor_real'],
      dataEnvio: DateTime.parse(map['data_envio']),
      dataRecebimento: map['data_recebimento'] != null 
          ? DateTime.parse(map['data_recebimento'])
          : null,
      contaOrigemId: map['conta_origem_id'],
      contaDestinoId: map['conta_destino_id'],
      observacoes: map['observacoes'],
      status: map['status'] ?? 'enviado',
      taxaCambio: map['taxa_cambio'],
      codigoRastreamento: map['codigo_rastreamento'],
    );
  }

  Remessa copyWith({
    int? id,
    double? valorEuro,
    double? valorReal,
    DateTime? dataEnvio,
    DateTime? dataRecebimento,
    int? contaOrigemId,
    int? contaDestinoId,
    String? observacoes,
    String? status,
    double? taxaCambio,
    String? codigoRastreamento,
  }) {
    return Remessa(
      id: id ?? this.id,
      valorEuro: valorEuro ?? this.valorEuro,
      valorReal: valorReal ?? this.valorReal,
      dataEnvio: dataEnvio ?? this.dataEnvio,
      dataRecebimento: dataRecebimento ?? this.dataRecebimento,
      contaOrigemId: contaOrigemId ?? this.contaOrigemId,
      contaDestinoId: contaDestinoId ?? this.contaDestinoId,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
      taxaCambio: taxaCambio ?? this.taxaCambio,
      codigoRastreamento: codigoRastreamento ?? this.codigoRastreamento,
    );
  }
}