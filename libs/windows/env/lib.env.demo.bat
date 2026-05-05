@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title 调用 envlib 环境变量库 

:: ==================== 管理员提权 ====================
cacls.exe "%SYSTEMROOT%\system32\config\system" >nul 2>&1
if '%errorlevel%' NEQ '0' (
    echo 正在请求管理员权限...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs" >nul 2>&1
    exit /B
)

set "LIBDIR=%~dp0"
set "LIBDIR=!LIBDIR:~0,-1!"
set "envlib=%LIBDIR%\lib.env.bat"
echo %envlib%

:: ==================== 调用库函数 ====================

call "%envlib%" :SetVar JAVA_HOME "C:\Program Files\Java\jdk1.8.0_391" system
:: 注册表中的环境变量此时无法直接获取，所以从当前环境中直接取值。但是不要使用引号，否则对比值存在引号导致无法在`:AddPath`中去重。
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_391
call "%envlib%" :AddPath "%%JAVA_HOME%%\bin" system 0

@REM 这里最好使用`%%`代替`%`来引用变量；无论使用哪种方式，使用该脚本设置环境变量之后，都是解析之后的值，可能和后期的代码继续调用被解析有关。
call "%envlib%" :SetVar ANDROID_HOME "%LOCALAPPDATA%\Android\Sdk" user
:: 注册表中的环境变量此时无法直接获取，所以从当前环境中直接取值。但是不要使用引号，否则对比值存在引号导致无法在`:AddPath`中去重。
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
call "%envlib%" :AddPath "%%ANDROID_HOME%%\platform-tools" user
call "%envlib%" :AddPath "%%ANDROID_HOME%%\emulator" user
call "%envlib%" :AddPath "%%ANDROID_HOME%%\build-tools\37.0.0" user

call "%envlib%" :SetVar MAVEN_HOME "D:\apache-maven-3.9.7" user
call "%envlib%" :AddPath "!MAVEN_HOME!\bin" user 2

call "%envlib%" :AddPath "D:\NodeJS" system
call "%envlib%" :AddPath "C:\Program Files\Git\bin" user 1

echo.
echo ==========================
echo  全部配置完成！当前窗口已生效
echo ==========================
pause