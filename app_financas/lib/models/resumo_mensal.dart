class ResumoMensal {
  int? id;
  int ano;
  int mes;
  double totalReceitas;
  double totalDespesas;
  double saldoAnterior;
  double saldoFinal;
  DateTime dataCalculo;

  ResumoMensal({
    this.id,
    required this.ano,
    required this.mes,
    required this.totalReceitas,
    required this.totalDespesas,
    required this.saldoAnterior,
    required this.saldoFinal,
    required this.dataCalculo,
  });

  // Getters calculados
  double get economia => totalReceitas - totalDespesas;
  bool get gastouMaisQueGanhou => totalDespesas > totalReceitas;
  double get percentualGasto => totalReceitas > 0 ? (totalDespesas / totalReceitas) * 100 : 0;

  // Converter para Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ano': ano,
      'mes': mes,
      'total_receitas': totalReceitas,
      'total_despesas': totalDespesas,
      'saldo_anterior': saldoAnterior,
      'saldo_final': saldoFinal,
      'data_calculo': dataCalculo.toIso8601String(),
    };
  }

  // Criar objeto a partir do Map (do banco de dados)
  factory ResumoMensal.fromMap(Map<String, dynamic> map) {
    return ResumoMensal(
      id: map['id'],
      ano: map['ano'],
      mes: map['mes'],
      totalReceitas: map['total_receitas'].toDouble(),
      totalDespesas: map['total_despesas'].toDouble(),
      saldoAnterior: map['saldo_anterior'].toDouble(),
      saldoFinal: map['saldo_final'].toDouble(),
      dataCalculo: DateTime.parse(map['data_calculo']),
    );
  }

  // Método copy para atualizar dados
  ResumoMensal copyWith({
    int? id,
    int? ano,
    int? mes,
    double? totalReceitas,
    double? totalDespesas,
    double? saldoAnterior,
    double? saldoFinal,
    DateTime? dataCalculo,
  }) {
    return ResumoMensal(
      id: id ?? this.id,
      ano: ano ?? this.ano,
      mes: mes ?? this.mes,
      totalReceitas: totalReceitas ?? this.totalReceitas,
      totalDespesas: totalDespesas ?? this.totalDespesas,
      saldoAnterior: saldoAnterior ?? this.saldoAnterior,
      saldoFinal: saldoFinal ?? this.saldoFinal,
      dataCalculo: dataCalculo ?? this.dataCalculo,
    );
  }

  @override
  String toString() {
    return 'ResumoMensal{ano: $ano, mes: $mes, receitas: $totalReceitas, despesas: $totalDespesas, economia: $economia}';
  }
}