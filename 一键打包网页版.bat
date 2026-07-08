@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "GODOT_EXE=%~dp0tools\godot\Godot_v4.7-stable_win64_console.exe"
set "WEB_TEMPLATE=%APPDATA%\Godot\export_templates\4.7.stable\web_nothreads_release.zip"
set "WEB_DIR=%~dp0web"

if not exist "%GODOT_EXE%" (
  echo [失败] 找不到项目自带的 Godot 4.7。
  pause
  exit /b 1
)

if not exist "%WEB_TEMPLATE%" (
  echo [失败] 本机尚未安装 Godot 4.7 Web 导出模板。
  echo 请在 Godot 中打开“编辑器 - 管理导出模板”，安装 Web 模板后重试。
  pause
  exit /b 1
)

if not exist "%WEB_DIR%" mkdir "%WEB_DIR%"

echo 正在导入资源……
"%GODOT_EXE%" --headless --path "%~dp0" --import
if errorlevel 1 goto :failed

echo 正在生成 Vercel 网页版……
"%GODOT_EXE%" --headless --path "%~dp0" --export-release "Web" "%WEB_DIR%\index.html"
if errorlevel 1 goto :failed

if not exist "%WEB_DIR%\index.html" goto :failed

echo.
echo [完成] Vercel 网页版已经生成：
echo %WEB_DIR%
start "" explorer.exe "%WEB_DIR%"
pause
exit /b 0

:failed
echo.
echo [失败] 网页版打包没有完成，请保留窗口中的错误信息。
pause
exit /b 1
