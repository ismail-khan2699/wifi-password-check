@echo off
setlocal enabledelayedexpansion

echo =========================================
echo WiFi Password Recovery Script
echo Network: Wireless
echo Base Password: 0123456789
echo =========================================
echo.

set SSID=Wireless
set BASE_PASSWORD=0123456789
set TEMP_PROFILE=%TEMP%\wifi_temp_profile.xml

REM Disconnect from current network first
echo Disconnecting from any current network...
netsh wlan disconnect >nul 2>&1
timeout /t 2 /nobreak >nul

echo Testing original password first...
call :test_password "%BASE_PASSWORD%" "original"
if !errorlevel! equ 0 goto :end

echo Original password failed. Testing variations...
echo.

REM Generate variations where each digit is doubled
set /a count=1
for /l %%i in (0,1,10) do (
    set "password="
    
    REM Build password with doubled digit at position %%i
    for /l %%j in (0,1,10) do (
        set "char=!BASE_PASSWORD:~%%j,1!"
        if "!char!" neq "" (
            if %%j equ %%i (
                set "password=!password!!char!!char!"
            ) else (
                set "password=!password!!char!"
            )
        )
    )
    
    if defined password (
        set /a count+=1
        call :test_password "!password!" "doubled at position %%i"
        if !errorlevel! equ 0 goto :end
    )
)

REM Generate variations where each digit is tripled
echo.
echo Testing tripled digit variations...
echo.

for /l %%i in (0,1,10) do (
    set "password="
    
    REM Build password with tripled digit at position %%i
    for /l %%j in (0,1,10) do (
        set "char=!BASE_PASSWORD:~%%j,1!"
        if "!char!" neq "" (
            if %%j equ %%i (
                set "password=!password!!char!!char!!char!"
            ) else (
                set "password=!password!!char!"
            )
        )
    )
    
    if defined password (
        set /a count+=1
        call :test_password "!password!" "tripled at position %%i"
        if !errorlevel! equ 0 goto :end
    )
)

echo.
echo ============================================
echo No working password found from variations
echo Total attempts: !count!
echo ============================================
goto :cleanup

:test_password
set "TEST_PASS=%~1"
set "TEST_DESC=%~2"

echo [Attempt] Testing: %TEST_PASS% ^(%TEST_DESC%^)

REM Disconnect first
netsh wlan disconnect >nul 2>&1
timeout /t 1 /nobreak >nul

REM Create WiFi profile XML
(
echo ^<?xml version="1.0"?^>
echo ^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>
echo     ^<name^>%SSID%_TEST^</name^>
echo     ^<SSIDConfig^>
echo         ^<SSID^>
echo             ^<name^>%SSID%^</name^>
echo         ^</SSID^>
echo     ^</SSIDConfig^>
echo     ^<connectionType^>ESS^</connectionType^>
echo     ^<connectionMode^>manual^</connectionMode^>
echo     ^<MSM^>
echo         ^<security^>
echo             ^<authEncryption^>
echo                 ^<authentication^>WPA2PSK^</authentication^>
echo                 ^<encryption^>AES^</encryption^>
echo                 ^<useOneX^>false^</useOneX^>
echo             ^</authEncryption^>
echo             ^<sharedKey^>
echo                 ^<keyType^>passPhrase^</keyType^>
echo                 ^<protected^>false^</protected^>
echo                 ^<keyMaterial^>%TEST_PASS%^</keyMaterial^>
echo             ^</sharedKey^>
echo         ^</security^>
echo     ^</MSM^>
echo ^</WLANProfile^>
) > "%TEMP_PROFILE%"

REM Delete old test profile
netsh wlan delete profile name="%SSID%_TEST" >nul 2>&1

REM Add new profile
netsh wlan add profile filename="%TEMP_PROFILE%" >nul 2>&1

REM Try to connect
netsh wlan connect name="%SSID%_TEST" ssid="%SSID%" >nul 2>&1

REM Wait for connection attempt
timeout /t 6 /nobreak >nul

REM Check if connected to the specific SSID
netsh wlan show interfaces | findstr /C:"State" > "%TEMP%\wifi_state.txt"
netsh wlan show interfaces | findstr /C:"SSID" >> "%TEMP%\wifi_state.txt"

type "%TEMP%\wifi_state.txt" | findstr /C:"connected" >nul
if !errorlevel! neq 0 (
    echo [Result] Failed - Not connected
    echo.
    exit /b 1
)

type "%TEMP%\wifi_state.txt" | findstr /C:"%SSID%" >nul
if !errorlevel! neq 0 (
    echo [Result] Failed - Connected but to different network
    echo.
    exit /b 1
)

echo.
echo ============ SUCCESS ============
echo Working password: %TEST_PASS%
echo Description: %TEST_DESC%
echo =================================
exit /b 0

:end
:cleanup
if exist "%TEMP_PROFILE%" del "%TEMP_PROFILE%" >nul 2>&1
if exist "%TEMP%\wifi_state.txt" del "%TEMP%\wifi_state.txt" >nul 2>&1
netsh wlan delete profile name="%SSID%_TEST" >nul 2>&1
echo.
echo Script completed.
pause
exit /b 0
