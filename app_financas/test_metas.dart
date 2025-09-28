import 'lib/models/meta.dart';
import 'lib/services/database_service.dart';

void main() async {
  print('=== TESTE DE METAS ===');
  
  // Teste do modelo Meta
  final meta = Meta(
    nome: 'Teste Meta',
    descricao: 'Descrição teste',
    valorMeta: 1000.0,
    valorAtual: 0.0,
    moeda: 'EUR',
    ativa: true,
    dataCriacao: DateTime.now(),
  );
  
  print('Meta criada:');
  print('Nome: ${meta.nome}');
  print('Valor Meta: ${meta.valorMeta}');
  print('Moeda: ${meta.moeda}');
  
  // Teste do toMap
  final metaMap = meta.toMap();
  print('\nMapa gerado:');
  metaMap.forEach((key, value) {
    print('$key: $value');
  });
  
  // Teste do fromMap
  final metaRecuperada = Meta.fromMap(metaMap);
  print('\nMeta recuperada:');
  print('Nome: ${metaRecuperada.nome}');
  print('Valor Meta: ${metaRecuperada.valorMeta}');
  print('Moeda: ${metaRecuperada.moeda}');
  
  print('\n=== TESTE CONCLUÍDO ===');
}