@echo off
if not "%1"=="startap" (
	chcp 963 >nul
	setlocal ENABLEDELAYEDEXPANSION
	mode con cols=80 lines=20
	)
set "command2=%1"
echo ==============================================================================
echo 		　　　注意！添加任务计划需要管理员权限！
echo ==============================================================================
echo.
if not "%command2%"=="startap" call :getadmin

schtasks | findstr "Miyouzi_AP" >nul 2>nul
if !errorlevel! equ 0 (
	echo ==============================================================================
	echo 		　　　　　任务计划已存在！5s后退出
	echo ==============================================================================
	choice /t 5 /d 9 /c 98 /n >nul
	goto :eof
	)

schtasks /create /ru "System" /tn "Miyouzi_AP" /tr "%~dp0Miyouzi_AP【启用监控】.bat" /sc onstart
if %errorlevel%==0 (
	echo.	
	echo ==============================================================================
	echo 		　　任务计划添加成功！计划名：Miyouzi_AP
	echo.
	echo 		　　　　任务将在每次开机后后台运行
	echo.
	echo 　　　PS：批处理创建默认仅使用交流电才运行！你可以前往“任务计划”进行修改
	echo ==============================================================================
	) else (
	echo.	
	echo ==============================================================================
	echo 			　　　任务计划添加失败！
	echo.
	echo 		　　　　请检查是否以管理员方式运行！
	echo ==============================================================================
	)
if not "%command2%"=="startap" (
	echo 【按任意键继续】
	pause >nul
	)
goto :eof




REM =============================检查并尝试获取管理员权限==============================
REM 借鉴 https://sites.google.com/site/eneerge/home/BatchGotAdmin
:getadmin
	>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
	if '%errorlevel%' NEQ '0' (
		echo 【正在尝试获取管理员权限】
		mshta vbscript:"<html style=background:buttonface><title>Miyouzi_AP_GetAdmin</title><body><script language=vbscript>Set UAC = CreateObject(""Shell.Application""):UAC.ShellExecute ""%~s0"", """", """", ""runas"", 1:self.close</script></body></html>"
		exit
	)
goto :eof
REM ==================================================================================
