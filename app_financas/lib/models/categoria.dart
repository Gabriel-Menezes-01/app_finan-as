import 'package:flutter/material.dart';

// Mapa de ícones constantes para evitar problemas de tree shaking
const Map<int, IconData> iconMap = {
  57415: Icons.restaurant,
  59197: Icons.directions_car,
  58470: Icons.home,
  58714: Icons.local_hospital,
  59404: Icons.school,
  59569: Icons.sports_esports,
  59688: Icons.shopping_bag,
  57404: Icons.build,
  58835: Icons.more_horiz,
  59641: Icons.work,
  57379: Icons.computer,
  59685: Icons.trending_up,
  59680: Icons.sell,
  57445: Icons.card_giftcard,
  58068: Icons.emoji_events,
};

class Categoria {
  int? id;
  String nome;
  String tipo; // 'receita' ou 'despesa'
  IconData icone;
  Color cor;
  bool ativo;

  Categoria({
    this.id,
    required this.nome,
    required this.tipo,
    required this.icone,
    required this.cor,
    this.ativo = true,
  });

  // Converter para Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'icone_code': icone.codePoint,
      'cor_value': cor.value,
      'ativo': ativo ? 1 : 0,
    };
  }

  // Criar objeto a partir do Map (do banco de dados)
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nome: map['nome'],
      tipo: map['tipo'],
      icone: iconMap[map['icone_code']] ?? Icons.more_horiz,
      cor: Color(map['cor_value']),
      ativo: map['ativo'] == 1,
    );
  }

  // Método copy para atualizar dados
  Categoria copyWith({
    int? id,
    String? nome,
    String? tipo,
    IconData? icone,
    Color? cor,
    bool? ativo,
  }) {
    return Categoria(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      icone: icone ?? this.icone,
      cor: cor ?? this.cor,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() {
    return 'Categoria{id: $id, nome: $nome, tipo: $tipo}';
  }
}

// Categorias padrão para despesas
List<Categoria> categoriasDepesasPadrao = [
  Categoria(nome: 'Alimentação', tipo: 'despesa', icone: Icons.restaurant, cor: Colors.orange),
  Categoria(nome: 'Transporte', tipo: 'despesa', icone: Icons.directions_car, cor: Colors.blue),
  Categoria(nome: 'Moradia', tipo: 'despesa', icone: Icons.home, cor: Colors.green),
  Categoria(nome: 'Saúde', tipo: 'despesa', icone: Icons.local_hospital, cor: Colors.red),
  Categoria(nome: 'Educação', tipo: 'despesa', icone: Icons.school, cor: Colors.purple),
  Categoria(nome: 'Lazer', tipo: 'despesa', icone: Icons.sports_esports, cor: Colors.pink),
  Categoria(nome: 'Compras', tipo: 'despesa', icone: Icons.shopping_bag, cor: Colors.teal),
  Categoria(nome: 'Serviços', tipo: 'despesa', icone: Icons.build, cor: Colors.brown),
  Categoria(nome: 'Transferências para o Brasil', tipo: 'despesa', icone: Icons.flight_takeoff, cor: Colors.deepOrange),
  Categoria(nome: 'Outros', tipo: 'despesa', icone: Icons.more_horiz, cor: Colors.grey),
];

// Categorias padrão para ganhos extras
List<Categoria> categoriasReceitasPadrao = [
  Categoria(nome: 'Freelance', tipo: 'receita', icone: Icons.computer, cor: Colors.blue),
  Categoria(nome: 'Bônus', tipo: 'receita', icone: Icons.card_giftcard, cor: Colors.green),
  Categoria(nome: 'Comissões', tipo: 'receita', icone: Icons.trending_up, cor: Colors.amber),
  Categoria(nome: 'Vendas Extras', tipo: 'receita', icone: Icons.sell, cor: Colors.orange),
  Categoria(nome: 'Trabalho Extra', tipo: 'receita', icone: Icons.work, cor: Colors.indigo),
  Categoria(nome: 'Prêmios', tipo: 'receita', icone: Icons.emoji_events, cor: Colors.pink),
  Categoria(nome: 'Outros', tipo: 'receita', icone: Icons.more_horiz, cor: Colors.grey),
];