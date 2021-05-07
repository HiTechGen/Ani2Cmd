@Echo Off & Setlocal EnableDelayedExpansion
@Title Ani2Cmd
Chcp 65001 >Nul
Mode Con:Cols=100 Lines=25
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
    For /f "Skip=1 Tokens=1,3" %%A In ('Wmic path Win32_VideoController get VideoModeDescription') Do FFmpeg.exe -i "source\!video!.mp4" -y -q:v 0 -s %%Ax%%B "!tmp!/seq/F%%d.jpg"
    For %%A In (!tmp!\seq\*.jpg) Do Set /a "jpg+=1"
    For /l %%A In (1,2,!jpg!) Do Del /s /f /q "!tmp!\seq\F%%A.jpg" >Nul
    For /l %%A In (2,2,!jpg!) Do FFmpeg.exe -i "!tmp!\seq\F%%A.jpg" -y -q:v 0 -s 640x360 "!tmp!/seq/M%%A.jpg"
    If Not Exist "source" Md "source"
    Powershell compress-archive "!tmp!\seq\*.jpg" "source/zipping.zip"
    Ren "source\zipping.zip" "!video!.zip"
    Set "jpg="
    Set "video="
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
    Powershell expand-archive -path "source\unzipping.zip" -destinationpath "!tmp!/seq"
    Ren "source\unzipping.zip" "!video!.zip"
    Set "video="
) Else Goto :Menu
Cls
Echo.Do you want fullscreen play? (y/n).
Choice /cs /c:yn /n >Nul
If !errorlevel! Equ 1 (Set "fs=F") Else If !errorlevel! Equ 2 Set "fs=M"
Mode Con:Cols=640 Lines=360
Pixelfnt.exe 1
For /f "Skip=1 Tokens=1,3" %%A In ('Wmic path Win32_VideoController get VideoModeDescription') Do Set /a "rs=%%A-%%B"
For /l %%. In () Do (
    Set /a "seq=0,fr=8,ms=0,ss=0,mn=0,hr=0"
    For %%A In (!tmp!\seq\*.jpg) Do Set /a "seq+=1"
    For /l %%A In (2,2,!seq!) Do (
        Cmddraw.exe /dimg "!tmp!\seq\!fs!%%A.jpg" /x 0 /y 0
        If !ms! Equ !fr! (
            Call Getdim.bat lines cols >Nul 2>&1
            Set /a "fr+=15,ss+=1,con=!cols!-!lines!"         
            If /i "!fs!" == "F" If !con! Neq !rs! Fstoggle.exe 1
            If /i "!fs!" == "M" If !con! Neq 280 Mode Con:Cols=640 Lines=360
            If !ss! Equ 60 Set /a "mn+=1,ss=0"
            If !mn! Equ 60 Set /a "hr+=1,mn=0"
        ) Else (
            If !ss! Leq 9 (Set "tsz1=0") Else If !ss! Geq 10 Set "tsz1="
            If !mn! Leq 9 (Set "tsz2=0") Else If !mn! Geq 10 Set "tsz2="
            If !hr! Leq 9 (Set "tsz3=0") Else If !hr! Geq 10 Set "tsz3="
            Set /a "ms=%%A/2"
        )
        If /i "!fs!" == "M" (
            If %%A Equ 2 Set /a "seq=!seq!/2"
            Title Ani2Cmd ^| !tsz3!!hr!:!tsz2!!mn!:!tsz1!!ss! ^| !seq!:!ms! ^| !cols!x!lines!
        ) 
    )
)