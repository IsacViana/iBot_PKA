@echo off
setlocal
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"
cd /d "%~dp0"

set "PYTHON_BUILD=py -3.13"
set "RELEASE_VERSION=%~1"
if "%RELEASE_VERSION%"=="" set "RELEASE_VERSION=2.0.1"

REM Localiza o Git
if exist "C:\Users\Usuario\AppData\Local\vcpkg\downloads\tools\git-2.55.0.windows.3-windows\cmd\git.exe" (
    set "PATH=C:\Users\Usuario\AppData\Local\vcpkg\downloads\tools\git-2.55.0.windows.3-windows\cmd;%PATH%"
) else if exist "C:\Program Files\Git\cmd\git.exe" (
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
)

echo =========================================================
echo    PUBLICAR ATUALIZACAO NO GITHUB DE TESTE (iBot_PKA)
echo    Repositorio: https://github.com/IsacViana/iBot_PKA
echo    [AVISO] O repositorio de producao (NightBot) NAO sera alterado!
echo =========================================================
echo.

echo [1/4] Compilando Laucher_Nigthbot.exe C++ nativo...
call "%~dp0_FERRAMENTAS_DEV\Laucher_Nigthbot\build_native.bat" --no-pause
if %errorlevel% neq 0 (
    echo [!] Erro ao compilar Laucher_Nigthbot.exe.
    pause
    exit /b 1
)
copy /y "%~dp0_FERRAMENTAS_DEV\Laucher_Nigthbot\Laucher_Nigthbot.exe" "%~dp0Laucher_Nigthbot.exe" >nul

echo.
echo [2/4] Sincronizando e criptografando o bot em shards rsv...
echo       (Apaga bot.lua, panels e functions do disco, deixando so os .dat protegidos)
%PYTHON_BUILD% _FERRAMENTAS_DEV\fast_bot_sync.py --release --workspace-only
if %errorlevel% neq 0 (
    echo [!] Erro ao sincronizar fragmentos do bot.
    pause
    exit /b 1
)

echo.
echo [3/4] Gerando manifest.json apontando para o repositorio de TESTE (iBot_PKA)...
%PYTHON_BUILD% _FERRAMENTAS_DEV\publish_update.py %RELEASE_VERSION% https://raw.githubusercontent.com/IsacViana/iBot_PKA/main/
if %errorlevel% neq 0 (
    echo [!] Erro ao gerar manifest.json de teste.
    pause
    exit /b 1
)

echo.
echo [4/4] Enviando atualizacao EXCLUSIVAMENTE para o remote 'test' (iBot_PKA)...
git config user.name "IsacViana"
git config user.email "isacviana@users.noreply.github.com"
git rm --cached --ignore-unmatch core.exe >nul 2>&1
git rm --ignore-unmatch PokeAlliance_Launcher.exe launcher_pokealliance.exe >nul 2>&1
git add -- Laucher_Nigthbot.exe manifest.json modules data
for %%F in (PokeAlliance_dx.exe PokeAlliance_gl.exe d3dcompiler_47.dll libEGL.dll libGLESv2.dll) do if exist "%%F" git add -- "%%F"

git commit -m "Release %RELEASE_VERSION%: NIGHT Bot native launcher" >nul 2>&1
git -c credential.helper= -c credential.helper=manager push -u test main

if %errorlevel% neq 0 (
    echo.
    echo [!] Falha no push para o remote test. Verifique sua conexao ou permissoes do GitHub.
    pause
    exit /b 1
)

echo.
echo =========================================================
echo [OK] SUCESSO TOTAL!
echo Atualizacao enviada exclusivamente para o GitHub de TESTES:
echo https://github.com/IsacViana/iBot_PKA
echo.
echo O repositorio de producao (NightBot) continua 100%% seguro e intacto.
echo =========================================================
pause
