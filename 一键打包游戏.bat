@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "GODOT_EXE=%~dp0tools\godot\Godot_v4.7-stable_win64_console.exe"
set "OUTPUT_DIR=%~dp0output"
set "GAME_EXE=%OUTPUT_DIR%\汐汐公主城堡防御.exe"
set "GAME_PCK=%OUTPUT_DIR%\汐汐公主城堡防御.pck"

if not exist "%GODOT_EXE%" (
  echo [失败] 找不到项目自带的 Godot 4.7：
  echo %GODOT_EXE%
  echo.
  pause
  exit /b 1
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if exist "%GAME_EXE%" del /q "%GAME_EXE%"
if exist "%GAME_PCK%" del /q "%GAME_PCK%"
if exist "%OUTPUT_DIR%\汐汐公主城堡防御.tmp" del /q "%OUTPUT_DIR%\汐汐公主城堡防御.tmp"

echo 正在整理游戏资源……
"%GODOT_EXE%" --headless --path "%~dp0" --import
if errorlevel 1 goto :failed

echo 正在打包 Windows 游戏……
"%GODOT_EXE%" --headless --path "%~dp0" --export-release "Windows Desktop" "%GAME_EXE%"
if errorlevel 1 goto :failed

if not exist "%GAME_EXE%" goto :failed
if not exist "%GAME_PCK%" goto :failed

echo.
echo [完成] 游戏已经打包到：
echo %OUTPUT_DIR%
echo.
echo 双击“汐汐公主城堡防御.exe”即可开始游戏。
start "" explorer.exe "%OUTPUT_DIR%"
pause
exit /b 0

:failed
echo.
echo [失败] 打包没有完成，请保留窗口中的错误信息。
pause
exit /b 1
