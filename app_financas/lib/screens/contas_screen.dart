import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financas_provider.dart';
import '../models/conta.dart';

class ContasScreen extends StatelessWidget {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '€');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Contas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContaDialog(context),
          ),
        ],
      ),
      body: Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.contas.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.carregarContas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.contas.length,
              itemBuilder: (context, index) {
                final conta = provider.contas[index];
                return _buildContaCard(context, conta, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma conta cadastrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione sua primeira conta para começar',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddContaDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Conta'),
          ),
        ],
      ),
    );
  }

  Widget _buildContaCard(BuildContext context, Conta conta, FinancasProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getContaColor(conta.tipo).withOpacity(0.2),
          child: Icon(
            _getContaIcon(conta.tipo),
            color: _getContaColor(conta.tipo),
          ),
        ),
        title: Text(
          conta.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getContaTipoNome(conta.tipo)),
            if (conta.descricao != null) ...[
              const SizedBox(height: 4),
              Text(
                conta.descricao!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currencyFormat.format(conta.saldo),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: conta.saldo >= 0 ? Colors.green : Colors.red,
              ),
            ),
            Text(
              'Saldo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () => _showContaDetails(context, conta, provider),
      ),
    );
  }

  IconData _getContaIcon(String tipo) {
    switch (tipo) {
      case 'corrente':
        return Icons.account_balance;
      case 'poupanca':
        return Icons.savings;
      case 'cartao_credito':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getContaColor(String tipo) {
    switch (tipo) {
      case 'corrente':
        return Colors.blue;
      case 'poupanca':
        return Colors.green;
      case 'cartao_credito':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getContaTipoNome(String tipo) {
    switch (tipo) {
      case 'corrente':
        return 'Conta Corrente';
      case 'poupanca':
        return 'Poupança';
      case 'cartao_credito':
        return 'Cartão de Crédito';
      default:
        return 'Outro';
    }
  }

  void _showAddContaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddContaDialog(),
    );
  }

  void _showContaDetails(BuildContext context, Conta conta, FinancasProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ContaDetailsBottomSheet(conta: conta, provider: provider),
    );
  }
}

class AddContaDialog extends StatefulWidget {
  @override
  _AddContaDialogState createState() => _AddContaDialogState();
}

class _AddContaDialogState extends State<AddContaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _saldoController = TextEditingController();
  String _tipoSelecionado = 'corrente';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Conta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Conta',
                hintText: 'Ex: Conta Principal',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoSelecionado,
              decoration: const InputDecoration(labelText: 'Tipo de Conta'),
              items: const [
                DropdownMenuItem(value: 'corrente', child: Text('Conta Corrente')),
                DropdownMenuItem(value: 'poupanca', child: Text('Poupança')),
                DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão de Crédito')),
              ],
              onChanged: (value) {
                setState(() => _tipoSelecionado = value!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _saldoController,
              decoration: const InputDecoration(
                labelText: 'Saldo Inicial',
                hintText: '0,00',
                prefixText: '€ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Saldo é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Adicione uma descrição...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvarConta,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _salvarConta() async {
    if (_formKey.currentState!.validate()) {
      try {
        final saldo = double.parse(_saldoController.text.replaceAll(',', '.'));
        final conta = Conta(
          nome: _nomeController.text,
          tipo: _tipoSelecionado,
          saldo: saldo,
          descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
          dataCriacao: DateTime.now(),
        );

        await Provider.of<FinancasProvider>(context, listen: false).adicionarConta(conta);
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta adicionada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar conta: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _saldoController.dispose();
    super.dispose();
  }
}

class ContaDetailsBottomSheet extends StatelessWidget {
  final Conta conta;
  final FinancasProvider provider;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '€');

  ContaDetailsBottomSheet({required this.conta, required this.provider});

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
            conta.nome,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(conta.saldo),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: conta.saldo >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarDialogoEdicao(context);
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _mostrarDialogoEdicao(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditarContaDialog(conta: conta, provider: provider),
    );
  }

  void _confirmarExclusao(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a conta "${conta.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.excluirConta(conta.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conta excluída com sucesso!')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir conta: $e')),
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

class EditarContaDialog extends StatefulWidget {
  final Conta conta;
  final FinancasProvider provider;

  const EditarContaDialog({Key? key, required this.conta, required this.provider}) : super(key: key);

  @override
  _EditarContaDialogState createState() => _EditarContaDialogState();
}

class _EditarContaDialogState extends State<EditarContaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _saldoController;
  late String _tipoSelecionado;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.conta.nome);
    _descricaoController = TextEditingController(text: widget.conta.descricao ?? '');
    _saldoController = TextEditingController(text: widget.conta.saldo.toStringAsFixed(2).replaceAll('.', ','));
    _tipoSelecionado = widget.conta.tipo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _saldoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Conta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Conta',
                hintText: 'Ex: Banco do Brasil',
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de Conta',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'corrente', child: Text('Conta Corrente')),
                DropdownMenuItem(value: 'poupanca', child: Text('Poupança')),
                DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão de Crédito')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoSelecionado = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _saldoController,
              decoration: const InputDecoration(
                labelText: 'Saldo Atual',
                hintText: '0,00',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Saldo é obrigatório';
                }
                final saldo = double.tryParse(value.replaceAll(',', '.'));
                if (saldo == null) {
                  return 'Saldo deve ser um número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Informações adicionais...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvarEdicao,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _salvarEdicao() async {
    if (_formKey.currentState!.validate()) {
      try {
        final saldo = double.parse(_saldoController.text.replaceAll(',', '.'));
        
        final contaEditada = Conta(
          id: widget.conta.id,
          nome: _nomeController.text,
          tipo: _tipoSelecionado,
          saldo: saldo,
          descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
          dataCriacao: widget.conta.dataCriacao,
        );

        await widget.provider.atualizarConta(contaEditada);
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}