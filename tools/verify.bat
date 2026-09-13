@echo off
setlocal
set "GODOT_EXE=C:\Users\MrSeb\OneDrive\Desktop\Godot.exe"
if not exist "%GODOT_EXE%" (
    where godot >nul 2>nul
    if %errorlevel% equ 0 (
        for /f "delims=" %%i in ('where godot') do set "GODOT_EXE=%%i"
    ) else (
        echo [ERROR] Godot executable not found at %GODOT_EXE% or in PATH.
        exit /b 1
    )
)

"%GODOT_EXE%" --headless --path "%~dp0.." res://tools/verify_runner.tscn
exit /b %errorlevel%
