@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\play.ps1" -Editor
if errorlevel 1 pause
