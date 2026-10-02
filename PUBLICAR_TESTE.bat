@echo off
setlocal
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"
cd /d "%~dp0"

set "PYTHON_BUILD=py -3.13"

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

echo [1/4] Compilando Core C++ Nativo (core_native.exe)...
cd /d "%~dp0_FERRAMENTAS_DEV\native_core"
set "ZIG_EXE=C:\Users\Usuario\AppData\Local\Nuitka\Nuitka\Cache\downloads\pip\private-49c291cb\Lib\site-packages\ziglang\zig.exe"
"%ZIG_EXE%" c++ -target x86_64-windows -std=c++17 -O3 -Wno-nullability-completeness -Wl,--subsystem,windows gui_main.cpp -o core_native.exe -lwinhttp -luser32 -lkernel32 -lgdi32 -ladvapi32 -ldwmapi -lcomctl32 -lshell32 -lole32 -lbcrypt
copy /y core_native.exe "..\..\core.exe" >nul
cd /d "%~dp0"

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
%PYTHON_BUILD% _FERRAMENTAS_DEV\publish_update.py 1.0.8 https://raw.githubusercontent.com/IsacViana/iBot_PKA/main/
if %errorlevel% neq 0 (
    echo [!] Erro ao gerar manifest.json de teste.
    pause
    exit /b 1
)

echo.
echo [4/4] Enviando atualizacao EXCLUSIVAMENTE para o remote 'test' (iBot_PKA)...
git config user.name "IsacViana"
git config user.email "isacviana@users.noreply.github.com"
git add -- core.exe manifest.json modules data
for %%F in (PokeAlliance_dx.exe PokeAlliance_gl.exe d3dcompiler_47.dll libEGL.dll libGLESv2.dll) do if exist "%%F" git add -- "%%F"

git commit -m "Test release: protected bot runtime without plaintext code" >nul 2>&1
git -c credential.helper= -c credential.helper=manager push -f -u test main

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
