use strict;
use warnings;

use Prima qw(Application);

my $wDisplay = Prima::MainWindow-> create(
	text    => 'Clipping test',
	backColor => cl::White,
	onPaint => sub {
		my ( $self, $canvas) = @_;
		$canvas->clear;
		$canvas->clipRect(-1 , -1, -1, -1);
		$canvas->line(0, 0, 500, 500);
	},
	width => 600,
	height => 600,
);

package test;

{
	no strict 'refs';
	*{'foo'} = sub { print "Hello!\n" };
}

package main;

test::foo();

my $method_name = 'width';
print "Got width ", $wDisplay->$method_name(), "\n";

run Prima;
