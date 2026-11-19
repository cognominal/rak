use Test;
use lib $?FILE.IO.parent.add('lib');
use RakEvalProbe;

plan 3;

# Run through the rak wrapper, so RAKU_RAK_MODE=1 is set. A module is Raku,
# and so is code it EVALs: the environment variable must not reach it.

is tilde-method(), '2,3',   'EVAL in a module: ~.name is prefix ~';
is dotty-call(),   'Supply', 'EVAL in a module: .Name is a method call';

# EVAL from this (non-module) test file still follows RAKU_RAK_MODE.
is EVAL('my %h = a => 42; %h.a'), 42, 'EVAL from the test file is rak';
