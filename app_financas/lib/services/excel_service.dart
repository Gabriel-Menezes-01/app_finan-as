import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transacao.dart';
import '../models/conta.dart';

class ExcelService {
  static Future<void> exportarTransacoes(
    List<Transacao> transacoes,
    List<Conta> contas,
  ) async {
    try {
      // Criar novo Excel
      var excel = Excel.createExcel();
      Sheet sheet = excel['Transações'];
      
      // Limpar a planilha padrão
      excel.delete('Sheet1');
      
      // Criar cabeçalho
      _criarCabecalho(sheet);
      
      // Adicionar dados das transações
      for (int i = 0; i < transacoes.length; i++) {
        _adicionarTransacao(sheet, transacoes[i], contas, i + 2);
      }
      
      // Aplicar formatação
      _aplicarFormatacao(sheet, transacoes.length);
      
      // Salvar arquivo
      await _salvarArquivo(excel);
      
    } catch (e) {
      print('Erro ao exportar para Excel: $e');
      rethrow;
    }
  }
  
  static void _criarCabecalho(Sheet sheet) {
    final headers = [
      'ID',
      'Data',
      'Descrição',
      'Tipo',
      'Categoria',
      'Valor (€)',
      'Valor (R\$)',
      'Taxa Câmbio',
      'Conta',
      'Status',
      'Observações',
      'Mês/Ano',
    ];
    
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      
      // Formatação do cabeçalho
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
      );
    }
  }
  
  static void _adicionarTransacao(
    Sheet sheet,
    Transacao transacao,
    List<Conta> contas,
    int rowIndex,
  ) {
    final conta = contas.firstWhere(
      (c) => c.id == transacao.contaId,
      orElse: () => Conta(
        id: 0,
        nome: 'Desconhecida',
        saldo: 0,
        tipo: 'corrente',
        dataCriacao: DateTime.now(),
      ),
    );
    
    final dateFormat = DateFormat('dd/MM/yyyy');
    final monthYearFormat = DateFormat('MM/yyyy');
    
    final data = [
      transacao.id,
      dateFormat.format(transacao.data),
      transacao.descricao,
      transacao.tipo == 'receita' ? 'Receita' : 'Despesa',
      transacao.categoria,
      transacao.valor,
      transacao.valorReal,
      transacao.taxaCambio,
      conta.nome,
      transacao.pago ? 'Pago' : 'Pendente',
      transacao.observacoes ?? '',
      monthYearFormat.format(transacao.data),
    ];
    
    for (int i = 0; i < data.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
      
      if (data[i] is num) {
        cell.value = DoubleCellValue((data[i] as num).toDouble());
      } else if (data[i] is bool) {
        cell.value = TextCellValue(data[i].toString());
      } else {
        cell.value = TextCellValue(data[i]?.toString() ?? '');
      }
      
      // Formatação especial para transferências para o Brasil
      if (transacao.categoria == 'Transferências para o Brasil') {
        cell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.lightBlue,
        );
      }
      
      // Formatação para valores monetários
      if (i == 5 || i == 6) { // Colunas de valores
        cell.cellStyle = CellStyle(
          numberFormat: NumFormat.standard_2,
        );
      }
    }
  }
  
  static void _aplicarFormatacao(Sheet sheet, int totalTransacoes) {
    // Formatação das linhas
    // (Largura das colunas fica automática na versão atual do Excel)
  }
  
  static Future<void> _salvarArquivo(Excel excel) async {
    try {
      // Obter diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final fileName = 'financas_export_${dateFormat.format(now)}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      // Salvar arquivo
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      // Compartilhar arquivo
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Exportação de Transações Financeiras',
        subject: 'Relatório Financeiro - $fileName',
      );
      
    } catch (e) {
      print('Erro ao salvar arquivo: $e');
      rethrow;
    }
  }
  
  static Future<void> exportarResumoMensal(
    Map<String, List<Transacao>> transacoesPorMes,
    List<Conta> contas,
  ) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Resumo Mensal'];
      excel.delete('Sheet1');
      
      // Cabeçalho do resumo
      final headers = [
        'Mês/Ano',
        'Total Receitas (€)',
        'Total Despesas (€)',
        'Transferências BR (€)',
        'Transferências BR (R\$)',
        'Saldo do Mês (€)',
      ];
      
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.green,
          fontColorHex: ExcelColor.white,
        );
      }
      
      // Adicionar dados mensais
      int rowIndex = 1;
      transacoesPorMes.forEach((mes, transacoes) {
        final receitas = transacoes.where((t) => t.tipo == 'receita').fold(0.0, (sum, t) => sum + t.valor);
        final despesas = transacoes.where((t) => t.tipo == 'despesa').fold(0.0, (sum, t) => sum + t.valor);
        final transferenciasEur = transacoes.where((t) => t.categoria == 'Transferências para o Brasil').fold(0.0, (sum, t) => sum + t.valor);
        final transferenciasReal = transacoes.where((t) => t.categoria == 'Transferências para o Brasil').fold(0.0, (sum, t) => sum + (t.valorReal ?? 0));
        final saldo = receitas - despesas;
        
        final data = [mes, receitas, despesas, transferenciasEur, transferenciasReal, saldo];
        
        for (int i = 0; i < data.length; i++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
          
          if (data[i] is num) {
            cell.value = DoubleCellValue((data[i] as num).toDouble());
            if (i > 0) { // Aplicar formato de moeda para valores
              cell.cellStyle = CellStyle(numberFormat: NumFormat.standard_2);
            }
          } else {
            cell.value = TextCellValue(data[i].toString());
          }
        }
        rowIndex++;
      });
      
      await _salvarArquivo(excel);
      
    } catch (e) {
      print('Erro ao exportar resumo mensal: $e');
      rethrow;
    }
  }
}