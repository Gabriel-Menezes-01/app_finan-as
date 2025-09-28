import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financas_provider.dart';
import '../models/transacao.dart';

class GanhosExtrasScreen extends StatefulWidget {
  @override
  _GanhosExtrasScreenState createState() => _GanhosExtrasScreenState();
}

class _GanhosExtrasScreenState extends State<GanhosExtrasScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '€');
  DateTime _mesSelecionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganhos Extras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGanhoExtraDialog(context),
          ),
        ],
      ),
      body: Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildMesSelector(provider),
              _buildResumoGanhos(provider),
              Expanded(
                child: _buildGanhosList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMesSelector(FinancasProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _mesSelecionado = DateTime(_mesSelecionado.year, _mesSelecionado.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy', 'pt_BR').format(_mesSelecionado),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    );
  }

  Widget _buildResumoGanhos(FinancasProvider provider) {
    final ganhosDoMes = provider.transacoes.where((t) => 
      t.tipo == 'receita' && 
      t.data.month == _mesSelecionado.month && 
      t.data.year == _mesSelecionado.year
    ).toList();
    
    final totalGanhos = ganhosDoMes.fold<double>(0, (sum, t) => sum + t.valor);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total de Ganhos Extras',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(totalGanhos),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${ganhosDoMes.length} ganho${ganhosDoMes.length != 1 ? 's' : ''} este mês',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGanhosList(FinancasProvider provider) {
    final ganhosDoMes = provider.transacoes.where((t) => 
      t.tipo == 'receita' && 
      t.data.month == _mesSelecionado.month && 
      t.data.year == _mesSelecionado.year
    ).toList();

    ganhosDoMes.sort((a, b) => b.data.compareTo(a.data));

    if (ganhosDoMes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.carregarTransacoes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ganhosDoMes.length,
        itemBuilder: (context, index) {
          final ganho = ganhosDoMes[index];
          return _buildGanhoCard(ganho, provider);
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
            Icons.trending_up,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum ganho extra este mês',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seus freelances, bônus e outros ganhos',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddGanhoExtraDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Ganho Extra'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGanhoCard(Transacao ganho, FinancasProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(
            Icons.trending_up,
            color: Colors.green,
          ),
        ),
        title: Text(
          ganho.descricao,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ganho.categoria),
            Text(
              DateFormat('dd/MM/yyyy').format(ganho.data),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${_currencyFormat.format(ganho.valor)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
        onTap: () => _showGanhoOptions(ganho, provider),
      ),
    );
  }

  void _showGanhoOptions(Transacao ganho, FinancasProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditGanhoDialog(ganho, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(ganho, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGanhoExtraDialog(BuildContext context) {
    _showGanhoDialog(context, null);
  }

  void _showEditGanhoDialog(Transacao ganho, FinancasProvider provider) {
    _showGanhoDialog(context, ganho);
  }

  void _showGanhoDialog(BuildContext context, Transacao? ganho) {
    final _formKey = GlobalKey<FormState>();
    final _descricaoController = TextEditingController(text: ganho?.descricao ?? '');
    final _valorController = TextEditingController(text: ganho?.valor.toString() ?? '');
    final _observacoesController = TextEditingController(text: ganho?.observacoes ?? '');
    
    String _categoriaSelecionada = ganho?.categoria ?? '';
    int? _contaSelecionada = ganho?.contaId;
    DateTime _dataSelecionada = ganho?.data ?? DateTime.now();

    final List<String> _categorias = [
      'Freelance',
      'Bônus',
      'Comissões',
      'Vendas Extras',
      'Trabalho Extra',
      'Prêmios',
      'Outros',
    ];

    showDialog(
      context: context,
      builder: (context) => Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.add_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(ganho == null ? 'Novo Ganho Extra' : 'Editar Ganho Extra'),
              ],
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex: Freelance, bônus, venda extra',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
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
                        prefixIcon: Icon(Icons.euro),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
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
                    DropdownButtonFormField<String>(
                      value: _categoriaSelecionada.isEmpty ? null : _categoriaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (value) => _categoriaSelecionada = value ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Categoria é obrigatória';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _contaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Conta',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        border: OutlineInputBorder(),
                      ),
                      items: provider.contas.map((conta) {
                        return DropdownMenuItem(
                          value: conta.id,
                          child: Text(conta.nome),
                        );
                      }).toList(),
                      onChanged: (value) => _contaSelecionada = value,
                      validator: (value) {
                        if (value == null) {
                          return 'Conta é obrigatória';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observacoesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final novaTransacao = Transacao(
                        id: ganho?.id,
                        descricao: _descricaoController.text,
                        valor: double.parse(_valorController.text),
                        categoria: _categoriaSelecionada,
                        tipo: 'receita',
                        data: _dataSelecionada,
                        contaId: _contaSelecionada!,
                        pago: true, // Ganhos extras são sempre pagos (já recebidos)
                        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
                        dataCriacao: ganho?.dataCriacao ?? DateTime.now(),
                      );

                      if (ganho == null) {
                        await provider.adicionarTransacao(novaTransacao);
                      } else {
                        await provider.atualizarTransacao(novaTransacao);
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ganho == null ? 'Ganho extra adicionado!' : 'Ganho extra atualizado!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(ganho == null ? 'Adicionar' : 'Atualizar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Transacao ganho, FinancasProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o ganho extra "${ganho.descricao}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.excluirTransacao(ganho.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ganho extra excluído!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}