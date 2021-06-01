@Echo Off & Setlocal EnableDelayedExpansion
@Title Ani2Cmd
Pushd "%~dp0"
Chcp 65001 >Nul
Mode 100,25
:Menu
Cls
Echo.(1) Extract or Play Animation
Echo.(2) Convert MP4 To Animation
Echo.(x) Delete Previous Animation
Choice /cs /c:12x /n >Nul
If !errorlevel! Equ 1 Goto :Unzip
If !errorlevel! Equ 2 Goto :Conv
If !errorlevel! Equ 3 (
    If Exist "!tmp!\seq" Del /s /f /q "!tmp!\seq\*.jpg" >Nul 2>&1
    Rd "!tmp!\seq" >Nul 2>&1
    Goto :Menu
)
:Conv
If Exist "source\*.mp4" (
    Set "video="
    Cls
    Echo.[List of unconverted video]
    Echo.
    For /f "Tokens=*" %%A In ('Dir /b "source"') Do If /i "%%~xA" == ".mp4" Echo.• %%~nA
    Echo.
    Echo.^<Leave the input empty to return^>
    Set /p "video=Video name » "
    If Not Defined video Goto :Menu
    If Not Exist "source\!video!.mp4" Goto :Conv
    If Exist "source\!video!.zip" Goto :Conv
    If Not Exist "!tmp!\seq" Md "!tmp!/seq"
    Del /s /f /q "!tmp!\seq\*.jpg" >Nul 2>&1
    For /f "Skip=1 Tokens=1,3" %%A In ('Wmic path Win32_VideoController get VideoModeDescription') Do Start /b /w "" FFmpeg.exe -i "source\!video!.mp4" -y -q:v 0 -r 30 -s %%Ax%%B "!tmp!/seq/F%%d.jpg"
    Start /b /w "" FFmpeg.exe -i "source\!video!.mp4" -y -q:v 0 -r 30 -s 640x360 "!tmp!/seq/M%%d.jpg"
    For %%A In (!tmp!\seq\*.jpg) Do Set /a "jpg+=1"
    For /l %%A In (1,2,!jpg!) Do (
        If Exist "!tmp!\seq\F%%A.jpg" Del /s /f /q "!tmp!\seq\F%%A.jpg" >Nul
        If Exist "!tmp!\seq\M%%A.jpg" Del /s /f /q "!tmp!\seq\M%%A.jpg" >Nul
    )
    If Not Exist "source" Md "source"
    Start /b /w "" Powershell compress-archive "!tmp!\seq\*.jpg" "source/zipping.zip"
    Ren "source\zipping.zip" "!video!.zip"
    Set "jpg="
) Else Goto :Menu
:Unzip
If Not Exist "!tmp!\seq\*.jpg" If Exist "source\*.zip" (
    Cls
    Echo.[List of available archived video]
    Echo.
    For /f "Tokens=*" %%A In ('Dir /b "source"') Do If /i "%%~xA" == ".zip" Echo.• %%~nA
    Echo.
    Echo.^<Leave the input empty to return^>
    Set /p "video=Video name » "
    If Not Defined video Goto :Menu
    If Not Exist "source\!video!.zip" Goto :Unzip
    If Not Exist "!tmp!\seq" Md "!tmp!/seq"
    Ren "source\!video!.zip" "unzipping.zip"
    Start /b /w "" Powershell expand-archive -path "source\unzipping.zip" -destinationpath "!tmp!/seq"
    Ren "source\unzipping.zip" "!video!.zip"
) Else Goto :Menu
Set "video="
Cls
Echo.Do you want fullscreen play? (y/n).
Choice /cs /c:yn /n >Nul
If !errorlevel! Equ 1 (Set "fs=F") Else If !errorlevel! Equ 2 (
    Mode 640,360
    Set "fs=M"
)
Pixelfnt.exe 1
For /f "Skip=1 Tokens=1,3" %%A In ('Wmic path Win32_VideoController get VideoModeDescription') Do Set /a "rs=%%A-%%B,seq=2"
For /l %%. In () Do (
    If !seq! Equ 2 (
        Set /a "fr=20,total=0"
        For %%A In (!tmp!\seq\*.jpg) Do Set /a "total+=1"
    )
    If !seq! Geq !fr! (
        Call Getdim.bat lines cols >Nul 2>&1
        Set /a "fr=!seq!!op!20,con=!cols!-!lines!"
        If /i "!fs!" == "F" If !con! Neq !rs! Start /b /w "" Fstoggle.exe 1
        If /i "!fs!" == "M" If !con! Neq 280 Mode 640,360
    )
    If Exist "!tmp!\seq\!fs!!seq!.jpg" (Set /a "seq!op!=2") Else If Not Exist "!tmp!\seq\!fs!!seq!.jpg" Set "seq=2"
    Set "op=+"
    Start /b /w "" Cmddraw.exe /dimg "!tmp!\seq\!fs!!seq!.jpg" /x 0 /y 0
    Start /b /w "" Batbox.exe /k_
    If !errorlevel! Equ 330 Set "op=-"
    If !errorlevel! Equ 332 Set /a "seq+=50"
    If !errorlevel! Equ 27 (Start /i "" ani2cmd.bat & Exit)
    If !errorlevel! Equ 32 (
        If !seq! Lss !total! Pause >Nul
        If !seq! Equ !total! Set /a "seq=2"
    )
    Title Ani2Cmd [!total!:!seq!] !cols!x!lines!
    If !seq! Lss 2 (Set "seq=2") Else If !seq! Equ !total! Set /a "seq-=2"
)