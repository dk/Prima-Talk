# Tests the functionality of Prima::Drawable::Subcanvas

# Failes for seed 1387326203

use strict;
use warnings;
use Test::More;
use Prima::Drawable::Subcanvas;
use Prima qw(Application);
use Test::Prima;

package Prima::ImageTester;

our @ISA = qw(Prima::Image);
sub backColor {
	my $self = shift;
#	printf "Called backColor with arg %06x\n", @_;
	return $self->SUPER::backColor(@_);
}

sub clipRect {
#	print "Called clipRect with args ", join(', ', @_), "\n";
	my $self = shift;
	$self->SUPER::clipRect(@_);
}

sub clear {
#	print "Called clear with args ", join(', ', @_), "\n";
	my $self = shift;
#	printf "  background color is %06x\n", $self->SUPER::backColor;
	$self->SUPER::clear(@_);
}

package main;

unlink 'subcanvas.png';
unlink 'window.png';

sub debug_output {
	# Comment this to disable debug printing
#	goto &diag
}

# This will use random numbers to produce its output. Here we seed the generator
# and print the seed so that I have it for failing test reports.
my $seed = shift || time;
srand($seed);
note("Seeding random generator with $seed");

################### Build the generators ###################

# The way that we test this system is by creating a set of random drawing
# operations. The random values in the operations persist because we store a
# closure to the operation. We produce the closure using these generators:
my ($window_image, $subcanvas_image);

my @drawing_generators = (
	sub {
		# Set the color to a random value
		my $color = int(rand(cl::White));
		return sub {
			my $widget = shift;
			debug_output(sprintf("Setting color on $widget to %6x", $color));
			$widget->color($color);
		};
	},
	sub {
		# Set the background color to a random value
		my $color = int(rand(cl::White));
		return sub {
			my $widget = shift;
			debug_output(sprintf("Setting background color on $widget to %6x", $color));
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
			debug_output("Setting raster operation on $widget to $rop");
			$widget->rop($rop);
		},
	},
	sub {
		# Clear the whole canvas
		return sub {
			debug_output("Clearing the whole canvas $_[0]");
			debug_output(sprintf('Before clear op, pixel at (0, 0) is %6x', $subcanvas_image->pixel(0, 0)))
				if defined $subcanvas_image;
			$_[0]->clear;
			debug_output(sprintf('After clear op, pixel at (0, 0) is %6x', $subcanvas_image->pixel(0, 0)))
				if defined $subcanvas_image;
		};
	},
	sub {
		# Clear a random rectangle of the canvas
		my ($x1, $y1, $x2, $y2) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			debug_output("Clearing $widget from ($x1, $y1) to ($x2, $y2) with scaling ($w, $h)");
			debug_output(sprintf('Before clear op, pixel at (0, 0) is %6x', $subcanvas_image->pixel(0, 0)))
				if defined $subcanvas_image;
			$widget->clear($w*$x1, $h*$y1, $w*$x2, $h*$y2);
			debug_output(sprintf('After clear op, pixel at (0, 0) is %6x', $subcanvas_image->pixel(0, 0)))
				if defined $subcanvas_image;
		};
	},
	sub {
		# Draw a line with random end points
		my ($x1, $y1, $x2, $y2) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			debug_output("Drawing line on $widget from ($x1, $y1) to ($x2, $y2) with scaling ($w, $h)");
			$widget->line($w*$x1, $h*$y1, $w*$x2, $h*$y2);
		};
	},
	sub {
		# Draw a rectangle with random end points
		my ($x1, $y1, $x2, $y2) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			debug_output("Drawing rectangle on $widget from ($x1, $y1) to ($x2, $y2) with scaling ($w, $h)");
			$widget->rectangle($w*$x1, $h*$y1, $w*$x2, $h*$y2);
		};
	},
	sub {
		# Draw a filled ellipse with random end points
		my ($x, $y, $xdiam, $ydiam) = (rand(1), rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			debug_output("Drawing filled ellipse on $widget at ($x, $y) with diameters ($xdiam, $ydiam) and scaling ($w, $h)");
			$widget->fill_ellipse($w*$x, $h*$y, $w*$xdiam/2, $h*$ydiam/2);
		};
	},
	sub {
		# Draw a random string of text at a random location
		my ($x, $y, $text) = (rand(1), rand(1), rand(1));
		return sub {
			my $widget = shift;
			my ($w, $h) = $widget->size;
			debug_output("Drawing text \"$text\" on $widget at ($x, $y) with scaling ($w, $h)");
			$widget->text_out($text, $x*$w, $y*$h);
		};
	},
	sub {
		# Set the pixel of a random point to a random color
		my ($w, $h, $color) = (rand(1), rand(1), rand(cl::White));
		return sub {
			my $widget = shift;
			my $i = int($widget->width * $w);
			my $j = int($widget->height * $h);
			debug_output(sprintf("Setting pixel at ($i, $j) to color %06x", $color));
			$widget->pixel($i, $j, $color);
		},
	},
);

sub new_random_drawing_operation {
	return $drawing_generators[rand(@drawing_generators)]->();
}

################### Check proper drawing of single widget ###################

my @window_ops = map { new_random_drawing_operation } (1 .. 10);

my $current_test_number = 1;

# Create the main window
my $extent = 600;
my $window = Prima::MainWindow->new(
	height => $extent,
	width => $extent,
	onPaint => sub {
		debug_output(" *** Painting on main window for test $current_test_number");
		my ($self, $canvas) = @_;
		$canvas->clear;
		for my $op (@window_ops) {
			$op->($canvas);
		}
	},
);

# Create an image with the same dimensions and draw to it
Prima::Timer->new(
	timeout => 0,
	onTick => sub {
		my $self = shift;
		$self->stop;
		
		# Get a copy of the window via subcanvas
		debug_output("Saving image");
		$subcanvas_image = Prima::ImageTester->new(
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
	'Subcanvas faithfully produces a good image of a widget without children')
	or do {
		$subcanvas_image->save('subcanvas-single.png');
		$window_image->save('window-single.png');
	};

################### Check proper drawing of child widgets ###################

$current_test_number = 2;

# Create a window with a collectin of embedded widgets. The embedded widgets
# invoke random paint operations, and we know that the subcanvas works if the
# raster image that it produces is identical to the parent raster image.

sub add_random_widgets {
	my ($widget, $N_children) = @_;
	return if $N_children == 0;
	for (1 .. $N_children) {
		# Produce the location where we will draw the child widget.
		my ($relx, $rely) = map { rand(1)-rand(1)+rand(1)-rand(1) } 1..2;
		my ($relwidth, $relheight)
			= map { rand(0.25)+rand(0.25)+rand(0.25)+rand(0.25) } 1..2;
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
				debug_output('Painting child widget');
				my ($self, $canvas) = @_;
				for my $prop_name (qw(backColor color fillWinding fillPattern font lineEnd
					lineJoin linePattern lineWidth rop rop2
					splinePrecision textOpaque textOutBaseline)
				) {
					debug_output("About to paint on $canvas with $prop_name = ", 
						($prop_name =~ /color/i ? sprintf('%6x', $canvas->$prop_name()) : $canvas->$prop_name())
					);
				}
				debug_output(sprintf('Before clear, pixel at (0, 0) is %6x', $subcanvas_image->pixel(0, 0)));
				$canvas->clear;
				debug_output(sprintf('After clear, pixel at (0, 0) is %6x', $subcanvas_image->pixel(0, 0)));
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
Prima::Timer->new(
	timeout => 0,
	onTick => sub {
		my $self = shift;
		$self->stop;
		
		# Get a copy of the window via subcanvas
		debug_output("Saving image");
		$subcanvas_image = Prima::ImageTester->new(
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

####
####
####
# Eventually test what happens if we have a widget that goes beyond one of the
# borders of its parent, and then sets the clipping region in that too-far
# space. That that case, we should not get any drawin operations.

done_testing;
