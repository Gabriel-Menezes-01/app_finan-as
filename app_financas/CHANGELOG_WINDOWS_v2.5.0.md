# 📋 Changelog - Versão 2.5.0 Windows Desktop

## 🆕 Nova Plataforma: Windows Desktop!

**Data:** 2024
**Versão:** 2.5.0+5

---

## ✨ Principais Novidades

### 🪟 Suporte Windows Desktop
- **Aplicativo nativo para Windows 10/11**
- Janela redimensionável (padrão: 1100x700, mínimo: 900x600)
- Execução 100% offline, sem necessidade de internet
- Instalador MSIX para facilitar distribuição

### 🔧 Melhorias Técnicas

#### Gerenciamento de Plataformas
- ✅ Firebase desabilitado automaticamente no Windows
- ✅ Detecção inteligente de plataforma (Android/iOS/Windows/Web)
- ✅ Inicialização condicional baseada em plataforma
- ✅ Configuração automática de janela no Windows

#### Window Manager
- 📐 Tamanho inicial: 1100x700 pixels
- 📏 Tamanho mínimo: 900x600 pixels
- 🎯 Janela centralizada ao abrir
- ✨ Foco automático na janela

### 📚 Documentação Nova

1. **WINDOWS_BUILD_GUIDE.md**
   - Guia completo de build para Windows
   - Requisitos de sistema detalhados
   - Instruções passo-a-passo
   - Solução de problemas comuns

2. **README_WINDOWS.md**
   - Guia para usuários finais
   - Como executar o app
   - Requisitos do sistema
   - FAQ e troubleshooting

3. **QUICK_REFERENCE_WINDOWS.md**
   - Referência rápida de comandos
   - Checklist de distribuição
   - Tabela de problemas comuns

### 🛠️ Scripts de Build

#### build_windows.bat
```
- Verifica instalação do Flutter
- Habilita suporte Windows automaticamente
- Limpa builds anteriores
- Compila versão Release
- Abre pasta do executável
```

#### build_msix.bat
```
- Adiciona dependência MSIX
- Compila app
- Cria instalador MSIX
- Mostra informações do arquivo gerado
```

### 📦 Configuração MSIX

Adicionada ao `pubspec.yaml`:
- Nome de exibição: "Finanças App"
- Publisher: Gabriel Menezes
- Identity: com.gabrielmenezes.financas
- Versão MSIX: 2.5.0.0
- Capabilities: internetClient

## 🔄 Mudanças no Código

### main.dart
**Antes:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase não disponível');
  }
  
  runApp(MyApp());
}
```

**Depois:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  // Configurar janela Windows
  await _initWindow();
  
  // Firebase apenas em Android/iOS/Web
  await _initFirebaseIfSupported();
  
  runApp(MyApp());
}
```

### Novas Dependências
```yaml
dependencies:
  window_manager: ^0.3.7  # Gerenciamento de janela desktop
```

### .gitignore Atualizado
```
# Windows build artifacts
/windows/flutter/ephemeral
/windows/flutter/generated_*
/build/windows/
*.msix
```

## ✅ Funcionalidades Testadas no Windows

| Funcionalidade | Status | Notas |
|----------------|--------|-------|
| Dashboard | ✅ OK | Interface adaptada |
| Contas | ✅ OK | Gerenciamento completo |
| Transações | ✅ OK | Gastos, ganhos, transferências |
| Metas | ✅ OK | Sistema simplificado |
| Relatórios | ✅ OK | Exportação Excel funciona |
| Backup | ✅ OK | Salvar/Restaurar JSON |
| SQLite | ✅ OK | Banco local funcional |
| Firebase | ⏸️ Desabilitado | Apenas em mobile/web |

## 🎯 Plataformas Suportadas

| Plataforma | Status | Build | Tamanho |
|------------|--------|-------|---------|
| Android | ✅ v2.5.0 | APK | 25MB |
| **Windows** | ✅ **v2.5.0** | **EXE/MSIX** | **~40MB** |
| iOS | 🔄 Requer Mac | IPA | - |
| Web | 🔄 Possível | HTML | - |
| Linux | 🔄 Possível | - | - |
| macOS | 🔄 Possível | - | - |

## 🚀 Como Atualizar

### Para Desenvolvedores:
```bash
git pull
flutter pub get
flutter build windows --release
```

### Para Usuários:
1. Baixe o novo instalador MSIX, ou
2. Baixe e extraia a pasta Release atualizada

## 📊 Estatísticas

- **Arquivos Modificados:** 3
- **Arquivos Novos:** 4 documentações + 2 scripts
- **Linhas Adicionadas:** ~650
- **Linhas Removidas:** ~90
- **Commits:** 2

## 🐛 Correções de Bugs

- Removida classe `AppInitializer` duplicada e não utilizada
- Limpeza de código desnecessário no main.dart
- Melhor tratamento de erros de inicialização

## ⚠️ Breaking Changes

**Nenhum!** Todas as mudanças são retrocompatíveis.
- Apps Android/iOS continuam funcionando normalmente
- Firebase continua funcionando onde é suportado
- Código existente não foi quebrado

## 📝 Notas Importantes

### Para Desenvolvedores Windows:
1. É necessário Visual Studio 2022 com C++ workload
2. Windows 10 SDK deve estar instalado
3. Primeira build pode demorar 5-10 minutos

### Para Usuários:
1. Windows 10 (1809+) ou Windows 11 necessário
2. Todos os dados ficam salvos localmente
3. App funciona 100% offline

### Limitações Windows:
- Sem Firebase (login, sync cloud)
- Sem notificações push
- Backup/restore manual apenas

## 🔮 Próximos Passos

### v2.6.0 (Planejado)
- [ ] Suporte para Linux Desktop
- [ ] Suporte para macOS Desktop
- [ ] Tema escuro/claro
- [ ] Atalhos de teclado
- [ ] Sincronização via arquivo (Dropbox/OneDrive)

## 👏 Agradecimentos

Obrigado aos contribuidores e usuários que solicitaram suporte Windows!

---

**Download:** [Releases](https://github.com/Gabriel-Menezes-01/app_finan-as/releases)
**Documentação:** Ver arquivos README e GUIDE
**Suporte:** Abra uma issue no GitHub
