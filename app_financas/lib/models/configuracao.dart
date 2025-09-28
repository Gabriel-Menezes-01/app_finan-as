class Configuracao {
  static const String euro = 'EUR';
  static const String real = 'BRL';
  
  final String moeda;
  
  const Configuracao({
    this.moeda = euro,
  });
  
  Configuracao copyWith({
    String? moeda,
  }) {
    return Configuracao(
      moeda: moeda ?? this.moeda,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'moeda': moeda,
    };
  }
  
  factory Configuracao.fromMap(Map<String, dynamic> map) {
    return Configuracao(
      moeda: map['moeda'] ?? euro,
    );
  }
  
  String get simboloMoeda {
    switch (moeda) {
      case real:
        return 'R\$';
      case euro:
      default:
        return '€';
    }
  }
  
  String get nomeMoeda {
    switch (moeda) {
      case real:
        return 'Real';
      case euro:
      default:
        return 'Euro';
    }
  }
}