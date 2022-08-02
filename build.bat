@echo off

set build_dir=%cd%/build
set source_dir=%cd%/src

set compiler=odin build "%source_dir%"
set compiler_options=-o:minimal -show-timings -build-mode:exe -debug -strict-style -verbose-errors -subsystem:console

if not exist "%build_dir%" ( mkdir "%build_dir%" )

pushd "%build_dir%"
echo %cd%
%compiler% %compiler_options% -out:th.exe

popd
