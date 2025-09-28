# Funcionalidade de Exportação para Excel

## Como usar a exportação Excel

### 1. Acesse a aba "Relatórios"
- No app, toque na aba "Relatórios" na barra de navegação inferior

### 2. Menu de Exportação
- Na tela de relatórios, toque no ícone de menu (três pontos) no canto superior direito
- Você verá duas opções de exportação:
  - **"Exportar Todas as Transações"** - Exporta todas as transações do banco de dados
  - **"Exportar Resumo do Mês"** - Exporta apenas as transações do mês atual

### 3. Processo de Exportação
1. Selecione uma das opções de exportação
2. O app mostrará uma tela de carregamento enquanto gera o arquivo Excel
3. Após a geração, o sistema de compartilhamento será aberto automaticamente
4. Você pode escolher onde salvar ou compartilhar o arquivo

## Conteúdo dos Arquivos Excel

### Exportação Completa (Todas as Transações)
- **Nome do arquivo**: `transacoes_completas_[data].xlsx`
- **Colunas**:
  - Data
  - Descrição
  - Categoria
  - Valor (€)
  - Valor Real (R$) - apenas para transferências
  - Taxa de Câmbio - apenas para transferências
  - Status (Pago/Aguardando)

### Exportação do Mês Atual
- **Nome do arquivo**: `resumo_mensal_[mes_ano].xlsx`
- **Conteúdo**: Apenas transações do mês atual com as mesmas colunas

## Formatação do Excel
- Cabeçalhos em negrito com fundo cinza
- Valores monetários formatados como moeda
- Largura das colunas ajustada automaticamente
- Cores diferenciadas para transferências (azul)

## Observações
- Os arquivos são salvos na pasta de documentos do dispositivo
- O compartilhamento permite enviar por WhatsApp, email, etc.
- Transferências para o Brasil mostram tanto o valor em € quanto em R$
- Taxa de câmbio é registrada para cada transferência