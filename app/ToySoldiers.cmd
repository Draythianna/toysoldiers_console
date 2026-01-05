@echo off
cls
echo ...Launching Toy Soldiers: Warchest - Hall of Fame Edition...
title Toy Soldiers: Warchest - Hall of Fame Launcher

tasklist /FI "IMAGENAME eq Steam.exe" | find /I "Steam.exe" >nul
if errorlevel 0 (
"%PROGRAMFILES(x86)%\steam\steam.exe" steam://run/276770
)
if errorlevel 1 (
start "" Game.exe
)

:: Wait 10 seconds
timeout /t 10 /nobreak >nul

:: Launch Game.exe with RunAsDate
RunAsDate.exe 30\08\2015 00:00:00 attach:Game.exe

:: Wait 5 seconds
timeout /t 5 /nobreak >nul

:: Launch toysoldiers_dev.exe
start "" toysoldiers_dev.exe

:: Monitor Game.exe
:monitor
tasklist /FI "IMAGENAME eq Game.exe" | find /I "Game.exe" >nul
if errorlevel 1 (
    echo Game.exe has exited. Terminating toysoldiers_dev.exe...
    taskkill /F /IM toysoldiers_dev.exe
    goto end
)
timeout /t 5 /nobreak >nul
goto monitor

:end
echo Monitoring complete.
exit
