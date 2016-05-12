A very reliable windows copy tool, uses VSS to take a snapshot, and RoboCopy to mirror a folder and it's ACL, it sends an email on any failure with description of the problem


Usage:

reliaCopy <src_path> <dest_path> [gmailAddr] [enc_pwd] [recpt_addr] [prefix]

src_path: What you want to copy (the fully qualified path) must be local NTFS (because VSS)

dest_path: The destination location (the fully qualified path) can be a UNC path

gmailAddr: optional: gmail address to send failure notices from

enc_pwd: optional (required if gmailAddr is provided) the base64 encoded gmail account password (surround it with quotes)

recpt_addr: optional (required if gmailAddr is provided) the address to which to send failure notices

prefix: optional: A prefix to add to the subject line of the email to better identify the specific job

Example:

reliaCopy "C:\Program Files\Microsoft SQL Server\MSSQL13.X" "\\\server01\backups" rcpt@gmail.com "cGFzcw==" whoever@whatever.com SQL-DB


NOTE: to base64 encode the password, there are online tools:
https://www.base64encode.org/

NOTE2: Due to a windows bug, the following hotfox may be needed:
https://support.microsoft.com/en-us/kb/2695888
