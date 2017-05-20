@chcp 963 >nul
@echo off
setlocal ENABLEDELAYEDEXPANSION
@mode con cols=79 lines=40
title Miyouzi_AP_V2.0
set "command=%1"
cd /D "%~dp0"
set /A trynum=0
if not exist settings.ini (
	echo 日志路径【无需引号，不需要Log请填写nul】:%~dp0Miyouzi_Ap.log>>settings.ini
	echo 日志体积上限【MB,不可有小数】:10>>settings.ini
	echo 缓存目录【会不停读写】:%~dp0Ap_monitor_tmp>>settings.ini
	echo Wget路径【无需引号】:%~dp0wget\wget.exe>>settings.ini
	echo 是否弹窗显示AP接入动态【True/False】:True>>settings.ini
	echo 是否弹窗显示新接入设备【True/False】:True>>settings.ini
	echo 是否在启动失败时自动禁用不支持承载网络的网卡（若启动AP成功后会自动恢复）【True/False】:True>>settings.ini
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
		echo 　　　　　　　　　　　　日志已达上限，删除旧日志！
		echo ==============================================================================
		del /q "%logfile%"
		)
	)
	
:begin

if "%1"=="start" (
	echo %date% %time%	用户启动后台监控 >>"%logfile%"
	echo ==============================================================================
	echo 　　　　　　　　　　　　　正在后台启动监控。请确认授权！
	echo ==============================================================================
	call :getadmin
	for /F "tokens=3" %%i in ('schtasks ^| findstr Miyouzi_AP') do (
		if "%%i"=="正在运行" (
			echo ==============================================================================
			echo 　　　　　　　　　　　　　　　后台启动监控已在运行！
			echo ==============================================================================
			echo %date% %time%	后台启动监控已在运行 >>"%logfile%"
			goto :end
			)
		)
	schtasks | findstr "Miyouzi_AP" >nul 2>nul
	if not !errorlevel! equ 0 (
		echo.
		echo ==============================================================================
		echo 　　　　　　　　　　　　手动后台启动监控需要添加任务计划
		echo 　　　　　　　　　　　　任务计划尚未添加，现在开始添加
		echo ==============================================================================
		echo.
		call "%~dp0【管理员】【开机后台自启动热点】.bat" startap
		echo.
		echo %date% %time%	添加任务计划 >>"%logfile%"
		)
	mshta vbscript:"<html style=background:buttonface><title>Miyouzi_AP_Start</title><body><script language=vbscript>Set UAC = CreateObject(""Shell.Application""):UAC.ShellExecute ""schtasks"", ""/Run /I /TN Miyouzi_AP"", """", ""runas"", 1:self.close</script></body></html>"
	echo ==============================================================================
	echo 　　　　　　　　　　　　　　　　已后台启动监控！
	echo ==============================================================================
	goto :end
	)

if "%1"=="stop" (
		@mode con cols=79 lines=20
		call :check_status onlycode
		if !ap_on! equ 0 (
			echo ==============================================================================
			echo 　　　　　　　　　　　　　　　　　AP未启用
			echo ==============================================================================
			goto :end
			)
		cd /D "%tmpdir%"
		echo. >StopAP.inf
		netsh wlan stop hostednetwork
		echo %date% %time%	用户停用AP >>"%logfile%"
		echo ==============================================================================
		echo 　　　　　　　　　　　　　　　　　已停用AP
		echo ==============================================================================
	) else (
		call :CheckDevice
		echo ==============================================================================
		echo 　　　　　　　　　　　　　　　　　正在启动AP
		echo ==============================================================================
		netsh wlan start hostednetwork
		if not !errorlevel!==0 goto :error
		echo ==============================================================================
		echo 　　　　　　　　　　　　　　　　　AP启动成功！
		echo ==============================================================================
		echo %date% %time%	AP启动成功！ >>"%logfile%"
		if !trynum! gtr 0 if %autostopdevice%==True call :StartOtherDevice
		echo. >>"%logfile%"
		choice /t 2 /d 9 /c 98 /n >nul
	)
	
if "%1"=="monitor" call :monitor
:end
echo.
echo 【按任意键退出】
pause >nul
exit

:check_status
	set /A ap_on=0
	for /F "delims=" %%i in ('netsh wlan show hostednetwork') do (
		set "line=%%i"
		set "line=!line: =!"
		set "line=!line::=!"
		set "line=!line:*状态已启动=啦啦啦啦啦啦啦!"
		set "line=!line:~0,7!"
		if "!line!"=="啦啦啦啦啦啦啦" (
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
				echo 　　　　　　　　　　　　　　收到停止信号！将停止监控！
				echo 　　　　　　　　　　　　　　	5s后自动退出！
				echo ==============================================================================
				echo.
				choice /t 5 /d 9 /c 98 /n >nul
				echo %date% %time%	收到停止信号！停止监控！ >>"%logfile%"
				echo. >>"%logfile%"
				exit
				)
			set /A trynum+=1
			echo ==============================================================================
			echo 	AP未启动！正在尝试禁用其他非支持承载网络网卡！将请求管理员权限
			echo.
			echo 　　　　　　　　　　　　　　　　正在第!trynum!次尝试
			echo ==============================================================================
			echo %date% %time%	AP未启动！正在尝试禁用其他非支持承载网络网卡！正在第!trynum!次尝试 >>"%logfile%"
			call :getadmin
			call :StopOtherDevice
			goto :begin
			)
		call :CheckDevice
		echo ==============================================================================
		echo 　　　　　　　　　AP未启动！请检查网卡是否支持承载网络以及配置
		echo 　　　　　　　　　　　　　　10s后自动退出！
		echo ==============================================================================
		( echo 　　　　　　　　【Miyouzi-AP】 & echo AP未启动！请检查网卡是否支持承载网络以及配置 ) | msg *
		echo %date% %time%	AP未启动！请检查网卡是否支持承载网络以及配置 >>"%logfile%"
		echo. >>"%logfile%"
		choice /t 10 /d 9 /c 98 /n >nul
		exit
		)
goto :eof

:monitor
echo ==============================================================================
echo 　　　　　　　　　　　　　　　正在监测AP接入动态。。。
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
		set "jud=!jud:*已经过=!"
		if "!jud!"=="身份验证" (
			set "mac=%%i"
			set "mac=!mac: =!"
			set "mac=!mac:已经过身份验证=!"
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
		echo 　!showchange!　MAC: !mactmp! 【!macinf!】
		echo ==============================================================================
		echo %date% %time%	!showchange!MAC:!mactmp!【!macinf!】 >>"%logfile%"
		echo. >>"%logfile%"
		
		echo 　　　　　　　　　　　　　　DELL7559 AP NEWS >%changetype%
		echo. >>%changetype%
		echo =============================================== >>%changetype%
		echo 　!showchange!MAC: !mactmp!【!macinf!】 >>%changetype%
		echo =============================================== >>%changetype%
		echo. >>%changetype%	
		echo. >>%changetype%
		echo =============================================== >>%changetype%
		echo 　　　　　　　　　　　　　　　当前在线设备 >>%changetype%
		echo. >>%changetype%
		for /F "eol=@ delims=" %%p in (maclist2.ini) do (
			set "target=%%p"
			call :getinf
			echo 　　MAC: %%p　　【!macinf!】 >>%changetype%
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
	set "showchange=【发现设备接入AP！】"
	call :for_check2
	set "check1=maclist2.ini"
	set "check2=maclist1.ini"
	set "changetype=delmac.ini"
	set "showchange=【发现设备断开AP！】"
	call :for_check2
	
goto :eof

:wait
	choice /t 1 /d 9 /c 98 /n >nul
goto :eof

:getinf
	REM echo ==============================================================================
	REM echo 　　　　　　　　　　正在查询 !target!的网卡信息
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
		set "infjud=!infjud:*center厂商=啦啦啦啦啦啦啦啦!"
		set "infjud=!infjud:~0,8!"
		if !found! equ 1 (
			set "line=!line:*;=!"
			set "macinf=!line!"
			set /A found=0
			)
		if "!infjud!"=="啦啦啦啦啦啦啦啦" set /A found=1
		)
	del /q macinf.html
	del /q macinf.html.ansi.txt
	
	if "%shownewdevice%"=="True" (
		echo ==============================================================================
		echo 　【发现新设备！】MAC: !target!【!macinf!】
		echo ==============================================================================
		echo 　　　　　　　　　　　　　　DELL7559 AP NEWS >newdevice.ini
		echo. >>newdevice.ini
		echo =============================================== >>newdevice.ini
		echo 　【发现新设备！】MAC: !target!【!macinf!】 >>newdevice.ini
		echo =============================================== >>newdevice.ini
		type newdevice.ini | msg *
		)
	echo !target! !macinf!>>"%~dp0\MyMacList.ini"
goto :eof

REM =============================检查并尝试获取管理员权限==============================
REM 借鉴 https://sites.google.com/site/eneerge/home/BatchGotAdmin
:getadmin
	>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
	if '%errorlevel%' NEQ '0' (
		echo 【正在尝试获取管理员权限】
		echo %date% %time%	正在尝试获取管理员权限... >>"%logfile%"
		mshta vbscript:"<html style=background:buttonface><title>Miyouzi_AP_GetAdmin</title><body><script language=vbscript>Set UAC = CreateObject(""Shell.Application""):UAC.ShellExecute ""%~s0"", ""%command%"", """", ""runas"", 1:self.close</script></body></html>"
		exit
	)
	echo %date% %time%	已获取管理员权限！ >>"%logfile%"
goto :eof
REM ==================================================================================


:CheckDevice
	set /a yes=0
	for /F "delims=" %%i in ('netsh wlan show drivers') do (
	set "line=%%i"
	set "line=!line: =!"
	set "line=!line::=!"
	set "jud2=!line:~0,7!"
	if "!jud2!"=="支持的承载网络" (
		set "ap=!line:~7,1!
		if "!ap!"=="是" set /a yes+=1
		)
	)
	if %yes% equ 0 (
		echo ==============================================================================
		echo 　　　　　　　　　	AP未启动！未找到支持承载网络的网卡
		echo 　　　　　　　　　　　　	　10s后自动退出！
		echo ==============================================================================
		( echo 　　　　　　【Miyouzi-AP】 & echo AP未启动！未找到支持承载网络的网卡 ) | msg *
		echo %date% %time%	AP未启动！未找到支持承载网络的网卡 >>"%logfile%"
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
			echo %date% %time%	禁用网卡：%%i >>"%logfile%"
			)
		)
goto :eof


:StartOtherDevice
	for /F "delims=" %%i in (UnsupportDevice.ini) do (
		netsh interface set interface "%%i" enable
		echo %date% %time%	启用网卡：%%i >>"%logfile%"
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
		if "!jud!"=="接口名称" (
			set "Device=!line:~4!"
			)
		if "!jud2!"=="支持的承载网络" (
			set "ap=!line:~7,1!
			if not "!ap!"=="是" (
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