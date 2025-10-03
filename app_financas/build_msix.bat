@echo off
REM ========================================
REM   Build MSIX Installer - Financas App
REM ========================================

echo.
echo ========================================
echo   Build MSIX Installer
echo   Financas App v2.5.0
echo ========================================
echo.

REM Verificar se Flutter esta instalado
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERRO: Flutter nao esta instalado ou nao esta no PATH!
    echo.
    pause
    exit /b 1
)

echo [1/7] Verificando instalacao...
flutter --version
echo.

echo [2/7] Adicionando dependencia MSIX...
flutter pub add msix --dev
echo.

echo [3/7] Obtendo dependencias...
flutter pub get
echo.

echo [4/7] Limpando build anterior...
flutter clean
echo.

echo [5/7] Compilando para Windows...
flutter build windows --release
echo.

echo [6/7] Criando instalador MSIX...
echo     Isso pode demorar alguns minutos...
flutter pub run msix:create
echo.

echo [7/7] Verificando resultado...
if exist "build\windows\x64\runner\Release\*.msix" (
    echo.
    echo ========================================
    echo   INSTALADOR MSIX CRIADO COM SUCESSO!
    echo ========================================
    echo.
    
    for %%F in ("build\windows\x64\runner\Release\*.msix") do (
        echo Arquivo: %%~nxF
        echo Tamanho: %%~zF bytes
        echo Local: %%~dpF
    )
    
    echo.
    echo Para instalar:
    echo   1. Duplo clique no arquivo .msix, ou
    echo   2. PowerShell: Add-AppxPackage .\arquivo.msix
    echo.
    
    set /p open="Deseja abrir a pasta do instalador? (S/N): "
    if /i "%open%"=="S" (
        start "" "build\windows\x64\runner\Release\"
    )
) else (
    echo.
    echo ========================================
    echo   ERRO AO CRIAR INSTALADOR!
    echo ========================================
    echo.
    echo Verifique se o pubspec.yaml tem a configuracao msix_config.
    echo.
    echo Exemplo:
    echo msix_config:
    echo   display_name: Financas App
    echo   publisher_display_name: Gabriel Menezes
    echo   identity_name: com.gabrielmenezes.financas
    echo   msix_version: 2.5.0.0
    echo.
)

echo.
pause
