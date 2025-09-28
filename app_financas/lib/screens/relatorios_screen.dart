import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/financas_provider.dart';
import '../services/excel_service.dart';
import '../models/transacao.dart';

class RelatoriosScreen extends StatefulWidget {
  @override
  _RelatoriosScreenState createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '€');
  DateTime _mesSelecionado = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            onSelected: (String value) async {
              final provider = Provider.of<FinancasProvider>(context, listen: false);
              
              if (value == 'excel_todas') {
                await _exportarTodasTransacoes(provider);
              } else if (value == 'excel_resumo') {
                await _exportarResumoMensal(provider);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'excel_todas',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Exportar Todas as Transações'),
                  subtitle: Text('Excel detalhado'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'excel_resumo',
                child: ListTile(
                  leading: Icon(Icons.summarize),
                  title: Text('Exportar Resumo Mensal'),
                  subtitle: Text('Resumo por mês'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selecionarMes,
          ),
        ],
      ),
      body: Consumer<FinancasProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMesSelector(),
                const SizedBox(height: 20),
                _buildResumoMensal(provider),
                const SizedBox(height: 20),
                _buildGraficoResumo(provider),
                const SizedBox(height: 20),
                _buildGraficoCategorias(provider),
                const SizedBox(height: 20),
                _buildEstatisticas(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMesSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Relatório de ${DateFormat('MMMM yyyy', 'pt_BR').format(_mesSelecionado)}',
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

  Widget _buildResumoMensal(FinancasProvider provider) {
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
                    'Ganhos Extras',
                    provider.totalReceitasMes,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResumoItem(
                    'Despesas',
                    provider.totalDespesasMes,
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                    provider.saldoMes >= 0 ? 'Sobrou no Mês' : 'Faltou no Mês',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: provider.saldoMes >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(provider.saldoMes.abs()),
                    style: TextStyle(
                      fontSize: 24,
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

  Widget _buildResumoItem(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFormat.format(value),
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

  Widget _buildGraficoResumo(FinancasProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativo Ganhos Extras vs Despesas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: provider.totalReceitasMes == 0 && provider.totalDespesasMes == 0
                  ? Center(
                      child: Text(
                        'Não há dados para este período',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: [provider.totalReceitasMes, provider.totalDespesasMes].reduce((a, b) => a > b ? a : b) * 1.2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Ganhos Extras', style: TextStyle(fontSize: 12));
                                  case 1:
                                    return const Text('Despesas', style: TextStyle(fontSize: 12));
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  'R\$ ${(value / 1000).toStringAsFixed(1)}k',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: provider.totalReceitasMes,
                                color: Colors.green,
                                width: 40,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: provider.totalDespesasMes,
                                color: Colors.red,
                                width: 40,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoCategorias(FinancasProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: provider.obterGastosPorCategoria(_mesSelecionado.month),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Gastos por Categoria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Não há gastos registrados neste período',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final gastos = snapshot.data!;
        final total = gastos.values.fold(0.0, (sum, value) => sum + value);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gastos por Categoria',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: gastos.entries.map((entry) {
                        final percentage = (entry.value / total) * 100;
                        return PieChartSectionData(
                          color: _getCategoriaColor(entry.key),
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...gastos.entries.map((entry) => _buildCategoriaLegenda(
                  entry.key,
                  entry.value,
                  total,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriaLegenda(String categoria, double valor, double total) {
    final percentage = (valor / total) * 100;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getCategoriaColor(categoria),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              categoria,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currencyFormat.format(valor),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticas(FinancasProvider provider) {
    final mediaDiaria = provider.totalDespesasMes / DateTime.now().day;
    final projecaoMensal = mediaDiaria * 30;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEstatisticaItem(
              'Média de Gastos Diários',
              _currencyFormat.format(mediaDiaria),
              Icons.calendar_today,
            ),
            _buildEstatisticaItem(
              'Projeção Mensal',
              _currencyFormat.format(projecaoMensal),
              Icons.trending_up,
            ),
            _buildEstatisticaItem(
              'Total de Transações',
              '${provider.transacoes.length}',
              Icons.swap_horiz,
            ),
            _buildEstatisticaItem(
              'Contas Cadastradas',
              '${provider.contas.length}',
              Icons.account_balance_wallet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticaItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    // Cores predefinidas para categorias
    final cores = {
      'Alimentação': Colors.orange,
      'Transporte': Colors.blue,
      'Moradia': Colors.green,
      'Saúde': Colors.red,
      'Educação': Colors.purple,
      'Lazer': Colors.pink,
      'Compras': Colors.teal,
      'Serviços': Colors.brown,
      'Outros': Colors.grey,
    };
    
    return cores[categoria] ?? Colors.grey;
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
  
  Future<void> _exportarTodasTransacoes(FinancasProvider provider) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Exportando transações...'),
            ],
          ),
        ),
      );
      
      // Exportar
      await ExcelService.exportarTransacoes(
        provider.transacoes,
        provider.contas,
      );
      
      // Fechar loading
      Navigator.of(context).pop();
      
      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Transações exportadas com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      Navigator.of(context).pop();
      
      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Erro ao exportar: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  Future<void> _exportarResumoMensal(FinancasProvider provider) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Exportando resumo mensal...'),
            ],
          ),
        ),
      );
      
      // Organizar transações por mês
      Map<String, List<Transacao>> transacoesPorMes = {};
      
      for (var transacao in provider.transacoes) {
        final mesAno = DateFormat('MM/yyyy').format(transacao.data);
        if (transacoesPorMes[mesAno] == null) {
          transacoesPorMes[mesAno] = [];
        }
        transacoesPorMes[mesAno]!.add(transacao);
      }
      
      // Exportar
      await ExcelService.exportarResumoMensal(
        transacoesPorMes,
        provider.contas,
      );
      
      // Fechar loading
      Navigator.of(context).pop();
      
      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Resumo mensal exportado com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      Navigator.of(context).pop();
      
      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Erro ao exportar: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}