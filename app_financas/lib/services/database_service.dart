import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'financas.db';
  static const int _databaseVersion = 6;

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Getter para o banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar o banco de dados
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Criar as tabelas
  Future<void> _onCreate(Database db, int version) async {
    // Tabela de contas
    await db.execute('''
      CREATE TABLE contas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        saldo REAL NOT NULL DEFAULT 0,
        tipo TEXT NOT NULL,
        data_criacao TEXT NOT NULL,
        ativo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabela de categorias
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        icone_code INTEGER NOT NULL,
        cor_value INTEGER NOT NULL,
        ativo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabela de transações
    await db.execute('''
      CREATE TABLE transacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        categoria TEXT NOT NULL,
        conta_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        data_criacao TEXT NOT NULL,
        pago INTEGER NOT NULL DEFAULT 0,
        observacoes TEXT,
        valor_real REAL,
        taxa_cambio REAL,
        FOREIGN KEY (conta_id) REFERENCES contas (id)
      )
    ''');

    // Tabela de resumo mensal
    await db.execute('''
      CREATE TABLE resumos_mensais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ano INTEGER NOT NULL,
        mes INTEGER NOT NULL,
        total_receitas REAL NOT NULL DEFAULT 0,
        total_despesas REAL NOT NULL DEFAULT 0,
        saldo_anterior REAL NOT NULL DEFAULT 0,
        saldo_final REAL NOT NULL DEFAULT 0,
        data_calculo TEXT NOT NULL,
        UNIQUE(ano, mes)
      )
    ''');

    // Criar tabela de remessas
    await db.execute('''
      CREATE TABLE remessas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor_euro REAL NOT NULL,
        valor_real REAL,
        data_envio TEXT NOT NULL,
        data_recebimento TEXT,
        conta_origem_id INTEGER NOT NULL,
        conta_destino_id INTEGER,
        observacoes TEXT,
        status TEXT NOT NULL DEFAULT 'enviado',
        taxa_cambio REAL,
        codigo_rastreamento TEXT,
        FOREIGN KEY (conta_origem_id) REFERENCES contas (id),
        FOREIGN KEY (conta_destino_id) REFERENCES contas (id)
      )
    ''');

    // Criar tabela de configurações
    await db.execute('''
      CREATE TABLE configuracoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chave TEXT NOT NULL UNIQUE,
        valor TEXT NOT NULL
      )
    ''');

    // Criar tabela de metas (versão simplificada)
    await db.execute('''
      CREATE TABLE metas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT,
        valor_meta REAL NOT NULL,
        valor_atual REAL NOT NULL DEFAULT 0,
        moeda TEXT NOT NULL DEFAULT 'EUR',
        ativa INTEGER NOT NULL DEFAULT 1,
        data_criacao INTEGER NOT NULL
      )
    ''');

    // Inserir configuração padrão de moeda
    await db.insert('configuracoes', {
      'chave': 'moeda',
      'valor': 'EUR'
    });

    // Inserir categorias padrão
    await _inserirCategoriasPadrao(db);
  }

  // Upgrade do banco de dados
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Criar tabela de remessas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS remessas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          valor_euro REAL NOT NULL,
          valor_real REAL,
          data_envio TEXT NOT NULL,
          data_recebimento TEXT,
          conta_origem_id INTEGER NOT NULL,
          conta_destino_id INTEGER,
          observacoes TEXT,
          status TEXT NOT NULL DEFAULT 'enviado',
          taxa_cambio REAL,
          codigo_rastreamento TEXT,
          FOREIGN KEY (conta_origem_id) REFERENCES contas (id),
          FOREIGN KEY (conta_destino_id) REFERENCES contas (id)
        )
      ''');
      
      // Criar tabela de configurações
      await db.execute('''
        CREATE TABLE IF NOT EXISTS configuracoes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chave TEXT NOT NULL UNIQUE,
          valor TEXT NOT NULL
        )
      ''');
      
      // Inserir configuração padrão de moeda
      await db.insert('configuracoes', {
        'chave': 'moeda',
        'valor': 'EUR'
      });
    }
    
    if (oldVersion < 4) {
      // Adicionar colunas para valor em Real e taxa de câmbio nas transferências
      await db.execute('ALTER TABLE transacoes ADD COLUMN valor_real REAL');
      await db.execute('ALTER TABLE transacoes ADD COLUMN taxa_cambio REAL');
    }
    
    if (oldVersion < 5) {
      // Criar tabela de metas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS metas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          descricao TEXT,
          valor_meta REAL NOT NULL,
          valor_atual REAL NOT NULL DEFAULT 0,
          categoria TEXT NOT NULL,
          tipo TEXT NOT NULL,
          data_inicio INTEGER NOT NULL,
          data_fim INTEGER NOT NULL,
          ativa INTEGER NOT NULL DEFAULT 1,
          data_criacao INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 6) {
      // Atualizar tabela de metas para versão simplificada
      // Criar nova tabela com estrutura simplificada
      await db.execute('''
        CREATE TABLE metas_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          descricao TEXT,
          valor_meta REAL NOT NULL,
          valor_atual REAL NOT NULL DEFAULT 0,
          moeda TEXT NOT NULL DEFAULT 'EUR',
          ativa INTEGER NOT NULL DEFAULT 1,
          data_criacao INTEGER NOT NULL
        )
      ''');

      // Copiar dados existentes (se houver)
      final List<Map<String, dynamic>> metasExistentes = await db.query('metas');
      for (var meta in metasExistentes) {
        await db.insert('metas_new', {
          'id': meta['id'],
          'nome': meta['nome'],
          'descricao': meta['descricao'],
          'valor_meta': meta['valor_meta'],
          'valor_atual': meta['valor_atual'],
          'moeda': 'EUR', // Padrão EUR
          'ativa': meta['ativa'],
          'data_criacao': meta['data_criacao'],
        });
      }

      // Remover tabela antiga e renomear nova
      await db.execute('DROP TABLE metas');
      await db.execute('ALTER TABLE metas_new RENAME TO metas');
    }
  }

  Future<void> _inserirCategoriasPadrao(Database db) async {
    final categoriasPadrao = [
      {'nome': 'Alimentação', 'tipo': 'despesa', 'icone_code': 57502, 'cor_value': 4284955319},
      {'nome': 'Transporte', 'tipo': 'despesa', 'icone_code': 59644, 'cor_value': 4286141768},
      {'nome': 'Moradia', 'tipo': 'despesa', 'icone_code': 58136, 'cor_value': 4288423856},
      {'nome': 'Saúde', 'tipo': 'despesa', 'icone_code': 57498, 'cor_value': 4293467747},
      {'nome': 'Educação', 'tipo': 'despesa', 'icone_code': 58091, 'cor_value': 4291681337},
      {'nome': 'Lazer', 'tipo': 'despesa', 'icone_code': 58748, 'cor_value': 4294198070},
      {'nome': 'Compras', 'tipo': 'despesa', 'icone_code': 59766, 'cor_value': 4288585374},
      {'nome': 'Serviços', 'tipo': 'despesa', 'icone_code': 59576, 'cor_value': 4291808606},
      {'nome': 'Outros', 'tipo': 'despesa', 'icone_code': 58093, 'cor_value': 4288256409},
      // Receitas
      {'nome': 'Salário', 'tipo': 'receita', 'icone_code': 58093, 'cor_value': 4283215696},
      {'nome': 'Freelance', 'tipo': 'receita', 'icone_code': 58123, 'cor_value': 4284613430},
      {'nome': 'Investimentos', 'tipo': 'receita', 'icone_code': 58107, 'cor_value': 4286473611},
      {'nome': 'Outros', 'tipo': 'receita', 'icone_code': 58093, 'cor_value': 4283215696},
    ];

    for (final categoria in categoriasPadrao) {
      await db.insert('categorias', categoria);
    }
  }

  // MÉTODOS PARA CONTAS
  Future<int> inserirConta(Map<String, dynamic> conta) async {
    final db = await database;
    return await db.insert('contas', conta);
  }

  Future<List<Map<String, dynamic>>> obterContas() async {
    final db = await database;
    return await db.query('contas', where: 'ativo = 1', orderBy: 'nome');
  }

  Future<int> atualizarConta(Map<String, dynamic> conta) async {
    final db = await database;
    return await db.update(
      'contas',
      conta,
      where: 'id = ?',
      whereArgs: [conta['id']],
    );
  }

  Future<int> deletarConta(int id) async {
    final db = await database;
    return await db.update(
      'contas',
      {'ativo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MÉTODOS PARA TRANSAÇÕES
  Future<int> inserirTransacao(Map<String, dynamic> transacao) async {
    final db = await database;
    return await db.insert('transacoes', transacao);
  }

  Future<List<Map<String, dynamic>>> obterTransacoes() async {
    final db = await database;
    return await db.query('transacoes', orderBy: 'data DESC');
  }

  Future<int> atualizarTransacao(Map<String, dynamic> transacao) async {
    final db = await database;
    return await db.update(
      'transacoes',
      transacao,
      where: 'id = ?',
      whereArgs: [transacao['id']],
    );
  }

  Future<int> deletarTransacao(int id) async {
    final db = await database;
    return await db.delete(
      'transacoes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MÉTODOS PARA CATEGORIAS
  Future<List<Map<String, dynamic>>> obterCategorias() async {
    final db = await database;
    return await db.query('categorias', where: 'ativo = 1', orderBy: 'nome');
  }

  // MÉTODOS PARA REMESSAS
  Future<int> inserirRemessa(Map<String, dynamic> remessa) async {
    final db = await database;
    return await db.insert('remessas', remessa);
  }

  Future<List<Map<String, dynamic>>> obterRemessas() async {
    final db = await database;
    return await db.query('remessas', orderBy: 'data_envio DESC');
  }

  Future<int> atualizarRemessa(Map<String, dynamic> remessa) async {
    final db = await database;
    return await db.update(
      'remessas',
      remessa,
      where: 'id = ?',
      whereArgs: [remessa['id']],
    );
  }

  Future<int> excluirRemessa(int id) async {
    final db = await database;
    return await db.delete(
      'remessas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MÉTODOS PARA CÁLCULOS
  Future<double> calcularSaldoTotal() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(saldo) as total FROM contas WHERE ativo = 1
    ''');
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> calcularTotalMensal(String tipo, int ano, int mes) async {
    final db = await database;
    final dataInicio = '$ano-${mes.toString().padLeft(2, '0')}-01';
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    final dataFim = '$ano-${mes.toString().padLeft(2, '0')}-$ultimoDia';
    
    final result = await db.rawQuery('''
      SELECT SUM(valor) as total
      FROM transacoes
      WHERE tipo = ? AND date(data) >= date(?) AND date(data) <= date(?) AND pago = 1
    ''', [tipo, dataInicio, dataFim]);

    return result.first['total'] as double? ?? 0.0;
  }

  Future<Map<String, double>> obterGastosPorCategoria(int ano, int mes) async {
    final db = await database;
    final dataInicio = '$ano-${mes.toString().padLeft(2, '0')}-01';
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    final dataFim = '$ano-${mes.toString().padLeft(2, '0')}-$ultimoDia';
    
    final result = await db.rawQuery('''
      SELECT categoria, SUM(valor) as total
      FROM transacoes
      WHERE tipo = 'despesa' AND date(data) >= date(?) AND date(data) <= date(?) AND pago = 1
      GROUP BY categoria
      ORDER BY total DESC
    ''', [dataInicio, dataFim]);

    Map<String, double> gastosPorCategoria = {};
    for (var row in result) {
      gastosPorCategoria[row['categoria'] as String] = row['total'] as double;
    }
    return gastosPorCategoria;
  }

  // MÉTODOS PARA CONFIGURAÇÕES
  Future<String?> obterConfiguracao(String chave) async {
    final db = await database;
    final result = await db.query(
      'configuracoes',
      where: 'chave = ?',
      whereArgs: [chave],
    );
    
    if (result.isNotEmpty) {
      return result.first['valor'] as String?;
    }
    return null;
  }

  Future<void> salvarConfiguracao(String chave, String valor) async {
    final db = await database;
    await db.insert(
      'configuracoes',
      {'chave': chave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // MÉTODOS PARA METAS
  Future<List<Map<String, dynamic>>> obterMetas() async {
    final db = await database;
    return await db.query('metas', orderBy: 'data_criacao DESC');
  }

  Future<int> inserirMeta(Map<String, dynamic> meta) async {
    final db = await database;
    return await db.insert('metas', meta);
  }

  Future<void> atualizarMeta(Map<String, dynamic> meta) async {
    final db = await database;
    await db.update(
      'metas',
      meta,
      where: 'id = ?',
      whereArgs: [meta['id']],
    );
  }

  Future<void> excluirMeta(int id) async {
    final db = await database;
    await db.delete(
      'metas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> obterMeta(int id) async {
    final db = await database;
    final result = await db.query(
      'metas',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Fechar conexão com o banco
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}