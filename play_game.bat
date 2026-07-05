@echo off
setlocal
cd /d "%~dp0"

set "GODOT_EXE=%~dp0tools\godot\Godot_v4.7-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot executable was not found:
  echo %GODOT_EXE%
  pause
  exit /b 1
)

start "" "%GODOT_EXE%" --path "%~dp0" --scene "res://scenes/main.tscn"
