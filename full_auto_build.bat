@echo off
setlocal enabledelayedexpansion
title Full Auto Install & Build Aseprite v1.3.18.2

set "ORIG_PATH=%PATH%"
set "WORK_DIR=%~dp0"
if "%WORK_DIR:~-1%"=="\" set "WORK_DIR=%WORK_DIR:~0,-1%"
cd /d "%WORK_DIR%"

:CHECK_VS
set "PATH=%ORIG_PATH%"
echo ========================================================
echo [1/6] Kiem tra Visual Studio, C++ Build Tools va Windows SDK...
echo ========================================================

set "VS_INSTALLER=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vs_installer.exe"
set "VSWHERE_DIR=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"

if not exist "%VSWHERE_DIR%\vswhere.exe" (
    echo.
    echo [CHUA DU DIEU KIEN] Khong tim thay Visual Studio tren may tinh!
    echo Vui long thuc hien cac buoc sau de tiep tuc:
    echo   1. Tai va cai dat Visual Studio Community [hoac Build Tools for Visual Studio].
    echo   2. Trong trinh cai dat, tich chon muc: "Desktop development with C++".
    echo   3. Dam bao ben cot phai da chon san "MSVC C++ x64/x86 build tools" va "Windows 10/11 SDK".
    echo.
    echo Sau khi cai dat xong, nhan phim bat ky tai day de kiem tra lai...
    pause >nul
    goto :CHECK_VS
)

set "ANY_VS="
set "VS_PATH="
pushd "%VSWHERE_DIR%"
for /f "usebackq tokens=*" %%i in (`vswhere.exe -latest -prerelease -products * -property installationPath`) do (
    set "ANY_VS=%%i"
)
for /f "usebackq tokens=*" %%i in (`vswhere.exe -latest -prerelease -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
    set "VS_PATH=%%i"
)
popd

if not defined ANY_VS (
    echo.
    echo [CHUA DU DIEU KIEN] Chua co phien ban Visual Studio nao duoc cai dat!
    echo Hay cai dat Visual Studio kem goi "Desktop development with C++", sau do nhan phim bat ky de kiem tra lai...
    if exist "%VS_INSTALLER%" start "" "%VS_INSTALLER%"
    pause >nul
    goto :CHECK_VS
)

if not defined VS_PATH (
    echo.
    echo [CHUA DU DIEU KIEN] Da tim thay Visual Studio tai: "%ANY_VS%"
    echo Tuy nhien ban CHUA CAI bo cong cu bien dich C++!
    echo Vui long thuc hien:
    echo   1. Mo Visual Studio Installer [dang tu dong mo neu co san].
    echo   2. Bam nut "Modify" [Sua doi] o phien ban Visual Studio cua ban.
    echo   3. Tich chon o "Desktop development with C++" roi bam "Modify" o goc duoi ben phai de cai dat.
    echo.
    echo Sau khi Visual Studio Installer cai xong, nhan phim bat ky tai day de tiep tuc...
    if exist "%VS_INSTALLER%" start "" "%VS_INSTALLER%"
    pause >nul
    goto :CHECK_VS
)

call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [CHUA DU DIEU KIEN] Khong the kich hoat moi truong C++ x64!
    echo Hay mo Visual Studio Installer, chon "Repair" hoac kiem tra lai goi "Desktop development with C++".
    echo Nhan phim bat ky de kiem tra lai...
    pause >nul
    goto :CHECK_VS
)

where cl.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [CHUA DU DIEU KIEN] Thieu trinh bien dich C++ [cl.exe]!
    echo Hay mo Visual Studio Installer =^> Modify =^> Tich chon "Desktop development with C++".
    echo Sau khi cai xong, nhan phim bat ky de kiem tra lai...
    if exist "%VS_INSTALLER%" start "" "%VS_INSTALLER%"
    pause >nul
    goto :CHECK_VS
)

where rc.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [CHUA DU DIEU KIEN] Da co C++ nhung thieu Windows SDK [rc.exe]!
    echo Hay mo Visual Studio Installer =^> Modify =^> Tab "Individual components" =^> Tich chon "Windows 11 SDK" [hoac Windows 10 SDK].
    echo Sau khi cai xong, nhan phim bat ky de kiem tra lai...
    if exist "%VS_INSTALLER%" start "" "%VS_INSTALLER%"
    pause >nul
    goto :CHECK_VS
)

echo - Da xac nhan Visual Studio va C++ day du tai: "%VS_PATH%"

echo ========================================================
echo [2/6] Kiem tra va cai dat CMake...
echo ========================================================
set "CMAKE_EXE="
for /f "delims=" %%i in ('where cmake 2^>nul') do if not defined CMAKE_EXE set "CMAKE_EXE=%%i"
if not defined CMAKE_EXE if exist "%ProgramFiles%\CMake\bin\cmake.exe" set "CMAKE_EXE=%ProgramFiles%\CMake\bin\cmake.exe"
if not defined CMAKE_EXE if exist "%ProgramFiles(x86)%\CMake\bin\cmake.exe" set "CMAKE_EXE=%ProgramFiles(x86)%\CMake\bin\cmake.exe"

if not defined CMAKE_EXE (
    if not exist "%WORK_DIR%\cmake-4.4.2-windows-x86_64.msi" (
        echo [LOI] Khong tim thay file cmake-4.4.2-windows-x86_64.msi!
        pause
        exit /b 1
    )
    echo Dang cai dat CMake - Vui long bam YES neu cua so UAC hien len...
    powershell -NoProfile -Command "Start-Process msiexec.exe -ArgumentList '/i', '\"%WORK_DIR%\cmake-4.4.2-windows-x86_64.msi\"', 'ADD_CMAKE_TO_PATH=System', '/qn', '/norestart' -Verb RunAs -Wait"
    if exist "%ProgramFiles%\CMake\bin\cmake.exe" set "CMAKE_EXE=%ProgramFiles%\CMake\bin\cmake.exe"
    if not defined CMAKE_EXE if exist "%ProgramFiles(x86)%\CMake\bin\cmake.exe" set "CMAKE_EXE=%ProgramFiles(x86)%\CMake\bin\cmake.exe"
)

if not defined CMAKE_EXE (
    echo [LOI] Cai dat CMake khong thanh cong hoac bi tu choi quyen Admin!
    pause
    exit /b 1
)
echo - Da san sang CMake: "%CMAKE_EXE%"

echo ========================================================
echo [3/6] Tao o dia ao chong loi duong dan dai...
echo ========================================================
set "VIRT_DRIVE="
for %%d in (Z Y X W V U T S R Q) do (
    if not defined VIRT_DRIVE (
        if not exist "%%d:\" set "VIRT_DRIVE=%%d:"
    )
)
if not defined VIRT_DRIVE (
    echo [LOI] Khong con ky tu o dia ao trong!
    pause
    exit /b 1
)
subst %VIRT_DRIVE% "%WORK_DIR%"
if %errorlevel% neq 0 (
    echo [LOI] Khong the tao o dia ao %VIRT_DRIVE%!
    pause
    exit /b 1
)
echo - Da anh xa thu muc lam viec sang o %VIRT_DRIVE%

echo ========================================================
echo [4/6] Giai nen Ninja, Skia va Ma nguon Aseprite...
echo ========================================================
if not exist "%VIRT_DRIVE%\extracted" mkdir "%VIRT_DRIVE%\extracted"

set "NINJA_EXE="
for /r "%VIRT_DRIVE%\extracted\ninja" %%f in (ninja.exe) do if exist "%%f" set "NINJA_EXE=%%f"
if not defined NINJA_EXE (
    echo - Dang giai nen ninja-win.zip...
    powershell -NoProfile -Command "Expand-Archive -Path '%VIRT_DRIVE%\ninja-win.zip' -DestinationPath '%VIRT_DRIVE%\extracted\ninja' -Force"
    for /r "%VIRT_DRIVE%\extracted\ninja" %%f in (ninja.exe) do if exist "%%f" set "NINJA_EXE=%%f"
)
if not defined NINJA_EXE (
    echo [LOI] Khong tim thay ninja.exe sau khi giai nen!
    goto :FAIL
)

set "SKIA_LIB="
for /r "%VIRT_DRIVE%\extracted\skia" %%f in (skia.lib) do if exist "%%f" set "SKIA_LIB=%%f"
if not defined SKIA_LIB (
    echo - Dang giai nen Skia-Windows-Release-x64.zip...
    powershell -NoProfile -Command "Expand-Archive -Path '%VIRT_DRIVE%\Skia-Windows-Release-x64.zip' -DestinationPath '%VIRT_DRIVE%\extracted\skia' -Force"
    for /r "%VIRT_DRIVE%\extracted\skia" %%f in (skia.lib) do if exist "%%f" set "SKIA_LIB=%%f"
)
if not defined SKIA_LIB (
    echo [LOI] Khong tim thay skia.lib sau khi giai nen!
    goto :FAIL
)
for %%i in ("%SKIA_LIB%") do set "SKIA_LIB_DIR=%%~dpi"
if "%SKIA_LIB_DIR:~-1%"=="\" set "SKIA_LIB_DIR=%SKIA_LIB_DIR:~0,-1%"
for %%i in ("%SKIA_LIB_DIR%\..\..") do set "SKIA_DIR=%%~fi"

set "SRC_DIR="
if exist "%VIRT_DRIVE%\extracted\source\CMakeLists.txt" set "SRC_DIR=%VIRT_DRIVE%\extracted\source"
if not defined SRC_DIR (
    for /d %%d in ("%VIRT_DRIVE%\extracted\source\*") do (
        if exist "%%d\CMakeLists.txt" set "SRC_DIR=%%d"
    )
)
if not defined SRC_DIR (
    echo - Dang giai nen Aseprite-v1.3.18.2-Source.zip, vui long cho 30-60 giay...
    powershell -NoProfile -Command "Expand-Archive -Path '%VIRT_DRIVE%\Aseprite-v1.3.18.2-Source.zip' -DestinationPath '%VIRT_DRIVE%\extracted\source' -Force"
    if exist "%VIRT_DRIVE%\extracted\source\CMakeLists.txt" set "SRC_DIR=%VIRT_DRIVE%\extracted\source"
    if not defined SRC_DIR (
        for /d %%d in ("%VIRT_DRIVE%\extracted\source\*") do (
            if exist "%%d\CMakeLists.txt" set "SRC_DIR=%%d"
        )
    )
)
if not defined SRC_DIR (
    echo [LOI] Khong tim thay CMakeLists.txt cua Aseprite!
    goto :FAIL
)

echo - Ninja: %NINJA_EXE%
echo - Skia:  %SKIA_DIR%
echo - Src:   %SRC_DIR%

echo ========================================================
echo [5/6] Cau hinh CMake...
echo ========================================================
if exist "%VIRT_DRIVE%\build" rmdir /s /q "%VIRT_DRIVE%\build"
mkdir "%VIRT_DRIVE%\build"
cd /d "%VIRT_DRIVE%\build"

"%CMAKE_EXE%" -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
              -DLAF_BACKEND=skia ^
              -DSKIA_DIR="%SKIA_DIR%" ^
              -DSKIA_LIBRARY_DIR="%SKIA_LIB_DIR%" ^
              -DSKIA_LIBRARY="%SKIA_LIB%" ^
              -DCMAKE_MAKE_PROGRAM="%NINJA_EXE%" ^
              -G Ninja ^
              "%SRC_DIR%"

if %errorlevel% neq 0 (
    echo [LOI] Cau hinh CMake that bai!
    goto :FAIL
)

echo ========================================================
echo [6/6] Dang bien dich Aseprite, mat khoang 5 - 15 phut...
echo ========================================================
"%NINJA_EXE%" aseprite

if %errorlevel% neq 0 (
    echo [LOI] Bien dich Ninja that bai!
    goto :FAIL
)

cd /d "%WORK_DIR%"
subst %VIRT_DRIVE% /D >nul 2>nul

echo ========================================================
echo [HOAN TAT 100%%]
echo File chay cua ban nam tai: %WORK_DIR%\build\bin\aseprite.exe
echo ========================================================
pause
exit /b 0

:FAIL
cd /d "%WORK_DIR%"
subst %VIRT_DRIVE% /D >nul 2>nul
pause
exit /b 1