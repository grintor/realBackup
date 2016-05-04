@echo off
if "%2"=="" goto usage
if not "%3"=="" if "%5"=="" goto usage

goto start
:usage
echo Usage:
echo %~n0 ^<src_path^> ^<dest_path^> [gmailAddr] [enc_pwd] [recpt_addr] [prefix]
exit /b 1

----------------------------------------------------

:start

set source_path=%~1
set destination_path=%~2
set gmail_address=%~3
set base-64_enc_password=%~4
set recpt_addr=%~5
set subject_prefix=%~6
set drive_letter=%source_path:~0,2%
set tmp_mount=%cd%\%random%
set shadow_source_path=%tmp_mount%\%source_path:~3%
if defined subject_prefix set subject_prefix=%subject_prefix%: 

if not exist "%source_path%" goto fail6

for /f "tokens=1,2,* delims=;= " %%a in ('wmic shadowcopy call create "ClientAccessible"^,"%drive_letter%\"') do set %%a=%%~b
if not '%ReturnValue%'=='0' goto fail1

for /f "tokens=2 delims=?" %%a in ('vssadmin list shadows /shadow^=%ShadowID% ^| find "\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy"') do set shadow_volume=\\?%%a\
if not defined shadow_volume goto fail2

mklink /d "%tmp_mount%" "%shadow_volume%" > nul
if not %errorlevel%==0 goto fail3

robocopy "%shadow_source_path%" "%destination_path%" /MIR /FFT > nul
if %errorlevel% gtr 1 goto fail4

robocopy "%shadow_source_path%" "%destination_path%" /E /Copy:S /IS /IT > nul
if %errorlevel% gtr 1 goto fail5

rd "%tmp_mount%"
vssadmin delete shadows /shadow=%ShadowID% /quiet > nul

exit /b 0

----------------------------------------------------

:fail1
set err=failed to create volume shadow copy
echo %err%
if defined gmail_address call :send_email "%err%"
exit /b 100

----------------

:fail2
set err=failed to get a shadow copy volume name
echo %err%
if defined gmail_address call :send_email "%err%"
exit /b 200

----------------

:fail3
set err=failed to create symbolic link to volume shadow copy
echo %err%
if defined gmail_address call :send_email "%err%"
vssadmin delete shadows /shadow=%ShadowID% /quiet > nul
exit /b 300

----------------

:fail4
set err=failed to copy files to the destination
echo %err%
if defined gmail_address call :send_email "%err%"
rd "%tmp_mount%"
vssadmin delete shadows /shadow=%ShadowID% /quiet > nul
exit /b 400

----------------

:fail5
set err=failed to copy the file ACL information to the destination
echo %err%
if defined gmail_address call :send_email "%err%"
rd "%tmp_mount%"
vssadmin delete shadows /shadow=%ShadowID% /quiet > nul
exit /b 500

----------------

:fail6
set err=the source does not exist
echo %err%
if defined gmail_address call :send_email "%err%"
exit /b 600

----------------------------------------------------

:send_email
set body=%~1

powershell -command $SMTPClient = New-Object Net.Mail.SmtpClient('smtp.gmail.com', 587); ^
                    $SMTPClient.EnableSsl = $true; ^
                    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential('%gmail_address%', ^
                       [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('%base-64_enc_password%'))); ^
                    $SMTPClient.Send('%gmail_address%', '%recpt_addr%', '%subject_prefix%%computername%', '%body%');
goto :EOF


