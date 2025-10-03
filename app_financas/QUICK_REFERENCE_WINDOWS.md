# 🚀 Referência Rápida - Build Windows

## ⚡ Configuração Inicial (Uma Vez)

```bash
# 1. Habilitar Windows Desktop
flutter config --enable-windows-desktop

# 2. Criar estrutura Windows
flutter create .

# 3. Instalar dependências
flutter pub get
```

## 🏗️ Build Rápido

### Opção 1: Script Automatizado (Recomendado)
```cmd
build_windows.bat
```

### Opção 2: Comandos Manuais
```bash
flutter clean
flutter pub get
flutter build windows --release
```

**Saída:** `build\windows\x64\runner\Release\app_financas.exe`

## 📦 Criar Instalador MSIX

### Usar Script
```cmd
build_msix.bat
```

### Ou Manual
```bash
flutter pub add msix --dev
flutter pub get
flutter pub run msix:create
```

## 🧪 Testar Durante Desenvolvimento

```bash
flutter run -d windows
```

## 📋 Checklist Antes de Distribuir

- [ ] Testou o app no Windows?
- [ ] Compilou em Release (não Debug)?
- [ ] Distribuiu a pasta Release **completa** (não só o .exe)?
- [ ] Testou em outro PC Windows limpo?
- [ ] Incluiu instruções para usuários finais?

## 💾 Estrutura de Distribuição

```
app_financas_windows.zip/
├── app_financas.exe          # Executável principal
├── data/                     # Dados do app
├── flutter_windows.dll       # DLL do Flutter (essencial)
└── [outras DLLs]            # Dependências
```

**⚠️ IMPORTANTE:** Distribua TUDO junto! O .exe sozinho NÃO funciona.

## 🔍 Verificar Instalação

```bash
# Ver versão Flutter
flutter --version

# Ver dispositivos disponíveis
flutter devices

# Verificar saúde da instalação
flutter doctor -v
```

## 🆘 Problemas Comuns

| Problema | Solução |
|----------|---------|
| "Flutter not found" | Adicione Flutter ao PATH |
| "Visual Studio not found" | Instale VS 2022 com C++ workload |
| "Build failed" | Execute `flutter doctor -v` |
| "App não abre" | Distribua pasta Release completa |

## 📱 Multiplataforma

| Comando | Plataforma | Resultado |
|---------|------------|-----------|
| `flutter build windows` | Windows | .exe |
| `flutter build apk` | Android | .apk |
| `flutter build ios` | iOS (Mac) | .ipa |
| `flutter build web` | Web | HTML/JS |

## 🎯 Recursos

- **Guia Completo:** `WINDOWS_BUILD_GUIDE.md`
- **README Usuários:** `README_WINDOWS.md`
- **Build Script:** `build_windows.bat`
- **MSIX Script:** `build_msix.bat`

---

**Pronto para compilar! 🎉**
