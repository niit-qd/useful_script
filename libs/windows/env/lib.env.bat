@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

:: ======================
:: 备份所有参数
:: ======================
set all_args=%*

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

:: ======================
:: 库入口：必须写在最前面
:: ======================
call :Main %*
goto :eof

:: ==================== 功能说明 ====================
:: 1. 设置系统/用户环境变量 
:: 2. 添加PATH时： 
::    若已存在 → 先删除旧路径 
::    再按 position 重新插入 
::    position=0 → 最前面 
::    position=N → 插入到第 N 段之后 
::    不填position → 默认追加到最后 
::    position 超过最大段数 → 自动放到最后 
:: ==================================================

:: ==================== 函数1：设置普通环境变量 ====================
:SetVar
echo.
echo.
echo ========== :SetVar ==========
set "varName=%~1"
set "varValue=%~2"
set "varScope=%~3"
echo varName=!varName!
echo varValue=!varValue!
echo varScope=!varScope!

if /i "!varScope!"=="system" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "!varName!" /t REG_EXPAND_SZ /d "!varValue!" /f >nul 2>&1
    echo [系统变量] !varName! = !varValue!
) else (
    reg add "HKCU\Environment" /v "!varName!" /t REG_EXPAND_SZ /d "!varValue!" /f >nul 2>&1
    echo [用户变量] !varName! = !varValue!
)
goto :eof

:: ==================== PATH 专用写入（使用PowerShell避免分号问题） ====================
:WritePath
echo ========== :WritePath ==========
set "pathValue=%~1"
set "scope=%~2"

if /i "!scope!"=="system" (
    powershell -Command "[Environment]::SetEnvironmentVariable('PATH','!pathValue!','Machine')" >nul 2>&1
) else (
    powershell -Command "[Environment]::SetEnvironmentVariable('PATH','!pathValue!','User')" >nul 2>&1
)
echo [!scope!变量] PATH 已更新
goto :eof

:: ==================== 函数2：PATH 强制按位置重插（新版规则） ====================
:AddPath
echo.
echo.
echo ========== :AddPath ==========
set "targetInsertPath=%~1"
set "pathScope=%~2"
set "insertPosition=%~3"
echo targetInsertPath=!targetInsertPath!
echo pathScope=!pathScope!
echo insertPosition=!insertPosition!

if not defined insertPosition set "insertPosition=-1"

if /i "!pathScope!"=="system" (
    set "envRegPath=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    set "pathScopeText=系统PATH"
) else (
    set "envRegPath=HKCU\Environment"
    set "pathScopeText=用户PATH"
)

set "rawCurrentPath="
for /f "skip=2 tokens=2,*" %%a in ('reg query "!envRegPath!" /v PATH 2^>nul') do set "rawCurrentPath=%%b"

:: 步骤1：去重
echo.
echo :AddPath 步骤1：去重 
set "cleanedPathList="
for %%p in ("!rawCurrentPath:;=" "!") do (
    set "pathSegment=%%~p"
    if /i not "!pathSegment!"=="!targetInsertPath!" (
        if defined cleanedPathList (
            set "cleanedPathList=!cleanedPathList!;!pathSegment!"
        ) else (
            set "cleanedPathList=!pathSegment!"
        )
    )
)

:: 步骤2：按新规则插入 
echo.
echo :AddPath 步骤2：按新position规则插入
set "cnt=0"
for %%p in ("!cleanedPathList:;=" "!") do (
    set "s=%%~p"
    if not "!s!"=="" (
        set /a cnt+=1
        set "seg[!cnt!]=!s!"
    )
)

:: 处理位置
set "insPos=!insertPosition!"
if "!insPos!"=="-1" set "insPos=!cnt!"
if !insPos! gtr !cnt! set "insPos=!cnt!"

set "newPath="
for /l %%i in (1,1,!insPos!) do (
    if defined newPath (set "newPath=!newPath!;!seg[%%i]!") else (set "newPath=!seg[%%i]!")
)

if defined newPath (set "newPath=!newPath!;!targetInsertPath!") else (set "newPath=!targetInsertPath!")

set /a start=insPos+1
for /l %%i in (!start!,1,!cnt!) do (
    set "newPath=!newPath!;!seg[%%i]!"
)

set "finalPathResult=!newPath!"
@REM echo finalPathResult = !finalPathResult!

if "!finalPathResult:~0,1!"==";" set "finalPathResult=!finalPathResult:~1!"

:: 写入PATH 
call :WritePath "!finalPathResult!" !pathScope!

echo [!pathScopeText!] 已重新定位：!targetInsertPath!  (位置：!insertPosition!)
goto :eof

:: ==================== 刷新环境变量 ====================
:RefreshAllEnv
echo.
echo ==============================================
echo 正在重载 全部系统环境变量 + 用户环境变量... 
echo ==============================================

powershell -Command "$machineEnv=[Environment]::GetEnvironmentVariables('Machine');$userEnv=[Environment]::GetEnvironmentVariables('User');foreach($key in $machineEnv.Keys){[Environment]::SetEnvironmentVariable($key,$machineEnv[$key],'Process')};foreach($key in $userEnv.Keys){[Environment]::SetEnvironmentVariable($key,$userEnv[$key],'Process')}" >nul 2>&1

set "PATH="
for /f "skip=2 tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "PATH=%%b"
for /f "skip=2 tokens=2,*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "PATH=!PATH!;%%b"

echo ✅ 所有环境变量已全部刷新，当前窗口立即生效 
echo ✅ JAVA_HOME / MAVEN_HOME / PATH 全部可用 
echo.
goto :eof

:: ======================
:: Main 必须写在最后
:: ======================
:Main
    :: 执行传入的完整命令（含函数名 + 参数）
    call %*
goto :eof