@echo off
if not "%1"=="startap" (
	chcp 963 >nul
	setlocal ENABLEDELAYEDEXPANSION
	mode con cols=80 lines=20
	)
set "command2=%1"
echo ==============================================================================
echo 		������ע�⣡�������ƻ���Ҫ����ԱȨ�ޣ�
echo ==============================================================================
echo.
if not "%command2%"=="startap" call :getadmin

schtasks | findstr "Miyouzi_AP" >nul 2>nul
if !errorlevel! equ 0 (
	echo ==============================================================================
	echo 		��������������ƻ��Ѵ��ڣ�5s���˳�
	echo ==============================================================================
	choice /t 5 /d 9 /c 98 /n >nul
	goto :eof
	)

schtasks /create /ru "System" /tn "Miyouzi_AP" /tr "%~dp0Miyouzi_AP�����ü�ء�.bat" /sc onstart
if %errorlevel%==0 (
	echo.	
	echo ==============================================================================
	echo 		��������ƻ���ӳɹ����ƻ�����Miyouzi_AP
	echo.
	echo 		��������������ÿ�ο������̨����
	echo.
	echo ������PS����������Ĭ�Ͻ�ʹ�ý���������У������ǰ��������ƻ��������޸�
	echo ==============================================================================
	) else (
	echo.	
	echo ==============================================================================
	echo 			����������ƻ����ʧ�ܣ�
	echo.
	echo 		�������������Ƿ��Թ���Ա��ʽ���У�
	echo ==============================================================================
	)
if not "%command2%"=="startap" (
	echo ���������������
	pause >nul
	)
goto :eof




REM =============================��鲢���Ի�ȡ����ԱȨ��==============================
REM ��� https://sites.google.com/site/eneerge/home/BatchGotAdmin
:getadmin
	>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
	if '%errorlevel%' NEQ '0' (
		echo �����ڳ��Ի�ȡ����ԱȨ�ޡ�
		mshta vbscript:"<html style=background:buttonface><title>Miyouzi_AP_GetAdmin</title><body><script language=vbscript>Set UAC = CreateObject(""Shell.Application""):UAC.ShellExecute ""%~s0"", """", """", ""runas"", 1:self.close</script></body></html>"
		exit
	)
goto :eof
REM ==================================================================================
