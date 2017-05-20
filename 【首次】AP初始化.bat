@chcp 963 >nul
@echo off
setlocal ENABLEDELAYEDEXPANSION
@mode con cols=80 lines=70
title Miyouzi_AP_V2.0【初始化】

set /a num=0
set /a no=0
set /a yes=0

for /F "delims=" %%i in ('netsh wlan show drivers') do (
	set "line=%%i"
	set "line=!line: =!"
	set "line=!line::=!"
	set "jud=!line:~0,4!"
	set "jud2=!line:~0,7!"
	if "!jud!"=="接口名称" (
		set "Device=!line:~4!"
		)
	if "!jud!"=="驱动程序" (
		set /a num+=1
		echo  检测到网卡：
		echo.
		echo 	!line:~4!
		)
	if "!jud2!"=="支持的承载网络" (
		set "ap=!line:~7,1!
		if "!ap!"=="是" (
			set /a yes+=1
			echo ==============================================================================
			echo 			　恭喜！该网卡支持承载网络！
			echo ==============================================================================
			echo.
			) else (
			set /a no+=1
			echo ==============================================================================
			echo 			　抱歉！该网卡不支持承载网络！
			echo ==============================================================================
			echo.
			
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

echo.
echo.
echo ==============================================================================
echo 	　　　共检测到 %num% 个网卡，其中 %yes% 个网卡可用本工具开启AP！
echo.
if %yes% equ 0 (
	echo.
	echo 　　　　　　　抱歉！你的电脑无法使用本工具开启热点！按任意键退出！
	echo ==============================================================================
	pause >nul
	exit
	) else (
	if %no% gtr 0 (
		echo 警告！你的电脑存在不支持承载网络的网卡，将可能导致热点开启失败！建议禁用该网卡！
		echo ==============================================================================
		call :setap
		) else (
		echo ==============================================================================
		call :setap
		)
	)
exit

:setap
	echo.
	echo.
	echo ==============================================================================
	echo 			　　　开始设定热点配置
	echo.
	echo 【请设定热点名称】：
	set /P ssid=
	echo.
	:resetkey
	echo 【请设定热点密码】：
	set /P key=
	echo.
	echo 			　　设定完成！开始初始化！
	netsh wlan set hostednetwork mode=allow ssid=%ssid% key=%key% >nul 2>nul
	if not %errorlevel% equ 0 (
		echo.
		echo 	　　　　　密码无效！！密码长度应该为 8 到 63 个字符。
		echo.
		goto :resetkey
		)
	echo ==============================================================================
	echo.
	echo 		　　初始化完成！按任意键召唤Miyouzi_AP！
	pause >nul
	call "%~dp0Miyouzi_AP.bat"
goto :eof