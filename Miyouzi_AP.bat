@chcp 963 >nul
@echo off
setlocal ENABLEDELAYEDEXPANSION
@mode con cols=79 lines=40
title Miyouzi_AP_V2.0
set "command=%1"
cd /D "%~dp0"
set /A trynum=0
if not exist settings.ini (
	echo ��־·�����������ţ�����ҪLog����дnul��:%~dp0Miyouzi_Ap.log>>settings.ini
	echo ��־������ޡ�MB,������С����:10>>settings.ini
	echo ����Ŀ¼���᲻ͣ��д��:%~dp0Ap_monitor_tmp>>settings.ini
	echo Wget·�����������š�:%~dp0wget\wget.exe>>settings.ini
	echo �Ƿ񵯴���ʾAP���붯̬��True/False��:True>>settings.ini
	echo �Ƿ񵯴���ʾ�½����豸��True/False��:True>>settings.ini
	echo �Ƿ�������ʧ��ʱ�Զ����ò�֧�ֳ��������������������AP�ɹ�����Զ��ָ�����True/False��:True>>settings.ini
	)

set /A tmpnum=1
for /F "tokens=1* delims=:" %%e in (settings.ini) do (
	set "set!tmpnum!=%%f"
	set /A tmpnum+=1
	)
set "logfile=%set1%"
set /A limitsize=%set2% * 1024 * 1024
set "tmpdir=%set3%"
set "wget=%set4%"
set "showmsg=%set5%"
set "shownewdevice=%set6%"
set "autostopdevice=%set6%"

if exist "%logfile%" (
	for /F %%i in ('dir /b %logfile%') do (
		set /A filesize=%%~zi
		)
	if !filesize! gtr %limitsize% (
		echo ==============================================================================
		echo ��������������������������־�Ѵ����ޣ�ɾ������־��
		echo ==============================================================================
		del /q "%logfile%"
		)
	)
	
:begin

if "%1"=="start" (
	echo %date% %time%	�û�������̨��� >>"%logfile%"
	echo ==============================================================================
	echo �����������������������������ں�̨������ء���ȷ����Ȩ��
	echo ==============================================================================
	call :getadmin
	for /F "tokens=3" %%i in ('schtasks ^| findstr Miyouzi_AP') do (
		if "%%i"=="��������" (
			echo ==============================================================================
			echo ��������������������������������̨��������������У�
			echo ==============================================================================
			echo %date% %time%	��̨��������������� >>"%logfile%"
			goto :end
			)
		)
	schtasks | findstr "Miyouzi_AP" >nul 2>nul
	if not !errorlevel! equ 0 (
		echo.
		echo ==============================================================================
		echo �������������������������ֶ���̨���������Ҫ�������ƻ�
		echo ����������������������������ƻ���δ��ӣ����ڿ�ʼ���
		echo ==============================================================================
		echo.
		call "%~dp0������Ա����������̨�������ȵ㡿.bat" startap
		echo.
		echo %date% %time%	�������ƻ� >>"%logfile%"
		)
	mshta vbscript:"<html style=background:buttonface><title>Miyouzi_AP_Start</title><body><script language=vbscript>Set UAC = CreateObject(""Shell.Application""):UAC.ShellExecute ""schtasks"", ""/Run /I /TN Miyouzi_AP"", """", ""runas"", 1:self.close</script></body></html>"
	echo ==============================================================================
	echo ���������������������������������Ѻ�̨������أ�
	echo ==============================================================================
	goto :end
	)

if "%1"=="stop" (
		@mode con cols=79 lines=20
		call :check_status onlycode
		if !ap_on! equ 0 (
			echo ==============================================================================
			echo ����������������������������������APδ����
			echo ==============================================================================
			goto :end
			)
		cd /D "%tmpdir%"
		echo. >StopAP.inf
		netsh wlan stop hostednetwork
		echo %date% %time%	�û�ͣ��AP >>"%logfile%"
		echo ==============================================================================
		echo ������������������������������������ͣ��AP
		echo ==============================================================================
	) else (
		call :CheckDevice
		echo ==============================================================================
		echo ������������������������������������������AP
		echo ==============================================================================
		netsh wlan start hostednetwork
		if not !errorlevel!==0 goto :error
		echo ==============================================================================
		echo ����������������������������������AP�����ɹ���
		echo ==============================================================================
		echo %date% %time%	AP�����ɹ��� >>"%logfile%"
		if !trynum! gtr 0 if %autostopdevice%==True call :StartOtherDevice
		echo. >>"%logfile%"
		choice /t 2 /d 9 /c 98 /n >nul
	)
	
if "%1"=="monitor" call :monitor
:end
echo.
echo ����������˳���
pause >nul
exit

:check_status
	set /A ap_on=0
	for /F "delims=" %%i in ('netsh wlan show hostednetwork') do (
		set "line=%%i"
		set "line=!line: =!"
		set "line=!line::=!"
		set "line=!line:*״̬������=��������������!"
		set "line=!line:~0,7!"
		if "!line!"=="��������������" (
			set /A ap_on=1
			)
		)
	if "%1"=="onlycode" goto :eof
	if !ap_on! equ 0 (
		:error
		if !trynum! LEQ 2 if %autostopdevice%==True (
			call :CheckDevice
			if exist StopAP.inf (
				del /q StopAP.inf
				echo.
				echo ==============================================================================
				echo �����������������������������յ�ֹͣ�źţ���ֹͣ��أ�
				echo ����������������������������	5s���Զ��˳���
				echo ==============================================================================
				echo.
				choice /t 5 /d 9 /c 98 /n >nul
				echo %date% %time%	�յ�ֹͣ�źţ�ֹͣ��أ� >>"%logfile%"
				echo. >>"%logfile%"
				exit
				)
			set /A trynum+=1
			echo ==============================================================================
			echo 	APδ���������ڳ��Խ���������֧�ֳ����������������������ԱȨ��
			echo.
			echo �����������������������������������ڵ�!trynum!�γ���
			echo ==============================================================================
			echo %date% %time%	APδ���������ڳ��Խ���������֧�ֳ����������������ڵ�!trynum!�γ��� >>"%logfile%"
			call :getadmin
			call :StopOtherDevice
			goto :begin
			)
		call :CheckDevice
		echo ==============================================================================
		echo ������������������APδ���������������Ƿ�֧�ֳ��������Լ�����
		echo ����������������������������10s���Զ��˳���
		echo ==============================================================================
		( echo ������������������Miyouzi-AP�� & echo APδ���������������Ƿ�֧�ֳ��������Լ����� ) | msg *
		echo %date% %time%	APδ���������������Ƿ�֧�ֳ��������Լ����� >>"%logfile%"
		echo. >>"%logfile%"
		choice /t 10 /d 9 /c 98 /n >nul
		exit
		)
goto :eof

:monitor
echo ==============================================================================
echo ���������������������������������ڼ��AP���붯̬������
echo ==============================================================================
if not exist "%tmpdir%" (
	md "%tmpdir%" >nul 2>nul
	) else (
	del /s /q "%tmpdir%" >nul
	md "%tmpdir%" >nul 2>nul
	)
cd /D "%tmpdir%"
	:recheck
call :check_status
call :listmacnow
if not exist maclist2.ini call :listmacnow
call :check
call :wait
goto :recheck


:listmacnow
	if not exist maclist1.ini (
		set file=maclist1.ini
		) else (
		set file=maclist2.ini
		)
	if exist maclist2.ini (
		del /q maclist1.ini
		ren maclist2.ini maclist1.ini
		)
	for /F "delims=" %%i in ('netsh wlan show hostednetwork') do (
		set "jud=%%i"
		set "jud=!jud:*�Ѿ���=!"
		if "!jud!"=="�����֤" (
			set "mac=%%i"
			set "mac=!mac: =!"
			set "mac=!mac:�Ѿ��������֤=!"
			set "mac=!mac::=-!"
			echo !mac!>>!file!
			)
		)
	echo @>>!file!
goto :eof

:for_check1
	set /A macjud=0
	for /F "delims=" %%k in (%check1%) do (
		if "%%j"=="%%k" (
			set /A macjud=1
			)
		)
	if !macjud! equ 0 (
		set "target=!mactmp!"
		call :getinf
		echo ==============================================================================
		echo ��!showchange!��MAC: !mactmp! ��!macinf!��
		echo ==============================================================================
		echo %date% %time%	!showchange!MAC:!mactmp!��!macinf!�� >>"%logfile%"
		echo. >>"%logfile%"
		
		echo ����������������������������DELL7559 AP NEWS >%changetype%
		echo. >>%changetype%
		echo =============================================== >>%changetype%
		echo ��!showchange!MAC: !mactmp!��!macinf!�� >>%changetype%
		echo =============================================== >>%changetype%
		echo. >>%changetype%	
		echo. >>%changetype%
		echo =============================================== >>%changetype%
		echo ��������������������������������ǰ�����豸 >>%changetype%
		echo. >>%changetype%
		for /F "eol=@ delims=" %%p in (maclist2.ini) do (
			set "target=%%p"
			call :getinf
			echo ����MAC: %%p������!macinf!�� >>%changetype%
			)
		echo =============================================== >>%changetype%
		
		if "%showmsg%"=="True" (
			type %changetype% | msg *
			)
		)
goto :eof

:for_check2
	for /F "delims=" %%j in (%check2%) do (
		set "mactmp=%%j"
		call :for_check1
		)
goto :eof

:check
	set "check1=maclist1.ini"
	set "check2=maclist2.ini"
	set "changetype=newmac.ini"
	set "showchange=�������豸����AP����"
	call :for_check2
	set "check1=maclist2.ini"
	set "check2=maclist1.ini"
	set "changetype=delmac.ini"
	set "showchange=�������豸�Ͽ�AP����"
	call :for_check2
	
goto :eof

:wait
	choice /t 1 /d 9 /c 98 /n >nul
goto :eof

:getinf
	REM echo ==============================================================================
	REM echo �����������������������ڲ�ѯ !target!��������Ϣ
	REM echo ==============================================================================
	if not exist "%~dp0\MyMacList.ini" echo FF.FF.FF.FF:FF:FF example >"%~dp0\MyMacList.ini"
	for /F "usebackq tokens=1* delims= " %%a in ("%~dp0\MyMacList.ini") do (		
		if "!target!"=="%%a" (
			set "macinf=%%b"
			goto :eof
			)
		)
	call "%wget%" "http://mac.51240.com/!target!__mac" -O macinf.html >nul 2>nul
	title Miyouzi_AP_V2.0
	if not exist UTF8_2_ANSI.vbs call :md_UTF8_2_ANSI
	call wscript -e:vbs "UTF8_2_ANSI.vbs"
	set /A found=0
	for /F "delims=" %%i in (macinf.html.ansi.txt) do (
		set "line=%%i"
		set "infjud=!line:>=!"
		set "infjud=!infjud:<=!"
		set "infjud=!infjud:/=!"
		set "infjud=!infjud:"=!"
		set "infjud=!infjud::=!"
		set "line=!infjud!"
		set "infjud=!infjud:*center����=����������������!"
		set "infjud=!infjud:~0,8!"
		if !found! equ 1 (
			set "line=!line:*;=!"
			set "macinf=!line!"
			set /A found=0
			)
		if "!infjud!"=="����������������" set /A found=1
		)
	del /q macinf.html
	del /q macinf.html.ansi.txt
	
	if "%shownewdevice%"=="True" (
		echo ==============================================================================
		echo �����������豸����MAC: !target!��!macinf!��
		echo ==============================================================================
		echo ����������������������������DELL7559 AP NEWS >newdevice.ini
		echo. >>newdevice.ini
		echo =============================================== >>newdevice.ini
		echo �����������豸����MAC: !target!��!macinf!�� >>newdevice.ini
		echo =============================================== >>newdevice.ini
		type newdevice.ini | msg *
		)
	echo !target! !macinf!>>"%~dp0\MyMacList.ini"
goto :eof

REM =============================��鲢���Ի�ȡ����ԱȨ��==============================
REM ��� https://sites.google.com/site/eneerge/home/BatchGotAdmin
:getadmin
	>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
	if '%errorlevel%' NEQ '0' (
		echo �����ڳ��Ի�ȡ����ԱȨ�ޡ�
		echo %date% %time%	���ڳ��Ի�ȡ����ԱȨ��... >>"%logfile%"
		mshta vbscript:"<html style=background:buttonface><title>Miyouzi_AP_GetAdmin</title><body><script language=vbscript>Set UAC = CreateObject(""Shell.Application""):UAC.ShellExecute ""%~s0"", ""%command%"", """", ""runas"", 1:self.close</script></body></html>"
		exit
	)
	echo %date% %time%	�ѻ�ȡ����ԱȨ�ޣ� >>"%logfile%"
goto :eof
REM ==================================================================================


:CheckDevice
	set /a yes=0
	for /F "delims=" %%i in ('netsh wlan show drivers') do (
	set "line=%%i"
	set "line=!line: =!"
	set "line=!line::=!"
	set "jud2=!line:~0,7!"
	if "!jud2!"=="֧�ֵĳ�������" (
		set "ap=!line:~7,1!
		if "!ap!"=="��" set /a yes+=1
		)
	)
	if %yes% equ 0 (
		echo ==============================================================================
		echo ������������������	APδ������δ�ҵ�֧�ֳ������������
		echo ������������������������	��10s���Զ��˳���
		echo ==============================================================================
		( echo ��������������Miyouzi-AP�� & echo APδ������δ�ҵ�֧�ֳ������������ ) | msg *
		echo %date% %time%	APδ������δ�ҵ�֧�ֳ������������ >>"%logfile%"
		echo. >>"%logfile%"
		choice /t 10 /d 9 /c 98 /n >nul
		exit
		)
goto :eof

:StopOtherDevice
	if not exist UnsupportDevice.ini (
		call :CheckUnsupportDevice
		) else (
		for /F "delims=" %%i in (UnsupportDevice.ini) do (
			netsh interface set interface "%%i" disable
			echo %date% %time%	����������%%i >>"%logfile%"
			)
		)
goto :eof


:StartOtherDevice
	for /F "delims=" %%i in (UnsupportDevice.ini) do (
		netsh interface set interface "%%i" enable
		echo %date% %time%	����������%%i >>"%logfile%"
		)
	)
goto :eof


:CheckUnsupportDevice
	for /F "delims=" %%i in ('netsh wlan show drivers') do (
		set "line=%%i"
		set "line=!line: =!"
		set "line=!line::=!"
		set "jud=!line:~0,4!"
		set "jud2=!line:~0,7!"
		if "!jud!"=="�ӿ�����" (
			set "Device=!line:~4!"
			)
		if "!jud2!"=="֧�ֵĳ�������" (
			set "ap=!line:~7,1!
			if not "!ap!"=="��" (
				if exist UnsupportDevice.ini (
					set /A DeviceExist=0
					for /F "delims=" %%i in (UnsupportDevice.ini) do (
						if "!Device!"=="%%i" set /A DeviceExist=1
						)
					if !DeviceExist! equ 0 echo !Device!>>UnsupportDevice.ini
				) else (
					echo !Device!>UnsupportDevice.ini
				)
				
			)
		)
	)
goto :eof

:md_UTF8_2_ANSI
	echo set fso = CreateObject("Scripting.FileSystemObject") >UTF8_2_ANSI.vbs
	echo FileList = "" >>UTF8_2_ANSI.vbs
	echo for each oFile in fso.GetFolder(".").Files >>UTF8_2_ANSI.vbs
	echo     if LCase(fso.GetExtensionName(oFile.Path)) = LCase("html") then >>UTF8_2_ANSI.vbs
	echo         FileList = FileList ^& oFile.Path ^& vbCrLf >>UTF8_2_ANSI.vbs
	echo     end if >>UTF8_2_ANSI.vbs
	echo next >>UTF8_2_ANSI.vbs
	echo Files = Split(FileList, vbCrLf) >>UTF8_2_ANSI.vbs
	echo for i=0 to UBound(Files)-1 >>UTF8_2_ANSI.vbs
	echo     U8ToAnsi Files(i) >>UTF8_2_ANSI.vbs
	echo next >>UTF8_2_ANSI.vbs
	echo function U8ToU8Bom(strFile) >>UTF8_2_ANSI.vbs
	echo     dim ADOStrm >>UTF8_2_ANSI.vbs
	echo     Set ADOStrm = CreateObject("ADODB.Stream") >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Type = 2 >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Mode = 3 >>UTF8_2_ANSI.vbs
	echo     ADOStrm.CharSet = "utf-8" >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Open >>UTF8_2_ANSI.vbs
	echo     ADOStrm.LoadFromFile strFile >>UTF8_2_ANSI.vbs
	echo     ADOStrm.SaveToFile strFile ^& ".u8.txt", 2 >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Close >>UTF8_2_ANSI.vbs
	echo     Set ADOStrm = Nothing >>UTF8_2_ANSI.vbs
	echo end function >>UTF8_2_ANSI.vbs
	echo function U8ToAnsi(strFile) >>UTF8_2_ANSI.vbs
	echo     dim ADOStrm >>UTF8_2_ANSI.vbs
	echo     dim s >>UTF8_2_ANSI.vbs
	echo     Set ADOStrm = CreateObject("ADODB.Stream") >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Type = 2 >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Mode = 3 >>UTF8_2_ANSI.vbs
	echo     ADOStrm.CharSet = "utf-8" >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Open >>UTF8_2_ANSI.vbs
	echo     ADOStrm.LoadFromFile strFile >>UTF8_2_ANSI.vbs
	echo     s = ADOStrm.ReadText >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Position = 0 >>UTF8_2_ANSI.vbs
	echo     ADOStrm.CharSet = "gbk" >>UTF8_2_ANSI.vbs
	echo     ADOStrm.WriteText s >>UTF8_2_ANSI.vbs
	echo     ADOStrm.SetEOS >>UTF8_2_ANSI.vbs
	echo     ADOStrm.SaveToFile strFile ^& ".ansi.txt", 2 >>UTF8_2_ANSI.vbs
	echo     ADOStrm.Close >>UTF8_2_ANSI.vbs
	echo     Set ADOStrm = Nothing >>UTF8_2_ANSI.vbs
	echo end function >>UTF8_2_ANSI.vbs
goto :eof