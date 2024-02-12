if exist syg_sms.exe del syg_sms.exe
if exist error.log   del error.log

@echo off
SET PATH=d:\devel\MINGW32\BIN;d:\devel\MINGW32\LIB;d:\devel\MINGW32\INCLUDE;d:\devel\hb-MINGW32\bin;d:\devel\hb-MINGW32\lib;d:\devel\hb-MINGW32\include;%PATH%
SET INCLUDE=%INCLUDE%;d:\devel\MINGW32\include;d:\devel\hb-MINGW32\include;d:\pgsql\include
SET LIB=%LIB%;d:\devel\MINGW32\lib;d:\devel\hb-MINGW32\lib
SET HB_PATH=d:\devel\hb-MINGW32
SET HRB_DIR=d:\devel\hb-MINGW32
::SET HB_INC_PGSQL=d:\pgsql\include
::SET HB_WITH_PGSQL=d:\pgsql\include

hbmk2 syg_sms.hbp > error.log 2>&1
if errorlevel 1 goto BUILD_ERR

:BUILD_OK
   if exist syg_sms.exe start syg_sms.exe
   goto EXIT


:BUILD_ERR
   notepad error.log
   goto EXIT
