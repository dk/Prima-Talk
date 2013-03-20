use strict;
use warnings;

use Prima qw(Application);
use Prima::Drawable::Subcanvas;

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

$window->insert(Widget =>
	place => { x => 0, rely => 0, relwidth => 1, relheight => 0.5, anchor => 'sw'},
	onPaint => sub {
		my ($self, $canvas) = @_;
		$canvas->clear;
		$canvas->line(200, 0, 100, 100);
	},
);

# Create an image with the same dimensions and draw to it
Prima::Timer->new(
	timeout => 100,
	onTick => sub {
		my $self = shift;
		$self->stop;
		print "Saving image\n";
		my $image = Prima::Image->new(
			height => $window->height,
			widht  => $window->width,
			type   => im::RGB,
		) or die "Could not create image: $@\n";
		$window->paint_with_widgets($image);
		$::application->yield;
		$image->save('test.png') or die "Unable to save to file: $@\n";
	},
)->start;

Prima->run;