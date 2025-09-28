import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/transacao.dart';
import '../models/conta.dart';
import '../models/categoria.dart';
import '../models/configuracao.dart';
import '../models/remessa.dart';
import 'auth_service.dart';

class CloudSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Obter referência da coleção do usuário
  static CollectionReference _getUserCollection(String collectionName) {
    final userId = AuthService.userId;
    if (userId == null) throw 'Usuário não autenticado';
    return _firestore.collection('users').doc(userId).collection(collectionName);
  }
  
  // TRANSAÇÕES
  static Future<void> syncTransacao(Transacao transacao) async {
    try {
      await _getUserCollection('transacoes').doc(transacao.id.toString()).set({
        'descricao': transacao.descricao,
        'valor': transacao.valor,
        'categoria': transacao.categoria,
        'data': transacao.data.toIso8601String(),
        'dataCriacao': transacao.dataCriacao.toIso8601String(),
        'tipo': transacao.tipo,
        'pago': transacao.pago,
        'observacoes': transacao.observacoes,
        'contaId': transacao.contaId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao sincronizar transação: $e');
    }
  }
  
  static Future<void> deleteTransacaoFromCloud(int transacaoId) async {
    try {
      await _getUserCollection('transacoes').doc(transacaoId.toString()).delete();
    } catch (e) {
      print('Erro ao deletar transação da nuvem: $e');
    }
  }
  
  static Future<List<Transacao>> getTransacoesFromCloud() async {
    try {
      final snapshot = await _getUserCollection('transacoes').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Transacao(
          id: int.parse(doc.id),
          descricao: data['descricao'],
          valor: data['valor'].toDouble(),
          categoria: data['categoria'],
          data: DateTime.parse(data['data']),
          tipo: data['tipo'],
          pago: data['pago'],
          observacoes: data['observacoes'],
          contaId: data['contaId'],
          dataCriacao: data['dataCriacao'] != null ? DateTime.parse(data['dataCriacao']) : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar transações da nuvem: $e');
      return [];
    }
  }
  
  // CONTAS
  static Future<void> syncConta(Conta conta) async {
    try {
      await _getUserCollection('contas').doc(conta.id.toString()).set({
        'nome': conta.nome,
        'descricao': conta.descricao,
        'saldo': conta.saldo,
        'tipo': conta.tipo,
        'dataCriacao': conta.dataCriacao.toIso8601String(),
        'ativo': conta.ativo,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao sincronizar conta: $e');
    }
  }
  
  static Future<void> deleteContaFromCloud(int contaId) async {
    try {
      await _getUserCollection('contas').doc(contaId.toString()).delete();
    } catch (e) {
      print('Erro ao deletar conta da nuvem: $e');
    }
  }
  
  static Future<List<Conta>> getContasFromCloud() async {
    try {
      final snapshot = await _getUserCollection('contas').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Conta(
          id: int.parse(doc.id),
          nome: data['nome'],
          descricao: data['descricao'],
          saldo: data['saldo'].toDouble(),
          tipo: data['tipo'],
          dataCriacao: DateTime.parse(data['dataCriacao']),
          ativo: data['ativo'],
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar contas da nuvem: $e');
      return [];
    }
  }
  
  // CATEGORIAS
  static Future<void> syncCategoria(Categoria categoria) async {
    try {
      await _getUserCollection('categorias').doc(categoria.id.toString()).set({
        'nome': categoria.nome,
        'tipo': categoria.tipo,
        'cor': categoria.cor.value,
        'icone': categoria.icone.codePoint,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao sincronizar categoria: $e');
    }
  }
  
  static Future<List<Categoria>> getCategoriasFromCloud() async {
    try {
      final snapshot = await _getUserCollection('categorias').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Categoria(
          id: int.parse(doc.id),
          nome: data['nome'],
          tipo: data['tipo'],
          cor: Color(data['cor']),
          icone: IconData(data['icone'], fontFamily: 'MaterialIcons'),
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar categorias da nuvem: $e');
      return [];
    }
  }
  
  // REMESSAS
  static Future<void> syncRemessa(Remessa remessa) async {
    try {
      await _getUserCollection('remessas').doc(remessa.id.toString()).set({
        'valorEuro': remessa.valorEuro,
        'valorReal': remessa.valorReal,
        'dataEnvio': remessa.dataEnvio.toIso8601String(),
        'dataRecebimento': remessa.dataRecebimento?.toIso8601String(),
        'contaOrigemId': remessa.contaOrigemId,
        'contaDestinoId': remessa.contaDestinoId,
        'observacoes': remessa.observacoes,
        'status': remessa.status,
        'taxaCambio': remessa.taxaCambio,
        'codigoRastreamento': remessa.codigoRastreamento,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao sincronizar remessa: $e');
    }
  }
  
  static Future<List<Remessa>> getRemessasFromCloud() async {
    try {
      final snapshot = await _getUserCollection('remessas').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Remessa(
          id: int.parse(doc.id),
          valorEuro: data['valorEuro'].toDouble(),
          valorReal: data['valorReal']?.toDouble(),
          dataEnvio: DateTime.parse(data['dataEnvio']),
          dataRecebimento: data['dataRecebimento'] != null ? DateTime.parse(data['dataRecebimento']) : null,
          contaOrigemId: data['contaOrigemId'],
          contaDestinoId: data['contaDestinoId'],
          observacoes: data['observacoes'],
          status: data['status'],
          taxaCambio: data['taxaCambio']?.toDouble(),
          codigoRastreamento: data['codigoRastreamento'],
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar remessas da nuvem: $e');
      return [];
    }
  }
  
  // CONFIGURAÇÕES
  static Future<void> syncConfiguracao(Configuracao config) async {
    try {
      await _getUserCollection('configuracoes').doc('user_config').set({
        'moeda': config.moeda,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erro ao sincronizar configuração: $e');
    }
  }
  
  static Future<Configuracao?> getConfiguracaoFromCloud() async {
    try {
      final doc = await _getUserCollection('configuracoes').doc('user_config').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Configuracao(
          moeda: data['moeda'] ?? Configuracao.euro,
        );
      }
      return null;
    } catch (e) {
      print('Erro ao buscar configuração da nuvem: $e');
      return null;
    }
  }
  
  // SINCRONIZAÇÃO COMPLETA
  static Future<void> syncAllDataToCloud({
    required List<Transacao> transacoes,
    required List<Conta> contas,
    required List<Categoria> categorias,
    required List<Remessa> remessas,
    required Configuracao configuracao,
  }) async {
    try {
      // Sincronizar em paralelo para melhor performance
      await Future.wait([
        // Transações
        ...transacoes.map((t) => syncTransacao(t)),
        // Contas
        ...contas.map((c) => syncConta(c)),
        // Categorias
        ...categorias.map((cat) => syncCategoria(cat)),
        // Remessas
        ...remessas.map((r) => syncRemessa(r)),
        // Configuração
        syncConfiguracao(configuracao),
      ]);
    } catch (e) {
      print('Erro na sincronização completa: $e');
      throw 'Erro ao sincronizar dados com a nuvem';
    }
  }
  
  // BAIXAR TODOS OS DADOS
  static Future<Map<String, dynamic>> downloadAllData() async {
    try {
      final results = await Future.wait([
        getTransacoesFromCloud(),
        getContasFromCloud(),
        getCategoriasFromCloud(),
        getRemessasFromCloud(),
        getConfiguracaoFromCloud(),
      ]);
      
      return {
        'transacoes': results[0],
        'contas': results[1],
        'categorias': results[2],
        'remessas': results[3],
        'configuracao': results[4],
      };
    } catch (e) {
      print('Erro ao baixar dados da nuvem: $e');
      throw 'Erro ao carregar dados da nuvem';
    }
  }
  
  // LIMPAR DADOS DA NUVEM (para logout completo)
  static Future<void> clearUserCloudData() async {
    try {
      final userId = AuthService.userId;
      if (userId == null) return;
      
      final userDoc = _firestore.collection('users').doc(userId);
      
      // Deletar todas as subcoleções
      await Future.wait([
        _deleteCollection(userDoc.collection('transacoes')),
        _deleteCollection(userDoc.collection('contas')),
        _deleteCollection(userDoc.collection('categorias')),
        _deleteCollection(userDoc.collection('remessas')),
        _deleteCollection(userDoc.collection('configuracoes')),
      ]);
      
      // Deletar o documento do usuário
      await userDoc.delete();
    } catch (e) {
      print('Erro ao limpar dados da nuvem: $e');
    }
  }
  
  // Função auxiliar para deletar coleção
  static Future<void> _deleteCollection(CollectionReference collection) async {
    final batch = _firestore.batch();
    final snapshot = await collection.get();
    
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}