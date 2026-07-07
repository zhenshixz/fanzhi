@echo off
setlocal
cd /d "%~dp0"
set "PROJECT_DIR=%CD%"

if defined GODOT_EXE (
  if not exist "%GODOT_EXE%" set "GODOT_EXE="
)

if not defined GODOT_EXE (
  for %%G in ("%~dp0tools\godot\Godot_v4.7-stable_win64.exe" "%~dp0tools\godot\Godot_v*-stable_win64.exe" "%~dp0tools\godot\Godot*.exe" "%~dp0tools\godot\godot*.exe") do (
    if not defined GODOT_EXE if exist "%%~fG" (
      set "GODOT_EXE=%%~fG"
    )
  )
)

if not defined GODOT_EXE (
  for %%C in (godot godot4 Godot_v4.7-stable_win64 Godot_v4.6-stable_win64 Godot_v4.5-stable_win64 Godot_v4.4-stable_win64 Godot_v4.3-stable_win64) do (
    for /f "delims=" %%G in ('where %%C 2^>nul') do (
      if not defined GODOT_EXE set "GODOT_EXE=%%G"
    )
  )
)

if not defined GODOT_EXE (
  for %%G in ("%ProgramFiles%\Godot\Godot*.exe" "%LocalAppData%\Programs\Godot\Godot*.exe") do (
    if not defined GODOT_EXE if exist "%%~fG" (
      set "GODOT_EXE=%%~fG"
    )
  )
)

if not defined GODOT_EXE (
  echo Godot 4 was not found on this computer.
  echo.
  echo To run this project, use one of these options:
  echo   1. Install Godot 4 and add it to PATH.
  echo   2. Set GODOT_EXE to your Godot exe path.
  echo   3. Put a local Godot exe under:
  echo      %~dp0tools\godot\
  echo.
  echo The tools\godot folder is ignored by git, so the engine will not be synced to GitHub.
  pause
  exit /b 1
)

if not exist "%PROJECT_DIR%\.godot\imported" (
  echo Importing Godot resources for first run...
  "%GODOT_EXE%" --path "%PROJECT_DIR%" --import
)

start "" /D "%PROJECT_DIR%" "%GODOT_EXE%" --path "%PROJECT_DIR%" --scene "res://scenes/menu.tscn"
exit /b 0
