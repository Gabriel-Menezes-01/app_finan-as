import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financas_provider.dart';
import '../models/meta.dart';

class MetasScreen extends StatefulWidget {
  @override
  _MetasScreenState createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Garantir que as metas sejam carregadas ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FinancasProvider>(context, listen: false);
      provider.recarregarMetas();
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
        title: const Text('Metas Financeiras'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ativas', icon: Icon(Icons.trending_up)),
            Tab(text: 'Concluídas', icon: Icon(Icons.check_circle)),
            Tab(text: 'Todas', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMetasAtivas(provider),
              _buildMetasConcluidas(provider),
              _buildTodasMetas(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogNovaMeta(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMetasAtivas(FinancasProvider provider) {
    final metasAtivas = provider.metas.where((meta) => 
      meta.ativa && !meta.foiAtingida
    ).toList();

    if (metasAtivas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhuma meta ativa',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie sua primeira meta financeira!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: metasAtivas.length,
      itemBuilder: (context, index) {
        return _buildMetaCard(metasAtivas[index], provider);
      },
    );
  }

  Widget _buildMetasConcluidas(FinancasProvider provider) {
    final metasConcluidas = provider.metas.where((meta) => 
      meta.foiAtingida || !meta.ativa
    ).toList();

    if (metasConcluidas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhuma meta concluída',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: metasConcluidas.length,
      itemBuilder: (context, index) {
        return _buildMetaCard(metasConcluidas[index], provider);
      },
    );
  }

  Widget _buildTodasMetas(FinancasProvider provider) {
    if (provider.metas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Nenhuma meta criada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.metas.length,
      itemBuilder: (context, index) {
        return _buildMetaCard(provider.metas[index], provider);
      },
    );
  }

  Widget _buildMetaCard(Meta meta, FinancasProvider provider) {
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '€');
    
    Color? cardColor = Colors.blue.withOpacity(0.1);
    IconData iconData = Icons.flag;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: _getStatusColor(meta)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meta.nome,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _onMetaMenuSelected(value, meta, provider),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'progresso',
                      child: ListTile(
                        leading: Icon(Icons.trending_up, color: Colors.blue),
                        title: Text('Atualizar Progresso'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'editar',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excluir',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Excluir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (meta.descricao != null && meta.descricao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meta.descricao!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progresso:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${currencyFormat.format(meta.valorAtual)} / ${currencyFormat.format(meta.valorMeta)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Status:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(meta),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        meta.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: meta.porcentagemProgresso,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(meta)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(meta.porcentagemProgresso * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${meta.simboloMoeda} ${meta.valorAtual.toStringAsFixed(2)} / ${meta.simboloMoeda} ${meta.valorMeta.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Moeda: ${meta.moeda}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Criada em ${DateFormat('dd/MM/yyyy').format(meta.dataCriacao)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Meta meta) {
    switch (meta.status) {
      case 'Atingida':
      case 'Concluída':
        return Colors.green;
      case 'Em andamento':
        return meta.porcentagemProgresso > 0.7 ? Colors.orange : Colors.blue;
      case 'Expirada':
        return Colors.red;
      case 'Inativa':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _onMetaMenuSelected(String value, Meta meta, FinancasProvider provider) {
    switch (value) {
      case 'progresso':
        _mostrarDialogAtualizarProgresso(context, meta, provider);
        break;
      case 'editar':
        _mostrarDialogEditarMeta(context, meta);
        break;
      case 'excluir':
        _mostrarDialogExcluirMeta(context, meta, provider);
        break;
    }
  }

  void _mostrarDialogNovaMeta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddMetaDialog(),
    ).then((_) {
      // Recarregar metas após fechar o diálogo
      final provider = Provider.of<FinancasProvider>(context, listen: false);
      provider.recarregarMetas();
    });
  }

  void _mostrarDialogEditarMeta(BuildContext context, Meta meta) {
    showDialog(
      context: context,
      builder: (context) => AddMetaDialog(meta: meta),
    ).then((_) {
      // Recarregar metas após fechar o diálogo
      final provider = Provider.of<FinancasProvider>(context, listen: false);
      provider.recarregarMetas();
    });
  }

  void _mostrarDialogAtualizarProgresso(BuildContext context, Meta meta, FinancasProvider provider) {
    final TextEditingController controller = TextEditingController(
      text: meta.valorAtual.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atualizar Progresso: ${meta.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Meta: ${meta.simboloMoeda} ${meta.valorMeta.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Valor Atual',
                border: const OutlineInputBorder(),
                prefixText: '${meta.simboloMoeda} ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novoValor = double.tryParse(controller.text);
              if (novoValor != null) {
                final metaAtualizada = Meta(
                  id: meta.id,
                  nome: meta.nome,
                  descricao: meta.descricao,
                  valorMeta: meta.valorMeta,
                  valorAtual: novoValor,
                  moeda: meta.moeda,
                  ativa: meta.ativa,
                  dataCriacao: meta.dataCriacao,
                );
                
                await provider.atualizarMeta(metaAtualizada);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progresso atualizado com sucesso')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogExcluirMeta(BuildContext context, Meta meta, FinancasProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Meta'),
        content: Text('Tem certeza que deseja excluir a meta "${meta.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.excluirMeta(meta.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meta excluída com sucesso')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AddMetaDialog extends StatefulWidget {
  final Meta? meta;

  const AddMetaDialog({Key? key, this.meta}) : super(key: key);

  @override
  _AddMetaDialogState createState() => _AddMetaDialogState();
}

class _AddMetaDialogState extends State<AddMetaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorMetaController = TextEditingController();
  
  String _moedaSelecionada = 'EUR';

  final List<String> _moedas = ['EUR', 'BRL'];

  @override
  void initState() {
    super.initState();
    if (widget.meta != null) {
      _nomeController.text = widget.meta!.nome;
      _descricaoController.text = widget.meta!.descricao ?? '';
      _valorMetaController.text = widget.meta!.valorMeta.toString();
      _moedaSelecionada = widget.meta!.moeda;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.meta == null ? 'Nova Meta' : 'Editar Meta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Meta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome da meta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _moedaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Moeda',
                  border: OutlineInputBorder(),
                ),
                items: _moedas.map((moeda) {
                  String label = moeda == 'EUR' ? '€ Euro' : 'R\$ Real';
                  return DropdownMenuItem(value: moeda, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _moedaSelecionada = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorMetaController,
                decoration: InputDecoration(
                  labelText: 'Valor da Meta',
                  border: const OutlineInputBorder(),
                  prefixText: _moedaSelecionada == 'EUR' ? '€ ' : 'R\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor da meta';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, insira um valor válido';
                  }
                  return null;
                },
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
          onPressed: _salvarMeta,
          child: Text(widget.meta == null ? 'Criar' : 'Salvar'),
        ),
      ],
    );
  }

  void _salvarMeta() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinancasProvider>(context, listen: false);
      
      final meta = Meta(
        id: widget.meta?.id,
        nome: _nomeController.text,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
        valorMeta: double.parse(_valorMetaController.text),
        valorAtual: widget.meta?.valorAtual ?? 0.0,
        moeda: _moedaSelecionada,
        dataCriacao: widget.meta?.dataCriacao ?? DateTime.now(),
      );

      try {
        if (widget.meta == null) {
          await provider.adicionarMeta(meta);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta criada com sucesso')),
          );
        } else {
          await provider.atualizarMeta(meta);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta atualizada com sucesso')),
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar meta: $e')),
        );
      }
    }
  }
}