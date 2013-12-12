# Tests Test::Prima

use strict;
use warnings;
use Prima;

use Test::More;
use Test::Builder::Tester;
use Test::Prima;

#### is_prima_color ####

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


#### is_prima_image ####

eval { is_prima_image(undef, undef, 'Undefined value in expected slot croaks') }
or pass('Undefined value in expected slot croaks');
like($@, qr/Expected value is not defined/,
	'Undefined value in expected slot explains why it croaks');
eval { is_prima_image(undef, 'foo', 'Unblessed value in expected slot croaks') }
or pass('Unblessed value in expected slot croaks');
like($@, qr/Expected value is not a Prima::Image/,
	'Unblessed value in expected slot explains why it croaks');
eval { is_prima_image(undef, bless({}, 'bar'),
	'Non-image value in expected slot croaks') }
or pass('Non-image value in expected slot croaks');
like($@, qr/Expected value is not a Prima::Image/,
	'Non-image value in expected slot explains why it croaks');

my $image1 = Prima::Image->new(width => 10, height => 11);

test_out('ok 1 - Prima images look the same');
is_prima_image($image1, $image1);
test_test('Comparison of an image with itself passes');

test_out('not ok 1 - Prima images look the same');
test_fail(+2);
test_err('/#\s*Got undefined value where expected a defined value/');
is_prima_image(undef, $image1);
test_test('Undefined value in $got slot fails with good explanation');

test_out('not ok 1 - Prima images look the same');
test_fail(+2);
test_err('/#\s*Got value (.*) is not a Prima::Image/');
is_prima_image('hello', $image1);
test_test('Unblessed value in $got slot fails with good explanation');

test_out('not ok 1 - Prima images look the same');
test_fail(+2);
test_err('/#\s*Got value (.*) is not a Prima::Image/');
is_prima_image(bless({}, 'bar'), $image1);
test_test('Non-image object in $got slot fails with good explanation');

my $image_bad_x = Prima::Image->new(width => 12, height => 11);
test_out('not ok 1 - Prima images look the same');
test_fail(+4);
test_err('/#\s*Image size mismatch/');
test_err('/#\s*got: 12x11/');
test_err('/#\s*expected: 10x11/');
is_prima_image($image_bad_x, $image1);
test_test('Fails on width mismatch');

my $image_bad_y = Prima::Image->new(width => 10, height => 12);
test_out('not ok 1 - Prima images look the same');
test_fail(+4);
test_err('/#\s*Image size mismatch/');
test_err('/#\s*got: 10x12/');
test_err('/#\s*expected: 10x11/');
is_prima_image($image_bad_y, $image1);
test_test('Fails on height mismatch');

my $image2 = Prima::Image->new(width => 10, height => 11);
test_out('ok 1 - Prima images look the same');
is_prima_image($image2, $image1);
test_test('Two fresh images with same dimensions look the same');

my ($x, $y) = (int(rand(10)), int(rand(11)));
$image2->pixel($x, $y, cl::Blue);
$image1->pixel($x, $y, cl::White);
test_out('not ok 1 - Prima images look the same');
test_fail(+4);
test_err("/#\\s*Pixel values disagree at \\($x, $y\\)/");
test_err('/#\s*got: .*/');
test_err('/#\s*expected: .*/');
is_prima_image($image2, $image1);
test_test('Pixel mismatches are correctly identified');

# Set $image2 to agree with $image1, and then randomly change various pixel
# values
$image2->pixel($x, $y, cl::White);
for (1 .. 100) {
	($x, $y) = (int(rand(10)), int(rand(11)));
	my $color = int(rand(cl::White));
	$image1->pixel($x, $y, $color);
	$image2->pixel($x, $y, $color);
}
test_out('ok 1 - Prima images look the same');
is_prima_image($image2, $image1);
test_test('Two images with random but identical pixel colors pass');

$image1->clear;
$image2->clear;
my ($x2, $y2) = (int(rand(10)), int(rand(11)));
$image1->line($x, $y, $x2, $y2);
$image2->line($x, $y, $x2, $y2);
test_out('ok 1 - Prima images look the same');
is_prima_image($image2, $image1);
test_test('Two images with identical line draws pass')
	or diag("Draw line from ($x, $y) to ($x2, $y2)");

# TODO: check that two images with different image formats still agree


done_testing;
