# Tests the functionality of Prima::Drawable::Record

use strict;
use warnings;
use Test::More;
use Prima::Drawable::Record;
use Prima;

# What does the class claim it can do?
isa_ok('Prima::Drawable::Record', 'Prima::Drawable');
can_ok('Prima::Drawable::Record', 'begin_paint');
can_ok('Prima::Drawable::Record', 'get_record');

# Create an image and build a Record wrapper around it
my $image = Prima::Image->new(width => 100, height => 100);
my $wrapper = Prima::Drawable::Record->new(canvas => $image);

# Do we have the correct isa relationships?
isa_ok($wrapper, 'Prima::Image');
isa_ok($wrapper, 'Prima::Drawable');

# Do we have methods?
can_ok($wrapper, 'begin_paint');
can_ok($wrapper, 'get_record');

# OK, let's see what we can do.
$wrapper->clear_record;
$wrapper->line(0, 0, 10, 10);
is_deeply(
	$wrapper->get_record,
	[ ['line', 0, 0, 10, 10] ],
	'Recorded the line drawing command'
);

# make sure that the subrefs returned from 'can' work correctly
$wrapper->clear_record;
my $line_subref = $wrapper->can('line');
$line_subref->($wrapper, 0, 0, 10, 10);
is_deeply(
	$wrapper->get_record,
	[ ['line', 0, 0, 10, 10] ],
	'Recorded the line drawing command via "can" subref'
);

# Make sure that the accessors path through cleanly
$wrapper->clear_record;
is($wrapper->width, 100, 'Recorder returns scalar getter cleanly');
is_deeply(
	[$wrapper->size],
	[100, 100],
	'Recorder returns array getter cleanly'
);
is_deeply(
	$wrapper->get_record,
	[ ['width'], ['size'] ],
	'Recorder records getters'
);

done_testing;

