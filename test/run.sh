#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
make compile_nif
mkdir -p ebin
erlc +debug_info -I include -o ebin src/*.erl test/integrity_test_SUITE.erl
cp src/elocaltime.app.src ebin/elocaltime.app
erl -noshell -pa ebin -eval '
    []=integrity_test_SUITE:init_per_suite([]),
    [{elocaltime_tests,_,Tests}]=integrity_test_SUITE:groups(),
    lists:foreach(fun(Test)->true=apply(integrity_test_SUITE,Test,[[]]) end,Tests),
    io:format("Native integrity suite: ~p cases passed on OTP ~s~n",[length(Tests),erlang:system_info(otp_release)]),
    halt().'
