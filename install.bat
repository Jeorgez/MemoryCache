@ECHO off
set CURRENT_PATH=%CD%
cd %~dp0

set list=AnyEvent::HTTPD, AnyEvent::Tools, Coro MIME::Types, DBD::SQLite

for %%i in (%list%) do perl -MCPAN -e "install %%i"

perl Makefile.PL
dmake
dmake install
dmake test TEST_VERBOSE=1
cd %CURRENT_PATH%