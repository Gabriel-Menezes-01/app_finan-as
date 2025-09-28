import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';
import '../services/backup_service.dart';
import 'contas_screen.dart';
import 'gastos_mensais_screen.dart';
import 'ganhos_extras_screen.dart';
import 'relatorios_screen.dart';
import 'metas_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar dados quando a tela carregar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinancasProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ) : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          ContasScreen(),
          GastosMensaisScreen(),
          GanhosExtrasScreen(),
          MetasScreen(),
          RelatoriosScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Contas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Ganhos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Metas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<FinancasProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized && provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Finanças Pessoais'),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sincronizar Saldos',
                onPressed: () => _sincronizarSaldos(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar Dados',
                onPressed: () => provider.refresh(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumoFinanceiro(provider),
                  const SizedBox(height: 20),
                  _buildResumoMensal(provider),
                  const SizedBox(height: 20),
                  _buildResumoTransferencias(provider),
                  const SizedBox(height: 20),
                  _buildTransacoesRecentes(provider),
                  const SizedBox(height: 20),
                  _buildAcoesRapidas(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumoFinanceiro(FinancasProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Financeiro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResumoItem(
                    'Saldo Total',
                    provider.saldoTotal,
                    Icons.account_balance_wallet,
                    Colors.blue,
                    provider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResumoItem(
                    'Contas',
                    provider.contas.length.toDouble(),
                    Icons.credit_card,
                    Colors.orange,
                    provider,
                    isCount: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoMensal(FinancasProvider provider) {
    final now = DateTime.now();
    final mesAtual = DateFormat('MMMM yyyy', 'pt_BR').format(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo de $mesAtual',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_down, color: Colors.red, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              'Despesas',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.formatarMoeda(provider.totalDespesasMes),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flight_takeoff, color: Colors.blue, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              'Enviado BR',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.formatarMoeda(provider.transferenciasParaBrasilMes),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: provider.saldoMes >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: provider.saldoMes >= 0 ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    provider.saldoMes >= 0 ? 'Economia do Mês' : 'Déficit do Mês',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: provider.saldoMes >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    provider.formatarMoeda(provider.saldoMes.abs()),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: provider.saldoMes >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoItem(String label, double value, IconData icon, Color color, FinancasProvider provider, {bool isCount = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isCount ? value.toInt().toString() : provider.formatarMoeda(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResumoTransferencias(FinancasProvider provider) {
    final totalMes = provider.transferenciasParaBrasilMes;
    
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Transferências para o Brasil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Este Mês',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '€${totalMes.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total em R\$',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'R\$ ${provider.transferenciasParaBrasilTotalReais.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransacoesRecentes(FinancasProvider provider) {
    final transacoesRecentes = provider.transacoes.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transações Recentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  child: const Text('Ver Todas'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (transacoesRecentes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhuma transação encontrada'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transacoesRecentes.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = transacoesRecentes[index];
                  return _buildTransacaoItem(item, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransacaoItem(Transacao item, FinancasProvider provider) {
    // Transferências para o Brasil sempre em azul
    final bool isTransferencia = item.categoria == 'Transferências para o Brasil';
    final Color backgroundColor = isTransferencia ? Colors.blue.shade100 : Colors.red.shade100;
    final Color iconColor = isTransferencia ? Colors.blue : Colors.red;
    final Color textColor = isTransferencia ? Colors.blue : Colors.red;
    final IconData iconData = isTransferencia ? Icons.flight_takeoff : Icons.trending_down;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: backgroundColor,
        child: Icon(
          iconData,
          color: iconColor,
        ),
      ),
      title: Text(item.descricao),
      subtitle: Text(
        '${item.categoria} • ${DateFormat('dd/MM/yyyy').format(item.data)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '- ${provider.formatarMoeda(item.valor)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          // Mostrar valor em Real para transferências
          if (isTransferencia && item.valorReal != null)
            Text(
              'R\$ ${item.valorReal!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAcoesRapidas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAcaoRapida(
                    'Adicionar\nDespesa',
                    Icons.remove_circle,
                    Colors.red,
                    () => _showAddTransacaoDialog('despesa'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAcaoRapida(
                    'Nova\nConta',
                    Icons.account_balance_wallet,
                    Colors.blue,
                    () => _navegarParaContas(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAcaoRapida(
                    'Ver\nGastos',
                    Icons.receipt_long,
                    Colors.orange,
                    () => _navegarParaGastos(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAcaoRapida(
                    'Relatórios',
                    Icons.bar_chart,
                    Colors.purple,
                    () => _navegarParaRelatorios(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAcaoRapida(
                    'Backup\nDados',
                    Icons.backup,
                    Colors.indigo,
                    () => _showBackupOptions(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAcaoRapida(
                    'Configurar\nMetas',
                    Icons.flag,
                    Colors.amber,
                    () => setState(() => _selectedIndex = 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcaoRapida(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransacaoDialog(String tipo) {
    // Forçar sempre como despesa
    showDialog(
      context: context,
      builder: (context) => AddTransacaoDialog(tipo: 'despesa'),
    );
  }

  // Métodos de navegação para as ações rápidas
  void _navegarParaContas() {
    setState(() => _selectedIndex = 1);
  }

  void _navegarParaGastos() {
    setState(() => _selectedIndex = 2);
  }

  void _navegarParaRelatorios() {
    setState(() => _selectedIndex = 3);
  }

  void _sincronizarSaldos() async {
    final provider = Provider.of<FinancasProvider>(context, listen: false);
    
    // Mostrar dialog de confirmação
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Colors.blue),
            SizedBox(width: 8),
            Text('Sincronizar Saldos'),
          ],
        ),
        content: const Text(
          'Esta ação irá recalcular todos os saldos das contas baseado nas transações registradas.\n\n'
          'Isso pode corrigir problemas de inconsistência nos valores.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Sincronizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Sincronizando saldos...'),
              ],
            ),
          ),
        );

// Sincronizar dados
          await provider.recalcularSaldos();        

        // Fechar loading
        Navigator.pop(context);

        // Mostrar sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saldos sincronizados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Fechar loading se estiver aberto
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Mostrar erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar saldos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _showBackupOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BackupOptionsBottomSheet(),
    );
  }
}

class AddTransacaoDialog extends StatefulWidget {
  final String tipo;

  const AddTransacaoDialog({Key? key, required this.tipo}) : super(key: key);

  @override
  _AddTransacaoDialogState createState() => _AddTransacaoDialogState();
}

class _AddTransacaoDialogState extends State<AddTransacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _categoriaSelecionada = '';
  int? _contaSelecionada;
  DateTime _dataSelecionada = DateTime.now();

  final List<String> _categoriasDespesa = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Compras',
    'Serviços',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _categoriaSelecionada = _categoriasDespesa.first;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancasProvider>(
      builder: (context, provider, child) {
        final categorias = _categoriasDespesa;
        final cor = Colors.red;
        final titulo = 'Nova Despesa';

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.remove_circle,
                color: cor,
              ),
              const SizedBox(width: 8),
              Text(titulo),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _descricaoController,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex: Supermercado, farmácia, posto',
                        prefixIcon: const Icon(Icons.description),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Descrição é obrigatória';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valorController,
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        hintText: '0,00',
                        prefixText: '€ ',
                        prefixIcon: Icon(Icons.monetization_on),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Valor é obrigatório';
                        }
                        try {
                          final valor = double.parse(value.replaceAll(',', '.'));
                          if (valor <= 0) {
                            return 'Valor deve ser maior que zero';
                          }
                          return null;
                        } catch (e) {
                          return 'Valor inválido';
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _categoriaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: categorias.map((categoria) =>
                        DropdownMenuItem(value: categoria, child: Text(categoria))
                      ).toList(),
                      onChanged: (value) {
                        setState(() => _categoriaSelecionada = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (provider.contas.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: _contaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Conta',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                        items: provider.contas.map((conta) =>
                          DropdownMenuItem(value: conta.id, child: Text(conta.nome))
                        ).toList(),
                        onChanged: (value) {
                          setState(() => _contaSelecionada = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecione uma conta';
                          }
                          return null;
                        },
                      ),
                    if (provider.contas.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange.shade600),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Você precisa criar uma conta primeiro!',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: _dataSelecionada,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (data != null) {
                          setState(() => _dataSelecionada = data);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observacoesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        hintText: 'Adicione observações...',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: provider.contas.isEmpty ? null : _salvarTransacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: cor,
                foregroundColor: Colors.white,
              ),
              child: Text('Adicionar Despesa'),
            ),
          ],
        );
      },
    );
  }

  void _salvarTransacao() async {
    if (_formKey.currentState!.validate()) {
      try {
        final valor = double.parse(_valorController.text.replaceAll(',', '.'));
        final transacao = Transacao(
          descricao: _descricaoController.text,
          valor: valor,
          tipo: 'despesa',
          categoria: _categoriaSelecionada,
          contaId: _contaSelecionada!,
          data: _dataSelecionada,
          dataCriacao: DateTime.now(),
          pago: true, // Por padrão, receitas e despesas adicionadas pelo dashboard são consideradas pagas
          observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
        );

        await Provider.of<FinancasProvider>(context, listen: false).adicionarTransacao(transacao);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Despesa adicionada com sucesso!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                // Navegar para a tela de gastos/transações
                Navigator.of(context).popUntil((route) => route.isFirst);
                if (context.mounted) {
                  final homeScreen = context.findAncestorStateOfType<_HomeScreenState>();
                  homeScreen?.setState(() {
                    homeScreen._selectedIndex = 2; // Índice da tela de gastos/transações
                  });
                }
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar ${widget.tipo}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
}

// Bottom Sheet para opções de backup
class BackupOptionsBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Backup dos Dados',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mantenha seus dados financeiros sempre seguros',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildBackupOption(
            context,
            'Exportar para Excel',
            'Exporte todas as transações em formato Excel',
            Icons.table_chart,
            Colors.green,
            () => _exportarParaExcel(context),
          ),
          const SizedBox(height: 12),
          _buildBackupOption(
            context,
            'Backup Local',
            'Salve uma cópia dos dados no dispositivo',
            Icons.save,
            Colors.blue,
            () => _backupLocal(context),
          ),
          const SizedBox(height: 12),
          _buildBackupOption(
            context,
            'Compartilhar Dados',
            'Envie os dados por email ou mensagem',
            Icons.share,
            Colors.orange,
            () => _compartilharDados(context),
          ),
          const SizedBox(height: 12),
          _buildBackupOption(
            context,
            'Restaurar Backup',
            'Importar dados de um arquivo de backup',
            Icons.restore,
            Colors.purple,
            () => _mostrarDialogRestaurar(context),
          ),
          const SizedBox(height: 12),
          _buildBackupOption(
            context,
            'Ver Estatísticas',
            'Visualizar informações do banco de dados',
            Icons.analytics,
            Colors.teal,
            () => _mostrarEstatisticas(context),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildBackupOption(BuildContext context, String title, String subtitle, 
      IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _exportarParaExcel(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de exportação para Excel será implementada em breve!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _backupLocal(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      // Mostrar indicador de carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Criando backup local...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      final backupService = BackupService();
      final arquivo = await backupService.salvarBackupLocal();
      
      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup salvo com sucesso!\n${arquivo.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar backup: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _compartilharDados(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      // Mostrar indicador de carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparando dados para compartilhamento...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      final backupService = BackupService();
      await backupService.compartilharBackup();
      
      // Sucesso será mostrado pelo sistema de compartilhamento
    } catch (e) {
      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar dados: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _mostrarDialogRestaurar(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.purple),
            SizedBox(width: 8),
            Text('Restaurar Backup'),
          ],
        ),
        content: const Text(
          'Selecione um arquivo de backup (.json) para importar os dados.\n\n'
          '⚠️ ATENÇÃO: Os dados importados serão ADICIONADOS aos seus dados atuais.\n\n'
          'Se você recebeu um backup de outra pessoa, certifique-se de que é um arquivo confiável.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _importarBackup(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Selecionar Arquivo'),
          ),
        ],
      ),
    );
  }

  void _importarBackup(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      // Mostrar indicador de carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecionando arquivo...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      final backupService = BackupService();
      final sucesso = await backupService.selecionarEImportarBackup();
      
      if (sucesso) {
        // Recarregar dados
        final provider = Provider.of<FinancasProvider>(context, listen: false);
        await provider.recarregarDados();
        
        // Mostrar sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup importado com sucesso!\nDados foram adicionados ao seu app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // Mostrar erro ou cancelamento
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Falha ao importar backup ou operação cancelada'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar backup: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _mostrarEstatisticas(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final backupService = BackupService();
      final stats = await backupService.obterEstatisticas();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.teal),
              SizedBox(width: 8),
              Text('Estatísticas do Banco'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Total de dados armazenados:\n'),
              const SizedBox(height: 8),
              Text('💰 Transações: ${stats['transacoes'] ?? 0}'),
              Text('🏦 Contas: ${stats['contas'] ?? 0}'),
              Text('📁 Categorias: ${stats['categorias'] ?? 0}'),
              Text('🌎 Remessas: ${stats['remessas'] ?? 0}'),
              Text('🎯 Metas: ${stats['metas'] ?? 0}'),
              const SizedBox(height: 12),
              Text(
                'Total: ${(stats.values.fold<int>(0, (sum, value) => sum + value))} registros',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao obter estatísticas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}