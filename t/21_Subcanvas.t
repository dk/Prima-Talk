# Tests my understanding of subcanvas concepts

use strict;
use warnings;
use Prima qw(Application);

########################################################################
                             package
                           My::Basic;
########################################################################
use Test::More;
use Test::Prima;

#### First, a set of methods the I probably won't need to override ####

# run_test is a class method and is the only entry point into this
# class's code. It is invoked as My::Basic->run_test, and derived
# classes are similarly invoked as My::Derived->run_test.
sub run_test {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;
	
	# Set up the tester object
	$self->build_canvases;
	$self->other_init;
	
	# Run the test-specific drawing operations
	$self->invoke_draws;
	
	subtest $self->test_name => sub {
		plan tests => 3;
		# At this point, we should have three images that we will compare
		is_prima_image(	$self->{widget_drawn_image},
						$self->{manual_drawn_image},
						'Window/widget drawing matches manually drawn'
		) or do {
			$self->save('widget');
			$self->save('manual');
		};
		is_prima_image(	$self->{raster_drawn_image},
						$self->{manual_drawn_image},
						'Window direct raster matches manually drawn'
		) or do {
			$self->save('raster');
			$self->save('manual');
		};
		is_prima_image(	$self->{widget_drawn_image},
						$self->{raster_drawn_image},
						'Window/widget drawing matches window direct raster'
		) or do {
			$self->save('widget');
			$self->save('raster');
		};
	};
	
	$self->{window}->destroy;
}

sub save {
	my ($self, $type) = @_;
	my $image_name = $self->short_name . "-${type}-drawn-image.png";
	$self->{"${type}_drawn_image"}->save($image_name);
}

# All of the canvas building is done in one routine to keep all relevant
# properties in one place
sub build_canvases {
	my $self = shift;
	# The window is a canvas
	$self->{window} = Prima::Window->new(
		$self->canvas_init_props,
		onPaint => sub {
			my ($window, $canvas) = @_;
			$self->paint_window($window, $canvas);
		},
	);
	# Create images that will be drawn on, either by the widget method,
	# or directly.
	$self->{widget_drawn_image} = Prima::Image->new(
		$self->canvas_init_props,
	);
	$self->{manual_drawn_image} = Prima::Image->new(
		$self->canvas_init_props,
	);
}

sub invoke_draws {
	my $self = shift;
	# After the window has been initialized, create a couple of images
	# of it and then exit the Prima runloop
	Prima::Timer->new(
		timeout => 0,
		onTick => sub {
			shift->stop;
			# Paint to the image
			$self->{widget_drawn_image}->begin_paint;
			$self->{window}->notify('Paint', $self->{widget_drawn_image});
			$::application->yield;
			$self->{widget_drawn_image}->end_paint;
			# Get a direct rasterization of the window
			$self->{raster_drawn_image}
				= $::application->get_image($self->{window}->origin,
							$self->{window}->size);
			# Exit the run-loop cleanly by throwing an exception
			die "All done";
		},
	)->start;

	eval { Prima->run };
	die('Exception during Prima runloop for test `' . $self->test_name . "': $@")
		unless $@ =~ /All done/;
	
	$self->draw_manual;
}

###### Now some things that can be overridden by derived classes ######

sub width { 100 }
sub height { 110 }
sub color { cl::Black }
sub backColor {cl::White }
sub canvas_init_props {
	my $self = shift;
	return (
		height => $self->height, width => $self->width,
		color => $self->color, backColor => $self->backColor,
	);
}

############### These must be overridden with each test ###############
sub test_name { 'Basic line draw without widgets' }
sub short_name { 'basic_line_draw' }

sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->line(0, 0, $self->width, $self->height);
	$image->end_paint;
}

sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->line(0, 0, $self->width, $self->height);
}

sub other_init {}

My::Basic->run_test;

=observations

This demonstrates that the drawing on a widget can be invoked on another
canvas by sending that canvas to the widget's Paint notification. Note
that in order to get the paint behavior, we have to invoke the runloop.

There is nothing in the drawing operations that can be removed and still
pass the tests. For example, we need to call C<begin_paint> and
C<end_paint> on the Prima::Image in order to get the proper behavior, as
in C<invoke_draws()>. As shown in C<paint_window()>, painting operations
must clear the canvas; this is not for us beforehand. We must be
explicit about background color in C<canvas_init_props()> because a
widget's background color is not the same as a straight image's
background, and the Paint notification does not impose its settins on
the incoming canvas.


=cut back

########################################################################
                             package
                           My::Translated;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Translated line draw without widgets' }
sub short_name { 'translated_line_draw' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	# Set the (0, 0) pixel to something different from the window pixel,
	# to be certain that this would fail if clear was on the othe side
	# of the translate. This is generally not necessary, because the
	# contents of images and windows are not initialized to anything,
	# so they usually contain different pixels anyway.
	#$image->pixel(0, 0, cl::Black);
	$image->clear;
	$image->translate(5, 10);
	$image->line(0, 0, $self->width, $self->height);
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	# Set the (0, 0) pixel to something different from the manual pixel,
	# to be certain that this would fail if clear was on the other side
	# of the translate. This is generally not necessary, because the
	# contents of images and windows are not initialized to anything,
	# so they usually contain different pixels anyway.
	#$canvas->pixel(0, 0, cl::White);
	$canvas->clear;
	$canvas->translate(5, 10);
	$canvas->line(0, 0, $self->width, $self->height);
}

My::Translated->run_test;

=observations

Far and away the most surprising result in this context, for me, is
that C<clear()> pays attention to the current C<translate> settings!
Somehow I didn't think C<clear()> would care. However, if the call to
C<clear> is placed after the call to C<translate>, the L-shaped strip of
pixels along the left and bottom of the images will, almost certainly,
differ in their colors. (In case that exchange passes, you can set the
pixel at (0, 0) to different colors, as is done in the commented-out
call to C<pixel()> in the manual and window-based drawing.)


=cut back

done_testing;
