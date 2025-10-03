# 🪟 App Finanças - Versão Windows Desktop

## 🎯 Sobre

Aplicativo completo de controle financeiro pessoal, agora disponível para **Windows Desktop**!

## ✨ Funcionalidades

- 💰 **Gerenciamento de Contas** - Controle múltiplas contas bancárias
- 📊 **Transações** - Registre gastos, ganhos e transferências
- 🎯 **Metas Financeiras** - Defina e acompanhe metas em EUR ou BRL
- 📈 **Relatórios** - Visualize e exporte para Excel
- 💾 **Backup/Restauração** - Salve e compartilhe seus dados
- 🔄 **Conversão de Moedas** - Suporte para EUR e BRL com conversão

## 🚀 Como Executar no Windows

### Opção 1: Executável Portable (Simples)

1. Faça o download da pasta `Release` completa
2. Extraia o arquivo ZIP
3. Execute `app_financas.exe`
4. Pronto! O app está rodando

**Importante:** Não mova o `.exe` para fora da pasta - ele precisa das DLLs que estão junto!

### Opção 2: Instalador MSIX (Recomendado)

1. Faça o download do arquivo `app_financas.msix`
2. Dê duplo clique para instalar
3. O app aparecerá no Menu Iniciar
4. Atualizações automáticas via Windows Store (futuro)

## 💻 Requisitos do Sistema

- **SO:** Windows 10 (versão 1809 ou superior) ou Windows 11
- **RAM:** 4GB mínimo, 8GB recomendado
- **Espaço:** 200MB livres
- **Arquitetura:** x64 (64-bit)

## 🛠️ Para Desenvolvedores

### Compilar do Código-Fonte

#### Pré-requisitos:
- Flutter SDK 3.8.1 ou superior
- Visual Studio 2022 (Community ou superior)
  - Workload: "Desktop development with C++"
  - Windows 10 SDK

#### Passos:

```bash
# 1. Habilitar suporte Windows
flutter config --enable-windows-desktop

# 2. Instalar dependências
flutter pub get

# 3. Executar em modo debug
flutter run -d windows

# 4. Compilar release
flutter build windows --release
```

**Ou use o script automatizado:**
```cmd
build_windows.bat
```

### Estrutura do Projeto

```
app_financas/
├── lib/
│   ├── main.dart              # Entrada principal com suporte Windows
│   ├── models/                # Modelos de dados
│   ├── providers/             # Gerenciamento de estado
│   ├── screens/               # Telas do app
│   └── services/              # Serviços (DB, Backup, etc)
├── windows/                   # Configurações Windows específicas
├── build_windows.bat          # Script de build automatizado
└── WINDOWS_BUILD_GUIDE.md     # Guia detalhado de build
```

## 🔧 Configurações Específicas Windows

### Janela da Aplicação
- **Tamanho Padrão:** 1100x700 pixels
- **Tamanho Mínimo:** 900x600 pixels
- **Redimensionável:** Sim
- **Maximizável:** Sim
- **Título:** "Finanças App"

### Armazenamento de Dados
Os dados são salvos localmente em:
```
C:\Users\[SeuUsuario]\AppData\Roaming\com.example\app_financas\
```

Inclui:
- `app.db` - Banco SQLite com todas as transações
- `backups/` - Pasta de backups automáticos

## 📋 Diferenças das Versões Mobile

### ✅ Funciona Igual:
- Todas as funcionalidades principais
- Interface adaptada para desktop
- Banco de dados SQLite local
- Exportação Excel
- Sistema de Backup

### ❌ Não Disponível:
- **Firebase** - Desabilitado no Windows
- **Sincronização em Nuvem** - Apenas backup/restauração manual
- **Notificações Push** - Não suportado

## 🔐 Privacidade e Segurança

- ✅ Todos os dados ficam **localmente** no seu computador
- ✅ **Sem login** - acesso direto
- ✅ **Sem internet** - funciona 100% offline
- ✅ **Seus dados são seus** - exporte quando quiser

## 🐛 Problemas Conhecidos e Soluções

### "O aplicativo não abre"
**Solução:** Certifique-se de ter extraído a pasta Release completa, não apenas o .exe

### "Faltam DLLs"
**Solução:** Use a pasta Release completa ou instale o MSIX que já inclui tudo

### "Banco de dados corrompido"
**Solução:** 
1. Faça backup dos dados antes (Menu > Backup)
2. Delete o arquivo `app.db`
3. O app criará um novo banco vazio

### Performance lenta
**Solução:**
- Feche outros aplicativos pesados
- Exporte e limpe transações antigas
- Verifique espaço em disco disponível

## 📦 Tamanhos dos Arquivos

| Componente | Tamanho |
|------------|---------|
| Executável (.exe) | ~15MB |
| DLLs e dependências | ~25MB |
| **Total (portable)** | **~40MB** |
| Instalador (.msix) | ~30MB |

## 🔄 Atualizações

### Versão Atual: 2.5.0

**Novidades:**
- ✅ Suporte Windows Desktop
- ✅ Sistema de metas simplificado
- ✅ Janela redimensionável
- ✅ Firebase desabilitado automaticamente no desktop

**Próximas Versões:**
- 🔜 Temas claro/escuro
- 🔜 Atalhos de teclado
- 🔜 Gráficos melhorados
- 🔜 Sincronização via arquivo na nuvem (Dropbox, OneDrive)

## 📞 Suporte

### Problemas Técnicos:
- Abra uma issue no GitHub
- Inclua: versão do Windows, descrição do erro, logs

### Solicitação de Funcionalidades:
- Abra uma issue com a tag "enhancement"
- Descreva o caso de uso e benefício

## 📄 Licença

[Incluir informação de licença aqui]

## 👨‍💻 Autor

Gabriel Menezes
- GitHub: [@Gabriel-Menezes-01](https://github.com/Gabriel-Menezes-01)

---

**Aproveite o App Finanças no Windows!** 💰🪟✨
