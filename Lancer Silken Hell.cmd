@echo off
setlocal DisableDelayedExpansion
set "RUNTIME=%SILKEN_LOVE%"
if defined RUNTIME goto launch
if exist "%~dp0runtime\love.exe" set "RUNTIME=%~dp0runtime\love.exe"
if defined RUNTIME goto launch
if exist "%ProgramFiles%\LOVE\love.exe" set "RUNTIME=%ProgramFiles%\LOVE\love.exe"
if defined RUNTIME goto launch
where love.exe >nul 2>nul
if not errorlevel 1 set "RUNTIME=love.exe"
if defined RUNTIME goto launch
echo Installez LOVE 11.5 depuis https://love2d.org puis relancez le jeu.
pause
exit /b 1
:launch
if exist "%~dp0dist\game.love" (
  "%RUNTIME%" "%~dp0dist\game.love" %*
) else (
  "%RUNTIME%" "%~dp0." %*
)
