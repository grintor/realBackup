@echo off
if "%2"=="" echo Usage: %~n0 "<full path to source>" "<full path to destination>" & exit /b 1

set source_path=%~1
set destination_path=%~2
set drive_letter=%source_path:~0,2%
set tmp_mount=%cd%\%random%
set shadow_source_path=%tmp_mount%\%source_path:~3%

for /f "tokens=1,2,* delims=;= " %%a in ('wmic shadowcopy call create "ClientAccessible"^,"%drive_letter%\"') do set %%a=%%~b
if not '%ReturnValue%'=='0' goto :fail1

for /f "tokens=2 delims=?" %%a in ('vssadmin list shadows /shadow^=%ShadowID% ^| find "\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy"') do set shadow_volume=\\?%%a\
if '%shadow_volume%'=='' goto :fail2

mklink /d "%tmp_mount%" "%shadow_volume%" > nul
if not %errorlevel%==0 goto :fail3

robocopy "%shadow_source_path%" "%destination_path%" /MIR /FFT > nul
if %errorlevel% gtr 1 goto :fail4

robocopy "%shadow_source_path%" "%destination_path%" /E /Copy:S /IS /IT > nul
if %errorlevel% gtr 1 goto :fail5

rd "%tmp_mount%"
vssadmin delete shadows /shadow=%ShadowID% /quiet > nul

::call :send_email %computername% "backup success"
exit /b 0

----------------------------------------------------

:fail1
set err=failed to create volume shadow copy
echo %err%
call :send_email %computername% "%err%"
exit /b 100

:fail2
set err=failed to get a shadow copy volume name
echo %err%
call :send_email %computername% "%err%"
exit /b 200

:fail3
set err=failed to create symbolic link to volume shadow copy
echo %err%
call :send_email %computername% "%err%"
vssadmin delete shadows /shadow=%ShadowID% /quiet
exit /b 300

:fail4
set err=failed to copy files to the destination
echo %err%
call :send_email %computername% "%err%"
rd "%tmp_mount%"
vssadmin delete shadows /shadow=%ShadowID% /quiet
exit /b 400

:fail5
set err=failed to copy the file ACL information to the destination
echo %err%
call :send_email %computername% "%err%"
rd "%tmp_mount%"
vssadmin delete shadows /shadow=%ShadowID% /quiet
exit /b 500

------------------------------------------------------

:send_email
set pwd=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("REDACTED=="))
set subject=%~1
set body=%~2

echo $SMTPClient = New-Object Net.Mail.SmtpClient("smtp.gmail.com", 587); >> email.ps1
echo $SMTPClient.EnableSsl = $true; >> email.ps1
echo $SMTPClient.Credentials = New-Object System.Net.NetworkCredential("alerts@georgiatc.com", %pwd%); >> email.ps1
echo $SMTPClient.Send("alerts@georgiatc.com", "support@gmail.com", "%subject%", "%body%"); >> email.ps1
PowerShell.exe -ExecutionPolicy ByPass -file "%cd%\email.ps1"
del email.ps1
goto :EOF


