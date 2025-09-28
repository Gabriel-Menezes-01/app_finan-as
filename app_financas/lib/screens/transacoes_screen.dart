import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';

class TransacoesScreen extends StatefulWidget {
  @override
  _TransacoesScreenState createState() => _TransacoesScreenState();
}

class _TransacoesScreenState extends State<TransacoesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '€');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Despesas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTransacaoDialog(context),
          ),
        ],
      ),
      body: Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransacoesList(provider.transacoes),
              _buildTransacoesList(provider.transacoes.where((t) => t.tipo == 'despesa').toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransacoesList(List<Transacao> transacoes) {
    if (transacoes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<FinancasProvider>(context, listen: false).carregarTransacoes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transacoes.length,
        itemBuilder: (context, index) {
          final transacao = transacoes[index];
          return _buildTransacaoCard(transacao);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma transação encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione sua primeira transação',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddTransacaoDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Transação'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransacaoCard(Transacao transacao) {
    // Transferências para o Brasil sempre em azul
    final bool isTransferencia = transacao.categoria == 'Transferências para o Brasil';
    final Color backgroundColor = isTransferencia ? Colors.blue.shade100 : Colors.red.shade100;
    final Color iconColor = isTransferencia ? Colors.blue : Colors.red;
    final IconData iconData = isTransferencia ? Icons.flight_takeoff : Icons.trending_down;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        title: Text(
          transacao.descricao,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transacao.categoria),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(transacao.data),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '- ${_currencyFormat.format(transacao.valor)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: transacao.pago ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transacao.pago ? 'Pago' : 'Pendente',
                style: TextStyle(
                  fontSize: 10,
                  color: transacao.pago ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransacaoDetails(transacao),
      ),
    );
  }

  void _showAddTransacaoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTransacaoDialog(),
    );
  }

  void _showTransacaoDetails(Transacao transacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransacaoDetailsBottomSheet(transacao: transacao),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AddTransacaoDialog extends StatefulWidget {
  @override
  _AddTransacaoDialogState createState() => _AddTransacaoDialogState();
}

class _AddTransacaoDialogState extends State<AddTransacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  String _tipoSelecionado = 'despesa';
  String _categoriaSelecionada = 'Alimentação';
  int? _contaSelecionada;
  DateTime _dataSelecionada = DateTime.now();
  bool _pago = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancasProvider>(
      builder: (context, provider, child) {
        final categorias = provider.getCategoriasPorTipo(_tipoSelecionado);
        
        return AlertDialog(
          title: const Text('Nova Despesa'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fixado como 'despesa' - não permite mais criar receitas
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.trending_down, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Nova Despesa', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: Almoço no restaurante',
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
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Valor é obrigatório';
                      }
                      try {
                        double.parse(value.replaceAll(',', '.'));
                        return null;
                      } catch (e) {
                        return 'Valor inválido';
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (categorias.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: categorias.any((c) => c.nome == _categoriaSelecionada) 
                          ? _categoriaSelecionada 
                          : categorias.first.nome,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: categorias.map((categoria) => 
                        DropdownMenuItem(value: categoria.nome, child: Text(categoria.nome))
                      ).toList(),
                      onChanged: (value) {
                        setState(() => _categoriaSelecionada = value!);
                      },
                    ),
                  const SizedBox(height: 16),
                  if (provider.contas.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _contaSelecionada,
                      decoration: const InputDecoration(labelText: 'Conta'),
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
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}'),
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
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Transação paga'),
                    value: _pago,
                    onChanged: (value) {
                      setState(() => _pago = value ?? false);
                    },
                  ),
                  TextFormField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      hintText: 'Adicione observações...',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _salvarTransacao,
              child: const Text('Salvar'),
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
          tipo: _tipoSelecionado,
          categoria: _categoriaSelecionada,
          contaId: _contaSelecionada!,
          data: _dataSelecionada,
          dataCriacao: DateTime.now(),
          pago: _pago,
          observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
        );

        await Provider.of<FinancasProvider>(context, listen: false).adicionarTransacao(transacao);
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação adicionada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar transação: $e')),
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

class TransacaoDetailsBottomSheet extends StatelessWidget {
  final Transacao transacao;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '€');

  TransacaoDetailsBottomSheet({required this.transacao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            transacao.descricao,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '- ${_currencyFormat.format(transacao.valor)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Categoria', transacao.categoria),
          _buildDetailRow('Data', DateFormat('dd/MM/yyyy').format(transacao.data)),
          _buildDetailRow('Status', transacao.pago ? 'Pago' : 'Pendente'),
          if (transacao.observacoes != null)
            _buildDetailRow('Observações', transacao.observacoes!),
          const SizedBox(height: 20),
          // Só permite editar despesas, não receitas
          if (transacao.tipo == 'despesa')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mostrarDialogoEdicao(context, transacao);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmarExclusao(context);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          // Para receitas, só permite excluir
          if (transacao.tipo == 'receita')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmarExclusao(context);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Excluir Receita'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEdicao(BuildContext context, Transacao transacao) {
    showDialog(
      context: context,
      builder: (context) => EditarTransacaoDialog(transacao: transacao),
    );
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a transação "${transacao.descricao}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<FinancasProvider>(context, listen: false).excluirTransacao(transacao.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transação excluída com sucesso!')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir transação: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Dialog específico para adicionar apenas despesas
class AddDespesaDialog extends StatefulWidget {
  @override
  _AddDespesaDialogState createState() => _AddDespesaDialogState();
}

class _AddDespesaDialogState extends State<AddDespesaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _taxaCambioController = TextEditingController();
  
  final String _tipoSelecionado = 'despesa'; // Fixo em despesa
  String _categoriaSelecionada = 'Alimentação';
  int? _contaSelecionada;
  DateTime _dataSelecionada = DateTime.now();
  bool _pago = false;
  String _valorRealCalculado = 'R\$ 0,00';

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancasProvider>(
      builder: (context, provider, child) {
        final categorias = provider.getCategoriasPorTipo(_tipoSelecionado);
        
        return AlertDialog(
          title: const Text('Nova Despesa'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Removido o SegmentedButton - apenas despesas
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: Almoço no restaurante',
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
                    decoration: InputDecoration(
                      labelText: 'Valor (€)',
                      hintText: 'Ex: 25.50',
                      prefixIcon: const Icon(Icons.euro_symbol),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      if (_categoriaSelecionada == 'Transferências para o Brasil') {
                        _calcularValorReal(_taxaCambioController.text);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Valor é obrigatório';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (categorias.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: categorias.any((c) => c.nome == _categoriaSelecionada) 
                        ? _categoriaSelecionada 
                        : categorias.first.nome,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categorias.map((categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria.nome,
                          child: Row(
                            children: [
                              Icon(categoria.icone, size: 20),
                              const SizedBox(width: 8),
                              Text(categoria.nome),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaSelecionada = value!;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _contaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Conta',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Selecionar conta'),
                      ),
                      ...provider.contas.map((conta) {
                        return DropdownMenuItem<int>(
                          value: conta.id,
                          child: Text(conta.nome),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _contaSelecionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma conta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selecionarData(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                            ),
                            child: Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Conversor automático para transferências para o Brasil
                  if (_categoriaSelecionada == 'Transferências para o Brasil') ...[
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.currency_exchange, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Conversor EUR → BRL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _taxaCambioController,
                              decoration: const InputDecoration(
                                labelText: 'Taxa de Câmbio',
                                hintText: 'Ex: 5.42',
                                prefixIcon: Icon(Icons.trending_up),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: _calcularValorReal,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Taxa obrigatória';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Taxa inválida';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(color: Colors.green.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Valor em Real:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    _valorRealCalculado,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      hintText: 'Informações adicionais...',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _pago,
                        onChanged: (value) {
                          setState(() {
                            _pago = value ?? false;
                          });
                        },
                      ),
                      const Text('Gasto já pago'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _salvarTransacao(context, provider),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  void _calcularValorReal(String value) {
    if (value.isNotEmpty && _valorController.text.isNotEmpty) {
      final taxa = double.tryParse(value);
      final valorEuro = double.tryParse(_valorController.text);
      
      if (taxa != null && valorEuro != null) {
        final valorReal = valorEuro * taxa;
        setState(() {
          _valorRealCalculado = 'R\$ ${valorReal.toStringAsFixed(2)}';
        });
      } else {
        setState(() {
          _valorRealCalculado = 'R\$ 0,00';
        });
      }
    } else {
      setState(() {
        _valorRealCalculado = 'R\$ 0,00';
      });
    }
  }

  void _salvarTransacao(BuildContext context, FinancasProvider provider) async {
    if (_formKey.currentState!.validate()) {
      try {
        final transacao = Transacao(
          descricao: _descricaoController.text,
          valor: double.parse(_valorController.text),
          tipo: _tipoSelecionado, // Sempre 'despesa'
          categoria: _categoriaSelecionada,
          data: _dataSelecionada,
          contaId: _contaSelecionada!,
          pago: _pago,
          observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
          dataCriacao: DateTime.now(),
          valorReal: _categoriaSelecionada == 'Transferências para o Brasil' && _taxaCambioController.text.isNotEmpty
              ? double.parse(_valorController.text) * double.parse(_taxaCambioController.text)
              : null,
          taxaCambio: _categoriaSelecionada == 'Transferências para o Brasil' && _taxaCambioController.text.isNotEmpty
              ? double.parse(_taxaCambioController.text)
              : null,
        );

        await provider.adicionarTransacao(transacao);
        
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Despesa adicionada com sucesso!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao adicionar despesa: $e')),
          );
        }
      }
    }
  }
}

// Dialog para editar transações existentes
class EditarTransacaoDialog extends StatefulWidget {
  final Transacao transacao;

  const EditarTransacaoDialog({Key? key, required this.transacao}) : super(key: key);

  @override
  _EditarTransacaoDialogState createState() => _EditarTransacaoDialogState();
}

class _EditarTransacaoDialogState extends State<EditarTransacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricaoController;
  late final TextEditingController _valorController;
  late final TextEditingController _observacoesController;
  late final TextEditingController _taxaCambioController;
  
  late String _tipoSelecionado;
  late String _categoriaSelecionada;
  late int? _contaSelecionada;
  late DateTime _dataSelecionada;
  late bool _pago;
  String _valorRealCalculado = 'R\$ 0,00';

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController(text: widget.transacao.descricao);
    _valorController = TextEditingController(text: widget.transacao.valor.toString());
    _observacoesController = TextEditingController(text: widget.transacao.observacoes ?? '');
    _taxaCambioController = TextEditingController(
      text: widget.transacao.taxaCambio?.toString() ?? ''
    );
    
    _tipoSelecionado = 'despesa'; // Forçar sempre como despesa
    _categoriaSelecionada = widget.transacao.categoria;
    _contaSelecionada = widget.transacao.contaId;
    _dataSelecionada = widget.transacao.data;
    _pago = widget.transacao.pago;
    
    // Calcular valor inicial em Real se for transferência
    if (_categoriaSelecionada == 'Transferências para o Brasil' && widget.transacao.valorReal != null) {
      _valorRealCalculado = 'R\$ ${widget.transacao.valorReal!.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancasProvider>(
      builder: (context, provider, child) {
        final categorias = provider.getCategoriasPorTipo(_tipoSelecionado);
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _categoriaSelecionada == 'Transferências para o Brasil' 
                    ? Icons.flight_takeoff 
                    : Icons.edit,
                color: _categoriaSelecionada == 'Transferências para o Brasil' 
                    ? Colors.blue.shade600 
                    : Colors.orange.shade600,
              ),
              const SizedBox(width: 8),
              Text(_categoriaSelecionada == 'Transferências para o Brasil' 
                  ? 'Editar Transferência' 
                  : 'Editar Despesa'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fixado como 'despesa' - não permite mais alterar para receita
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.trending_down, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Despesa', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: Almoço no restaurante',
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
                      labelText: 'Valor (€)',
                      hintText: 'Ex: 25.50',
                      prefixIcon: Icon(Icons.euro_symbol),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      if (_categoriaSelecionada == 'Transferências para o Brasil') {
                        _calcularValorReal(_taxaCambioController.text);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Valor é obrigatório';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (categorias.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: categorias.any((c) => c.nome == _categoriaSelecionada) 
                          ? _categoriaSelecionada 
                          : categorias.first.nome,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categorias.map((categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria.nome,
                          child: Row(
                            children: [
                              Icon(categoria.icone, size: 20),
                              const SizedBox(width: 8),
                              Text(categoria.nome),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaSelecionada = value!;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _contaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Conta',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Selecionar conta'),
                      ),
                      ...provider.contas.map((conta) {
                        return DropdownMenuItem<int>(
                          value: conta.id,
                          child: Text(conta.nome),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _contaSelecionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma conta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selecionarData(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                            ),
                            child: Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Transação paga'),
                    value: _pago,
                    onChanged: (value) {
                      setState(() => _pago = value ?? false);
                    },
                  ),
                  // Conversor automático para transferências para o Brasil
                  if (_categoriaSelecionada == 'Transferências para o Brasil') ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.currency_exchange, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Conversor EUR → BRL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _taxaCambioController,
                              decoration: const InputDecoration(
                                labelText: 'Taxa de Câmbio',
                                hintText: 'Ex: 5.42',
                                prefixIcon: Icon(Icons.trending_up),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: _calcularValorReal,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Taxa obrigatória';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Taxa inválida';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(color: Colors.green.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Valor em Real:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    _valorRealCalculado,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      hintText: 'Adicione observações...',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _salvarEdicao(context, provider),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  void _calcularValorReal(String value) {
    if (value.isNotEmpty && _valorController.text.isNotEmpty) {
      final taxa = double.tryParse(value);
      final valorEuro = double.tryParse(_valorController.text);
      
      if (taxa != null && valorEuro != null) {
        final valorReal = valorEuro * taxa;
        setState(() {
          _valorRealCalculado = 'R\$ ${valorReal.toStringAsFixed(2)}';
        });
      } else {
        setState(() {
          _valorRealCalculado = 'R\$ 0,00';
        });
      }
    } else {
      setState(() {
        _valorRealCalculado = 'R\$ 0,00';
      });
    }
  }

  void _salvarEdicao(BuildContext context, FinancasProvider provider) async {
    if (_formKey.currentState!.validate()) {
      try {
        final transacaoEditada = Transacao(
          id: widget.transacao.id,
          descricao: _descricaoController.text,
          valor: double.parse(_valorController.text),
          tipo: _tipoSelecionado,
          categoria: _categoriaSelecionada,
          data: _dataSelecionada,
          contaId: _contaSelecionada!,
          pago: _pago,
          observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
          dataCriacao: widget.transacao.dataCriacao, // Manter data de criação original
          valorReal: _categoriaSelecionada == 'Transferências para o Brasil' && _taxaCambioController.text.isNotEmpty
              ? double.parse(_valorController.text) * double.parse(_taxaCambioController.text)
              : null,
          taxaCambio: _categoriaSelecionada == 'Transferências para o Brasil' && _taxaCambioController.text.isNotEmpty
              ? double.parse(_taxaCambioController.text)
              : null,
        );

        await provider.atualizarTransacao(transacaoEditada);
        
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transação atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar transação: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

// Dialog específico para transferências para o Brasil
class AddTransferenciaDialog extends StatefulWidget {
  @override
  _AddTransferenciaDialogState createState() => _AddTransferenciaDialogState();
}

class _AddTransferenciaDialogState extends State<AddTransferenciaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController(text: 'Transferência para o Brasil');
  final _valorController = TextEditingController();
  final _taxaCambioController = TextEditingController();
  
  final String _tipoSelecionado = 'despesa';
  final String _categoriaSelecionada = 'Transferências para o Brasil';
  int? _contaSelecionada;
  DateTime _dataSelecionada = DateTime.now();
  bool _pago = true; // Transferências geralmente são pagas imediatamente
  String _valorRealCalculado = 'R\$ 0,00';

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancasProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.flight_takeoff, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Nova Transferência'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Transferência para o Brasil',
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
                      labelText: 'Valor em Euro (€)',
                      hintText: 'Ex: 250.00',
                      prefixIcon: Icon(Icons.euro_symbol),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => _calcularValorReal(_taxaCambioController.text),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Valor é obrigatório';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _contaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Conta de origem',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Selecionar conta'),
                      ),
                      ...provider.contas.map((conta) {
                        return DropdownMenuItem<int>(
                          value: conta.id,
                          child: Text(conta.nome),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _contaSelecionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma conta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.currency_exchange, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Conversor EUR → BRL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _taxaCambioController,
                            decoration: const InputDecoration(
                              labelText: 'Taxa de Câmbio',
                              hintText: 'Ex: 5.42',
                              prefixIcon: Icon(Icons.trending_up),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _calcularValorReal,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Taxa obrigatória';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Taxa inválida';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Valor em Real:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  _valorRealCalculado,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selecionarData(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                            ),
                            child: Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _salvarTransferencia(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
              ),
              child: const Text('Salvar Transferência'),
            ),
          ],
        );
      },
    );
  }

  void _calcularValorReal(String value) {
    if (value.isNotEmpty && _valorController.text.isNotEmpty) {
      final taxa = double.tryParse(value);
      final valorEuro = double.tryParse(_valorController.text);
      
      if (taxa != null && valorEuro != null) {
        final valorReal = valorEuro * taxa;
        setState(() {
          _valorRealCalculado = 'R\$ ${valorReal.toStringAsFixed(2)}';
        });
      } else {
        setState(() {
          _valorRealCalculado = 'R\$ 0,00';
        });
      }
    } else {
      setState(() {
        _valorRealCalculado = 'R\$ 0,00';
      });
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  void _salvarTransferencia(BuildContext context, FinancasProvider provider) async {
    if (_formKey.currentState!.validate()) {
      try {
        final transacao = Transacao(
          descricao: _descricaoController.text,
          valor: double.parse(_valorController.text),
          tipo: _tipoSelecionado,
          categoria: _categoriaSelecionada,
          data: _dataSelecionada,
          contaId: _contaSelecionada!,
          pago: _pago,
          observacoes: null,
          dataCriacao: DateTime.now(),
          valorReal: _taxaCambioController.text.isNotEmpty
              ? double.parse(_valorController.text) * double.parse(_taxaCambioController.text)
              : null,
          taxaCambio: _taxaCambioController.text.isNotEmpty
              ? double.parse(_taxaCambioController.text)
              : null,
        );

        await provider.adicionarTransacao(transacao);
        
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transferência registrada com sucesso!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao registrar transferência: $e')),
          );
        }
      }
    }
  }
}