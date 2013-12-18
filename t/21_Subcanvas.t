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

__PACKAGE__->run_test;

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

__PACKAGE__->run_test;

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

########################################################################
                             package
                        My::Translated::Pix;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Translated pixel draw without widgets' }
sub short_name { 'translated_pixel_draw' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->translate(5, 10);
	$image->pixel(-5, -10, cl::Blue);
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->pixel(0, 0, cl::Blue);
}

__PACKAGE__->run_test;

=observations

This test demonstrates that the pixel location CARES ABOUT THE CURRENT
TRANSLATE! WHAT?! I thought tha pixel handling was independent of
translate, but clearly this is not the case.

=cut back

########################################################################
                             package
                        My::Translated::EndPaint;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Translated then restarted pixel draw without widgets' }
sub short_name { 'translated_restarted_pixel_draw' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->translate(5, 10);
	$image->end_paint;
	$image->begin_paint;
	$image->pixel(0, 0, cl::Blue);
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->pixel(0, 0, cl::Blue);
}

__PACKAGE__->run_test;

=observations

This test demonstrates that any translation information is lost after
the C<end_paint()> method is called.

=cut back

########################################################################
                             package
                        My::Translated::ClipRect;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Translated+clipRect+clear, without widgets' }
sub short_name { 'translated_cliprect_clear' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->translate(5, 10);
	$image->clipRect(0, 0, $image->size);
	$image->backColor(cl::Blue);
	$image->clear;
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->clipRect(5, 10, $canvas->size);
	$canvas->backColor(cl::Blue);
	$canvas->clear;
}

__PACKAGE__->run_test;

=observations

This test demonstrates that even C<clipRect()> pays attention to the current
translate! For purposes of subcanvas work, this means that it's not possible to
get the correct (translated) clipRect after a call to translate, because THERE
IS NO WAY TO DETERMINE THE TRANSLATION THAT WAS IN PLACE WHEN clipRect WAS
CALLED. However, see the next test for why this is not really much of a problem.

=cut back

########################################################################
                             package
                   My::Translated::ClipRect::Repeated;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Translated+clipRect+begin/end paint, without widgets' }
sub short_name { 'translated_cliprect_end_begin_paint' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->translate(5, 10);
	$image->clipRect(0, 0, $image->size);
	#printf "translated clipRect was (%d, %d) -> (%d, %d)\n", $image->clipRect;
	$image->end_paint;
	
	$image->begin_paint;
	#printf "translated clipRect is (%d, %d) -> (%d, %d)\n", $image->clipRect;
	$image->backColor(cl::Blue);
	$image->clear;
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->clipRect(5, 10, $canvas->size);
	#printf "untranslated clipRect was (%d, %d) -> (%d, %d)\n", $canvas->clipRect;
	$canvas->end_paint;
	
	$canvas->begin_paint;
	#printf "untranslated clipRect is (%d, %d) -> (%d, %d)\n", $canvas->clipRect;
	$canvas->backColor(cl::Blue);
	$canvas->clear;
}

__PACKAGE__->run_test;

=observations

Now for some good news. This test demonstrates that when we begin painting anew,
the value of translate is set back to (0, 0), and the clipRect is set to the
whole canvas. This is good news for the subcanvas work, as it means
paint_with_widgets knows how to prepare the subcanvas before it begins its work.

=cut back

########################################################################
                             package
                       My::ClipRect::Negative;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Translated+negative-clipRect, without widgets' }
sub short_name { 'negative_cliprect' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->translate(10, 10);
	$image->clipRect(-10, -10, $image->size);
	$image->backColor(cl::Blue);
	$image->clear;
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->translate(10, 10);
	$canvas->clipRect(0, 0, $canvas->size);
	$canvas->backColor(cl::Blue);
	$canvas->clear;
}

__PACKAGE__->run_test;

=observations

This test demonstrates that C<clipRect()> silently converts negative values to
zero BEFORE APPLYING THE TRANSLATION. Thus, you cannot "adjust" for a
translation by specifying a negative offset like you can with the drawing
primitives.

=cut back

########################################################################
                             package
                   My::Translated::Negative::Pixel;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Negative translation works with pixel() as expected' }
sub short_name { 'negative_translated_pixel' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->translate(-10, -10);
	$image->pixel(20, 20, cl::Blue);
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->pixel(10, 10, cl::Blue);
}

__PACKAGE__->run_test;

=observations

This test demonstrates the negative translations work as we would expect them
to work with drawing primitives, such as pixel().

=cut back

########################################################################
                             package
                  My::Translated::Negative::ClipRect;
########################################################################
use Test::More;

our @ISA = 'My::Basic';
sub test_name { 'Negative translation has weird effects on clipRect' }
sub short_name { 'negative_translated_cliprect' }
sub draw_manual {
	my $self = shift;
	my $image = $self->{manual_drawn_image};
	$image->begin_paint;
	$image->clear;
	$image->translate(-10, -15);
	$image->clipRect(10, 10, $image->width + 50, $image->height + 50);
	$image->backColor(cl::Blue);
	$image->clear;
	$image->end_paint;
}
sub paint_window {
	my ($self, $window, $canvas) = @_;
	$canvas->clear;
	$canvas->clipRect(10, 10, $canvas->width - 11, $canvas->height - 16);
	$canvas->backColor(cl::Blue);
	$canvas->clear;
}

__PACKAGE__->run_test;

=observations

This test seems to demonstrate that NEGATIVE TRANSLATIONS ARE APPLIED VERY
STRANGELY TO THE CLIPPING RECTANGLE. The upper right corner of the clipRect is
truncated assuming that it cannot exceed the canvas size, but then its actual
location is translated. In contrast, the lower left corner does not pay any
attention to the translation.

=cut back

################################################################################
                                package main;
################################################################################

# some basic drawable interface tests
use Test::More;

my $image = Prima::Image->new(width => 20, height => 20);
$image->begin_paint;

# Demonstrate clipRect's truncation of sizes that go outside the boundaries
$image->clipRect(-5, -5, 40, 40);
is_deeply([$image->clipRect], [0, 0, 19, 19], 'clipRect truncates clipRect');

# Demonstrate how translate effects the truncation
$image->translate(10, 10);
$image->clipRect(-5, -5, 40, 40);
is_deeply([$image->clipRect], [0, 0, 19, 19],
	'clipRect truncates clipRect the same after translate, even though it should not');

# Does translation allow negative (if unrendered) values?
$image->translate(-10, -10);
is_deeply([$image->translate], [-10, -10], 'translate accepts negative values');


done_testing;
