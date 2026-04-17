@echo off
title Pulse TI PRO v59
color 0B
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

:: ============================================================
::  Pulse TI PRO v59 - Script de Suporte e Manutencao
:: ============================================================

set "BASE=%~dp0Pulse_TI_PRO"
set "LOG=%BASE%\logs"
set "BACKUP=%BASE%\backups"
set "VERSION=59"

call :estrutura
call :check_admin

:: ============================================================
:menu
:: ============================================================
call :header "MENU PRINCIPAL"
echo.
echo   [1] Informacoes do Sistema
echo   [2] Rede PRO
echo   [3] Atualizacoes  (Winget)
echo   [4] Limpeza e Manutencao
echo   [5] GTA Central
echo   [6] Modo Forense
echo   [7] Sobre / Logs
echo   [0] Sair
echo.
set /p op="  Opcao: "

if "%op%"=="1" goto menu_sysinfo
if "%op%"=="2" goto menu_ping
if "%op%"=="3" goto menu_update
if "%op%"=="4" goto menu_limpeza
if "%op%"=="5" goto menu_gta
if "%op%"=="6" goto menu_forense
if "%op%"=="7" goto menu_sobre
if "%op%"=="0" goto sair
goto menu

:: ============================================================
:menu_sysinfo
:: ============================================================
call :header "INFORMACOES DO SISTEMA"
echo.
echo   [1] Resumo geral (CPU, RAM, OS)
echo   [2] Uso de CPU e RAM em tempo real
echo   [3] Informacoes de disco
echo   [4] Temperatura (OpenHardwareMonitor necessario)
echo   [5] Exportar relatorio completo
echo   [0] Voltar
echo.
set /p op="  Opcao: "

if "%op%"=="1" (
    echo.
    systeminfo | findstr /C:"Nome do host" /C:"Sistema Operacional" /C:"Versao do SO" /C:"Processador" /C:"Memoria Fisica Total"
    echo.
    pause
    goto menu_sysinfo
)
if "%op%"=="2" (
    echo. & echo Pressione Ctrl+C para parar...
    :cpu_loop
    set /a count=0
    for /f "skip=1" %%p in ('wmic cpu get loadpercentage') do (
        if not "%%p"=="" set "cpu=%%p"
    )
    for /f "skip=1 tokens=2" %%m in ('wmic OS get FreePhysicalMemory^,TotalVisibleMemorySize /value ^| findstr "="') do (
        set "%%m" >nul 2>&1
    )
    wmic cpu get loadpercentage /value | findstr "="
    wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /value | findstr "="
    timeout /t 3 /nobreak >nul
    goto cpu_loop
)
if "%op%"=="3" (
    echo.
    wmic logicaldisk get caption,size,freespace,volumename
    echo.
    pause
    goto menu_sysinfo
)
if "%op%"=="4" (
    echo. & echo Funcao requer OpenHardwareMonitor instalado.
    pause
    goto menu_sysinfo
)
if "%op%"=="5" (
    set "rep=%LOG%\relatorio_%date:~0,2%-%date:~3,2%-%date:~6,4%.txt"
    echo Pulse TI PRO v%VERSION% - Relatorio do Sistema > "!rep!"
    echo Data: %date% %time% >> "!rep!"
    echo. >> "!rep!"
    systeminfo >> "!rep!"
    echo. >> "!rep!"
    wmic logicaldisk get caption,size,freespace >> "!rep!"
    echo.
    echo Relatorio salvo em: !rep!
    echo.
    pause
    goto menu_sysinfo
)
if "%op%"=="0" goto menu
goto menu_sysinfo

:: ============================================================
:menu_ping
:: ============================================================
call :header "REDE PRO"
echo.
echo   [1] Ping Google (8.8.8.8)
echo   [2] Ping Cloudflare (1.1.1.1)
echo   [3] Teste de perda de pacotes
echo   [4] Tracert para Google
echo   [5] Ver IP e configuracoes de rede
echo   [6] Liberar e renovar IP (DHCP)
echo   [7] Flush DNS
echo   [0] Voltar
echo.
set /p op="  Opcao: "

if "%op%"=="1" (
    ping 8.8.8.8 -n 10
    pause & goto menu_ping
)
if "%op%"=="2" (
    ping 1.1.1.1 -n 10
    pause & goto menu_ping
)
if "%op%"=="3" (
    echo Testando 100 pacotes...
    ping 8.8.8.8 -n 100 > "%LOG%\ping.txt"
    type "%LOG%\ping.txt" | findstr /C:"perdidos" /C:"Aproximado" /C:"Perdidos" /C:"Lost"
    echo.
    echo Log completo salvo em: %LOG%\ping.txt
    pause & goto menu_ping
)
if "%op%"=="4" (
    tracert google.com
    pause & goto menu_ping
)
if "%op%"=="5" (
    ipconfig /all
    pause & goto menu_ping
)
if "%op%"=="6" (
    call :check_admin_action
    echo Liberando IP...
    ipconfig /release
    echo Renovando IP...
    ipconfig /renew
    pause & goto menu_ping
)
if "%op%"=="7" (
    call :check_admin_action
    ipconfig /flushdns
    echo DNS limpo com sucesso!
    pause & goto menu_ping
)
if "%op%"=="0" goto menu
goto menu_ping

:: ============================================================
:menu_update
:: ============================================================
call :header "ATUALIZACOES (WINGET)"
echo.
echo   [1] Ver atualizacoes disponiveis
echo   [2] Atualizar tudo (com saida visual)
echo   [3] Atualizacao silenciosa (background)
echo   [4] Instalar programa (por nome)
echo   [0] Voltar
echo.
set /p op="  Opcao: "

if "%op%"=="1" (
    call :winget_check
    winget upgrade
    pause & goto menu_update
)
if "%op%"=="2" goto winget_update
if "%op%"=="3" goto winget_auto
if "%op%"=="4" (
    call :winget_check
    set /p pkg="  Nome do programa: "
    winget install "!pkg!" --accept-source-agreements --accept-package-agreements
    pause & goto menu_update
)
if "%op%"=="0" goto menu
goto menu_update

:winget_check
where winget >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERRO] Winget nao encontrado!
    echo  Instale o App Installer pela Microsoft Store.
    echo.
    pause
    goto menu
)
exit /b

:winget_update
call :winget_check
echo Atualizando tudo... (log em %LOG%\winget_update.txt)
winget upgrade --all --accept-source-agreements --accept-package-agreements 2>&1 | tee "%LOG%\winget_update.txt"
echo. & echo Concluido!
pause
goto menu_update

:winget_auto
call :winget_check
echo Executando atualizacao silenciosa em segundo plano...
start /b winget upgrade --all --silent --accept-source-agreements --accept-package-agreements > "%LOG%\winget_auto.txt" 2>&1
echo Log sera salvo em: %LOG%\winget_auto.txt
pause
goto menu_update

:: ============================================================
:menu_limpeza
:: ============================================================
call :header "LIMPEZA E MANUTENCAO"
echo.
echo   [1] Limpar arquivos temporarios (%TEMP%)
echo   [2] Limpar lixeira
echo   [3] Verificar integridade do sistema (SFC)
echo   [4] DISM - Reparar imagem do Windows
echo   [5] Desfragmentar disco C:
echo   [0] Voltar
echo.
set /p op="  Opcao: "

if "%op%"=="1" (
    echo Limpando temporarios...
    del /q /f /s "%TEMP%\*" >nul 2>&1
    echo Pasta TEMP limpa!
    pause & goto menu_limpeza
)
if "%op%"=="2" (
    echo Esvaziando lixeira...
    powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
    echo Lixeira esvaziada!
    pause & goto menu_limpeza
)
if "%op%"=="3" (
    call :check_admin_action
    echo Verificando integridade... (isso pode demorar)
    sfc /scannow
    pause & goto menu_limpeza
)
if "%op%"=="4" (
    call :check_admin_action
    echo Executando DISM... (isso pode demorar varios minutos)
    DISM /Online /Cleanup-Image /RestoreHealth
    pause & goto menu_limpeza
)
if "%op%"=="5" (
    echo Desfragmentando C:...
    defrag C: /U /V
    pause & goto menu_limpeza
)
if "%op%"=="0" goto menu
goto menu_limpeza

:: ============================================================
:menu_gta
:: ============================================================
call :header "GTA CENTRAL"
echo.
echo   [1] Backup do GTA V (Documents)
echo   [2] Restaurar backup do GTA V
echo   [3] Abrir pasta de saves
echo   [0] Voltar
echo.
set /p op="  Opcao: "

set "GTA_SRC=%USERPROFILE%\Documents\Rockstar Games\GTA V"
set "GTA_DST=%BACKUP%\gta"

if "%op%"=="1" (
    if not exist "!GTA_SRC!" (
        echo  [AVISO] Pasta do GTA V nao encontrada.
    ) else (
        echo Fazendo backup...
        xcopy "!GTA_SRC!" "!GTA_DST!" /E /I /Y /Q
        echo Backup concluido em: !GTA_DST!
    )
    pause & goto menu_gta
)
if "%op%"=="2" (
    if not exist "!GTA_DST!" (
        echo  [AVISO] Nenhum backup encontrado em: !GTA_DST!
    ) else (
        set /p confirm="  Restaurar backup? Isso sobrescreve os saves atuais (s/n): "
        if /i "!confirm!"=="s" (
            xcopy "!GTA_DST!" "!GTA_SRC!" /E /I /Y /Q
            echo Restaurado com sucesso!
        ) else (
            echo Cancelado.
        )
    )
    pause & goto menu_gta
)
if "%op%"=="3" (
    explorer "!GTA_SRC!" 2>nul || echo  [ERRO] Pasta nao encontrada.
    goto menu_gta
)
if "%op%"=="0" goto menu
goto menu_gta

:: ============================================================
:menu_forense
:: ============================================================
call :header "MODO FORENSE"
echo.
echo   [1] Abrir Recuva
echo   [2] Analise detalhada de disco
echo   [3] Listar processos ativos
echo   [4] Listar servicos rodando
echo   [5] Conexoes de rede ativas (netstat)
echo   [0] Voltar
echo.
set /p op="  Opcao: "

if "%op%"=="1" (
    if exist "%ProgramFiles%\Recuva\recuva.exe" (
        start "" "%ProgramFiles%\Recuva\recuva.exe"
    ) else (
        echo  [ERRO] Recuva nao encontrado em ProgramFiles.
        pause
    )
    goto menu_forense
)
if "%op%"=="2" (
    echo.
    wmic logicaldisk get caption,volumename,size,freespace,filesystem
    echo.
    wmic logicaldisk get caption,size,freespace > "%LOG%\disk.txt"
    echo Log salvo em: %LOG%\disk.txt
    pause & goto menu_forense
)
if "%op%"=="3" (
    tasklist | more
    pause & goto menu_forense
)
if "%op%"=="4" (
    net start | more
    pause & goto menu_forense
)
if "%op%"=="5" (
    netstat -ano | more
    pause & goto menu_forense
)
if "%op%"=="0" goto menu
goto menu_forense

:: ============================================================
:menu_sobre
:: ============================================================
call :header "SOBRE / LOGS"
echo.
echo   Pulse TI PRO v%VERSION%
echo   Desenvolvido para manutencao e suporte Windows
echo.
echo   Pasta base  : %BASE%
echo   Pasta logs  : %LOG%
echo   Pasta backup: %BACKUP%
echo.
echo   [1] Abrir pasta de logs
echo   [2] Limpar todos os logs
echo   [0] Voltar
echo.
set /p op="  Opcao: "

if "%op%"=="1" (
    explorer "%LOG%"
    goto menu_sobre
)
if "%op%"=="2" (
    del /q "%LOG%\*.*" >nul 2>&1
    echo Logs removidos.
    pause & goto menu_sobre
)
if "%op%"=="0" goto menu
goto menu_sobre

:: ============================================================
:sair
:: ============================================================
call :header "ATE LOGO!"
echo.
echo   Pulse TI PRO v%VERSION% encerrado.
echo.
timeout /t 2 /nobreak >nul
exit

:: ============================================================
:: SUB-ROTINAS
:: ============================================================

:estrutura
for %%d in (logs tools downloads backups\gta) do (
    if not exist "%BASE%\%%d" mkdir "%BASE%\%%d" >nul 2>&1
)
exit /b

:header
cls
echo.
echo  ==========================================
echo    Pulse TI PRO v%VERSION%  ^|  %~1
echo  ==========================================
echo.
exit /b

:check_admin
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [AVISO] Execute como Administrador para funcoes avancadas.
    echo.
    timeout /t 3 /nobreak >nul
)
exit /b

:check_admin_action
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo  [ERRO] Esta funcao requer privilegios de Administrador.
    echo  Reinicie o script como Administrador.
    echo.
    pause
    goto menu
)
exit /b
