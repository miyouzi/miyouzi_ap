@chcp 963 >nul
@echo off
setlocal ENABLEDELAYEDEXPANSION
@mode con cols=80 lines=70
title Miyouzi_AP_V2.0����ʼ����

set /a num=0
set /a no=0
set /a yes=0

for /F "delims=" %%i in ('netsh wlan show drivers') do (
	set "line=%%i"
	set "line=!line: =!"
	set "line=!line::=!"
	set "jud=!line:~0,4!"
	set "jud2=!line:~0,7!"
	if "!jud!"=="�ӿ�����" (
		set "Device=!line:~4!"
		)
	if "!jud!"=="��������" (
		set /a num+=1
		echo  ��⵽������
		echo.
		echo 	!line:~4!
		)
	if "!jud2!"=="֧�ֵĳ�������" (
		set "ap=!line:~7,1!
		if "!ap!"=="��" (
			set /a yes+=1
			echo ==============================================================================
			echo 			����ϲ��������֧�ֳ������磡
			echo ==============================================================================
			echo.
			) else (
			set /a no+=1
			echo ==============================================================================
			echo 			����Ǹ����������֧�ֳ������磡
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
echo 	����������⵽ %num% ������������ %yes% ���������ñ����߿���AP��
echo.
if %yes% equ 0 (
	echo.
	echo ����������������Ǹ����ĵ����޷�ʹ�ñ����߿����ȵ㣡��������˳���
	echo ==============================================================================
	pause >nul
	exit
	) else (
	if %no% gtr 0 (
		echo ���棡��ĵ��Դ��ڲ�֧�ֳ�������������������ܵ����ȵ㿪��ʧ�ܣ�������ø�������
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
	echo 			��������ʼ�趨�ȵ�����
	echo.
	echo �����趨�ȵ����ơ���
	set /P ssid=
	echo.
	:resetkey
	echo �����趨�ȵ����롿��
	set /P key=
	echo.
	echo 			�����趨��ɣ���ʼ��ʼ����
	netsh wlan set hostednetwork mode=allow ssid=%ssid% key=%key% >nul 2>nul
	if not %errorlevel% equ 0 (
		echo.
		echo 	����������������Ч�������볤��Ӧ��Ϊ 8 �� 63 ���ַ���
		echo.
		goto :resetkey
		)
	echo ==============================================================================
	echo.
	echo 		������ʼ����ɣ���������ٻ�Miyouzi_AP��
	pause >nul
	call "%~dp0Miyouzi_AP.bat"
goto :eof