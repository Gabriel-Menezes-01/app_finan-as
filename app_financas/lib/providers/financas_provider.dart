import 'package:flutter/material.dart';
import '../models/conta.dart';
import '../models/transacao.dart';
import '../models/categoria.dart';
import '../models/resumo_mensal.dart';
import '../models/remessa.dart';
import '../models/configuracao.dart';
import '../models/meta.dart';
import '../services/database_service.dart';

class FinancasProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // Listas de dados
  List<Conta> _contas = [];
  List<Transacao> _transacoes = [];
  List<Categoria> _categorias = [];
  List<ResumoMensal> _resumosMensais = [];
  List<Remessa> _remessas = [];
  List<Meta> _metas = [];

  
  // Configurações
  Configuracao _configuracao = const Configuracao();
  
  // Estado de loading
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  List<Conta> get contas => _contas;
  List<Transacao> get transacoes => _transacoes;
  List<Categoria> get categorias => _categorias;
  List<ResumoMensal> get resumosMensais => _resumosMensais;
  List<Remessa> get remessas => _remessas;
  List<Meta> get metas => _metas;

  Configuracao get configuracao => _configuracao;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  FinancasProvider() {
    _inicializar();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  double get saldoTotal {
    return _contas.fold(0.0, (total, conta) => total + conta.saldo);
  }

  double get receitaMensal {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return _transacoes
        .where((t) => t.tipo == 'receita' && 
                     t.data.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                     t.data.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (total, t) => total + t.valor);
  }

  double get despesaMensal {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return _transacoes
        .where((t) => t.tipo == 'despesa' && 
                     t.data.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                     t.data.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (total, t) => total + t.valor);
  }

  double get transferenciasParaBrasilMes {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return _transacoes
        .where((t) => t.categoria == 'Transferências para o Brasil' && 
                     t.data.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                     t.data.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (total, t) => total + t.valor);
  }

  double get transferenciasParaBrasilTotal {
    return _transacoes
        .where((t) => t.categoria == 'Transferências para o Brasil')
        .fold(0.0, (total, t) => total + t.valor);
  }

  double get transferenciasParaBrasilTotalReais {
    return _transacoes
        .where((t) => t.categoria == 'Transferências para o Brasil')
        .fold(0.0, (total, t) => total + (t.valorReal ?? 0.0));
  }

  // Getters adicionais para compatibilidade
  double get totalReceitasMes => receitaMensal;
  double get totalDespesasMes => despesaMensal;
  double get saldoMes => receitaMensal - despesaMensal;
  
  // Método para inicialização (compatibilidade)
  Future<void> initialize() async {
    await _inicializar();
  }
  
  // Método para atualizar transação
  Future<void> atualizarTransacao(Transacao transacao) async {
    try {
      _setLoading(true);
      
      final index = _transacoes.indexWhere((t) => t.id == transacao.id);
      if (index != -1) {
        final transacaoAntiga = _transacoes[index];
        
        // Se a transação antiga estava paga, reverter seu efeito no saldo
        if (transacaoAntiga.pago) {
          await _reverterSaldoConta(transacaoAntiga.contaId, transacaoAntiga.valor, transacaoAntiga.tipo);
        }
        
        // Atualizar no banco de dados
        await _db.atualizarTransacao(transacao.toMap());
        
        // Atualizar na lista local
        _transacoes[index] = transacao;
        
        // Se a nova transação está paga, aplicar seu efeito no saldo
        if (transacao.pago) {
          await _atualizarSaldoConta(transacao.contaId, transacao.valor, transacao.tipo);
        }
      }
      
      await calcularResumoMensal();
    } catch (e) {
      debugPrint('Erro ao atualizar transação: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Método para obter gastos por categoria
  Future<Map<String, double>> obterGastosPorCategoria(int mes) async {
    return gastosPorCategoria;
  }
  
  // Método para obter categorias por tipo
  List<Categoria> getCategoriasPorTipo(String tipo) {
    return _categorias.where((c) => c.tipo == tipo).toList();
  }

  Future<void> _inicializar() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    try {
      await _carregarConfiguracao();
      await carregarContas();
      await carregarTransacoes();
      await carregarCategorias();
      await _carregarRemessas();
      await _carregarMetas();
      
      // NÃO recalcular saldos na inicialização para preservar valores salvos
      // Os saldos permanecerão exatamente como estavam no banco de dados
      debugPrint('Dados inicializados - saldos preservados');
      
      await calcularResumoMensal();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Erro na inicialização: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    try {
      await carregarContas();
      await carregarTransacoes();
      await carregarCategorias();
      await _carregarRemessas();
      await calcularResumoMensal();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar dados: $e');
    }
  }

  Future<void> carregarContas() async {
    try {
      final contasMapas = await _db.obterContas();
      _contas = contasMapas.map((mapa) => Conta.fromMap(mapa)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar contas: $e');
      _contas = [];
    }
  }

  Future<void> carregarCategorias() async {
    try {
      final categoriasMapas = await _db.obterCategorias();
      _categorias = categoriasMapas.map((mapa) => Categoria.fromMap(mapa)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar categorias: $e');
      _categorias = [];
    }
  }

  // Método removido - categorias são criadas automaticamente

  Future<void> carregarTransacoes({DateTime? dataInicio, DateTime? dataFim}) async {
    try {
      final transacoesMapas = await _db.obterTransacoes();
      _transacoes = transacoesMapas.map((mapa) => Transacao.fromMap(mapa)).toList();
      
      if (dataInicio != null && dataFim != null) {
        _transacoes = _transacoes.where((t) => 
            t.data.isAfter(dataInicio.subtract(const Duration(days: 1))) && 
            t.data.isBefore(dataFim.add(const Duration(days: 1))))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar transações: $e');
      _transacoes = [];
    }
  }

  Future<void> adicionarTransacao(Transacao transacao) async {
    try {
      _setLoading(true);
      
      // Inserir no banco de dados
      final id = await _db.inserirTransacao(transacao.toMap());
      transacao.id = id;
      
      // Adicionar na lista local
      _transacoes.add(transacao);
      
      // Atualizar saldo da conta APENAS se for uma transação paga
      if (transacao.pago) {
        await _atualizarSaldoConta(transacao.contaId, transacao.valor, transacao.tipo);
      }
      
      await calcularResumoMensal();
    } catch (e) {
      debugPrint('Erro ao adicionar transação: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _atualizarSaldoConta(int contaId, double valor, String tipo) async {
    try {
      final conta = _contas.firstWhere((c) => c.id == contaId);
      
      if (tipo == 'receita') {
        conta.saldo += valor;
      } else {
        conta.saldo -= valor;
      }
      
      await _db.atualizarConta(conta.toMap());
    } catch (e) {
      debugPrint('Erro ao atualizar saldo da conta: $e');
      rethrow;
    }
  }

  Future<void> excluirTransacao(int id) async {
    try {
      final transacao = _transacoes.firstWhere((t) => t.id == id);
      
      // Primeiro remove da lista e do banco
      await _db.deletarTransacao(id);
      _transacoes.removeWhere((t) => t.id == id);
      
      // Apenas reverte a operação específica SEM recalcular tudo
      await _reverterSaldoConta(transacao.contaId, transacao.valor, transacao.tipo);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao excluir transação: $e');
      rethrow;
    }
  }

  Future<void> _reverterSaldoConta(int contaId, double valor, String tipo) async {
    try {
      final conta = _contas.firstWhere((c) => c.id == contaId);
      
      // Reverte exatamente o que foi feito
      if (tipo == 'receita') {
        conta.saldo -= valor; // Remove o que foi adicionado
      } else {
        conta.saldo += valor; // Adiciona de volta o que foi subtraído
      }
      
      await _db.atualizarConta(conta.toMap());
      debugPrint('Saldo revertido para conta ${conta.nome}: ${conta.saldo}');
    } catch (e) {
      debugPrint('Erro ao reverter saldo: $e');
      rethrow;
    }
  }

  Future<void> calcularResumoMensal() async {
    try {
      final now = DateTime.now();
      final primeiroDiaDoMes = DateTime(now.year, now.month, 1);
      final ultimoDiaDoMes = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      final transacoesMes = _transacoes.where((t) => 
        t.data.isAfter(primeiroDiaDoMes.subtract(const Duration(microseconds: 1))) &&
        t.data.isBefore(ultimoDiaDoMes.add(const Duration(microseconds: 1)))
      ).toList();
      
      double totalReceitas = 0;
      double totalDespesas = 0;
      
      for (final transacao in transacoesMes) {
        if (transacao.tipo == 'receita') {
          totalReceitas += transacao.valor;
        } else {
          totalDespesas += transacao.valor;
        }
      }
      
      final resumo = ResumoMensal(
        mes: now.month,
        ano: now.year,
        totalReceitas: totalReceitas,
        totalDespesas: totalDespesas,
        saldoAnterior: 0, // Por ora, usando 0 como padrão
        saldoFinal: totalReceitas - totalDespesas,
        dataCalculo: now,
      );
      
      // Remove resumo existente do mesmo mês/ano e adiciona o novo
      _resumosMensais.removeWhere((r) => r.mes == now.month && r.ano == now.year);
      _resumosMensais.add(resumo);
      
      // Manter apenas os últimos 12 meses
      _resumosMensais.sort((a, b) => DateTime(b.ano, b.mes).compareTo(DateTime(a.ano, a.mes)));
      if (_resumosMensais.length > 12) {
        _resumosMensais = _resumosMensais.take(12).toList();
      }
      
      debugPrint('Resumo mensal calculado - Receitas: €${totalReceitas.toStringAsFixed(2)}, Despesas: €${totalDespesas.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('Erro ao calcular resumo mensal: $e');
    }
  }

  List<Transacao> get transacoesPorData {
    final transacoesOrdenadas = List<Transacao>.from(_transacoes);
    transacoesOrdenadas.sort((a, b) => b.data.compareTo(a.data));
    return transacoesOrdenadas;
  }

  List<Transacao> get transacoesRecentes {
    return transacoesPorData.take(5).toList();
  }

  Map<String, double> get gastosPorCategoria {
    final Map<String, double> gastos = {};
    
    final now = DateTime.now();
    final inicioMes = DateTime(now.year, now.month, 1);
    final fimMes = DateTime(now.year, now.month + 1, 0);
    
    final despesasMes = _transacoes.where((t) => 
      t.tipo == 'despesa' && 
      t.data.isAfter(inicioMes.subtract(const Duration(days: 1))) &&
      t.data.isBefore(fimMes.add(const Duration(days: 1)))
    );
    
    for (final transacao in despesasMes) {
      gastos[transacao.categoria] = (gastos[transacao.categoria] ?? 0) + transacao.valor;
    }
    
    return gastos;
  }

  Future<void> adicionarConta(Conta conta) async {
    try {
      _setLoading(true);
      final id = await _db.inserirConta(conta.toMap());
      conta.id = id;
      _contas.add(conta);
    } catch (e) {
      debugPrint('Erro ao adicionar conta: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> atualizarConta(Conta conta) async {
    try {
      _setLoading(true);
      await _db.atualizarConta(conta.toMap());
      
      final index = _contas.indexWhere((c) => c.id == conta.id);
      if (index != -1) {
        _contas[index] = conta;
      }
    } catch (e) {
      debugPrint('Erro ao atualizar conta: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> excluirConta(int id) async {
    try {
      _setLoading(true);
      await _db.deletarConta(id);
      _contas.removeWhere((c) => c.id == id);
    } catch (e) {
      debugPrint('Erro ao excluir conta: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos de categoria removidos temporariamente por incompatibilidade de API

  Future<void> sincronizarDados() async {
    try {
      _setLoading(true);
      
      // Recarregar todos os dados do banco
      await carregarContas();
      await carregarTransacoes();
      await carregarCategorias();
      await _carregarRemessas();
      await calcularResumoMensal();
      
      debugPrint('Sincronização concluída');
    } catch (e) {
      debugPrint('Erro na sincronização: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Método para debugar e forçar recálculo completo de saldos
  Future<void> forcarRecalculoCompleto() async {
    try {
      _setLoading(true);
      
      // Zerar todos os saldos das contas
      for (final conta in _contas) {
        conta.saldo = 0;
        await _db.atualizarConta(conta.toMap());
      }
      
      // Recalcular com base em todas as transações pagas
      for (final transacao in _transacoes.where((t) => t.pago)) {
        await _atualizarSaldoConta(transacao.contaId, transacao.valor, transacao.tipo);
      }
      
      // Recarregar para garantir consistência
      await carregarContas();
      
    } catch (e) {
      debugPrint('Erro no recálculo forçado: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> recarregarDados() async {
    try {
      _isInitialized = false;
      await _inicializar();
    } catch (e) {
      debugPrint('Erro ao recarregar dados: $e');
      rethrow;
    }
  }

  Future<void> validarSaldos() async {
    try {
      for (final conta in _contas) {
        final transacoesConta = _transacoes.where((t) => 
          t.contaId == conta.id && t.pago
        );
        
        double saldoCalculado = 0;
        for (final transacao in transacoesConta) {
          if (transacao.tipo == 'receita') {
            saldoCalculado += transacao.valor;
          } else {
            saldoCalculado -= transacao.valor;
          }
        }
        
        debugPrint('Conta ${conta.nome}: Saldo salvo: €${conta.saldo.toStringAsFixed(2)}, Saldo calculado: €${saldoCalculado.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('Erro na validação de saldos: $e');
    }
  }

  // Métodos para remessas
  Future<void> adicionarRemessa(Remessa remessa) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Inserir no banco de dados
      final id = await _db.inserirRemessa(remessa.toMap());
      
      // Adicionar na lista local
      final remessaComId = remessa.copyWith(id: id);
      _remessas.add(remessaComId);
      
      // Descontar valor da conta de origem
      final conta = _contas.firstWhere((c) => c.id == remessa.contaOrigemId);
      final contaAtualizada = conta.copyWith(saldo: conta.saldo - remessa.valorEuro);
      await _db.atualizarConta(contaAtualizada.toMap());
      
      // Atualizar na lista local
      final indexConta = _contas.indexWhere((c) => c.id == remessa.contaOrigemId);
      if (indexConta != -1) {
        _contas[indexConta] = contaAtualizada;
      }
      
    } catch (e) {
      debugPrint('Erro ao adicionar remessa: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarRemessa(Remessa remessa) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _db.atualizarRemessa(remessa.toMap());
      
      final index = _remessas.indexWhere((r) => r.id == remessa.id);
      if (index != -1) {
        _remessas[index] = remessa;
      }
      
    } catch (e) {
      debugPrint('Erro ao atualizar remessa: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> excluirRemessa(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _db.excluirRemessa(id);
      _remessas.removeWhere((r) => r.id == id);
      
    } catch (e) {
      debugPrint('Erro ao excluir remessa: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _carregarRemessas() async {
    try {
      final remessasMap = await _db.obterRemessas();
      _remessas = remessasMap.map((map) => Remessa.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Erro ao carregar remessas: $e');
      _remessas = [];
    }
  }

  Future<void> recalcularSaldos() async {
    await carregarTransacoes();
    await carregarContas();
    notifyListeners();
  }

  // Métodos de configuração
  Future<void> _carregarConfiguracao() async {
    try {
      final moeda = await _db.obterConfiguracao('moeda');
      _configuracao = Configuracao(moeda: moeda ?? Configuracao.euro);
    } catch (e) {
      debugPrint('Erro ao carregar configuração: $e');
      _configuracao = const Configuracao();
    }
  }

  Future<void> alterarMoeda(String moeda) async {
    try {
      await _db.salvarConfiguracao('moeda', moeda);
      _configuracao = _configuracao.copyWith(moeda: moeda);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao alterar moeda: $e');
    }
  }

  String formatarMoeda(double valor) {
    return '${_configuracao.simboloMoeda} ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // === MÉTODOS PARA SINCRONIZAÇÃO COM A NUVEM ===
  
  /// Criar dados iniciais para novo usuário
  Future<void> criarDadosIniciais() async {
    try {
      _setLoading(true);
      
      // Criar conta padrão
      final contaPadrao = Conta(
        nome: 'Conta Principal',
        descricao: 'Conta principal criada automaticamente',
        saldo: 0.0,
        tipo: 'corrente',
        dataCriacao: DateTime.now(),
      );
      
      await adicionarConta(contaPadrao);
      
      // Sincronizar dados iniciais com a nuvem
      await sincronizarComNuvem();
      
    } catch (e) {
      debugPrint('Erro ao criar dados iniciais: $e');
      throw 'Erro ao configurar conta inicial';
    } finally {
      _setLoading(false);
    }
  }
  
  /// Carregar todos os dados da nuvem
  Future<void> carregarDadosDaNuvem() async {
    try {
      _setLoading(true);
      
      // Importar dados do CloudSyncService (será implementado quando corrigirmos os imports)
      // final cloudData = await CloudSyncService.downloadAllData();
      
      // Por enquanto, apenas recarregar dados locais
      await carregarContas();
      await carregarTransacoes();
      await carregarCategorias();
      await _carregarRemessas();
      
    } catch (e) {
      debugPrint('Erro ao carregar dados da nuvem: $e');
      throw 'Erro ao carregar dados da nuvem';
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sincronizar todos os dados com a nuvem
  Future<void> sincronizarComNuvem() async {
    try {
      // Sincronização será implementada quando corrigirmos os imports
      // await CloudSyncService.syncAllDataToCloud(
      //   transacoes: _transacoes,
      //   contas: _contas,
      //   categorias: _categorias,
      //   remessas: _remessas,
      //   configuracao: _configuracao,
      // );
      
      debugPrint('Dados sincronizados com a nuvem');
    } catch (e) {
      debugPrint('Erro ao sincronizar com a nuvem: $e');
      throw 'Erro ao sincronizar dados';
    }
  }
  
  /// Limpar dados locais (para logout)
  Future<void> limparDadosLocais() async {
    try {
      _contas.clear();
      _transacoes.clear();
      _categorias.clear();
      _resumosMensais.clear();
      _remessas.clear();
      _metas.clear();
      _configuracao = const Configuracao();
      _isInitialized = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao limpar dados locais: $e');
    }
  }

  // ===== MÉTODOS DE METAS =====

  /// Carregar metas do banco de dados
  Future<void> _carregarMetas() async {
    try {
      final metasMap = await _db.obterMetas();
      _metas = metasMap.map((map) => Meta.fromMap(map)).toList();
      await _atualizarProgressoMetas();
      debugPrint('Metas carregadas: ${_metas.length} metas encontradas');
    } catch (e) {
      debugPrint('Erro ao carregar metas: $e');
    }
  }

  /// Recarregar metas do banco de dados
  Future<void> recarregarMetas() async {
    await _carregarMetas();
    notifyListeners();
  }

  /// Adicionar nova meta
  Future<void> adicionarMeta(Meta meta) async {
    try {
      _setLoading(true);
      debugPrint('Tentando inserir meta: ${meta.nome} - ${meta.valorMeta} ${meta.moeda}');
      debugPrint('Dados da meta para inserção: ${meta.toMap()}');
      
      final id = await _db.inserirMeta(meta.toMap());
      debugPrint('Meta inserida no banco com ID: $id');
      
      // Recarregar todas as metas do banco para garantir consistência
      await _carregarMetas();
      debugPrint('Metas recarregadas. Total: ${_metas.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao adicionar meta: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualizar meta existente
  Future<void> atualizarMeta(Meta meta) async {
    try {
      _setLoading(true);
      await _db.atualizarMeta(meta.toMap());
      debugPrint('Meta atualizada no banco: ${meta.id}');
      
      // Recarregar todas as metas do banco para garantir consistência
      await _carregarMetas();
      debugPrint('Metas recarregadas após atualização. Total: ${_metas.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar meta: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Excluir meta
  Future<void> excluirMeta(int id) async {
    try {
      _setLoading(true);
      await _db.excluirMeta(id);
      debugPrint('Meta excluída do banco: $id');
      
      // Recarregar todas as metas do banco para garantir consistência
      await _carregarMetas();
      debugPrint('Metas recarregadas após exclusão. Total: ${_metas.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao excluir meta: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualizar progresso de uma meta específica (versão simplificada)
  Future<void> _atualizarProgressoMeta(Meta meta) async {
    // Metas simplificadas - progresso será atualizado manualmente pelo usuário
    // Não há cálculo automático baseado em transações
  }

  /// Atualizar progresso de todas as metas
  Future<void> _atualizarProgressoMetas() async {
    try {
      for (final meta in _metas) {
        await _atualizarProgressoMeta(meta);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar progresso das metas: $e');
    }
  }

  /// Obter metas por status
  List<Meta> obterMetasPorStatus(String status) {
    return _metas.where((meta) => meta.status == status).toList();
  }

  /// Obter metas ativas
  List<Meta> get metasAtivas {
    return _metas.where((meta) => 
      meta.ativa && !meta.foiAtingida
    ).toList();
  }

  /// Obter metas concluídas
  List<Meta> get metasConcluidas {
    return _metas.where((meta) => 
      meta.foiAtingida || !meta.ativa
    ).toList();
  }


}