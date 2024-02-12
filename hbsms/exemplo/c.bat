@echo off
SET PATH=d:\devel\MINGW32\BIN;d:\devel\MINGW32\LIB;d:\devel\MINGW32\INCLUDE;d:\devel\hb-MINGW32\bin;d:\devel\hb-MINGW32\lib;d:\devel\hb-MINGW32\include;%PATH%
SET INCLUDE=%INCLUDE%;d:\devel\MINGW32\include;d:\devel\hb-MINGW32\include
SET LIB=%LIB%;d:\devel\MINGW32\lib;d:\devel\hb-MINGW32\lib
SET HB_PATH=d:\devel\hb-MINGW32
SET HRB_DIR=d:\devel\hb-MINGW32

if exist exemplo.exe del exemplo.exe

hbmk2 exemplo.hbp > comp_log.txt 2>&1

if exist exemplo.exe start exemplo.exe