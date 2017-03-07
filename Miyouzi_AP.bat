@chcp 963 >nul
@echo off
setlocal ENABLEDELAYEDEXPANSION
@mode con cols=80 lines=30
title Miyouzi_AP

cd /D "%~dp0"
if not exist settings.ini (
	echo 日志路径【无需引号，不需要Log请填写nul】:%~dp0Miyouzi_Ap.log>>settings.ini
	echo 日志体积上限【MB,不可有小数】:10>>settings.ini
	echo 缓存目录【会不停读写】:%~dp0Ap_monitor_tmp>>settings.ini
	echo Wget路径【无需引号】:%~dp0wget\wget.exe>>settings.ini
	echo 是否弹窗显示AP接入动态【True/False】:True>>settings.ini
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
	
	
if "%1"=="stop" (
	netsh wlan stop hostednetwork
	) else (
	echo ==============================================================================
	echo 　　　　　　　　　　　　　　　　　正在启动AP
	echo ==============================================================================
	netsh wlan start hostednetwork
	if not !errorlevel!==0 goto :error
	echo ==============================================================================
	echo 　　　　　　　　　　　　　　　　　AP启动成功！
	echo ==============================================================================
	echo %date% %time%	AP启动成功！ >>"%logfile%"
	echo. >>"%logfile%"
	choice /t 2 /d 9 /c 98 /n >nul
	)
	
if "%1"=="monitor" call :monitor
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
	if !ap_on! equ 0 (
		:error
		echo ==============================================================================
		echo 　　　　　　　　　AP未启动！请检查网卡是否支持承载网络以及配置
		echo 　　　　　　　　　　　　　　3s后自动退出！
		echo ==============================================================================
		( echo 　　　　　　　　【Miyouzi-AP】 & echo AP未启动！请检查网卡是否支持承载网络以及配置 ) | msg *
		echo %date% %time%	AP未启动！请检查网卡是否支持承载网络以及配置 >>"%logfile%"
		echo. >>"%logfile%"
		choice /t 3 /d 9 /c 98 /n >nul
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
		
		echo 　　　　　　　　　　　　　　Miyouzi AP NEWS >%changetype%
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
	if not exist "%~dp0\MyMacList.ini" echo FF.FF.FF.FF:FF:FF example>"%~dp0\MyMacList.ini"
	for /F "usebackq tokens=1* delims= " %%a in ("%~dp0\MyMacList.ini") do (		
		if "!target!"=="%%a" (
			set "macinf=%%b"
			goto :eof
			)
		)
	call "%wget%" "http://mac.51240.com/!target!__mac" -O macinf.html >nul 2>nul
	title Miyouzi_AP
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
	echo !target! !macinf!>>"%~dp0\MyMacList.ini"
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
	wscript -e:vbs "UTF8_2_ANSI.vbs" 
goto :eof