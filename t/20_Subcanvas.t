# Tests the functionality of Prima::Drawable::Subcanvas
# This requires a working Prima::Drawable::Record.

use strict;
use warnings;
use Test::More;
use Prima::Drawable::Record;
use Prima::Drawable::Subcanvas;
use Prima qw(Application Label);
use Test::Prima;

unlink 'subcanvas.png';
unlink 'window.png';

# This will use random numbers to produce its output. Here we seed the generator
# and print the seed so that I have it for failing test reports.
my $seed = shift || time;
srand($seed);
note("Seeding random generator with $seed");

# Create a window with a collectin of embedded widgets. The embedded widgets
# invoke random paint operations, and we know that the subcanvas works if the
# raster image that it produces is identical to the parent raster image.

# Create the main window
my $extent = 600;
my $window = Prima::MainWindow->new(
	height => $extent,
	width => $extent,
);

# The way that we test this system is by creating a set of random drawing
# operations. The random values in the operations persist because we store a
# closure to the operation. We produce the closure using these generators:

my @drawing_generators = (
	sub {
		# Set the color to a random value
		my $color = int(rand(cl::White));
		return sub {
			my $widget = shift;
			$widget->color($color);
		};
	},
	sub {
		# Set the background color to a random value
		my $color = int(rand(cl::White));
		return sub {
			my $widget = shift;
			$widget->backColor($color);
		};
	},
	sub {
		# Set a random raster operation
		my @rops = (fp::Empty, fp::Solid, fp::Line, fp::LtSlash, fp::Slash,
			fp::BkSlash, fp::LtBkSlash, fp::Hatch, fp::XHatch, fp::Interleave,
			fp::WideDot, fp::CloseDot, fp::SimpleDots, fp::Borland, fp::Parquet,
		);
		my $rop = $rops[rand(@rops)];
		return sub {
			my $widget = shift;
			$widget->rop($rop);
		},
	},
	sub {
		# Clear the whole canvas
		return sub { $_[0]->clear };
	},
	sub {
		# Clear a random rectangle of the canvas
		my ($x1, $y1, $x2, $y2) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			$widget->line($w*$x1, $h*$y1, $w*$x2, $h*$y2);
		};
	},
	sub {
		# Draw a line with random end points
		my ($x1, $y1, $x2, $y2) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			$widget->line($w*$x1, $h*$y1, $w*$x2, $h*$y2);
		};
	},
	sub {
		# Draw a rectangle with random end points
		my ($x1, $y1, $x2, $y2) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			$widget->rectangle($w*$x1, $h*$y1, $w*$x2, $h*$y2);
		};
	},
	sub {
		# Draw a filled ellipse with random end points
		my ($x, $y, $xdiam, $ydiam) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			$widget->fill_ellipse($w*$x, $h*$y, $w*$xdiam, $h*$ydiam);
		};
	},
	sub {
		# Draw a random string of text at a random location
		my ($x, $y, $text) = (rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			$widget->text_out($text, $x*$w, $y*$h);
		};
	},
);

sub new_random_drawing_operation {
	return $drawing_generators[rand(@drawing_generators)]->();
}

sub add_random_widgets {
	my ($widget, $N_children) = @_;
	return if $N_children == 0;
	for (1 .. $N_children) {
		# Produce the location where we will draw the child widget.
		my ($relx, $rely, $relwidth, $relheight)
			= (rand(1), rand(1), rand(1), rand(1));
		# produce the series of drawing operations
		my @draw_ops = map { new_random_drawing_operation } (1 .. 10);
		# Add the child widget
		my $child = $widget->insert(Widget =>
			place => {
				width => 1, height => 1,
				relx => $relx, rely => $rely, anchor => 'sw',
				relwidth => $relwidth, relheight => $relheight,
			},
			onPaint => sub {
				my ($self, $canvas) = @_;
				$canvas->clear;
				for my $op (@draw_ops) {
					$op->($canvas);
				}
			},
		);
		add_random_widgets($child, $N_children - 1);
	}
}

add_random_widgets($window, 4);

# Create an image with the same dimensions and draw to it
my ($window_image, $subcanvas_image);
Prima::Timer->new(
	timeout => 1000,
	onTick => sub {
		my $self = shift;
		$self->stop;
		
		# Get a copy of the window via subcanvas
		print "Saving image\n";
		$subcanvas_image = Prima::Image->new(
			height => $window->height,
			width  => $window->width,
			type   => im::RGB,
		) or die "Could not create image: $@\n";
		$window->paint_with_widgets($subcanvas_image);
		
		# Get a direct rasterization of the window
		$window_image = $::application->get_image($window->origin, $window->size);
		
		# Exit the run-loop cleanly by throwing an exception
		die "All done";
	},
)->start;

eval { Prima->run };
die($@) unless $@ =~ /All done/;

# Do the images agree?
is_prima_image($subcanvas_image, $window_image,
	'Subcanvas faithfully produces a good image')
	or do {
		$subcanvas_image->save('subcanvas.png');
		$window_image->save('window.png');
	};

done_testing;
