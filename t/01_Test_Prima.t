# Tests Test::Prima

use strict;
use warnings;
use Prima qw(Application Label);

use Test::More tests => 7;
use Test::Builder::Tester;
use Test::Prima;

test_out('ok 1 - Prima colors are equal');
is_prima_color(cl::Green, cl::Green);
test_test('Identical numerical colors');

test_out('ok 1 - Prima colors are equal');
is_prima_color(cl::Green, 'Green');
test_test('Color names are acceptable');

test_out('not ok 1 - Prima colors are equal');
test_fail(+2);
test_err('/#\s*Got undefined value where expected a defined value/');
is_prima_color(undef, cl::Green);
test_test('Undefined $got fails');

test_out('not ok 1 - Prima colors are equal');
test_fail(+2);
test_err('/#\s*Got value \(.*\) that does not look like a Prima color/');
is_prima_color('foo', cl::Green);
test_test('Bad color value fails');

eval { is_prima_color(cl::White, 'blue', 'Nonexistent color names croak') }
or pass('Nonexistent color names croak');

test_out('not ok 1 - Prima colors are equal');
test_fail(+4);
test_err('/#\s*Prima color mismatch/');
test_err(sprintf '/#\s*got: %06x/', cl::Green);
test_err(sprintf '/#\s*expected: %06x/', cl::Blue);
is_prima_color(cl::Green, cl::Blue);
test_test('Color mismatch is clearly explained');

test_out('not ok 1 - Prima colors are equal');
test_fail(+4);
test_err('/#\s*Prima color mismatch/');
test_err(sprintf('/#\s*got: %06x/', cl::Green));
test_err(sprintf('/#\s*expected: %06x \(Blue\)/', cl::Blue));
is_prima_color(cl::Green, 'Blue');
test_test('Named colors are used if available');



