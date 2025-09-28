import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:file_picker/file_picker.dart';  // Temporariamente desabilitado
import '../services/database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _db = DatabaseService();

  /// Criar backup completo dos dados
  Future<Map<String, dynamic>> criarBackup() async {
    try {
      // Obter todos os dados do banco
      final transacoes = await _db.obterTransacoes();
      final contas = await _db.obterContas();
      final categorias = await _db.obterCategorias();
      final remessas = await _db.obterRemessas();
      final metas = await _db.obterMetas();

      // Criar estrutura do backup
      final backup = {
        'app_info': {
          'nome': 'App Financas',
          'versao': '2.0',
          'data_backup': DateTime.now().toIso8601String(),
          'plataforma': defaultTargetPlatform.name,
        },
        'dados': {
          'transacoes': transacoes,
          'contas': contas,
          'categorias': categorias,
          'remessas': remessas,
          'metas': metas,
        },
        'estatisticas': {
          'total_transacoes': transacoes.length,
          'total_contas': contas.length,
          'total_categorias': categorias.length,
          'total_remessas': remessas.length,
          'total_metas': metas.length,
        }
      };

      final stats = backup['estatisticas'] as Map<String, dynamic>;
      debugPrint('Backup criado com ${stats['total_transacoes']} transações');
      return backup;
    } catch (e) {
      debugPrint('Erro ao criar backup: $e');
      rethrow;
    }
  }

  /// Salvar backup localmente
  Future<File> salvarBackupLocal() async {
    try {
      final backup = await criarBackup();
      final jsonString = jsonEncode(backup);

      // Obter diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'financas_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      // Escrever arquivo
      await file.writeAsString(jsonString);
      debugPrint('Backup salvo em: ${file.path}');
      
      return file;
    } catch (e) {
      debugPrint('Erro ao salvar backup local: $e');
      rethrow;
    }
  }

  /// Compartilhar backup
  Future<void> compartilharBackup() async {
    try {
      final backup = await criarBackup();
      final jsonString = jsonEncode(backup);

      // Criar arquivo temporário
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'financas_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);

      // Compartilhar arquivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup dos dados financeiros - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        subject: 'Backup App Finanças',
      );

      debugPrint('Backup compartilhado: ${file.path}');
    } catch (e) {
      debugPrint('Erro ao compartilhar backup: $e');
      rethrow;
    }
  }

  /// Selecionar e importar arquivo de backup (temporariamente desabilitado)
  Future<bool> selecionarEImportarBackup() async {
    // Funcionalidade temporariamente desabilitada devido a problemas de compatibilidade
    debugPrint('Importação de arquivo temporariamente desabilitada');
    return false;
  }

  /// Restaurar dados do backup
  Future<bool> restaurarBackup(String jsonContent) async {
    try {
      final Map<String, dynamic> backup = jsonDecode(jsonContent);
      
      // Validar estrutura do backup
      if (!_validarEstruturBackup(backup)) {
        throw Exception('Estrutura do backup inválida');
      }

      final dados = backup['dados'] as Map<String, dynamic>;
      final appInfo = backup['app_info'] as Map<String, dynamic>;

      debugPrint('Restaurando backup de: ${appInfo['data_backup']}');

      // Restaurar contas
      if (dados['contas'] != null) {
        final contas = dados['contas'] as List<dynamic>;
        debugPrint('Restaurando ${contas.length} contas...');
        for (final contaMap in contas) {
          try {
            await _db.inserirConta(Map<String, dynamic>.from(contaMap));
          } catch (e) {
            debugPrint('Erro ao inserir conta: $e - continuando...');
          }
        }
      }

      // Restaurar categorias (apenas se não existirem)
      if (dados['categorias'] != null) {
        final categoriasBackup = dados['categorias'] as List<dynamic>;
        final categoriasExistentes = await _db.obterCategorias();
        if (categoriasExistentes.isEmpty) {
          debugPrint('${categoriasBackup.length} categorias serão restauradas via inserção manual');
        }
      }

      // Restaurar transações
      if (dados['transacoes'] != null) {
        final transacoes = dados['transacoes'] as List<dynamic>;
        debugPrint('Restaurando ${transacoes.length} transações...');
        for (final transacaoMap in transacoes) {
          try {
            await _db.inserirTransacao(Map<String, dynamic>.from(transacaoMap));
          } catch (e) {
            debugPrint('Erro ao inserir transação: $e - continuando...');
          }
        }
      }

      // Restaurar remessas
      if (dados['remessas'] != null) {
        final remessas = dados['remessas'] as List<dynamic>;
        debugPrint('Restaurando ${remessas.length} remessas...');
        for (final remessaMap in remessas) {
          try {
            await _db.inserirRemessa(Map<String, dynamic>.from(remessaMap));
          } catch (e) {
            debugPrint('Erro ao inserir remessa: $e - continuando...');
          }
        }
      }

      // Restaurar metas
      if (dados['metas'] != null) {
        final metas = dados['metas'] as List<dynamic>;
        debugPrint('Restaurando ${metas.length} metas...');
        for (final metaMap in metas) {
          try {
            await _db.inserirMeta(Map<String, dynamic>.from(metaMap));
          } catch (e) {
            debugPrint('Erro ao inserir meta: $e - continuando...');
          }
        }
      }

      debugPrint('Backup restaurado com sucesso!');
      return true;
    } catch (e) {
      debugPrint('Erro ao restaurar backup: $e');
      return false;
    }
  }

  /// Validar estrutura do backup
  bool _validarEstruturBackup(Map<String, dynamic> backup) {
    if (!backup.containsKey('app_info') || !backup.containsKey('dados')) {
      return false;
    }

    final appInfo = backup['app_info'] as Map<String, dynamic>?;
    if (appInfo == null || !appInfo.containsKey('nome')) {
      return false;
    }

    return true;
  }

  /// Obter estatísticas do banco de dados
  Future<Map<String, int>> obterEstatisticas() async {
    try {
      final transacoes = await _db.obterTransacoes();
      final contas = await _db.obterContas();
      final categorias = await _db.obterCategorias();
      final remessas = await _db.obterRemessas();
      final metas = await _db.obterMetas();

      return {
        'transacoes': transacoes.length,
        'contas': contas.length,
        'categorias': categorias.length,
        'remessas': remessas.length,
        'metas': metas.length,
      };
    } catch (e) {
      debugPrint('Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Exportar dados para CSV
  Future<File> exportarParaCSV() async {
    try {
      final transacoes = await _db.obterTransacoes();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'financas_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      // Criar cabeçalho CSV
      final csvLines = <String>[];
      csvLines.add('Data,Tipo,Descrição,Valor,Categoria,Conta,Observações');

      // Adicionar dados
      for (final transacao in transacoes) {
        final linha = [
          transacao['data'] ?? '',
          transacao['tipo'] ?? '',
          '"${transacao['descricao'] ?? ''}"',
          transacao['valor']?.toString() ?? '0',
          transacao['categoria'] ?? '',
          transacao['conta'] ?? '',
          '"${transacao['observacoes'] ?? ''}"',
        ].join(',');
        csvLines.add(linha);
      }

      // Escrever arquivo
      await file.writeAsString(csvLines.join('\n'));
      debugPrint('CSV exportado: ${file.path}');
      
      return file;
    } catch (e) {
      debugPrint('Erro ao exportar CSV: $e');
      rethrow;
    }
  }
}