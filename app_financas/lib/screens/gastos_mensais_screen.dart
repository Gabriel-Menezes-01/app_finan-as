import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';
import 'transacoes_screen.dart';

class GastosMensaisScreen extends StatefulWidget {
  @override
  _GastosMensaisScreenState createState() => _GastosMensaisScreenState();
}

class _GastosMensaisScreenState extends State<GastosMensaisScreen> 
    with SingleTickerProviderStateMixin {
  DateTime _mesSelecionado = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Atualiza o FloatingActionButton quando muda de aba
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Mensais'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'Todos os Gastos',
            ),
            Tab(
              icon: Icon(Icons.flight_takeoff),
              text: 'Transferências BR',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selecionarMes,
          ),
          Consumer<FinancasProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.currency_exchange),
                tooltip: 'Alterar Moeda',
                onSelected: (String moeda) {
                  provider.alterarMoeda(moeda);
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'EUR',
                    child: Row(
                      children: [
                        Text('€', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Text('Euro'),
                        if (provider.configuracao.moeda == 'EUR')
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, color: Colors.green, size: 16),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'BRL',
                    child: Row(
                      children: [
                        Text('R\$', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Text('Real'),
                        if (provider.configuracao.moeda == 'BRL')
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, color: Colors.green, size: 16),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGastosTab(provider, false), // Todos os gastos
              _buildGastosTab(provider, true),  // Só transferências
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabController.index == 1 
            ? _showAdicionarTransferenciaDialog(context)
            : _showAdicionarGastoDialog(context),
        icon: Icon(_tabController.index == 1 ? Icons.flight_takeoff : Icons.add),
        label: Text(_tabController.index == 1 ? 'Nova Transferência' : 'Novo Gasto'),
        backgroundColor: _tabController.index == 1 ? Colors.blue.shade600 : Colors.red.shade600,
      ),
    );
  }

  Widget _buildGastosTab(FinancasProvider provider, bool apenasTransferencias) {
    final gastosMes = _getGastosMes(provider, apenasTransferencias);
    final totalGastos = gastosMes.fold(0.0, (sum, gasto) => sum + gasto.valor);

    return Column(
      children: [
        _buildMesSelector(),
        _buildResumoGastos(totalGastos, provider, gastosMes, apenasTransferencias),
        Expanded(
          child: gastosMes.isEmpty
              ? _buildEmptyState()
              : _buildListaGastos(gastosMes, provider),
        ),
      ],
    );
  }

  Widget _buildMesSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gastos de ${DateFormat('MMMM yyyy', 'pt_BR').format(_mesSelecionado)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _mesSelecionado = DateTime(_mesSelecionado.year, _mesSelecionado.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _mesSelecionado = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoGastos(double totalGastos, FinancasProvider provider, List<Transacao> gastosMes, [bool apenasTransferencias = false]) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              apenasTransferencias ? 'Transferências para o Brasil' : 'Total de Gastos no Mês',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.formatarMoeda(totalGastos),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${gastosMes.length} transações',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum gasto registrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione seus gastos do mês para ter controle total das suas despesas',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAdicionarGastoDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Primeiro Gasto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaGastos(List<Transacao> gastos, FinancasProvider provider) {
    final gastosPorDia = _agruparGastosPorDia(gastos);

    return RefreshIndicator(
      onRefresh: () => provider.carregarTransacoes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gastosPorDia.length,
        itemBuilder: (context, index) {
          final data = gastosPorDia.keys.elementAt(index);
          final gastosData = gastosPorDia[data]!;
          final totalDia = gastosData.fold(0.0, (sum, gasto) => sum + gasto.valor);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy - EEEE', 'pt_BR').format(data),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      provider.formatarMoeda(totalDia),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ...gastosData.map((gasto) => _buildGastoCard(gasto, provider)),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGastoCard(Transacao gasto, FinancasProvider provider) {
    // Transferências para o Brasil sempre em azul
    final bool isTransferencia = gasto.categoria == 'Transferências para o Brasil';
    
    final Color primaryColor = isTransferencia 
        ? Colors.blue 
        : (gasto.pago ? Colors.green : Colors.red);
    final Color lightColor = isTransferencia 
        ? Colors.blue.shade100 
        : (gasto.pago ? Colors.green.shade100 : Colors.red.shade100);
    final Color darkColor = isTransferencia 
        ? Colors.blue.shade600 
        : (gasto.pago ? Colors.green.shade600 : Colors.red.shade600);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lightColor,
          child: Icon(
            _getCategoriaIcon(gasto.categoria),
            color: darkColor,
            size: 20,
          ),
        ),
        title: Text(
          gasto.descricao,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gasto.categoria),
            // Mostrar conta de origem para transferências para o Brasil
            if (gasto.categoria == 'Transferências para o Brasil')
              Consumer<FinancasProvider>(
                builder: (context, provider, child) {
                  final conta = provider.contas.firstWhere(
                    (c) => c.id == gasto.contaId,
                    orElse: () => provider.contas.first,
                  );
                  return Text(
                    'Conta: ${conta.nome}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            if (gasto.observacoes != null && gasto.observacoes!.isNotEmpty)
              Text(
                gasto.observacoes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Valor em Euro
            Text(
              provider.formatarMoeda(gasto.valor),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            // Valor em Real para transferências para o Brasil
            if (gasto.categoria == 'Transferências para o Brasil' && gasto.valorReal != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'R\$ ${gasto.valorReal!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTransferencia 
                          ? (gasto.pago ? Icons.flight_takeoff : Icons.schedule)
                          : (gasto.pago ? Icons.check_circle : Icons.schedule),
                      size: 10,
                      color: darkColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isTransferencia 
                          ? (gasto.pago ? 'Enviado' : 'Aguardando')
                          : (gasto.pago ? 'Pago' : 'Pendente'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: darkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showDetalhesGasto(gasto, provider),
      ),
    );
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'Alimentação':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_car;
      case 'Moradia':
        return Icons.home;
      case 'Saúde':
        return Icons.local_hospital;
      case 'Educação':
        return Icons.school;
      case 'Lazer':
        return Icons.sports_esports;
      case 'Compras':
        return Icons.shopping_bag;
      case 'Serviços':
        return Icons.build;
      case 'Transferências para o Brasil':
        return Icons.flight_takeoff;
      default:
        return Icons.attach_money;
    }
  }

  List<Transacao> _getGastosMes(FinancasProvider provider, [bool apenasTransferencias = false]) {
    final inicioMes = DateTime(_mesSelecionado.year, _mesSelecionado.month, 1);
    final fimMes = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1, 0, 23, 59, 59);

    var transacoesFiltradas = provider.transacoes.where((transacao) =>
      transacao.tipo == 'despesa' &&
      transacao.data.isAfter(inicioMes.subtract(const Duration(days: 1))) &&
      transacao.data.isBefore(fimMes.add(const Duration(days: 1)))
    );

    if (apenasTransferencias) {
      transacoesFiltradas = transacoesFiltradas.where((transacao) => 
        transacao.categoria == 'Transferências para o Brasil'
      );
    }

    return transacoesFiltradas.toList()..sort((a, b) => b.data.compareTo(a.data));
  }

  Map<DateTime, List<Transacao>> _agruparGastosPorDia(List<Transacao> gastos) {
    final Map<DateTime, List<Transacao>> gastosPorDia = {};

    for (final gasto in gastos) {
      final data = DateTime(gasto.data.year, gasto.data.month, gasto.data.day);
      if (gastosPorDia[data] == null) {
        gastosPorDia[data] = [];
      }
      gastosPorDia[data]!.add(gasto);
    }

    return gastosPorDia;
  }

  void _selecionarMes() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _mesSelecionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (data != null) {
      setState(() {
        _mesSelecionado = data;
      });
    }
  }

  void _showAdicionarGastoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddDespesaDialog(),
    );
  }

  void _showAdicionarTransferenciaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTransferenciaDialog(),
    );
  }

  void _showDetalhesGasto(Transacao gasto, FinancasProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransacaoDetailsBottomSheet(transacao: gasto),
    );
  }
}