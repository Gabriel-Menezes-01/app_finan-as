import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/financas_provider.dart';
import '../models/remessa.dart';
import '../models/transacao.dart';
import '../models/conta.dart';

class RemessasScreen extends StatefulWidget {
  @override
  _RemessasScreenState createState() => _RemessasScreenState();
}

class _RemessasScreenState extends State<RemessasScreen> {
  final NumberFormat _currencyFormatEuro = NumberFormat.currency(locale: 'pt_BR', symbol: '€');
  final NumberFormat _currencyFormatReal = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remessas para o Brasil'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _mostrarFormularioRemessa(context),
          ),
        ],
      ),
      body: Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          final remessas = provider.remessas;
          
          if (remessas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_to_mobile,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma remessa registrada',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toque em + para registrar uma remessa',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: remessas.length,
            itemBuilder: (context, index) {
              final remessa = remessas[index];
              return _buildRemessaCard(remessa, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildRemessaCard(Remessa remessa, FinancasProvider provider) {
    final conta = provider.contas.firstWhere(
      (c) => c.id == remessa.contaOrigemId,
      orElse: () => Conta(nome: 'Conta não encontrada', tipo: '', saldo: 0, dataCriacao: DateTime.now()),
    );
    
    final statusColor = _getStatusColor(remessa.status);
    final statusIcon = _getStatusIcon(remessa.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            statusIcon,
            color: statusColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _currencyFormatEuro.format(remessa.valorEuro),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Text(
                _getStatusText(remessa.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De: ${conta.nome}'),
            Text('Enviado: ${_dateFormat.format(remessa.dataEnvio)}'),
            if (remessa.dataRecebimento != null)
              Text('Recebido: ${_dateFormat.format(remessa.dataRecebimento!)}'),
            if (remessa.valorReal != null)
              Text(
                'Valor recebido: ${_currencyFormatReal.format(remessa.valorReal!)}',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        onTap: () => _mostrarDetalhesRemessa(context, remessa, provider),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'marcar_recebido':
                _marcarComoRecebido(remessa, provider);
                break;
              case 'editar':
                _mostrarFormularioRemessa(context, remessa: remessa);
                break;
              case 'excluir':
                _confirmarExclusao(context, remessa, provider);
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              if (remessa.status == 'enviado')
                const PopupMenuItem<String>(
                  value: 'marcar_recebido',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Marcar como Recebido'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir'),
                  ],
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'enviado':
        return Colors.orange;
      case 'recebido':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'enviado':
        return Icons.flight_takeoff;
      case 'recebido':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'enviado':
        return 'Enviado';
      case 'recebido':
        return 'Recebido';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  void _mostrarFormularioRemessa(BuildContext context, {Remessa? remessa}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FormularioRemessaBottomSheet(remessa: remessa),
    );
  }

  void _mostrarDetalhesRemessa(BuildContext context, Remessa remessa, FinancasProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DetalhesRemessaBottomSheet(
        remessa: remessa,
        provider: provider,
      ),
    );
  }

  void _marcarComoRecebido(Remessa remessa, FinancasProvider provider) {
    showDialog(
      context: context,
      builder: (context) => MarcarRecebidoDialog(
        remessa: remessa,
        provider: provider,
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Remessa remessa, FinancasProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Deseja realmente excluir esta remessa de ${_currencyFormatEuro.format(remessa.valorEuro)}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.excluirRemessa(remessa.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remessa excluída com sucesso!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// Formulário para criar/editar remessa
class FormularioRemessaBottomSheet extends StatefulWidget {
  final Remessa? remessa;

  const FormularioRemessaBottomSheet({Key? key, this.remessa}) : super(key: key);

  @override
  _FormularioRemessaBottomSheetState createState() => _FormularioRemessaBottomSheetState();
}

class _FormularioRemessaBottomSheetState extends State<FormularioRemessaBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _codigoRastreamentoController = TextEditingController();
  
  DateTime _dataEnvio = DateTime.now();
  int? _contaOrigemSelecionada;

  @override
  void initState() {
    super.initState();
    if (widget.remessa != null) {
      _valorController.text = widget.remessa!.valorEuro.toString();
      _observacoesController.text = widget.remessa!.observacoes ?? '';
      _codigoRastreamentoController.text = widget.remessa!.codigoRastreamento ?? '';
      _dataEnvio = widget.remessa!.dataEnvio;
      _contaOrigemSelecionada = widget.remessa!.contaOrigemId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_to_mobile, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    widget.remessa != null ? 'Editar Remessa' : 'Nova Remessa',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Valor em Euro
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor Enviado',
                  hintText: '0,00',
                  prefixText: '€ ',
                  prefixIcon: Icon(Icons.euro),
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
              
              // Conta de origem
              Consumer<FinancasProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    value: _contaOrigemSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Conta de Origem',
                      prefixIcon: Icon(Icons.account_balance),
                      border: OutlineInputBorder(),
                    ),
                    items: provider.contas
                        .where((conta) => conta.id != null)
                        .map((conta) => DropdownMenuItem<int>(
                              value: conta.id!,
                              child: Text(conta.nome),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _contaOrigemSelecionada = value),
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma conta';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Data de envio
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data de Envio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataEnvio)),
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: _dataEnvio,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (data != null) {
                    setState(() => _dataEnvio = data);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),
              
              // Código de rastreamento
              TextFormField(
                controller: _codigoRastreamentoController,
                decoration: const InputDecoration(
                  labelText: 'Código de Rastreamento (opcional)',
                  hintText: 'Ex: MT123456789BR',
                  prefixIcon: Icon(Icons.track_changes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Observações
              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Informações adicionais...',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              
              // Botões
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _salvarRemessa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.remessa != null ? 'Atualizar' : 'Salvar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _salvarRemessa() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FinancasProvider>(context, listen: false);
      final valor = double.parse(_valorController.text.replaceAll(',', '.'));
      
      final remessa = Remessa(
        id: widget.remessa?.id,
        valorEuro: valor,
        dataEnvio: _dataEnvio,
        contaOrigemId: _contaOrigemSelecionada!,
        observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
        codigoRastreamento: _codigoRastreamentoController.text.isEmpty ? null : _codigoRastreamentoController.text,
        status: widget.remessa?.status ?? 'enviado',
        valorReal: widget.remessa?.valorReal,
        dataRecebimento: widget.remessa?.dataRecebimento,
        contaDestinoId: widget.remessa?.contaDestinoId,
        taxaCambio: widget.remessa?.taxaCambio,
      );

      if (widget.remessa != null) {
        provider.atualizarRemessa(remessa);
      } else {
        provider.adicionarRemessa(remessa);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.remessa != null 
                ? 'Remessa atualizada com sucesso!' 
                : 'Remessa registrada com sucesso!'
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    _observacoesController.dispose();
    _codigoRastreamentoController.dispose();
    super.dispose();
  }
}

// Dialog para marcar como recebido
class MarcarRecebidoDialog extends StatefulWidget {
  final Remessa remessa;
  final FinancasProvider provider;

  const MarcarRecebidoDialog({
    Key? key,
    required this.remessa,
    required this.provider,
  }) : super(key: key);

  @override
  _MarcarRecebidoDialogState createState() => _MarcarRecebidoDialogState();
}

class _MarcarRecebidoDialogState extends State<MarcarRecebidoDialog> {
  final _valorRealController = TextEditingController();
  final _taxaCambioController = TextEditingController();
  DateTime _dataRecebimento = DateTime.now();
  int? _contaDestinoSelecionada;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marcar como Recebido'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Valor enviado: ${NumberFormat.currency(locale: 'pt_BR', symbol: '€').format(widget.remessa.valorEuro)}'),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _valorRealController,
              decoration: const InputDecoration(
                labelText: 'Valor Recebido',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _taxaCambioController,
              decoration: const InputDecoration(
                labelText: 'Taxa de Câmbio (opcional)',
                hintText: '5.50',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data de Recebimento'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataRecebimento)),
              onTap: () async {
                final data = await showDatePicker(
                  context: context,
                  initialDate: _dataRecebimento,
                  firstDate: widget.remessa.dataEnvio,
                  lastDate: DateTime.now(),
                );
                if (data != null) {
                  setState(() => _dataRecebimento = data);
                }
              },
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<int>(
              value: _contaDestinoSelecionada,
              decoration: const InputDecoration(
                labelText: 'Conta de Destino (opcional)',
                border: OutlineInputBorder(),
              ),
              items: widget.provider.contas
                  .where((conta) => conta.id != null)
                  .map((conta) => DropdownMenuItem<int>(
                        value: conta.id!,
                        child: Text(conta.nome),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _contaDestinoSelecionada = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final valorReal = _valorRealController.text.isNotEmpty 
                ? double.parse(_valorRealController.text.replaceAll(',', '.'))
                : null;
            final taxaCambio = _taxaCambioController.text.isNotEmpty
                ? double.parse(_taxaCambioController.text.replaceAll(',', '.'))
                : null;
                
            final remessaAtualizada = widget.remessa.copyWith(
              status: 'recebido',
              dataRecebimento: _dataRecebimento,
              valorReal: valorReal,
              taxaCambio: taxaCambio,
              contaDestinoId: _contaDestinoSelecionada,
            );
            
            widget.provider.atualizarRemessa(remessaAtualizada);
            
            // Adicionar valor recebido à conta destino se especificada
            if (_contaDestinoSelecionada != null && valorReal != null) {
              final transacao = Transacao(
                descricao: 'Remessa recebida - €${widget.remessa.valorEuro}',
                valor: valorReal,
                categoria: 'Transferência Internacional',
                tipo: 'receita',
                contaId: _contaDestinoSelecionada!,
                data: _dataRecebimento,
                dataCriacao: DateTime.now(),
                observacoes: 'Conversão de ${widget.remessa.valorEuro} EUR para $valorReal BRL'
                    + (taxaCambio != null ? ' (Taxa: $taxaCambio)' : ''),
              );
              widget.provider.adicionarTransacao(transacao);
            }
            
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Remessa marcada como recebida!')),
            );
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _valorRealController.dispose();
    _taxaCambioController.dispose();
    super.dispose();
  }
}

// BottomSheet com detalhes da remessa
class DetalhesRemessaBottomSheet extends StatelessWidget {
  final Remessa remessa;
  final FinancasProvider provider;

  const DetalhesRemessaBottomSheet({
    Key? key,
    required this.remessa,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatEuro = NumberFormat.currency(locale: 'pt_BR', symbol: '€');
    final NumberFormat currencyFormatReal = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    
    final conta = provider.contas.firstWhere(
      (c) => c.id == remessa.contaOrigemId,
      orElse: () => Conta(nome: 'Conta não encontrada', tipo: '', saldo: 0, dataCriacao: DateTime.now()),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Detalhes da Remessa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow('Valor Enviado:', currencyFormatEuro.format(remessa.valorEuro)),
          _buildInfoRow('Conta de Origem:', conta.nome),
          _buildInfoRow('Data de Envio:', dateFormat.format(remessa.dataEnvio)),
          _buildInfoRow('Status:', _getStatusText(remessa.status)),
          
          if (remessa.codigoRastreamento != null)
            _buildInfoRow('Código:', remessa.codigoRastreamento!),
          
          if (remessa.dataRecebimento != null)
            _buildInfoRow('Data de Recebimento:', dateFormat.format(remessa.dataRecebimento!)),
          
          if (remessa.valorReal != null)
            _buildInfoRow('Valor Recebido:', currencyFormatReal.format(remessa.valorReal!)),
          
          if (remessa.taxaCambio != null)
            _buildInfoRow('Taxa de Câmbio:', remessa.taxaCambio!.toStringAsFixed(4)),
          
          if (remessa.observacoes != null && remessa.observacoes!.isNotEmpty)
            _buildInfoRow('Observações:', remessa.observacoes!),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'enviado':
        return 'Enviado';
      case 'recebido':
        return 'Recebido';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }
}