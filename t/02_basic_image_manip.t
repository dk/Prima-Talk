# Some of my tests have made me a bit uncertain about how the different aspects
# of the Drawable API interact. This set of tests ensures that my understanding
# is correct.

use strict;
use warnings;
use Test::More;
use Test::Prima;
use Prima;

# This will use random numbers to produce its output. Here we seed the generator
# and print the seed so that I have it for failing test reports.
my $seed = shift || time;
srand($seed);
note("Seeding random generator with $seed");

my ($w, $h) = (100, 110);
my $rand_fore_color = int(rand(cl::White));
my $rand_back_color = int(rand(cl::White));
# Make sure our backColor is not pure black
$rand_back_color++ if $rand_back_color < 1;

my $image1 = Prima::Image->new(
	width => $w, height => $h,
	backColor => $rand_back_color,
	color => $rand_back_color,
);

# First thing's first: the canvas does not arrive pre-cleared to the background
# color, it arrives set to zeros (i.e. black).

my ($x, $y) = (rand($w), rand($h));
is_prima_color($image1->pixel($x, $y), 'Black',
	'Initial background color is always Black');

# Clear only works when the canvas is in a paint state.

$image1->clear;
($x, $y) = (rand($w), rand($h));
is_prima_color($image1->pixel($x, $y), 'Black',
	'Clear without begin_paint does nothing');

$image1->begin_paint;
$image1->clear;
$image1->end_paint;
($x, $y) = (rand($w), rand($h));
is_prima_color($image1->pixel($x, $y), $rand_back_color,
	'Clear after begin_paint sets background to pre-set background color');

# Clear the image to a black background
$image1->backColor(cl::Black);
$image1->begin_paint;
$image1->clear;
$image1->end_paint;
($x, $y) = (rand($w), rand($h));
is_prima_color($image1->pixel($x, $y), 'Black', 'Reset background to black');
$image1->backColor($rand_back_color);

# Do things change when we apply clipRect?
$image1->begin_paint;
my ($left, $bottom, $right, $top)
	= ($w/4+rand($w/2), $h/4+rand($h/2), $w/4+rand($w/2), $h/4+rand($h/2));
$image1->clipRect($left, $bottom, $right, $top);
$image1->clear;
$image1->end_paint;
# Sample outside and inside the clipRect
($x, $y) = (($left + $right)/2, ($bottom + $top)/2);
is_prima_color($image1->pixel($x, $y), $rand_back_color,
	'Clear sets to background color within a clipRect');
is_prima_color($image1->pixel(0, 0), 'Black',
	'Clear does not set the background color outside a clipRect');

# Now flip the colors. Clear with the fll clipRect and then with a restricted
# clipRect. The second clear should have no effect, since it will set the color
# to the exact same value just set by the first full-canvas clear.
# Swap the colors
($rand_fore_color, $rand_back_color) = ($rand_back_color, $rand_fore_color);
$image1->backColor($rand_back_color);
$image1->color($rand_fore_color);
$image1->begin_paint;
# Clear the full canvas
$image1->clipRect(0, 0, $image1->size);
$image1->clear;
is_prima_color($image1->pixel($x, $y), $rand_back_color,
	'Full-canvas clear works as expected within eventual clipped region');
is_prima_color($image1->pixel(0, 0), $rand_back_color,
	'Full-canvas clear works as expected outside eventual clipped region');
# Clear the subcanvas
$image1->clipRect($left, $bottom, $right, $top);
$image1->clear;
$image1->end_paint;
is_prima_color($image1->pixel($x, $y), $rand_back_color,
	'Clipped clear does not screw up region inseide the clip');
is_prima_color($image1->pixel(0, 0), $rand_back_color,
	'Clipped clear does not screw up region outside the clip');

done_testing;
