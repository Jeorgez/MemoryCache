#!/bin/bash

depend=( AnyEvent::HTTPD AnyEvent::Tools Coro MIME::Types DBD::SQLite)

for i in "${depend[@]}"
do
export PERL_MM_USE_DEFAULT=1 && perl -MCPAN -e "install ${i}"
done

perl Makefile.PL
make
make install
make test TEST_VERBOSE=1