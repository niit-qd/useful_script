@echo off

chcp 65001 >nul

setlocal enabledelayedexpansion

:: 管理员提权 VBS 方式
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo 正在请求管理员权限...
    goto UACPrompt
) else ( goto main )

:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B

call :Main

:Main
goto :eof

:: ====================== 核心获取命令 ======================
:: 1. 获取脚本**完整路径** (例: D:\test\myScript.bat)
set "SCRIPT_FULL_PATH=%~f0"

:: 2. 获取脚本**所在目录** (例: D:\test\)
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

:: 3. 获取脚本**完整文件名** (例: myScript.bat)
set "SCRIPT_NAME=%~nx0"

:: 4. 获取脚本**文件名(无后缀)** (例: myScript)
set "SCRIPT_NAME_ONLY=%~n0"

:: 5. 获取脚本**后缀名** (例: .bat)
set "SCRIPT_EXT=%~x0"
:: ==========================================================

:: 打印结果
echo 脚本完整路径：%SCRIPT_FULL_PATH%
echo 脚本所在目录：%SCRIPT_DIR%
echo 脚本完整文件名：%SCRIPT_NAME%
echo 脚本文件名(无后缀)：%SCRIPT_NAME_ONLY%
echo 脚本后缀名：%SCRIPT_EXT%


:: ==========================================================

set "LIBDIR=%~dp0"
set "LIBDIR=!LIBDIR:~0,-1!"
set "envlib=%LIBDIR%\lib.env.bat"
echo %envlib%


set CUSTOMED_USERPROFILE=%SCRIPT_DIR%\user

echo ===================       JDK        ===================
:: JDK
set jdks=%CUSTOMED_USERPROFILE%\.jdks
echo %jdks%
rd %USERPROFILE%\.jdks
mklink /J %USERPROFILE%\.jdks %jdks%
call "%envlib%" :SetVar JAVA_HOME "%USERPROFILE%\.jdks\corretto-1.8.0_492" user
:: 注册表中的环境变量此时无法直接获取，所以从当前环境中直接取值。
set JAVA_HOME=%USERPROFILE%\.jdks\corretto-1.8.0_492
call "%envlib%" :AddPath "%%JAVA_HOME%%\bin" user
echo "%%JAVA_HOME%%\bin"

echo ===================      Gradle       ===================
:: Gradle
set gradle=%CUSTOMED_USERPROFILE%\.gradle
echo %gradle%
rd %USERPROFILE%\.gradle
mklink /J %USERPROFILE%\.gradle %gradle%

echo ===================      Maven       ===================
:: Maven
set maven=%CUSTOMED_USERPROFILE%\.m2
echo %maven%
rd %USERPROFILE%\.m2
mklink /J %USERPROFILE%\.m2 %maven%

echo ===================     Android     ===================
:: JDK
set ANDROID_HOME_BASE=%CUSTOMED_USERPROFILE%\AppData\Local\Android
echo %ANDROID_HOME_BASE%
rd %LOCALAPPDATA%\Android
mklink /J %LOCALAPPDATA%\Android %ANDROID_HOME_BASE%
call "%envlib%" :SetVar ANDROID_HOME "%%LOCALAPPDATA%%\Android\Sdk" user
:: 注册表中的环境变量此时无法直接获取，所以从当前环境中直接取值。
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
call "%envlib%" :AddPath "%%ANDROID_HOME%%\platform-tools" user
call "%envlib%" :AddPath "%%ANDROID_HOME%%\emulator" user
call "%envlib%" :AddPath "%%ANDROID_HOME%%\build-tools\37.0.0" user


:: ==========================================================

set custom-programs=%SCRIPT_DIR%\custom-programs


echo ===================      VScode      ===================
set vsc_path=%custom-programs%\VSCode-win32-x64
call %vsc_path%\右键菜单.bat

pause
