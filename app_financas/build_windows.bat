@echo off
REM ========================================
REM   Build Windows - Financas App v2.5.0
REM ========================================

echo.
echo ========================================
echo   Build Windows - Financas App v2.5.0
echo ========================================
echo.

REM Verificar se Flutter esta instalado
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERRO: Flutter nao esta instalado ou nao esta no PATH!
    echo.
    echo Por favor, instale o Flutter SDK:
    echo https://docs.flutter.dev/get-started/install/windows
    echo.
    pause
    exit /b 1
)

echo [1/6] Verificando instalacao do Flutter...
flutter doctor --version
echo.

echo [2/6] Habilitando suporte Windows Desktop...
flutter config --enable-windows-desktop
echo.

echo [3/6] Limpando build anterior...
flutter clean
echo.

echo [4/6] Obtendo dependencias...
flutter pub get
echo.

echo [5/6] Compilando para Windows (Release)...
echo     Isso pode demorar alguns minutos na primeira vez...
flutter build windows --release
echo.

echo [6/6] Verificando resultado...
if exist "build\windows\x64\runner\Release\app_financas.exe" (
    echo.
    echo ========================================
    echo   BUILD CONCLUIDO COM SUCESSO!
    echo ========================================
    echo.
    echo Executavel criado em:
    echo   build\windows\x64\runner\Release\app_financas.exe
    echo.
    
    REM Mostrar tamanho da pasta
    for /f "tokens=3" %%a in ('dir /s "build\windows\x64\runner\Release\" ^| find "File(s)"') do set size=%%a
    echo Tamanho total: %size% bytes
    echo.
    
    echo Para distribuir:
    echo   1. Compacte a pasta Release completa em ZIP, ou
    echo   2. Use 'flutter pub run msix:create' para criar instalador
    echo.
    
    REM Perguntar se deseja abrir a pasta
    set /p open="Deseja abrir a pasta do executavel? (S/N): "
    if /i "%open%"=="S" (
        start "" "build\windows\x64\runner\Release\"
    )
) else (
    echo.
    echo ========================================
    echo   ERRO NO BUILD!
    echo ========================================
    echo.
    echo O executavel nao foi criado. Verifique os erros acima.
    echo.
    echo Solucoes comuns:
    echo   - Instale Visual Studio 2022 com "Desktop development with C++"
    echo   - Execute: flutter doctor -v
    echo   - Certifique-se que Windows 10 SDK esta instalado
    echo.
)

echo.
pause
