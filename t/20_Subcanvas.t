# Tests the functionality of Prima::Drawable::Subcanvas
# This requires a working Prima::Drawable::Record.

use strict;
use warnings;
use Test::More;
use Prima::Drawable::Record;
use Prima::Drawable::Subcanvas;
use Prima qw(Application Label);
use Test::Prima;

# Create a window with *two* widgets
my $window = Prima::MainWindow->new(
	height => 800,
	width => 400,
);

$window->insert(Widget =>
	place => { x => 0, rely => 0.5, relwidth => 1, relheight => 0.5, anchor => 'sw'},
	onPaint => sub {
		my ($self, $canvas) = @_;
		$canvas->clear;
		$canvas->line(0, 0, 100, 100);
	},
);

my $lower_box = $window->insert(Widget =>
	place => { x => 0, rely => 0, relwidth => 1, relheight => 0.5, anchor => 'sw'},
	onPaint => sub {
		my ($self, $canvas) = @_;
		$canvas->clear;
		$canvas->line(200, 0, 100, 100);
	},
);

$lower_box->insert(Widget =>
	place => { x => 100, y => 100, width => 200, height => 50, anchor => 'sw'},
	onPaint => sub {
		my ($self, $canvas) = @_;
		$canvas->clear;
		$canvas->text_out('Hello!', 0, 0);
	},
	backColor => cl::LightGreen,
);

# Create an image with the same dimensions and draw to it
my ($image, $recorder);
Prima::Timer->new(
	timeout => 1000,
	onTick => sub {
		my $self = shift;
		$self->stop;
		print "Saving image\n";
		$image = Prima::Image->new(
			height => $window->height,
			width  => $window->width,
			type   => im::RGB,
		) or die "Could not create image: $@\n";
		$recorder = Prima::Drawable::Record->new(canvas => $image);
		$window->paint_with_widgets($recorder);
		$image->save('test.png');
		die "All done";
	},
)->start;

eval { Prima->run };

# Check a few known pixel spots
is_prima_color($image->pixel(10, 2), 'White', 'Non-drawn pixel in bottom half of image is white');
is_prima_color($image->pixel(10, 600), 'White', 'Non-drawn pixel in top half of image is white');
is_prima_color($image->pixel(20, 420), 'Black', 'Drawn pixel in top half of image is black');
is_prima_color($image->pixel(150, 50), 'Black', 'Drawn pixel in bottom half of image is black');
is_prima_color($image->pixel(101, 148), 'LightGreen', 'Text background pixel is light green');

#############################################################################
# We now have a list of all method calls performed on $recorder. It is huge,
# trust me. To make sense of it, we get the state at the various operations
# of interest using search_record().

#### Line Drawing ####

my @line_draws = $recorder->search_record('line', apply_translate => 1);
my %found
	= map {$_ => 1}
	map {join(',', @$_)}
	map {$_->{line}}
	@line_draws;

use Data::Dumper;

is_deeply(\%found, {'0,400,100,500' => 1, '200,0,100,100' => 1},
	'Subcanvas recorded the line drawing')
		or diag(Data::Dumper->Dumper(\%found));

my ($text_state) = $recorder->search_record('text_out', apply_translate => 1);
my %text_state = %$text_state;
is_deeply($text_state{text_out},
	['Hello!', 100, 100],
	'Subcanvas properly handled text output'
);
is_prima_color($text_state{backColor}[0], 'LightGreen',
		'Subcanvas properly handles backColor');

done_testing;
