@echo off
if "%~2"=="" goto usage
if not "%~3"=="" if "%~5"=="" goto usage

set source_path=%~1
set destination_path=%~2
set gmail_address=%~3
set base-64_enc_password=%~4
set recpt_addr=%~5
set subject_prefix=%~6
set drive_letter=%source_path:~0,2%
set tmp_mount=%drive_letter%\temp-%random%
set shadow_source_path=%tmp_mount%\%source_path:~3%
if defined subject_prefix set email_subject=%subject_prefix%: %computername%
set shadow_volume=
set ShadowID=

if not exist "%source_path%" call :fail 0 & exit /b 100

for /f "tokens=1,2 delims=:" %%a in ('vssadmin Create Shadow /For^=%drive_letter% /AutoRetry^=3') do (
	echo %%a | findstr /c:"Shadow Copy ID" > nul && (
		set ShadowID=%%b
	)
	echo %%a | findstr /c:"Shadow Copy Volume Name" > nul && (
		set shadow_volume=%%b
	)
)

if not defined ShadowID call :fail 1 & exit /b 120
if not defined shadow_volume call :fail 2 & exit /b 120
set ShadowID=%ShadowID: =%
set shadow_volume=%shadow_volume: =%

mklink /d "%tmp_mount%" "%shadow_volume%" > nul
if not %errorlevel%==0 call :fail 3 & exit /b 130

robocopy "%shadow_source_path%" "%destination_path%" /MIR /FFT /W:1 /R:5 /XJD /SL /MT > nul
if %errorlevel% equ 16 (
	robocopy "%shadow_source_path%" "%destination_path%" /MIR /FFT /W:1 /R:5 /XJD /SL > nul
)
if %errorlevel% gtr 7 call :fail 4 & exit /b 140

robocopy "%shadow_source_path%" "%destination_path%" /E /Copy:S /IS /IT /W:1 /R:5 /XJD /SL /MT > nul
if %errorlevel% equ 16 (
	robocopy "%shadow_source_path%" "%destination_path%" /E /Copy:S /IS /IT /W:1 /R:5 /XJD /SL > nul
)
if %errorlevel% gtr 7 call :fail 5 & exit /b 150

rd "%tmp_mount%"
vssadmin delete shadows /shadow=%ShadowID% /quiet > nul

exit /b 0

----------------------------------------------------

:fail
if %1==0 set err=The source does not exist.
if %1==1 set err=Failed to create volume shadow copy.
if %1==2 set err=Failed to locate the shadow copy volume name.
if %1==3 (
           vssadmin delete shadows /shadow=%ShadowID% /quiet > nul
           set err=Failed to create symbolic link to volume shadow copy.
         )
if %1==4 (
           rd "%tmp_mount%"
           vssadmin delete shadows /shadow=%ShadowID% /quiet > nul
           set err=Failed to copy files to the destination.
         )
if %1==5 (
           rd "%tmp_mount%"
           vssadmin delete shadows /shadow=%ShadowID% /quiet > nul
           set err=Failed to copy the file ACL information to the destination.
         )
if defined gmail_address call :send_email "%err%"
echo %err%
goto :EOF

----------------------------------------------------

:send_email
set body=%~1

powershell -command $SMTPClient = New-Object Net.Mail.SmtpClient('smtp.gmail.com', 587); ^
                    $SMTPClient.EnableSsl = $true; ^
                    $SMTPClient.Credentials = New-Object System.Net.NetworkCredential('%gmail_address%', ^
                       [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('%base-64_enc_password%'))); ^
                    $SMTPClient.Send('%gmail_address%', '%recpt_addr%', '%email_subject%', '%body%');
goto :EOF

----------------------------------------------------

:usage
echo Usage:
echo %~n0 ^<src_path^> ^<dest_path^> [gmailAddr] [enc_pwd] [recpt_addr] [prefix]
exit /b 1
