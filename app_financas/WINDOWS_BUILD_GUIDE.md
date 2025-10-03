# 🪟 Guia para Build Windows Desktop - App Financas v2.5.0

## ✅ Requisitos para Build Windows

### 1. **Ferramentas Necessárias:**
- **Windows 10 ou superior** (64-bit)
- **Flutter SDK** instalado e configurado
- **Visual Studio 2022** (Community ou superior) com:
  - "Desktop development with C++" workload
  - Windows 10 SDK

### 2. **Verificar Instalação:**
```bash
flutter doctor -v
```

## 🚀 Passos para Configurar e Compilar

### Passo 1: Habilitar Suporte Windows Desktop
```bash
flutter config --enable-windows-desktop
```

### Passo 2: Criar Estrutura Windows (se não existir)
```bash
# Na pasta do projeto app_financas
flutter create .
```

### Passo 3: Instalar Dependências
```bash
flutter pub get
```

### Passo 4: Testar em Modo Debug
```bash
# Executar em modo debug
flutter run -d windows
```

### Passo 5: Compilar Release
```bash
# Gerar executável otimizado
flutter build windows --release
```

O executável estará em:
```
build\windows\x64\runner\Release\
```

## 📦 Distribuir Aplicativo Windows

### Opção 1: Pasta Release (Simples)
Compacte toda a pasta `build\windows\x64\runner\Release\` em um ZIP:
- Contém o .exe e todas as DLLs necessárias
- Usuários extraem e executam `app_financas.exe`

### Opção 2: Instalador MSIX (Recomendado)

#### 1. Adicionar dependência MSIX:
```yaml
# No pubspec.yaml, adicione em dev_dependencies:
dev_dependencies:
  msix: ^3.16.7
```

#### 2. Configurar MSIX no pubspec.yaml:
```yaml
msix_config:
  display_name: Finanças App
  publisher_display_name: Gabriel Menezes
  identity_name: com.gabrielmenezes.financas
  msix_version: 2.5.0.0
  logo_path: windows/runner/resources/app_icon.ico
  capabilities: internetClient
  execution_alias: financas
```

#### 3. Gerar MSIX:
```bash
flutter pub get
flutter pub run msix:create
```

O arquivo .msix estará em `build\windows\x64\runner\Release\`

#### 4. Instalar MSIX:
```bash
# Duplo clique no arquivo .msix
# ou via PowerShell:
Add-AppxPackage .\app_financas.msix
```

## 🎨 Personalizar Ícone da Aplicação

### 1. Criar Ícone .ico (256x256):
- Use ferramentas como GIMP, Photoshop, ou online: https://convertio.co/png-ico/

### 2. Substituir Ícone:
- Coloque o arquivo `.ico` em: `windows\runner\resources\app_icon.ico`

### 3. Recompilar:
```bash
flutter clean
flutter build windows --release
```

## 🛠️ Script de Build Automatizado

Crie um arquivo `build_windows.bat` na raiz do projeto:

```batch
@echo off
echo ========================================
echo   Build Windows - Financas App v2.5.0
echo ========================================
echo.

echo [1/5] Limpando build anterior...
flutter clean

echo [2/5] Obtendo dependencias...
flutter pub get

echo [3/5] Compilando para Windows (Release)...
flutter build windows --release

echo [4/5] Verificando resultado...
if exist "build\windows\x64\runner\Release\app_financas.exe" (
    echo.
    echo ========================================
    echo   BUILD CONCLUIDO COM SUCESSO!
    echo ========================================
    echo.
    echo Executavel: build\windows\x64\runner\Release\app_financas.exe
    echo.
    
    echo [5/5] Abrindo pasta do executavel...
    start "" "build\windows\x64\runner\Release\"
) else (
    echo.
    echo ========================================
    echo   ERRO NO BUILD!
    echo ========================================
    echo.
    pause
)

pause
```

Para usar, basta executar: `build_windows.bat`

## 📋 Funcionalidades Windows

### ✅ Já Funcionam:
- ✅ **SQLite** - Banco de dados local
- ✅ **Metas** - Sistema simplificado de metas
- ✅ **Contas** - Gerenciamento de contas
- ✅ **Transações** - Gastos e ganhos
- ✅ **Relatórios** - Exportação para Excel
- ✅ **Backup** - Salvar/Compartilhar JSON
- ✅ **Interface** - Janela redimensionável (min 900x600)

### ⚠️ Limitações:
- **Firebase** - Desabilitado automaticamente no Windows
- **Autenticação** - Sistema local apenas
- **Sincronização Nuvem** - Não disponível

### 💾 Localização dos Dados:
Os dados ficam salvos em:
```
C:\Users\[SeuUsuario]\AppData\Roaming\com.example\app_financas\
```

## 🔧 Solução de Problemas

### Erro: "Visual Studio not found"
**Solução:** Instale Visual Studio 2022 com "Desktop development with C++"

### Erro: "Windows SDK not found"
**Solução:** Instale Windows 10 SDK via Visual Studio Installer

### Erro: "Unable to find suitable Visual Studio toolchain"
**Solução:**
```bash
flutter doctor --verbose
# Verifique mensagens e instale componentes faltando
```

### App não abre após compilar
**Solução:** Certifique-se de distribuir a pasta Release completa, não apenas o .exe

## 📱 Plataformas Disponíveis

| Plataforma | Status | Arquivo | Tamanho Aprox. |
|------------|--------|---------|----------------|
| **Android** | ✅ Pronto | `app-release.apk` | 25MB |
| **Windows** | ✅ Pronto | `app_financas.exe` | 30-40MB |
| **iOS** | ⏳ Requer Mac | `.ipa` | - |
| **Linux** | 🔄 Possível | - | - |
| **Web** | 🔄 Possível | - | - |

## 🎯 Próximos Passos

1. **Teste o app em Windows:**
   ```bash
   flutter run -d windows
   ```

2. **Compile release:**
   ```bash
   flutter build windows --release
   ```

3. **Distribua:**
   - ZIP da pasta Release, ou
   - Crie MSIX para Windows Store

## 💡 Dicas

- Use `flutter clean` antes de builds importantes
- Teste em diferentes versões do Windows (10, 11)
- O primeiro build pode demorar 5-10 minutos
- Builds subsequentes são mais rápidos

---

**Pronto!** Seu app de finanças agora funciona no Windows Desktop! 🎉
