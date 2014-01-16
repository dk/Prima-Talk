use strict;
use warnings;


# XXX TODO LIST
# Figure out why em-widths don't work well for toc width

# XXX To think about
# Basic container classes might allow for indenting blocks of renderables,
# centering of all renderables, etc. Ideally, containers would get their
# dimensions from their children, but then relative heights such as
# '45%colheight' wouldn't work. I need to examine how CSS handles these
# issues. For example, sizes relative to parent containers may simply issue
# a fail if the parent container doesn't have a fixed size, or it might
# walk up the container tree until it finds a container with a fixed size.
# Also, it would be nice to have vertical fill spacers, and then use an
# algorithm to determine how many big a vertical fill should be.

# To think about
# For basic slow-exposure transitions, create a 'pause' renderable that
# appends all content up to the next 'pause' as a transition. It achieves
# this by creating its own "transition" subref. It can take options
# "clear", a boolean, which clears the contents of the current container
# before proceeding, and "before" and "after" subrefs that get run at the
# very beginning and very end of the generated transition subref.
#
# ** Make this interact nicely with a predefined "transition" by calling it,
# too.
#
# Also think about how to make transition and transitions both get invoked.

=head1 NAME

Prima::Talk - a widget for rendering presentations and talks

=head1 SYNOPSIS

Prima::Talk is just a widget, so you can pack or place it into windows
or other widgets. The usual usage case is for a full-screen talk, which you
could pack into a full-screen Window like so:

 # Build the application, which will only contain
 # our single talk widget
 my $app = Prima::MainWindow->new(
   text => 'My Talk',
   
   # Fill the screen:
   place => { x => 0, relwidth => 1, y => 0,
       relheight => 1, anchor => 'sw' },
   
   # Get rid of borderIcons if we're on Windows
   ($^O =~ /MS/ or $^O =~ /cywin/i) ? () : (borderIcons => bi::SystemMenu),
 );
 
 my $talk = $app->insert(Talk =>
   # Fill the application:
   place => {
     x => 0, relwidth => 1,
     y => 0, relheight => 1,
     anchor => 'sw',
   },
   
   # Set the em-width relative to the container size
   em_width => '2%width',
   # Set the table of contents color to contrast
   toc_color => cl::White,
   toc_backColor => cl::Black,
   # Relative widths and heights
   toc_width => '12%width',
   title_height => '10%height',
   # Default background is Grey, fix that:
   backColor => cl::White,
 );

If you are creating a full-screen talk, you might be tempted to get rid of
the window altogether. After all, widgets don't need windows to exist and be
displayed. The following recipe will work, but beware: it won't initially
have the keyboard focus when you begin the talk on a Mac (and maybe other
operating systems), so you'll have to select the talk with the mouse before
you can use keyboard navigation.

 use strict;
 use warnings;
 use Prima qw(Talk);
 
 #########################
 # Setup the Application #
 #########################
 
 my $talk = Prima::Talk->new(
   # Fill the screen:
   place => {
     x => 0, relwidth => 1,
     y => 0, relheight => 1,
     anchor => 'sw',
   },
   
   # Set the em-width relative to the container size
   em_width => '2%width',
   # Set the table of contents color to contrast
   toc_color => cl::White,
   toc_backColor => cl::Black,
   # Use relative widths and heights
   toc_width => '12%width',
   title_height => '10%height',
   # Default background is Grey, fix that:
   backColor => cl::White,
 );

=head1 DESCRIPTION

This module provides something of a super widget whose purpose is to let you
build a series of interactive slides. The content of the slides can include
anything from simple text and pictures to customized transitions. You can
even dictate the behavior of each transition dynamically, based on anything
from the amount of time that has passed, to values that have been entered in
a widget that was placed on the slide, to data that is pulled from the
internet. Indeed, you can include arbitrary widgets and interaction within
each slide.

=head2 Navigating a Talk

Prima::Talk does not provide its own file extension for talks. Instead,
talks are no more than Perl scripts. Thus, if you are trying to view a talk,
you need to run the script for that talk:

 $ perl my-talk.pl

Once the talk is displayed, you can navigate forward through the transitions
by pressing the "Down", "Right", and "PageDown" keys. You can navigate
backward by pressing the "Up", "Left", and "PageUp" keys. You quit the talk
by pressing the "q" key, and you can jump to any page by pressing the "g"
key and entering a slide number in the dialog that pops up. The table of
contents on the left are actually links to the named slides.

Prima::Talk is sensitive to a handful of special key combinations that map
to my personal clicker, and ostensibly to any normal clicker, too. I have
found that one of the buttons on my clicker emits the key combinations of
either "Esc" or "Shift-F5", so both of these issue a "Special Key" command
to the talk. This allows for rudimentary "extra" behavior in talks, which
your talk may or may not conain.

=head2 Building a Talk: an overview

There are a number of different ideas to get straight in understanding how
these talks work. First, you have a C<Prima::Talk> widget. You create such a
widget by saying something like:

 my $talk = $window->insert(Talk =>
   # Have the Talk fill the whole window:
   place => {
     x => 0, relwidth => 1,
     y => 0, relheight => 1,
     anchor => 'sw',
   },
   em_width => '2%width',         # Scale font width by screen size:
   font => { name => 'Georgia' }, # Set to a nice font
   logo => 'company-logo.jpg',    # upper-left corner
   toc_width => '15%width',       # logo/table-of-contents width
   toc_color => cl::White,        # color for table-of-contents text
   toc_backColor => cl::Black,    # make table-of-contents contrast
   backColor => cl::White,        #    against the main talk
 );

As you can see, there are many ways to configure your Talk, but I'll step
over that for now. Another idea to get straight is that your Talk does not
come with any content: you need to add slides to it. You add slides with
the L</add> method, in which you specify the class name of the slide object
that you want added followed by key/value pairs that indicate the settings
for the slide, and its content:

 $talk->add(Slide =>
   # Short phrase shown in the table of contents
   toc_entry => 'Basic Question',
   # Title displayed across the top of the screen
   title => 'How do we segment weigh-in data?',
   # Make the text on this slide a bit bigger
   font_factor => 1.4,
   # Specify the content of the slides
   content => [
     par => 'Regular weigh-in intervals:', # paragraph
     bullets => [                          # set
       'Identify break points',            #   of
     ],                                    #     bullets
     spacer => '0.5em',                    # spacer
     par => 'Regular users with a few big gaps', # paragraph
     bullets => [                          # set
       'Identify regular sampling rate',   #   of
       'Pick large gaps',                  #     more
     ],                                    #       bullets
     spacer => '0.5em',                    # another spacer
     par => 'Users with mixed behavior',   # etc...
     bullets => [
       'Extract periods of regular behavior',
     ],
   ],
 );

The built-in classes for slides include L</Slide>, L</WideSlide>, L<Section>,
and L</WideSection> (which cover at least 99% of my slide layout needs) as
well as L</Emphasize> and L</WideEmphasize>. The important thing to realize
about the slide types is that they specify how the slides interact with the
table of contents and the title, but use the exact same content mechanisms.

That brings me to content, and how to specify it. All slides should have a
L</title>. They should also specify a L<table-of-contents entry|/toc_entry>
since the title is likely to be quite a bit longer than what would fit in
the table-of-contents column. The other piece of content is an array ref
associated with the C<content> key, as demonstrated above. The array ref
should contain key/value pairs wherein the key indicates a content type and
a value indicates some value that the content type expects, and knows how to
render. For example, C<par> expects a single string of text which can
include newlines and lots of whitespace. All whitespace is replaced with
single spaces and the eventual text gets displayed with text wrapping, if
necessary.

Basic content types include L<par|/par>, L<spacer|/spacer>,
L<bullets|/bullets>, L<image|/image>, L<two_column|/two_column>,
L<plot|/plot>, and L<subref|/subref>. The last one takes arbitrary code for
adding custom one-off renderings, such as adding custom widgets to the
slide. (If you need to do many similar renderings for the same slide, you
should create a custom content type with a rendering subref under the
Slide's [not the contents'] key C<< render_<type> >>. If you need to do many
similar renderings across many slides, define
C<< Prima::Talk::Slide::render_<type> >>.)

And finally we get to the last bit. Transitions are custom behaviors that
happen every time the speaker hits the forward or back button. These
behaviors do not need to advance to the next slide. In fact, they don't even
need to behave in a set way each time. You specify transition behavior by
either associating a single subref with the Slide key C<transition>, or by
associating a list of subrefs with the C<transitions> key. When called, all
of these subrefs are passed the slide object and the direction of the
transition. The difference between the two is how they handle advancing to
the next (or previous) slide. For the single C<transition> subref, it must
return a false value when you have no more transitions for your slide in the
given direction (+1 for forward transitions, -1 for backward transitions).
For the set of transitions, each one is called in order, and the return value
is ignored.

=cut

use Prima qw(Label MsgBox FileDialog StretchyImage InputLine);
use Prima::PS::Drawable;
use Prima::Drawable::Subcanvas;

package Prima::Talk;
# Primary package, which describes a widget that holds all the Talk data,
# including the slide deck and the container widgets. This widget keeps
# track of things like key combos for slide advance or rewind, and such

our @ISA = qw(Prima::Widget);
use Carp;
use Prima::Utils qw(post);
use Time::Piece;

sub formatted_date {
	# Calculate today's date with the specified format, use that for the footer
	my $format = shift;
	my $t = localtime;
	return $t->strftime($format)
}

sub profile_default
{
	my %def = %{$_[ 0]-> SUPER::profile_default};

	# These lines are somewhat patterned from the Prima example called 'editor'
	my @acc = (
		# Up/Left means previous slide
		  ['', '', kb::Up, \&previous_slide]
		, ['', '', kb::Left, \&previous_slide]
		, ['', '', kb::PageUp, \&previous_slide]
		# Down/Right means next slide
		, ['', '', kb::Down, \&next_slide]
		, ['', '', kb::Right, \&next_slide]
		, ['', '', kb::PageDown, \&next_slide]
		# Special clicker keys
		, ['', '', kb::Esc, \&special_key]
		, ['', '', kb::F5 | km::Shift, \&special_key]
		# q to quite
		, ['', '', ord('q'), sub { exit() } ]
		# g for 'goto'
		, ['', '', ord('g'), \&goto_slide_dialog ]
		# p for "print"
		, ['', '', ord('p'), \&print_current_slide ]
	);
	
	my $day_of_month = formatted_date('%d');
	$day_of_month =~ s/^0+//;
	my $today = formatted_date("%A %B $day_of_month, %Y");
	return {
		%def,
		accelItems => \@acc,
		slides => [undef],
		curr_slide => undef,
		toc_indent => 20,
		title_font_ratio => 2,
		toc_backColor => cl::White,
		toc_color => cl::Black,
		toc_font_ratio => 1,
		padding => 10,
		footer => [$today, '', '%s / %n'],
		footer_height => '1.5em',
		aspect_backColor => cl::Black,
	}
}

sub goto_slide_dialog {
	my $self = shift;
	my $n_slides = $self->n_slides;
	my $slide_number = $n_slides;
	while($slide_number >= $n_slides) {
		$slide_number = Prima::MsgBox::input_box( 'Goto...', "Slide number (1-$n_slides):", '');
		return unless $slide_number =~ /^\d+$/;
		$slide_number-- unless $slide_number == 0;
	}
	$self->slide($slide_number);
}

# working here - this does not quite work quite right. :-(
sub print_current_slide {
	# Get the filename as an argument, or from the save-as dialog.
	my $self = shift;
	my $filename;
	$::application->pointer(cr::Wait);
	
	unless ($filename) {
		my $save_dialog = Prima::SaveDialog-> new(
			defaultExt => 'ps',
			filter => [
				['Postscript files' => '*.ps'],
				['All files' => '*'],
			],
		);
		# Return if they cancel out:
		return unless $save_dialog->execute;
		# Otherwise get the filename:
		$filename = $save_dialog->fileName;
	}
	unlink $filename if -f $filename;
	
print "Creating postscript canvas to save to $filename\n";
	# Create the postscript canvas
	my $ps = Prima::PS::Drawable-> create( onSpool => sub {
			open my $fh, ">>", $filename;
			print $fh $_[1];
			close $fh;
		},
		pageSize => [$self->{aspect_container}->size],
		pageMargins => [0, 0, 0, 0],
	);
	$ps->resolution($self->resolution);
	$ps->font(size => 16);
	
print "Initializing the canvas\n";
	# Initialize the canvas
	$ps->begin_doc
		or do {
			my $message = "Error generating Postscript output: $@";
			if (defined $::application) {
				Prima::MsgBox::message($message, mb::Ok);
				carp $message;
				return;
			}
			else {
				croak($message);
			}
		};
	
	# If we're good to go, draw on it
print "Painting widgets on the canvas\n";
	$self->{aspect_container}->paint_with_widgets($ps);
print "All done creating the postscript\n";
	$ps->end_doc;
	$::application->pointer(cr::Default);
}

# Returns a list of "place" key/value pairs suitable for the requested
# aspect ratio.
sub aspect_place_spec {
	my $self = shift;
	# If they didn't specify an aspect, return a fully filled setup
	return (x => 0, relwidth => 1, y => 0, relheight => 1, anchor => 'sw')
		unless $self->{aspect};
	
	# If they did specify an aspect, we have some calculating to do.
	my ($width, $height) = $self->size;
	
	if ($width / $height < $self->{aspect}) {
		# Widget is taller than the desired aspect, so fill the width and
		# pad the top and bottom
		my $calc_height = $width / $self->{aspect};
		
		return (x => 0, relwidth => 1, anchor => 'sw',
				y => ($height - $calc_height) / 2, height => $calc_height
		);
	}
	else {
		# Widget is wider than the desired aspect, so fill the height and
		# pad the left and right
		my $calc_width = $height * $self->{aspect};
		return (y => 0, relheight => 1, anchor => 'sw',
				x => ($width - $calc_width)/2, width => $calc_width
		);
	}
}

# optional:
#
# toc_width => sets logo width, too; default is 200
# If you do not specify a title height, it is computed by stretching the
# logo to fit in the toc_width. If you specify the title height, the logo is
# shrunk so that fits within both the toc width and the title height,
# preserving aspect ratio.
# If you do not specify a logo or a title height, twice the title font
# size is used.
# If you do not specify a toc_width or title_height, but you do specify a
# logo, the logo's dimensions are used for both.
# If you do not specify anything, toc_width defaults to 16 x font-size
# and title_height defaults to 2 x title-font-size

# This stage initializes the talk. I believe this is the appropriate stage
# for setting the properties above and creating the child widgets.
sub init {
	my $self = shift;
	my %profile = $self->SUPER::init(@_);
	
	# Copy basic properties
	for my $prop_name ( qw(
		toc_indent toc_color toc_backColor title_font_ratio
		em_width footer aspect
	) ) {
		$self->{$prop_name} = $profile{$prop_name};
	}
	
	# Copy the notes window, if supplied
	if (exists $profile{notes_window} ) {
		if (eval { $profile{notes_window}->isa('Prima::Widget') }) {
			$self->{notes_window} = $profile{notes_window};
		}
		else {
			croak('notes_window is not a Prima::Widget');
		}
	}
	
	# Copy custom size spec methods
	for my $key (keys %profile) {
		next unless $key =~ /^size_spec_.+$/;
		if (ref{$profile{$key}} eq 'CODE') {
			$self->{$key} = $profile{$key};
		}
		else {
			carp("key `$key' looks like it should be a size spec, but does not refer to a coderef");
		}
	}
	
	# Build the aspect-preserving container, which holds everything else.
	# This must be the first thing to be built since some of the relative
	# size specs depend on its existence.
	my $aspect_container = $self->{aspect_container} = 
			# Build the outermost container with the aspect back color,
			# into which we will insert the aspect container
			$self->insert(Widget =>
				place => { x => 0, y => 0, relwidth => 1, relheight => 1, anchor => 'sw'},
				color => $profile{aspect_backColor},
				backColor => $profile{aspect_backColor},
				# Allow the speaker to hide the mouse on the edges
				onMouseEnter => sub { $::application->pointerVisible(0) },
				onMouseLeave => sub { $::application->pointerVisible(1) },
			)->insert(Widget =>
		color => $self->color,
		backColor => $self->backColor,
		place => {$self->aspect_place_spec},
	);
	
	# The font size may be in terms of the width or height, so it cannot be
	# (re)set until the aspect container has been built.
	$self->reset_font_size;
	# Keep the aspect container's font size in line, too:
	$aspect_container->font->size($self->font->size);
	
	# Run the footer and toc heights through the setters
	my $footer_height = $self->footer_height($profile{footer_height});
	$self->footer(@{$profile{footer}});
	$self->toc_font_ratio($profile{toc_font_ratio});
	
	# if they specified a toc_width or title_height, use it
	$self->{toc_width} = $profile{toc_width} if exists $profile{toc_width};
	$self->{title_height} = $profile{title_height}
		if exists $profile{title_height};
	
	# Load the logo
	my %logo_options = (
		color => $self->{toc_color},
		backColor => $self->{toc_backColor},
		geometry => gt::Place,
	);
	if (not exists $profile{logo}) {
		# do nothing
	}
	elsif (ref($profile{logo}) eq 'HASH') {
		%logo_options = (%logo_options, %{$profile{logo}});
	}
	elsif (eval{$profile{logo}->isa('Prima::Image')}) {
		%logo_options = (%logo_options, image => $profile{logo});
	}
	else {
		%logo_options = (%logo_options, filename => $profile{logo});
	}
	$self->{logo} = $aspect_container->insert(StretchyImage => %logo_options);
	
	# Calculate the width of the table of contents and the title height,
	# in pixels
	my ($toc_width, $title_height) = $self->calculate_decorator_dims;
	
	# Reposition the logo
	$self->{logo}->set(place => {
		x => 0, width => $toc_width,
		rely => 1, y => -$title_height, height => $title_height,
		anchor => 'sw',
	});
	
	# Add the title label
	$self->{title_label} = $aspect_container->insert(Label => 
		place => {
			x => $toc_width, width => -$toc_width, relwidth => 1, 
			rely => 1, y => -$title_height,
			height => $title_height, anchor => 'sw',
		},
		font => {
			name     => $self->font->name,
			height   => $title_height,
			style    => $self->font->style,
			encoding => $self->font->encoding,
		},
		width => $aspect_container->width - $toc_width,
		color => $self->{toc_color},
		backColor => $self->{toc_backColor},
		valignment => ta::Middle,
		alignment => ta::Center,
		# Allow the speaker to hide the mouse in the title. :-)
		onMouseEnter => sub { $::application->pointerVisible(0) },
		onMouseLeave => sub { $::application->pointerVisible(1) },
	);
	
	# Add the lower container
	my $lower_container = $self->{lower_container}
		= $aspect_container->insert(Widget =>
		place => {
			x => 0, relwidth => 1,
			y => 0, relheight => 1, height => -$title_height,
			anchor => 'sw',
		},
		color => $self->color,
		backColor => $self->backColor,
	);
	my $padding = $self->{padding} = $profile{padding};
	# Add the main container
	$self->{main_container} = $lower_container->insert(Widget =>
		place => {
			x => $toc_width + $padding, relwidth => 1,
			width => -$toc_width - 2 * $padding,
			y => $padding + $footer_height, relheight => 1,
			height => -2*$padding - $footer_height,
			anchor => 'sw',
		},
		width => $self->width - $toc_width - 2*$padding,
		color => $self->color,
		backColor => $self->backColor,
	);
	
	# Add the toc widget
	$self->{toc_widget} = $lower_container->insert(Widget =>
		place => {
			x => 0, width => $toc_width,
			y => 0, relheight => 1,
			anchor => 'sw',
		},
		color => $profile{toc_color},
		backColor => $profile{toc_backColor},
	);
	
	$self->{footer_widget} = $lower_container->insert(Widget =>
		place => {
			x => $toc_width + $padding, relwidth => 1,
			width => -$toc_width - 2 * $padding,
			y => 0, height => $footer_height,
			anchor => 'sw',
		},
		buffered => 1,
		color => $profile{toc_color},
		backColor => $profile{toc_backColor},
		onPaint => sub {
			my $footer_widget = shift;
			return if not $self->footer_visible;
			
			$footer_widget->begin_paint;
			$footer_widget->clear;
			my $height = $footer_widget->height;
			my $font_height = $footer_widget->font->height;
			my $vert_offset = ($height - $font_height) / 2;
			
			# Paint left footer
			my ($left_text, $center_text, $right_text) = $self->footer;
			if ($left_text ne '') {
				my $to_paint = $self->process_footer_text($left_text);
				$footer_widget->text_out($to_paint, $padding, $vert_offset);
			}
			if ($center_text ne '') {
				my $to_paint = $self->process_footer_text($center_text);
				my $width = $footer_widget->get_text_width($to_paint);
				my $x = ($footer_widget->width - $width) / 2;
				$footer_widget->text_out($to_paint, $x, $vert_offset);
			}
			if ($right_text ne '') {
				my $to_paint = $self->process_footer_text($right_text);
				my $width = $footer_widget->get_text_width($to_paint);
				my $x = $footer_widget->width - $width - $padding;
				$footer_widget->text_out($to_paint, $x, $vert_offset);
			}
			$footer_widget->end_paint;
		},
	);
	
	# Add the table of contents labels 
	$self->build_toc;

	# Set the slides
	$self->slides(@{$profile{slides}});
	
	# Set the current slide
	$self->{curr_slide} = undef;
	if ($self->n_slides > 0 and defined $profile{curr_slide}) {
		$self->slide($profile{curr_slide});
	}
	
	return %profile;
}

# the aspect ratio needs to be adjusted if the container is resized.
sub on_size {
	my ($self, undef, undef, $width, $height) = @_;
	$self->{aspect_container}->place($self->aspect_place_spec);
	
	# See if the font needs recalibrating
	if ($self->{em_width} and $self->{em_width} =~ /%/) {
		$self->reset_font_size;
#		$self->{title_label}->font->size(
#			$self->font->size * $self->{title_font_ratio}
#		);
	}

	# Update the layout
	my ($toc_width, $title_height) = $self->calculate_decorator_dims;
	# Logo
	$self->{logo}->place(
			x => 0, width => $toc_width,
			rely => 1, y => -$title_height, height => $title_height,
			anchor => 'sw',
	);
	# Title
	$self->{title_label}->place(
			x => $toc_width, width => -$toc_width, relwidth => 1, 
			rely => 1, y => -$title_height,
			height => $title_height, anchor => 'sw',
	);
	$self->{title_label}->width($width - $toc_width);
	$self->{title_label}->font->height($title_height);
	# Lower container
	$self->{lower_container}->place(height => -$title_height);
	# Update the widths of the table of contents, main container, footer
	$self->toc_visible($self->toc_visible);
	$self->update_footer;
	
	# Update the table of contents widget
	my $toc_widget = $self->{toc_widget};
	$toc_widget->width($toc_width);
	$toc_widget->place( x => 0, width => $toc_width );
	for my $toc_container ($toc_widget->get_widgets) {
		$toc_container->width($toc_width);
		#$toc_container->place( x => 0, width => $toc_width );
		for my $label ($toc_container->get_widgets) {
			$label->width($toc_width);
			$label->place( x => 0, width => $toc_width );
		}
	}
}

sub reset_font_size {
	my $self = shift;
	
	# Don't do anything if there is no specification
	return unless $self->{em_width};
	
	my $em_width = $self->{em_width};
	if ($em_width =~ /em$/) {
		carp('Cannot specify the em-width in terms of em-widths! Ignoring em-width spec.');
		return;
	}
	elsif ($em_width =~ s/\%col(\w+)/\%$1/) {
		carp("Cannot specify the em-width in terms of \%col$1. Using \%$1 instead");
	}
	
	# Change the font size to the requested size; assumes that the size of M
	# grows linearly with font size, which may not always be correct
	my $current_em = $self->calculate_size(current_em_width => '1em');
	my $new_em = $self->calculate_size(em_width => $em_width);
	
	$self->font->size($self->font->size * $new_em / $current_em);
}

=head2 calculate_size

Semi-internal method that computes pixel sizes for a given size
specification. This method expects three argments: a descriptive name, the
size spec to be processed, and an optional container whose dimensions should
be used for the column height and width calculations. (If the calculation of
the size spec fails, the method will fail with a message including the
descriptive name, which is why it is taken as an argument.)

While writing talks using Prima::Talk, I found that I wanted a wider
vocabulary of sizes than was available with the standard Prima size specs.
Generaly, everything in Prima is about pixels, with relative sizes (i.e.
L<relwidth|/Prima::Widget::place/relwidth>) and foint sizes in

The following suffixes are available:

=over

=item px

A size in pixels. This is also what you get when you have no suffix at all.
Thus a spec of '5px' will return simply 5.

=item em

A multiple of the width of the letter M. The letter width is based on the
slide's default font properties. For example, if in your current font the
letter M is 20 pixels wide, the speck '3.2em' would return 64.

=item %height

A percentage of the full talk's height. If your talk widget is 800 pixels
tall, then '10%height' will be 80 pixels.

=item %colheight

A percentage of the current container widget's height. This is often a
useful metric when specifying the height of an image or plot. If your
container widget is 600 pixels tall, '50%colheight' will be 300 pixels.

=item %colheightleft

A percentage of the remaining free height in the current container widget.
This only works as long as the content renderers that you use pack their
contents into the container. If you have a container that is 600 pixels
tall and a paragaph consumes 112 pixels, then '30%colheightleft' will give
you 176.4, which is truncated to 176.

=item %width

A percentage of the full talk's width. If you talk widget is 1000 pixels
wide, then '50%width' will return 500.

=item %colwidth

A percentage of the width of the current container widget. Given that most
content packs down from the top, you will usually only use this for the
L</two_column> renderable.

=back

You can also supply your own suffixes. If you are trying a new size spec in
an experimental talk, you can simply provide a coderef to the talk widget
itself. For example, you could provide a multiple of the titlebar's height
with something like this in your constructor:

 my $talk = $window->insert(Talk =>
   ... normal args ...
   size_spec_titlebar => sub {
     my ($self, $name, $size, $container) = @_;
     my ($undef, $title_height) = $self->calculate_decorator_dims;
     # Note $size has already been stripped of its suffix and
     # is just a number
     return $size * $title_height;
   }
   ...
 );

Then you can use "2titlebar" to indicate a size that is twice the titlebar's
height.

A more permanent mechanism for creating new specs is available through
monkey-patching, or by creating derived classes. Simply provide a method
with the same special name:

 # monkey-patch:
 sub Prima::Talk::size_spec_titlebar {
   ...
 }
 
 # Derived class:
 
 package Prima::FancyTalk;
 our @ISA = ('Prima::Talk');
 sub size_spec_titlebar {
   ...
 }

Note that per-widget callback override custom size spec implementations.
That is, if you specify C<size_spec_titlebar> both as a class method and as
a coderef to the constructor, the consructor coderef will take precedence.

=cut

sub calculate_size {
	my ($self, $name, $size, $container) = @_;
	
	# Plain digits means pixels; pixel spec can simply have the px stripped
	return $size if $size =~ /^\d+(\.\d*)?$/ or $size =~ s/px$//;
	
	
	# Percent of talk height
	return $size / 100 * $self->{aspect_container}->height
		if $size =~ s/\%height$//;
	
	# Percent of talk width
	return $size / 100 * $self->{aspect_container}->width
		if $size =~ s/\%width$//;
	
	# Multiples of the width of the letter 'M'
	return $size * $self->get_text_width('M') if $size =~ s/em$//;
	
	# Croak if column specs are not allowed
	croak("Column $1 is not allowed for $name specification")
		if not defined $container and $size =~ /\%col(\w+)/;
	
	# Percent of the column height or width
	return $size * $container->height / 100 if $size =~ s/\%colheight$//;
	return $size * $container->width / 100  if $size =~ s/\%colwidth$//;
	# Percent of the remaining column height
	if ($size =~ s/\%colheightleft//) {
		my $top = $container->height;
		my $bottom = 0;
		for my $widget ($container->packSlaves) {
			next if (($widget->name || '') eq 'container_padding');
			my $pack_opts = $widget->packInfo;
			if ($$pack_opts{side} eq 'top') {
				$top = $widget->bottom if $widget->bottom < $top;
			}
			elsif ($$pack_opts{side} eq 'bottom') {
				$bottom = $widget->top if $widget->top > $bottom;
			}
		}
		return $size * ($top - $bottom) / 100;
	}
	
	# Handle special suffixes
	if ($size =~ /\d*(?:\.\d*)?(.+)/) {
		my $suffix = $1;
		if (exists $self->{"size_spec_$suffix"}) {
			$self->{"size_spec_$suffix"}->($self, $name, $size, $container);
		}
		elsif (my $subref = $self->can("size_spec_$suffix")) {
			$subref->($self, $name, $size, $container);
		}
	}
	
	croak("Unknown $name size specification $size");
}

=head2 calculate_decorator_dims

This semi-internal method can be used any time after the Talk object has
been initialized. It computes and returns two numbers: the width of the
table of contents and the height of the title bar. It does this by processing
the combination of an optional logo's dimensions and optional specifications
for the title height and the table of contents' width. All of these sorts of
things are based on data that are internal to the object, and typically only
change when the window gets resized. The logic is not very simple, which is
why it is encapsulated in this one function. It works as follows:

If specifications for the height and width were passed to the constructor,
their sizes are computed and returned. Relative sizes, such as C<'10em'>
or C<'12%width'>, can be used. If there is no logo, default dimensions of
C<'15%width'> and C<'15%height'> are used for the height and width,
respectively.

If there is a logo and none of the dimensions are specified, the logo's
size in pixels is used. This is not recommended if your talk's size is not
fixed because it will occupy diferent fractions of the screen for different
talk sizes. This could be the case, for example, if you give the talk in
full-screen but on different monitors with different screen resolutions.
Also, the size in pixels will remain fixed even when the presentation gets
resize. Under these situations, you should specify just one of the
dimensions in which case the logo's aspect ratio is used to determine the
size of the other dimension. You can also specify both dimensions, in which
case the logo is stretched to the given dimensions.

=cut

sub calculate_decorator_dims {
	my $self = shift;
	
	# Easy case: both dims are explicitly specified
	if ($self->{toc_width} and $self->{title_height}) {
		return (
			$self->calculate_size(toc_width => $self->{toc_width}),
			$self->calculate_size(title_height => $self->{title_height})
		)
	}
	
	# Moving forward, no more than one of the dims is specified
	
	# Easy case: logo but no dims
	return $self->{logo}->size if $self->{logo}->has_image
				and not $self->{toc_width} and not $self->{title_height};
	
	# No logo image is also fairly simple; unspecified dims revert to
	# defaults
	if (not $self->{logo}->has_image) {
		my $toc_width = $self->{toc_width} || '15%width';
		my $title_height = $self->{title_height} || '15%height';
		return (
			$self->calculate_size(toc_width => $toc_width),
			$self->calculate_size(title_height => $title_height)
		);
	}
	
	# At this point we have a logo with an image and only one of the
	# dimensions. Use the logo's aspect ratio to compute the size of the
	# other dimension.
	
	my $logo_aspect = $self->{logo}->width / $self->{logo}->height;
	if ($self->{toc_width}) {
		my $width_px = $self->calculate_size(toc_width => $self->{toc_width});
		my $height_px = $width_px / $logo_aspect;
		return ($width_px, $height_px);
	}
	
	my $height_px = $self->calculate_size(title_height => $self->{title_height});
	my $width_px = $height_px * $logo_aspect;
	return ($width_px, $height_px);
}

=head2 footer_height

Gets or sets the footer height. Called as a getter in scalar context returns
the height in pixels. Called as a getter in array context returns first the
pixel height, then the height spec, which is explained below. Called as a
setter, it sets the height spec.

Allowed height specifications are numbers, which are translated as pixel
heights, or strings with special endings. Special endings include C<"px">,
which means this is a pixel height, C<"%">, which means this height is a 
percentage of the full talk's vertical height, and C<"em">, which means this
height is a multiple of the width of the widget's letter C<"M">. Pixel
heights must be larger than 5 pixels, percentage heights can be anything
between 1% and 15%, and em-heights can be anything between 0.5em and 5em.

A height of 0 indicates that you do not want a footer.

=cut

sub footer_height {
	my $self = shift;
	
	# Called as getter
	if (@_ == 0) {
		# Return the height and the height-string if called in array context
		return ($self->{footer_height_px}, $self->{footer_height})
				if wantarray;
		# Return the height in pixels if called in scalar context
		return $self->{footer_height_px};
	}
	
	# Called as setter; determine the height and check for sanity
	my $height = $self->{footer_height} = shift;
	
	my $min_height = 5;
	my $max_height = $self->calculate_size(max_footer_height => '15%height');
	my $height_px = $self->calculate_size(footer_height => $height);
	
	# Store the height, in case 
	if ($height_px > 0 and $height_px < $min_height) {
		warn("Footer height too small; enlarging to ${min_height}px\n");
		$height_px = $min_height;
	}
	elsif ($height_px > $max_height) {
		warn("Footer height too large; shrinking to 15\%height\n");
		$height_px = $max_height;
	}
	
	# Set the widget height; don't adjust the footer or container; that will
	# happen with the call to update_footer
	$self->{footer_height_px} = $height_px;
}

=head2 footer

Gets or sets the footer text. The footer has three distinct regions: left,
center, and right. When called in getter mode, this returns three elements,
corresponding to the three elements of the footer. When called in setter
mode, this method expects between one and three arguments corresponding to
the desired left, center, and right footer texts. If you want to clear a
footer element, set it to the empty string. If do not want to change an
element's text, pass in the undefined value for that place in the array.

The strings allow for some basic field interpretation, and the field
interpretation can be extended by subclassing or by per-widget methods. If
your footer string includes the string C<'%s'>, the current slide number
will be inserted its place. The string C<'%n'> will be replaced with the
total number of slides. The string C<'%%'> will be replaced with a single
percent sign. You can add new fields by adding methods to your subclass
called C<footer_field_LETTER>, where the letter is what you want to
override, or by adding anonymous subroutines to your talk object with the
associated name. When the footer updater gets called, it will call
your new method if it encounters C<"%LETTER"> in any of your footer strings.

For example:

 # Sets the left and center footers to blank,
 # right footer to current-slide / slide-count
 $talk->footer('', '', '%s / %n');
 
 # Changes the center footer to my name
 $talk->footer(undef, 'David Mertens', undef);
 
 # Gets the current footer text strings
 my ($left, $center, $right) = $talk->footer;
 
 # Add something to render the author name
 $talk->{footer_field_a} = sub {
	 return 'David Mertens'
 }
 
 # Use the new footer field
 $talk->footer(undef, '%a', undef);

To expand on this, you could create a new field that delegates to slides for
content. This provides one of multiple methods for having per-slide
customization in your footer.

=cut

sub footer {
	my $self = shift;
	my @footer = @{$self->{footer}};
	return @footer if @_ == 0;
	
	my ($left, $center, $right) = @_;
	$footer[0] = $left if defined $left;
	$footer[1] = $center if defined $center;
	$footer[2] = $right if defined $right;
	
	# Finally, store the resulting footer data
	$self->{footer} = \@footer;
}

sub footer_field_s {
	my $slide_number = $_[0]->slide;
	return '---' unless defined $slide_number;
	return $slide_number + 1;
}

sub footer_field_n {
	return $_[0]->n_slides;
}

sub process_footer_text {
	my ($self, $text) = @_;
	
	# Split the text on footer fields
	my @elements = split /(%.)/, $text;
	
	# Build the return string
	my $to_return = '';
	for my $element (@elements) {
		if ($element eq '%%') {
			$to_return .= '%';
		}
		elsif ($element =~ /^%(.)$/) {
			my $char = $1;
			if (my $subref = $self->can("footer_field_$char")) {
				$to_return .= $subref->($self);
			}
			elsif (exists $self->{"footer_field_$char"}) {
				$to_return .= $self->{"footer_field_$char"}->($self);
			}
			else {
				carp("No method for interpreting footer $element");
				$to_return .= $element;
			}
		}
		else {
			$to_return .= $element;
		}
	}
	return $to_return;
}

=head2 footer_left

Gets or sets the left footer text. See above for more details.

=cut

sub footer_left {
	return $_[0]->{footer}->[0] if @_ == 1;
	$_[0]->footer($_[1], undef, undef);
}

=head2 footer_right

Gets or sets the right footer text. See above for more details.

=cut

sub footer_right {
	return $_[0]->{footer}->[2] if @_ == 1;
	$_[0]->footer(undef, undef, $_[1]);
}

=head2 footer_center

Gets or sets the center footer text. See above for more details.

=cut

sub footer_center {
	return $_[0]->{footer}->[1] if @_ == 1;
	$_[0]->footer(undef, $_[1], undef);
}

# adjust the footer dimensions and call the paint method
sub update_footer {
	my $self = shift;
	my $footer_widget = $self->{footer_widget};
	$footer_widget->height($self->{footer_height_px});
	$footer_widget->font->height($self->{footer_height_px});
	$footer_widget->notify("Paint");
}

=head2 container

Returns the main container object, into which slide contents should be added.

=cut

sub container {
	return $_[0]->{main_container};
}

=head2 toc_width

Gets/sets the table-of-contents container width. This can be used to set the
width, but it is no more than a wrapper around L</toc_width_spec> (and therefore
it triggers a slide redraw). In get mode, this returns the computed width in
pixels. To get the spec string, see L</toc_width_spec>.

=cut

sub toc_width {
	my $self = shift;
	# Called as getter
	if (@_ == 0) {
		my ($width) = $self->calculate_decorator_dims;
		return $width;
	};
	# Called as setter
	$self->toc_width_spec(@_);
}

=head2 toc_width_spec

Gets/sets the table-of-contents container width spec. The setter accepts a spec
string and applies it immediately, issuing a slide redraw. The getter simply
returns the spec string currently in use.

=cut

sub toc_width_spec {
	my $self = shift;
	return $self->{toc_width} if @_ == 0;
	
	# If called as a setter, calculate the pixel size and redraw everything
	$self->{toc_width} = my $width = shift;
	$self->notify("Size", $self->size, $self->size);
	
	# Issue  reslide
	$self->reslide;
}

=head2 toc_indent

Gets/sets the table-of-contents' indentation, i.e. the indentation used when
displaying the slides under the current section. In set mode, this triggers
a redraw of the table of contents, but not the slide itself.

=cut

sub toc_indent {
	return $_[0]->{toc_indent} if @_ == 1;
	my ($self, $indent) = @_;
	$self->{toc_indent} = $indent;
	
	$self->update_toc;
}

=head2 toc_font_ratio

Gets/sets the table-of-contents' font size as a ratio of the default slide font
size. Font sizes in Prima are in whole numbers, so you may not actually get your
requested ratio. The method L</toc_real_font_ratio> will give you the actual
ratio of the fonts in use.

=cut

use Scalar::Util;

sub toc_font_ratio {
	return shift->{toc_font_ratio} if @_ == 1;
	my ($self, $new_ratio) = @_;
	# Sanity check the new ratio
	if (not Scalar::Util::looks_like_number($new_ratio)) {
		carp("toc_font_ratio `$new_ratio' does not look like a number; ignoring");
		return;
	}
	if ($new_ratio <= 0) {
		carp("toc_font_ratio `$new_ratio' is not positive; ignoring");
		return;
	}
	$self->{toc_font_ratio} = $new_ratio;
	
	# Get the nearest height that can actually be realized with this font
	$self->begin_paint_info;
	$self->font->height($self->font->size * $new_ratio);
	$self->{toc_font_height} = $self->font->height;
	$self->end_paint_info;
}

=head2 toc_real_font_ratio

Because the font sizes are integers, it's not possible to represent the exact
ratio you specify when setting C<toc_font_ratio> (unless you happen to pick
something easy like 0.5). If you must know the actual ratio, this method will
give it to you.

=cut

sub toc_real_font_ratio {
	my $self = shift;
	return $self->{toc_font_height} / $self->font->size;
}

=head2 toc_visible

Getter/setter that indicates whether or not the table of contents should be
shown or not. This does B<not> issue a slide redraw as it it is expected to
be used primarily during the setup of a given slide.

=cut

sub toc_visible {
	my $self = shift;
	return $self->{toc_visible} if @_ == 0;
	
	my $is_visible = $self->{toc_visible} = $_[0];
	
	# Update the size of the main container (which already has relwidth of 1)
	my ($toc_width) = $self->calculate_decorator_dims;
	my $padding = $self->{padding};
	if ($is_visible) {
		$self->container->place(
			x => $toc_width + $padding, relwidth => 1,
			width => -$toc_width - 2 * $padding,
		);
		$self->{footer_widget}->place(
			x => $toc_width, relwidth => 1,
			width => -$toc_width,
		);
	}
	else {
		$self->container->place(
			x => $padding, relwidth => 1,
			width => -2 * $padding,
		);
		$self->{footer_widget}->place(x => 0, relwidth => 1, width => 0);
	}
	
	# Set the visibility of the toc widget
	$self->{toc_widget}->visible($is_visible);
	
	return $is_visible;
}

sub footer_visible {
	my $self = shift;
	return $self->{footer_visible} if @_ == 0;
	
	my $is_visible = $self->{footer_visible} = $_[0];
	
	# Update the size of the main container (which already has relheight of 1)
	my $padding = $self->{padding};
	if ($is_visible) {
		my $height = $self->footer_height;
		$self->container->place( y => $height + $padding, relheight => 1,
				height => -$height - 2 * $padding);
	}
	else {
		$self->container->place( y => $padding, height => -2 * $padding
				, relheight => 1);
	}
	
	# Set the visibility of the toc widget
	$self->{footer_widget}->visible($is_visible);
	
	return $is_visible;
}

=head2 reslide

Redraws the current slide, if the current selection is defined.

=cut

sub reslide {
	my $self = shift;
	my $curr_slide = $self->{curr_slide};
	if (defined $curr_slide) {
		my $slide = $self->{slides}->[$curr_slide];
		$slide->tear_down;
		$slide->setup;
	}
}

=head2 n_slides

Read-only accessor that returns the number of slides in the deck.

=cut

sub n_slides {
	carp('n_slides is a read-only property') unless @_ == 1;
	return scalar (@{$_[0]->{slides}});
}

=head2 slide

Gets or sets the offset of the currently viewed slide. In set mode, causes
the slide contents to change. Slide counting starts from zero and negative
offsets are allowed.

Setting the current slide to C<undef> is allowed, in which case the current
slide (if any) is torn down, but no slide is selected for display. In other
words, C<< $talk->slide(undef) >> is a simple way to invoke the current
slide's tear-down method while keeping the deck's state intact.

=cut

sub slide {
	# Handle the getter case
	return $_[0]->{curr_slide} if @_ == 1;
	
	# The rest is for the setter case
	
	my ($self, $number) = @_;
	
	# Handle the special case of undef, in which case we simply tear down
	# the currently selected slide, if any.
	if (not defined $number) {
		my @slides = $self->slides;
		$slides[$self->{curr_slide}]->tear_down if defined $self->{curr_slide};
		$self->{curr_slide} = undef;
		return;
	}
	
	# Ensure we have some slides in our deck
	if ($self->n_slides == 0) {
		carp('slide called on a deck that had no slides (yet?)');
		return;
	}
	
	# Make sure the request is within range, neither too big nor too negative
	if ($self->n_slides < $number) {
		carp("Requested slide offset ($number) too big; truncating to "
			. $self->n_slides - 1);
		$number = -1;
	}
	if ($number + $self->n_slides < 0) {
		carp("Requested negative slide offset ($number) too big (negative); "
			. 'truncating to 0');
		$number = 0;
	}
	
	# Allow negative slide offsets, which count from the end
	$number += $self->{n_slides} if $number < 0;
	
	# Call the current slide's cleanup method
	my @slides = $self->slides;
	if (defined $self->{curr_slide}) {
		$slides[$self->{curr_slide}]->tear_down;
	}
	
	# Set up this slide and save the current slide number
	$slides[$number]->setup;
	$self->{curr_slide} = $number;
	
	# Update the table of contents and footer
	$self->update_toc;
	$self->update_footer;
}

=head2 title_font_ratio

Get/set the title font ratio, the ratio of the WideSection title font to the
normal font. The height of the normal title space, the banner at the top of
the slide, is governed by C<title_height>.

=cut

sub title_font_ratio {
	return $_[0]->{title_font_ratio} if @_ == 1;
	$_[0]->{title_font_ratio} = $_[1];
}

=head2 build_toc

Function to build the initial structure of the table of contents.

=cut

sub build_toc {
	my $self = shift;
	
	# Add a bit of padding on the top and side
# working here - use the same padding as for basic container?
	$self->{toc_widget}->insert(Widget =>
		pack => { side => 'top', fill => 'x' },
		width => $self->toc_width,
		height => 5,
		color => $self->{toc_color},
		backColor => $self->{toc_backColor},
	);
	$self->{toc_widget}->insert(Widget =>
		pack => { side => 'left', fill => 'y' },
		width => 5,
		color => $self->{toc_color},
		backColor => $self->{toc_backColor},
	);
	$self->grow_toc(40);
}

=head2 grow_toc

Grows the table of contents by the given number of labels.

=cut

use Prima::PodView;   # Need this for the hand icon
sub grow_toc {
	my ($self, $n_to_add) = @_;
	my $toc_widget = $self->{toc_widget};
	my $toc_width = $self->toc_width;
	my %font_hash = (
		name     => $self->font->name,
		style    => $self->font->style,
		height   => $self->{toc_font_height},
		encoding => $self->font->encoding,
	);
	for (1..$n_to_add) {
		# Add the basic container
		my $toc_label_container = $toc_widget->insert(Widget =>
			pack => { side => 'top', fill => 'x', },
			color => $self->{toc_color},
			backColor => $self->{toc_backColor},
			height => $self->{toc_font_height},
		);
		# Create a hash of coderefs that we can later manipulate as
		# necessary
		my %toc_callbacks = (
			click => sub {},
		);
		# Add the label
		push @{$self->{toc_labels}}, $toc_label_container->insert(Label =>
			place => {
				x => 0, width => $toc_width,
				y => 0, relheight => 1,
				anchor => 'sw',
			},
			width => $toc_width,
			valignment => ta::Middle,
			pointer => $Prima::PodView::handIcon,
			color => $self->{toc_color},
			backColor => $self->{toc_backColor},
			font => \%font_hash,
			onMouseEnter => sub { $_[0]->font->style(fs::Underlined) },
			onMouseLeave => sub { $_[0]->font->style(fs::Normal) },
			onMouseClick => sub { $toc_callbacks{click}->() },
		);
		# Add the coderef hash
		push @{$self->{toc_callbacks}}, \%toc_callbacks;
	}
}

=head2 update_toc

Redraws the current slide's table of contents.

=cut

sub generate_toc_label_properties {
	my ($self, $label, $label_offset, $slide_data, $width, $is_current) = @_;
	my $toc_width = $self->toc_width;
	
	$label->text($slide_data->{name});
	$label->place( x => $width, width => $toc_width - $width );
	$label->width($toc_width - $width);
	$self->{toc_callbacks}[$label_offset]->{click} = sub {
		$self->slide($slide_data->{slide_offset});
	};
	
	if ($is_current) {
		$label->backColor($self->backColor);
		$label->color($self->color);
	}
	else {
		$label->backColor($self->{toc_backColor});
		$label->color($self->{toc_color});
	}
}

sub empty_label_properties {
	my ($self, $label, $offset) = @_;
	$label->text('');
	$self->{toc_callbacks}[$offset]->{click} = sub {};
	$label->backColor($self->{toc_backColor});
	$label->color($self->{toc_color});
}

sub update_toc {
	my $self = shift;
	
	# Nothing to do if the toc is not visible, there is not currently
	# selected slide, or there are no slides
	return if not $self->toc_visible or not defined $self->slide
		or 0 == $self->n_slides;
	
	# Display all the section titles, showing the slide titles only for
	# slides that are in this section.
	my @sections = @{$self->{sections}};
	
	# Add new toc entries
	my $slide_offset = $self->slide;
	my $toc_indent = $self->toc_indent;
	my $label_offset = 0;
	
	for my $section (@sections) {
		
		# Make sure we have enough labels lying around
		$self->grow_toc(5) if @{$self->{toc_labels}} == $label_offset;
		
		# Add this section's title to the toc
		my $section_label = $self->{toc_labels}->[$label_offset];
		$self->generate_toc_label_properties($section_label, $label_offset,
			$section, 0, $slide_offset == $section->{slide_offset});
		
		$label_offset++;
		
		# if this is the current section and it has sub-slides, add them
		if (exists $section->{sub_slides}
				&& $section->{slide_offset} <= $slide_offset
				&& $section->{slide_offset} + @{$section->{sub_slides}} >= $slide_offset
		) {
			for my $slide (@{$section->{sub_slides}}) {
				# Make sure we have enough labels lying around
				$self->grow_toc(5) if @{$self->{toc_labels}} == $label_offset;
				
				my $slide_label = $self->{toc_labels}->[$label_offset];
				$self->generate_toc_label_properties($slide_label,
					$label_offset, $slide, $toc_indent,
					$slide_offset == $slide->{slide_offset}
				);
				
				$label_offset++;
			}
		}
	}
	
	while ($label_offset < @{$self->{toc_labels}}) {
		$self->empty_label_properties($self->{toc_labels}->[$label_offset],
			$label_offset);
		$label_offset++;
	}
}

=head2 previous_slide

Rewinds the talk to the previous slide in the deck

=cut

sub previous_slide {
	my $self = shift;
	
	# Get the current slide
	my $curr_slide_offset = $self->slide;
	
	# Do nothing if we do not have a defined slide
	return unless defined $curr_slide_offset;
	
	# Check if the current slide can transition back, and return if so
	my @slides = $self->slides;
	return if $slides[$curr_slide_offset]->transition(-1);
	
	# Do nothing if currently at the first slide
	return if $curr_slide_offset == 0;
	
	# Rewind one
	$self->slide($curr_slide_offset - 1);
}

=head2 next_slide

Advances the talk to the next slide in the deck

=cut

sub next_slide {
	my $self = shift;
	
	# Get the current slide
	my $curr_slide_offset = $self->slide;
	
	# Advance to the first slide if we're currently undefined
	return $self->slide(0) if not defined $curr_slide_offset;
	
	# Check if the current slide can transition forward, and return if so
	my @slides = $self->slides;
	return if $slides[$curr_slide_offset]->transition(1);
	
	# Do nothing if currently at the last slide
	return if $curr_slide_offset == $self->n_slides - 1;
	
	# Advance one
	$self->slide($curr_slide_offset + 1);
}

=head2 special_key

Calls the "special_key" callback for the given slide, if one exists.

=cut

sub special_key {
	my $self = shift;
	
	# Get the current slide; exit if it doesn't make sense
	my $curr_slide_offset = $self->slide;
	return unless defined $curr_slide_offset;
	
	# Get the current slide and call its callback
	my $curr_slide = ($self->slides)[$curr_slide_offset]->special_key;
}

=head2 slides

Getter/setter for the list of slides. Returns an array of slide objects if
called without any arguments. If called with arguments, all arguments are
assumed to be slides, the collection of which becomes the slide deck.

Clears the slide deck if called with a single undef. Note that clearing a
deck does not ensure that the slides are destroyed.

=cut

sub slides {
	my ($self, @slides) = @_;
	
	# Getter case
	return @{$self->{slides}} if @slides == 0;
	
	# Special setter case---array with only one undef element---clears out
	# the slides.
	if (@slides == 1 and not defined $slides[0]) {
		$self->{slides} = [];
		$self->{curr_slide} = undef;
		return;
	}
	
	# Generic setter case: make sure the slides are OK before finalizing
	for my $slide (@slides) {
		eval {
			$slide->slide_deck($self);
			1;
		} or do {
			croak("Slide [$slide] could not be added to the deck: $@");
		}
	}
	
	# Tear down the current slide
	my $curr_slide = $self->slide;
	$self->slide(undef);
	
	# Assign the list of slides
	$self->{slides} = \@slides;
	
	# Parse the slides into the section/slide nested structure
	# Run through all the slides, gathering toc titles and parsing section
	# structure. Each entry is an anonymous hash with:
	# {
	#	name => 'name-for-toc',
	#	slide_offset => slide-list-offset-number,
	#	sub_slides => [],
	# }
	
	my @sections;
	my $curr_section_list = \@sections;
	for (my $i = 0; $i < @slides; $i++) {
		my $slide = $slides[$i];
		my %details = (
			name => $slide->toc_entry,
			slide_offset => $i,
		);
		
		# If we encounter a section, wrap-up the current section
		if ($slide->isa('Prima::Talk::Section')) {
			$curr_section_list = $details{sub_slides} = [];
			push @sections, \%details;
		}
		else {
			push @$curr_section_list, \%details;
		}
	}
	$self->{sections} = \@sections;
	
	# Go to the selected slide
	if (defined $curr_slide) {
		$curr_slide = $#slides if @slides < $curr_slide;
		$self->slide($curr_slide);
	}
}

=head2 add

Adds a new slide. This accepts two kinds of arguments. Slide objects are
appended to the deck, and a class => constructor-key/value pairs leads to a
slide object of the specified class that is built with the arguments passed
in the hashref. Note that the class name can be either a full class name, or
a class name to which C<Prima::Talk::> should be appended. For example, both
C<Prima::Talk::Slide> and simply C<Slide> can be used to build a new slide.
You can achieve the same end with the C<slides> method, but this makes things
easier.

For example:

 my $talk = Prima::Talk->new;
 my $title_slide = Prima::Talk::Title->new('Title', 'David Mertens');
 $talk->add($title_slide);
 $talk->add(Section =>
     # key/value Prima::Talk::Section spcification here
 );
 $talk->add(Slide =>
     # key/value spec for the Prima::Talk::Slide object
 );
 $talk->add(Slide =>
     # key/value spec for another Prima::Talk::Slide
 );

=head2 Prima::Talk::DONT_ADD

This is global variable that, when set to true, turns L</slide> into a
no-op. This is quite useful when you are working through the writing stage
of your talk. If you are building a set of slides and are constantly
switching between editing and viewing, it is handy to disable a set of
slides. Consider starting with this set of slides:

 $talk->add(Slide =>
   ... content for first slide ...
 );
 
 $talk->add(Slide =>
   ... content for second slide ...
 );
 
 $talk->add(Slide =>
   ... content for third slide ...
 );
 
 $talk->add(Slide =>
   ... CURRENTLY WORKING HERE ...
 );

To disable the rendering for the first three slides you simply surround
them with a block and localize C<Prima::Talk::DONT_ADD> to a true value:

 {  # open an block so the localization works correctly
 
 local $Prima::Talk::DONT_ADD = 1;
 
 $talk->add(Slide =>
   ... content for first slide ...
 );
 
 $talk->add(Slide =>
   ... content for second slide ...
 );
 
 $talk->add(Slide =>
   ... content for third slide ...
 );
 
 }  # close the block; re-enable slide addition
 
 $talk->add(Slide =>
   ... CURRENTLY WORKING HERE ...
 );

=cut

use Scalar::Util qw(blessed);

sub add {
	return if $Prima::Talk::DONT_ADD;
	my $self = shift;
	
	# exit if no argument
	if (@_ == 0) {
		carp('Talk::add called with no slides to add');
		return;
	}
	
	# Did they supply a collection of slides?
	if (blessed($_[0]) and $_[0]->isa('Prima::Talk::Slide')) {
		# Make sure everything is a slide object
		my @slides = grep {blessed($_) and $_->isa('Prima::Talk::Slide')} @_;
		carp('Not all objects supplied to Talk::add are slides; ignoring non-slides')
			if @slides != @_;
		
		# append the slides
		$self->slides($self->slides, @slides);
		return;
	}
	
	# No, so they should have supplied a class name and a bunch of arguments
	my $potential_class_name = shift @_;
	my $class_name;
	for my $check ($potential_class_name, "Prima::Talk::$potential_class_name") {
		if ( eval { $check->isa('Prima::Talk::Slide') } ) {
			$class_name = $check;
			last;
		}
	}
	croak("Neither $potential_class_name nor Prima::Talk::$potential_class_name "
		. 'are valid slide class names') unless defined $class_name;
	
	# Ensure they provided key/value constructor options
	croak("Arguments for $class_name constructor not supplied as key/value pairs")
		if @_ % 2 == 1;
	
	# append the slide
	$self->slides($self->slides, $class_name->new(@_));
}

=head2 DONT_add

This is a no-op that is handy if you have a slide that you don't want to
show but which you don't want to delete quite yet. As with
C<Prima::Talk::DONT_ADD>, this is handy during the editing process, but it
offers a slightly more fine-graned approach to omitting slides. For
example, if you have three slides and you are considering omitting the
second, but don't want to just delete the code, you could change this:

 $talk->add(Slide =>
   ... content for first slide ...
 );
 
 $talk->add(Slide =>
   ... content for second slide ...
 );
 
 $talk->add(Slide =>
   ... content for third slide ...
 );

to this:

 $talk->add(Slide =>
   ... content for first slide ...
 );
 
 $talk->DONT_add(Slide =>
   ... content for second slide ...
 );
 
 $talk->add(Slide =>
   ... content for third slide ...
 );

=cut

sub DONT_add {}

=head2 set_title

Sets the talk's title text, but does not call any triggers, callbacks, or
anything else. This simply changes the title text.

=cut

sub set_title {
	my ($self, $title) = @_;
	$self->{title_label}->text($title);
}

=head2 notes_window

Returns the container window that represents the notes window. If no notes
window was defined when the talk was created, this returns the undefined
value.

This is used primarily during slide setup and tear down to render any
notes elements.

=cut

sub notes_window {
	return $_[0]->{notes_window};
}

=head2 animate

Kicks off an animation sequence. Takes the number of frames, the timeout
(in milliseconds), and a subroutine reference that executes the animation.

 Prima::Talk::animate($N_frames, $timeout, sub {
   my ($curr_frame, $N_frames) = @_;
   # do animation for the current frame
 });

=cut

sub animate {
	my ($N_frames, $timeout, $sub) = @_;
	
	# Create a state variable for the timer
	my $counter = 0;
	Prima::Timer->create(
		timeout => $timeout,
		onTick => sub {
			my $self = shift;
			
			if ($counter < $N_frames) {
				$sub->($counter, $N_frames);
				$counter++;
			}
			else {
				$self->destroy;
			}
		},
	)->start;
}

=head1 CREATING SLIDES

You can create slides either by calling the C<new> method on the desired slide
class or by supplying the class name to your slide deck's L</add> method.

=cut

package Prima::Talk::Slide;
use Carp;

sub new {
	my $class = shift;
	$class = ref($class) || $class;
	my $self = bless { @_ }, $class;
	$self->init;
	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	my $stash_name = our $AUTOLOAD;
	$stash_name =~ s/.*:://;
	# Called as a setter
	if (@_ == 1) {
		my $new_value = shift;
		return $self->{stash}->{$stash_name} = $new_value;
	}
	# Called as a getter
	return $self->{stash}->{$stash_name}
		if @_ == 0 and exists $self->{stash}->{$stash_name};
	
	# Carp if called as a getter, but no value yet
	if (@_ == 0) {
		carp("No stashed value for `$stash_name'");
		return;
	}
	
	# Croak if called with arguments, as this is clearly not what was
	# meant to happen
	croak("Unknown slide method `$stash_name'");
}

=pod

The constructor expects a list of key/value pairs. None of these keys are
strictly necessary, but some are expected and will issue a warning if you do
not provide them. The basic keys dictate the appearance of the slide:

=over

=item title

 title => String (expected)

The string to use for the slide's title. This is one of the expected keys that
will issue a warning if you do not provide one, and the string C<No name> will
be used as the title if none is supplied. Unless you supply a C<toc> entry,
this string will also be used for the table of contents listing.

=item content

 content => String | CodeRef | ArrayRefOf[ContentPairs] (expected)

The content should be a paragraph to display, a coderef to execute, or an
anonymous I<array> of content material. Although the key/value pairs of the
array form of content looks a lot like an anonymous hash, the content is
produced in order, so you must us an arrayref. You will get a warning if you
accidentally use a hashref.

Here is a simple example of a paragraph, some bullets, and a centered image:

 content => [
   par => 'You should take certain precautions when feeding
           a hoard of cats. You should always:',
   bullets => [
     'remove catnip from pockets,',
     'wear thick jeans and leather gloves, and',
     'quickly step away as soon as the food is down.',
   ],
   image => {
     filename => 'one-hundred-hungry-cats.jpg',
     alignment => ta::Center,
   },
 ],

The equivalent coderef form looks like this:

 content => sub {
   my ($slide, $container) = @_;
   $slide->render_par('You should take certain precautions
     when feeding a hoard of cats. You should always:',
     $container);
   $slide->render_bullets([
     'remove catnip from pockets,',
     'wear thick jeans and leather gloves, and',
     'quickly step away as soon as the food is down.',
     ], $container);
   $slide->render_image({
     filename => 'one-hundred-hungry-cats.jpg',
     alignment => ta::Center,
   }, $conainer);
 },

The coderef form is more verbose, and therefore more tedious for static
material. However, it also gives you a simple way to determine the material
dynamically in ways that the data structure in the first for does not. Of
course, Prima::Talk lets you mix and match the two forms as necessary. One
suitable L<content type|/Content Types> that you could include in the array
of content is a L<subref> type, which will be executed during slide
rendering. Conversely, one method that slides support is L<render_content>.
In the arrayref content specification, you would specify code to be executed
as

 content => [
   par => 'a paragraph...',
   subref => sub {
     my ($slide, $container) = @_;
     ... code to be exectued ... 
   },
   par => 'more static content...', 
 ],

When using the coderef specification, you could incorporate a nested data
structure as

 content => sub {
   my ($slide, $container) = @_;
   $slide->render_content($container,
     par => 'static-content formatting...',
     bullets => [get_bullets_text()],
     par => 'more static content...',
   );
   # more dynamic code can go here... 
 },

Most of the L<content types|/Content Types> expect a hashref of
configuration arguments, but can take a single argument (usually a string)
and do something intelligent with it.

=item notes

 notes => String | CodeRef | ArrayRefOf[ContentPairs]

If you declared a C<notes_window> when you built your slide deck, the
content you specify with your notes will be rendered in your notes window.
You can interact with named content in transitions, just as with your
normal content. This is most useful in a two-monitor setup, in which case
you can position your talk's window on the "second" screen and your notes
window on the first screen. Although called "notes", any content is allowed,
including interactive elements that you may wish to hide from your audience.

=item toc

 toc => String

Specifies the string to use in the table of contents listing. This is most
useful if you want to use a shorter string for the table of contents, or if
you want your table of contents to convey other information. If you do not
supply a C<toc> entry, the C<title> will be used, though bear in mind it may
not quite fit.

=item font_factor

 font_factor => Number

If you want the font sizes for this slide to be slightly smaller or larger
than default, you can specify a font factor. Values larger than 1 will amplify
the font size; values smaller than 1 will diminish the font size. Bear in mind
that in Prima, font sizes are measured in whole numbers of points and Prima
will round to the nearest font size for your given ratio. In other words, don't
expect to see any difference between C<< font_factor => 1.4999 >> and
C<< font_factor => 1.5 >>. This expects positive numbers and will complain if
you provide a non-number, or a negative number (and default to a factor of 1).

=item alignment

 alignment => ta::Left|ta::Right|ta::Center

Sets the slide's default alignment

=back

Transitions and dynamic behavior are my primary motivation for writing this
software. In addition to letting you generate the slide content through
blocks of code, the basic Slide class gives you a few rather general
mechanisms for specifying intra-slide transitions. The constructor key/value
pairs for specifying this dynamic behavior include:

=over

=item transitions

 transitions => ArrayRefOf[CodeRef|HashRef]

The simplest sort of intra-slide transitions can be specified by providing
a collection of coderefs to the C<transitions> key. Whether we came to this
slide from the previous slide or the next slide (or any other slide), the
transitions I<always> start from the first one. This behavior differs from
most other presentation software when going I<backward> through slides, a
point which I'll clarify in a bit.

For example, suppose that we want to emphasize two different parts of the
slide in sequence, starting off initially with everything drawn in black,
then highlighting one of the elements, then highlighting the second and
unhighlighting the first, and finally unhighlighting the second. A naive set
of transitions using color changes to achieve the highlighting would look
like this:

 content => [
   par => {
     name => 'foo',
     text => 'First important thing',
   }
   par => {
     name => 'bar',
     text => 'Second important thing',
   }
 ],
 transitions => [
   # no setup, so this is empty
   sub {},
   # highlight foo
   sub {
     my $slide_obj = shift;
     $slide_obj->foo->color(cl::LightRed);
   },
   # unhilight foo, highlight bar
   sub {
     my $slide_obj = shift;
     $slide_obj->foo->color(cl::Black);
     $slide_obj->bar->color(cl::LightRed);
   },
   # unhilight bar
   sub {
     my $slide_obj = shift;
     $slide_obj->bar->color(cl::Black);
   }
 ],

For a real talk, this set of transitions is problematic. It is quite common
to want to go backwards as well as forwards during a talk, and these
transitions do not handle backwards transitions gracefully. For example,
after highighting foo, if we go backwards by pressing the up or left or
page-up key, the first coderef will be called again, and it does not do
anything. We need it to un-highlight foo. Similarly, if we advance up to the
third transition and then go back to the second, the code for the second
transition will re-highlight foo but not unhighlight bar. A better set of
transitions would be these:

 content => [
   par => {
     name => 'foo',
     text => 'First important thing',
   }
   par => {
     name => 'bar',
     text => 'Second important thing',
   }
 ],
 transitions => [
   sub {   ### Initially all black
     my ($slide_obj, $dir) = @_;
     # unhighlight foo on a backwards transition
     $slide_obj->foo->color(cl::Black) if $dir < 0;
   },
   sub {   ### Highlight foo
     my ($slide_obj, $dir) = @_;
     # highlight foo
     $slide_obj->foo->color(cl::LightRed);
     # unhighlight bar on a backwards transition
     $slide_obj->bar->color(cl::Black) if $dir < 0;
   },
   sub {   ### Highlight bar
     my ($slide_obj, $dir) = @_;
     $slide_obj->bar->color(cl::LightRed);
     # unhighlight foo on a forwards transition
     $slide_obj->foo->color(cl::Black) if $dir > 0;
   },

   sub {   ### Go back to all black
     my ($slide_obj, $dir) = @_;
     $slide_obj->bar->color(cl::Black);
   }
 ],

The above code also shows you the arguments that are passed to each
transition coderef: the slide object and the direction of the transition. A
direction of 1 or -1 indicates a forward or backward transition,
respectively. The first transition coderef may also get a direction of 0,
which indicates that the slide was just transitioned to from a different
slide. It also follows logically that the first coderef should never get a
direction of 1: it should only get a 0 or -1.

You probably noticed that I accessed the paragraphs by invoking the
paragraph name on the slide object. Any named content is accessible in this
way, called I<stashing>. You can store arbitrary data in the stash by
calling your desired stash key as a setter:

 # Set up the data
 $slide_obj->some_data([1 .. 10]);
 ...
 $slide_obj->some_data->[4] = -5;

Be aware that the slide's reference to the stashed values is destroyed upon
slide tear-down. If you later return to the slide, you will have to
re-initialize your stash data. If you need your data to persist even after
you leave the slide, you could store the data in lexical or package
variables, or consider more robust data caching options.

Notice in the set of transitions give above that we change the color of
C<foo> to black in both the first and third transitions. A more natural
approach would be to reset C<foo>'s color upon I<leaving> the second
transition. You can provide such enter and exit coderefs by specifying a
hash of coderefs rather than a single transition coderef:

 transitions => [
   
   sub { },### No initialization
   
   {       ### Highlight foo
     enter => sub {
       my $slide_obj = shift;
       $slide_obj->foo->color(cl::LightRed);
     },
     leave => sub {
       my $slide_obj = shift;
       $slide_obj->foo->color(cl::Black);
     }
   },
   
   {       ### Highlight bar
     enter => sub {
       shift->bar->color(cl::LightRed);
     },
     leave => sub [
       shift->bar->color(cl::Black);
     },
   },
   
   sub { },### Final state is all black
 ],

The coderefs for the C<enter> and C<leave> keys get called with the slide
object and the transition direction. Two additional keys, C<leave_forwards>
and C<leave_backwards>, can be used as well, and these are only called with
the slide object. And finally, empty hashrefs are allowed, so you could just
as well replace the empty coderefs with empty hashrefs and achieve the same
end.

I mentioned already that the set of transitions always starts with the first
transition. You can think of each slide as its own sort of mini-slideshow.
Each time you land on a slide, it I<starts> the mini-slideshow from the
beginning. Putting a programmer's perspective on it, a presentation is one
huge state machine. Slides know how to set up their state from scratch, and
it is possible to jump around between slides. However, intra-slide
transitions do I<not> know how to set up their state from scratch: they
assume that the previous state was created by the transition coderef
immediately preceding or following. As a corollary, the last coderef in a
sequence of transitions should never get a direction of -1.

Of course, you may find that you need to jump into the middle of your
sequence of transitions. In that case, the C<transitions> key is not the
right tool for the job. You should either (1) revise your talk so that each
important intermediate state gets its own slide, or (2) use a more dynamic
slide whose state is specified by either transition clicks or by some form
of input widget. You can then "jump" to the desired state by entering the
appropriate input into the input widget. For the latter option, you will
probably want to use the L</transition> key, which I discuss next.

=item transition

 transition => CodeRef

While the C<transitions> key discussed above lets you specify a
pre-determined sequence of transitions, the C<transition> key makes no such
assumptions. This makes it more primitive and yet more powerful: the number
of transitions and their behavior can be varied dynamically depending on
whatever sort of input you like.

The coderef you provide to C<transition> gets called just like those under
C<transitions>: with the slide object and the transition direction.

Unlike the coderefs in the C<transitions> key, the return value of your
C<transition> coderef is important: a boolean true value means "stay on this
slide" while a boolean false value means "leave this slide". In the latter
case, if the transition direction is negative the talk will go to the
previous slide, and if the transition direction is positive the talk will go
to the next slide.

XXX discuss how to use this.

=item special_key

 special_key => CodeRef

Some clickers have a special key on them. C<Prima::Talk> pays attention to
these events and calls the supplied subref whenever they occur. This provides
a means of invoking dynamic behavior distinct from intra-slide transitions.
The sole argument to the special key coderef is the slide object.

=item tear_down

 tear_down => CodeRef

It is tempting to put resource cleanup code in your transitions. Given the
usual way to "leave" a slide (by a forward or backward transition issued in
response to a page-down or page-up keypress, for example) this would seem
like a sensible thing to do. However, it is also possible to leave the slide
by clicking on one of the other slides in the table of contents, or issuing
a Goto Slide command by pressing the 'g' key. Such an exit can happen in the
middle of a series of intra-slide transitions.

The simplest way to handle cleanup is to store data in your stash which
knows how to garbage collect itself. For example, lexical file handles
automatically close themselves when garbage collected. However, if you need
to specify particular cleanup code, you should supply a C<tear_down>
coderef:

 tear_down => sub {
   my $self = shift;
   # cleanup code goes here ...
 },

The tear-down coderef is called before the stash is cleared or the content
widgets are destroyed.

=item subref content type

Although not strictly an argument to the constructor, one of the supported
content types is a subref. This content type simply specifies a subroutine
that should be called during slide rendering. Although you could use subref
content types to initialize slide state, I recommend using this content type
primarily for I<rendering visible content>. The exception to this rule
arises when you need to tweak the slide before any content rendering. For
example, if a custom content type needs stashed data, or if you need to
dynamically tweak the slide before rendering the content, a subref
content type would be appropriate. This and other content types are
discussed in greater depth below.

=back

XXX Put this somewhere more useful

Furthermore, Prima::Talk::animation provides a convenient mechanism for
calling a subroutine a fixed number of times in sequence.

=cut

sub init {
	my $self = shift;
	
	# Set up a clean stash
	$self->{stash} = {};
	
	# Make sure we have a name
	if (not defined $self->{title}) {
		carp('No title for slide!');
		$self->{title} = 'No name';
	}
	# Make sure we have a toc entry
	$self->{toc_entry} = $self->{toc} if exists $self->{toc};
	$self->{toc_entry} = $self->{title} unless exists $self->{toc_entry};
	
	# Make sure we have a good font size factor
	$self->{font_factor} ||= 1;
	if (not Scalar::Util::looks_like_number($self->{font_factor})
		or $self->{font_factor} <= 0
	) {
		carp('Ignoring non-numeric or negative font_factor');
		$self->{font_factor} = 1;
	}

	# gripe if they don't have content
	if (not defined $self->{content}) {
		carp('No content for slide!');
		$self->{content} = [par => 'No content'];
	}
	# If they supplied a single text string, interpret it as a paragraph
	elsif (ref ($self->{content}) eq ref('')) {
		$self->{content} = [par => $self->{content}];
	}
	# If they supplied a single subref, set it up to be run
	elsif (ref ($self->{content}) eq ref(sub{})) {
		$self->{content} = [subref => $self->{content}];
	}
}

sub slide_deck {
	return $_[0]->{slide_deck} if @_ == 1;
	my ($self, $deck) = @_;
	# XXX weaken?
	$self->{slide_deck} = $deck;
}

sub title {
	return $_[0]->{title} if @_ == 1;
	my ($self, $title) = @_;
	$self->{title} = $title;
}

sub toc_entry {
	return $_[0]->{toc_entry} if @_ == 1;
	my ($self, $toc_entry) = @_;
	$self->{toc_entry} = $toc_entry;
}

sub content {
	my $self = shift;
	return @{$self->{content}} if @_ == 0;
	if (@_ % 2 == 1) {
		carp("Content must be in key/value pairs");
		pop @_;
	}
	$self->{content} = [@_];
}

sub set_toc_visibility {
	# Turn on the table of contents
	my $self = shift;
	
	$self->slide_deck->toc_visible(1);
}

sub set_footer_visibility {
	my $self = shift;
	
	$self->slide_deck->footer_visible(1);
}

sub font_factor {
	my $self = shift;
	return $self->{font_factor} if @_ == 0;
	$self->{font_factor} = $_[0];
}

sub font_size {
	my $self = shift;
	
	# Called as a getter
	return $self->slide_deck->container->font->{size} * $self->font_factor
		if @_ == 0;
	
	# Called as a setter
	my $new_size = $_[0];
	$self->font_factor($new_size / $self->slide_deck->container->font->{size});
}

sub setup {
	my $self = shift;
	
	# Turn on the table of contents, get the slide container
	$self->set_toc_visibility;
	$self->set_footer_visibility;
	my $container = $self->slide_deck->container;
	
	# Focus on the talk widget. User interaction with widgets on previous
	# slides can cause us to lose focus and therefore not get slide advance
	# commands. This circumvents that. Slides can alter the focus with their
	# rendering commands if necessary.
	$self->slide_deck->focus(1);
	
	# Add some padding
	$container->insert(Widget =>
		width => 5,
		pack => { side => 'left', fill => 'y' },
		color => $container->color,
		backColor => $container->backColor,
		name => 'container_padding',
	);
	
	# Render the content
	# working here - add multicolumn support
	$self->render_content($container, title => $self->title, $self->content);
	
	# Render notes, if applicable
	$self->render_content($self->slide_deck->notes_window, @{$self->{notes}})
		if Prima::Object::alive($self->slide_deck->notes_window);
	
	$self->{stash}->{transition_count} = 0;
	$self->transition(0);
}

sub special_key {
	my $self = shift;
	$self->{special_key}->($self) if exists $self->{special_key};
}

=head2 prepare_font_hash

 $content{font} = $slide->prepare_font_hash($content{font}, $container);

Given a hashref with extended font specifications, prepares a font hashref
merged with the parent container's font specification. Note that this method
gracefully handles an undefined input font hash, so you need not check if
C<$content{font}> exists before calling this method. (However, you need to
ensure that the container is a Prima widget. We can only be so graceful
here.)

The extended font specification mostly focuses on size. Normally font sizes
must be in pixels, but here you can specify a multiple of the parent
container's font size with the C<x> suffix, such as C<1.2x>. You can also
use the normal size specifications for container dimensions discussed under
L</calculate_size>. Note the C<em> widths are relative to the slide-deck's
standard em-width, not the container's em-width.

=cut

sub prepare_font_hash {
	my ($self, $hashref, $container) = @_;
	return $container->font if not defined $hashref;
	
	my %font = %$hashref;
	# Account for relative sizes.
	if ($font{size}) {
		if ($font{size} =~ s/x$//) {
			$font{size} = $container->font->size * $font{size};
		}
		elsif ($font{size} =~ /[^\d.]/) {
			$font{size} = $self->slide_deck->calculate_size('font_size',
				$font{size}, $container);
		}
	}
	if ($font{height}) {
		if ($font{height} =~ s/x$//) {
			$font{height} = $container->font->height * $font{height};
		}
		elsif ($font{height} =~ /[^\d.]/) {
			$font{height} = $self->slide_deck->calculate_size('font_height',
				$font{height}, $container);
		}
	}
	return $container->font_match(\%font, $container->font, 1);
}


sub render_content {
	my ($self, $container, @content) = @_;
	while (@content) {
		my ($type, $stuff) = (shift @content, shift @content);
		my $rendered_content;
		if ($self->{"render_$type"}) {
			$rendered_content = $self->{"render_$type"}->($self, $stuff, $container);
		}
		elsif (my $subref = $self->can("render_$type")) {
			$rendered_content = $subref->($self, $stuff, $container);
		}
		else {
			carp("Unknown content type $type; defaulting to paragraph rendering");
			$rendered_content = $self->render_par($stuff, $container);
		}
		# Stash named content
		if(ref($stuff) eq 'HASH' and exists $stuff->{name}) {
			$self->{stash}->{$stuff->{name}} = $rendered_content;
		}
	}
}

sub alignment {
	return $_[0]->{alignment} || ta::Left;
}

sub get_alignment_for {
	my ($self, $widget) = @_;
	# First, does the widget have the algnment property?
	return $widget->alignment if eval{$widget->can('alignment')};
	# OK, does it have an alignment property?
	return $widget->{alignment} if exists $widget->{alignment};
	# OK, return *our* alignment if all else fails
	return $self->alignment;
}

sub render_title {
	my ($self, $title, $container) = @_;
	$self->slide_deck->set_title($title);
}

=head1 Content rendering

Rendering basic content on your slides is pretty easy, and Prima::Talk::Slide
provides a number of mechanisms for adding new rendering commands. For
example, the content arrayref to render some text and an image is

 content => [
     par => 'Chloe, my cat:',
     image => 'chloe-on-pillow.jpg',
     par => 'My dog, Buster:',
     image => 'buster-drinking-water.png',
 ],

If you want to have those images centered, you use a hashref with options:

 content => [
     par => 'Chloe, my cat:',
     image => {
         filename => 'chloe-on-pillow.jpg',
         alignment => ta::Center,
     },
     par => 'My dog, Buster:',
     image => {
         filename => 'buster-drinking-water.png',
         alignment => ta::Center,
     },
 ],

Most content renderers work with a hashref of arguments, but some (like
C<par> and C<image> shown above) accept a string and do something sensible
with it. The expected keys in the hashref are discussed in the documentation
for each renderer, below.

I often find that the built-in rendering types are not versatile enough for
my needs. Thankfully, there are many ways to write custom renderings. You
can begin by using the L<subref|/subref> rendering type, which simply expects
to get an anonymous subroutine or a subroutine reference. In fact, renderers
are not required to do anything, let alone render anything, so you could
simply sprinkle your content arrayref with diagnostic print statements, in
addition to rendering stuff:

 content => [
     subref => sub { print "About to render first paragraph\n" },
     par => 'Chloe, my cat:',
     subref => sub { print "About to render first image\n" },
     image => 'chloe-on-pillow.jpg',
     subref => sub {
         my ($slide, $container) = @_;
         # Pack a button
         $container->insert(Button =>
             text => 'Click for message',
             onClick => sub {
                 Prima::MsgBox::message('Clicked!');
             },
             pack => { side => 'top', fill => 'x' },
         );
         print "All done!\n"
     },
 ],

If you actually want to render something, your subref can choose to either
invoke the slide's C<render_content> method, or pack the new content on its
own:

 content => [
     subref => sub {
         my ($slide, $container) = @_;
         # Pack a new widget with a custom
         # drawing command:
         $container->insert(Widget =>
             onDraw => sub {
                 my ($widget, $canvas) = @_;
                 my ($height, $width) = $canvas->size;
                 $canvas->line(0, 0, $height, $width);
             },
         );
     }
 ],

=over

=item container

The most generic content type is simply an empty container widget. A
container takes a hashref of arguments with keys that can include height,
width, color, backColor, alignment, name, font, and all normal L<Prima::Widget>
properties:

   ...
   content => [
     ...
     container => {
       height => '10%colheight', name => 'upper_container',
       font => { style => fs::Bold }, alignment => ta::Right,
     },
     ...
   ],
   ...

Containers do not provide any shorthand for rendering content inside them.
However, if you provide a name, you can easily access a container during
rendering callbacks or in transitions, adding or removing content. The font,
alignment, and other properties are used as the defaults for any child
content.

If you simply need a spacer, use the L<spacer|/spacer> content type, which
is even simpler than the container.

=cut

sub render_container {
	my ($self, $content, $parent_container) = @_;
	unless (ref($content) and ref($content) eq ref({})) {
		carp("Container expects a hashref specification; skipping");
		return;
	}
	
	my $height = $self->slide_deck->calculate_size(container_height =>
		$content->{height} || '99%colheight', $parent_container
	);
	my $width = $self->slide_deck->calculate_size(container_width =>
		$content->{width} || '99%colwidth', $parent_container
	);
	my $font = $self->prepare_font_hash($content->{font}, $parent_container);
	my $to_return = $parent_container->insert(Widget =>
		color => $parent_container->color,
		backColor => $parent_container->backColor,
		pack => { side => 'top', fill => 'x' },
		%$content,
		font => $font,
		height => $height,
		width => $width,
	);
	$to_return->{alignment} = $self->get_alignment_for($content->{alignment});
	return $to_return;
}

=item par

Renders a paragraph of text. The content renderer expects either a string
of text to render or a hashref of options which include C<text>, C<color>,
C<backColor>, C<alignment>, C<autoHeight>, C<wordWrap>, C<pack>, C<name>, 
and C<font>. Unless explicitly specified, the alignment uses the parent's
alignment.

=cut

sub render_par {
	my ($self, $content, $container) = @_;
	# XXX Alignment needs to be handled better wrt parent containers.
	my %params = ( alignment => $self->alignment );
	if (ref($content)) {
		%params = (%params, %$content);
	}
	else {
		$params{text} = $content;
	}
	
	if (not exists $params{text}) {
		carp("No text for paragraph; skipping");
		return;
	}
	
	# Die on deprecated font_factor behavior
	confess("par font_factor was removed; specify font => { size => '$params{font_factor}x' } instead\n")
		if exists $params{font_factor};
	
	# Merge the font hash
	$params{font} = $self->prepare_font_hash($params{font}, $container);
	
	# Clean out extra whitespace
	$params{text} =~ s/\s+/ /g;
	# Remove beginning and trailing whitespace
	$params{text} =~ s/^\s+//;
	$params{text} =~ s/\s+$//;
	
	my $label = $container->insert(Label =>
		color => $container->color,
		backColor => $container->backColor,
		autoHeight => 1,
		pack => { side => 'top', fill => 'x' },
		wordWrap => 1,
		alignment => $self->get_alignment_for($container),
		%params,
	);
	return $label;
}

=item tex

Renders LaTeX by building a document with the given content and packages,
running LaTeX on the document, and converting the resulting postscript file
to a PNG file. The PNG file is cached and the cached version is used if it
exists. You can use this to your advantage by running the talk on a machine
with LaTeX and copying the cache files, allowing you to give the talk on a
machine that does not even have LaTeX installed. The cache string is based
on a hashing of the tex (and possibly the tex in the C<packages> key, if one
is supplied).

The argument to tex should be either a string of TeX to render, or a hashref
with options that include a C<tex> key with the text to render, an optional
C<packages> key with the tex code containing the package inclusion commands,
and any raster file rendering options.

I commonly find that the default C<tex> rendering is not what I need. For
simple talks, the easiest solution is to create a new rendering type that
invokes the C<tex> renderer with a useful set of defaults:

 # Create the centered_latex renderer
 sub Prima::Talk::Slide::render_centered_latex {
     my ($slide, $content, $container) = @_;
     my ($self, $content, $container) = @_;
     return $slide->render_tex( {
         tex => $content,
         packages => q{
             \usepackage[T1]{fontenc}
             \usepackage[latin9]{inputenc}
             \usepackage{amsmath}
             \usepackage{babel}
         },
         alignment => ta::Center,
     }, $container);
 }

I can then simply say C<< centered_latex => '$eqn$' >> and I will get a
centered equation with my usual math symbols.

The text for the LaTeX packages are placed in the usual location, after the
article documentclass has been declared but before C<\begin{document}>.

Note: The size of the latex does B<not> change 

=cut

use Digest::MD5 qw(md5_hex);
sub render_tex {
	my ($self, $content, $container) = @_;
	
	# Get the hash of content
	$content = {tex => $content} unless ref($content);
	my %content = %$content;
	
	if (not exists $content{tex}) {
		carp("No tex content; skipping");
		return;
	}
	
	# Extract the package details and string of tex
	my $packages = delete $content{packages} || '';
	my $tex = delete $content{tex};
	
	# Build the cache name
	my $cache_name = 'latex-' . md5_hex($packages . $tex) . '.png';
	
	# Create the png image if the file does not already exist
	unless (-f $cache_name) {
		# Generate the latex document with the content
		open my $out_fh, '>', '_tmp.tex';
		print $out_fh '
\documentclass{article}
' . $packages . '
\pagestyle{empty}
\begin{document}
' . $tex . '
\end{document}
';
		close $out_fh;
		
		# Execute the tex and conversion
		eval {
			system('latex', '-interaction=nonstopmode', '_tmp.tex');
			return unless -f '_tmp.dvi';
			unlink '_tmp.tex';
			system('dvips', '-E', '_tmp.dvi');
			return unless -f '_tmp.ps';
			unlink '_tmp.dvi';
			system('convert', '-density', '1600', '_tmp.ps', '-flatten', $cache_name);
			return unless -f $cache_name;
			unlink '_tmp.ps';
			1;
		} or do {
			carp("Unable to render latex");
			return $self->render_par($content, $container);
		}
	}
	
	# Open the image and set it in the container
	$self->render_image({filename => $cache_name, %content}, $container);
}

my %image_cache;

sub get_image {
	my ($self, $filename) = @_;
	
	$image_cache{$filename}
		||= Prima::Image->load($filename) or do {
			carp("Unable to open image file $filename");
			return;
		};
	return $image_cache{$filename};
}

=item image

Renders an image using L<Prima::StretchyImage>. The argument should either
be a scalar string containing the filename to render (image files are cached
by Prima::Talk, so this is decently fast), or it should be a hashref which
includes keys appropriate for constructing a Prima::StretchyImage. The
default alignment is the slide's alignment, and the default color and
backColor are copied from the container widget. The default preserveAspect
is 1.

You can set the height and width using normal specs, and the image will be
stretched to fit. Otherwise the image's normal pixel size will be used.

=cut

sub render_image {
	my ($self, $content, $container) = @_;
	
	# Get the hash of content
	$content = { filename => $content } unless ref($content);
	my %content = %$content;
	
	# Utilize image file caching and render a paragraph with the image file
	# name if it fails
	if (exists $content{filename}) {
		my $filename = delete $content->{filename};
		$content{image} = $self->get_image($filename)
			or return $self->render_par({text => $filename, %content}, $container);
	}
	
	# Determine computed heights
	$content{height} = $self->slide_deck->calculate_size('image height' =>
		$content->{height}, $container) if exists $content{height};
	$content{width} = $self->slide_deck->calculate_size('image width' =>
		$content->{width}, $container) if exists $content{width};
	
	# Open the image and set it in the container
	return $container->insert(StretchyImage =>
		alignment => $self->get_alignment_for($container),
		color => $container->color,
		backColor => $container->backColor,
		preserveAspect => 1,
		%content,
		pack => { side => 'top', fill => 'x' },
	);
}

=item plot

Renders a plot. This content renderer expects a hashref of options, the keys
of which are passed to a L<Plot|PDL::Graphics::Prima> constructor.

=cut

sub render_plot {
	my ($self, $content, $container) = @_;
	require PDL::Graphics::Prima;
	my $height = $self->slide_deck->calculate_size(plot_height =>
		$content->{height} || '99%colheight', $container
	);
	my $width = $self->slide_deck->calculate_size(plot_width =>
		$content->{width} || '99%colwidth', $container
	);
	my $plot = $container->insert(Plot =>
		color => $container->color,
		backColor => $container->backColor,
		pack => { side => 'top' },
		%$content,
		font => $self->prepare_font_hash($content->{font}, $container),
		height => $height,
		width => $width,
	);
	return $plot;
}

=item two_column

The two column rendering type expects a hashref with options. Keys to set
the dimensions of the columns include C<left_width>, C<right_width>, and
C<height>. Keys that specify the content for each column are C<left> and
C<right>, which should correspond to hashrefs.

Unlike most other content types, two_column will actually croak if you
do not provide a hashref. There is simply no way for it to do anything
sensible with a scalar input.

When called as a function (C<render_two_column>), this renderable differs
from most others by returning different things in different contexts. This
renderable actally builds an outer container into which it packs the two
columns, and in scalar context returns that outer container. In list
context, however, it returns the left and right containers. As such, these
two blocks of code achieve nearly the same end:

 # option one:
 my ($left_col, $right_col)
   = $slide->render_two_column({
     left_width  => '40%colwidth',
     right_width => '55%colwidth',
   }, $container);
 # Now carry on with $left_col and $right_col ...
 
 # option two:
 $slide->render_two_column({
   left_width  => '40%colwidth',
   left_name   => 'dates',
   right_width => '55%colwidth',
   right_name  => 'times',
 }, $container);
 # Now carry on with $slide->dates and $slide->times ...

Although the upper example is less verbose, the containers declared in the
second example can be accessed by name as slide methods in later code. For
example, if you anticipate updating the contents of a column in one or more
slide transitions, it is probably best to name your columns. If you simply
need to dynamically construct the columns in a coderef, then getting the
two containers as the return values from the rendering method is probably
easier.

=cut

# XXX work on better general container property handling
# Let a user specify left_props => { width => ..., name => ..., etc }
# instead of the left_width, left_name, etc
# Then render using the container rendering.
sub render_two_column {
	my ($self, $content, $container) = @_;
	croak("two_column expects a hashref")
		unless ref($content) eq ref({});
	my $full_width = $container->width;
	my $left_width = $self->slide_deck->calculate_size( left_width =>
		$content->{left_width} || '48%colwidth', $container
	);
	my $right_width = $self->slide_deck->calculate_size( right_width =>
		$content->{right_width} || '48%colwidth', $container
	);
	my $height = $self->slide_deck->calculate_size( two_column_height =>
		$content->{height} || '99%colheight', $container
	);
	
	my $two_container = $container->insert(Widget =>
		height => $height,
		pack => { side => 'top', fill => 'x' },
		color => $container->color,
		backColor => $container->backColor,
	);
	$two_container->font->size($self->font_size);
	
	# Render the left content
	my $left_column = $two_container->insert(Widget =>
		width => $left_width,
		height => $height,
		place => { x => 0, width => $left_width, anchor => 'sw' },
		color => $container->color,
		backColor => $container->backColor,
	);
	if ($content->{left_name}) {
		$self->{stash}->{$content->{left_name}} = $left_column;
	}
	my @content;
	if ($content->{left}) {
		if (ref($content->{left}) eq ref([])) {
			@content = @{$content->{left}};
		}
		elsif (ref($content->{left}) eq ref({})) {
			carp("Left content passed in an anonymous hash; better to pass "
				."in an anonymous array to guarantee content order");
			@content = %{$content->{left}};
		}
		else {
			carp("Unknown left content; skipping");
		}
	}
	$self->render_content($left_column, @content);
	
	# Render the right content
	my $right_column = $two_container->insert(Widget =>
		width => $right_width,
		height => $height,
		place => {
			x => $full_width - $right_width, width => $right_width, anchor => 'sw'
		},
		color => $container->color,
		backColor => $container->backColor,
	);
	if ($content->{left_name}) {
		$self->{stash}->{$content->{left_name}} = $left_column;
	}
	if ($content->{right}) {
		if (ref($content->{right}) eq ref([])) {
			@content = @{$content->{right}};
		}
		elsif (ref($content->{right}) eq ref({})) {
			carp("Right content passed in an anonymous hash; better to pass "
				."in an anonymous array to guarantee content order");
			@content = %{$content->{right}};
		}
		else {
			carp("Unknown right content; skipping");
		}
	}
	$self->render_content($right_column, @content);
	
	# Return either the main container or both columns, depending on the
	# calling context.
	return unless defined wantarray;
	return $two_container unless wantarray;
	return ($left_column, $right_column);
}

=item spacer

Accepts a height, or a hashref that can specify color and backColor, among
other properties. You can name spacers, which can be useful if you need to
animate the height of a spacer, for example. However, rendering content
inside spacers is generally discouraged. Use a general container for that.

=cut

sub render_spacer {
	my ($self, $content, $container) = @_;
	
	# One-argument form specifies the height
	$content = { height => $content } unless ref($content);
	
	my %content = %$content;
	
	my $height = $self->slide_deck->calculate_size( spacer_height =>
		$content{height}, $container
	);
	
	return $container->insert(Widget =>
		pack => { side => 'top', fill => 'x' },
		height => $height,
		color => $container->color,
		backColor => $container->backColor,
		%content,
	);
}

=item subref

=cut

sub render_subref {
	my ($self, $content, $container) = @_;
	if (ref($content) ne ref(sub {})) {
		carp("Cannot 'render' subref that's not actually a subref!");
		return;
	}
	$content->($self, $container);
}


=item bullets

=cut

use charnames ':full';
my $bullet = "\N{BULLET}";
sub render_bullets {
	my ($self, $content, $container) = @_;
	
	$content = { bullets => $content } if ref($content) eq ref([]);
	my %content = (
		color => $container->color,
		backColor => $container->backColor,
		%$content
	);
	# No pack/place allowed
	delete $content{pack};
	delete $content{place};
	
	# Add a small spacer
	$self->render_spacer('0.5em', $container);
	my $height = $container->font->height;
	
	# Determine the font
	$content{font} = $self->prepare_font_hash($content{font}, $container);
	
	# For each bullet, pack the bullet then the paragraph
	for my $bullet_text (@{$content{bullets}}) {
		my $bullet_container = $container->insert(Widget =>
			pack => { side => 'top', fill => 'x' },
			%content,
		);
		# Insert a phantom bullet to make the packer happy, but actually
		# use "place" to render the bullet where we want it
		my $shadow_bullet = $bullet_container->insert(Label =>
			pack => { side => 'left', padx => 20 },
			text => $bullet,
			visible => 0,
		);
		my $bullet = $bullet_container->insert(Label =>
			place => {
				x => 8, width => $shadow_bullet->width, anchor => 'sw',
				rely => 1, y => -$height, height => $height,
			},
			%content,
			text => $bullet,
			alignment => ta::Center,
		);
		$self->render_par({
			%content,
			text => $bullet_text,
			# XXX This needs to be handled better
			alignment => ta::Left,
		}, $bullet_container);
	}
	
	# Add a small spacer at the end.
	$self->render_spacer('0.5em', $container);
}

=item inputline

Renders a L<Prima::InputLine>, using the specified hashref as the arguments
to create the widget. Note that the height and width can be specified using
suffixes supported by L</calculate_size>. In particular, you can specify
the interactive callback functions such as onKeyUp:

 inputline => {
   text => 'default text',
   hint => 'type something interesting',
   onKeyUp => sub {
     my ($widget, $code, $key, $mod) = @_;
     # The slide object can be accessed as a hash member
     my $slide = $widget->{slide};
     my $text = $widget->text;
     ... do cool stuff here ...
   },
 }

=cut

sub render_inputline {
	my ($self, $content, $container) = @_;
	require Prima::InputLine;
	
	# Make sure we have some useful content
	if (ref($content) ne ref({})) {
		carp("inputline content type needs a hashref of options; rendering as a paragraph");
		return $self->render_par($container, $content);
	}
	
	# Get the hash of content
	my %content = %$content;
	
	# Determine computed dimensions
	$content{height} = $self->slide_deck->calculate_size('inputline height' =>
		$content->{height}, $container) if exists $content{height};
	$content{width} = $self->slide_deck->calculate_size('inputline width' =>
		$content->{width}, $container) if exists $content{width};
	
	# Build the widget
	my $widget = $container->insert(InputLine =>
		alignment => $self->get_alignment_for($container),
		color => $container->color,
		backColor => $container->backColor,
		pack => { side => 'top', fill => 'x' },
		%content,
		font => $self->prepare_font_hash($content{font}, $container),
	);
	$widget->{slide} = $self;
	Scalar::Util::weaken($widget->{slide});
	return $widget;
}

=item button

Renders a button. Unlike most widgets, this widget does *not* default to
the container's default color and backColor. If you want nonstandard button
colors, you will have to specify them in your content hashref.

=cut

sub render_button {
	my ($self, $content, $container) = @_;
	require Prima::Buttons;
	
	# Make sure we have some useful content
	if (ref($content) ne ref({})) {
		carp("button content type needs a hashref of options; rendering as a paragraph");
		return $self->render_par($container, $content);
	}
	
	# Get the hash of content
	my %content = %$content;
	
	# Determine computed dimensions
	$content{height} = $self->slide_deck->calculate_size('inputline height' =>
		$content->{height}, $container) if exists $content{height};
	$content{width} = $self->slide_deck->calculate_size('inputline width' =>
		$content->{width}, $container) if exists $content{width};
	
	# Build the button
	my $widget = $container->insert(Button =>
		alignment => $self->get_alignment_for($container),
		#color => $container->color,
		#backColor => $container->backColor,
		pack => { side => 'top', fill => 'x' },
		%content,
		font => $self->prepare_font_hash($content{font}, $container),
	);
	$widget->{slide} = $self;
	Scalar::Util::weaken($widget->{slide});
	return $widget;
}

=item radio_buttons

Renders a set of radio buttons. The text for the buttons themselves should
be specified in a list called C<selections>.

 radio_buttons => {
   selections => [ 'One', 'Alpha', 'A' ],
   onRadio => sub {
     my ($widget, $selected_radio) = @_;
     my $text = $selected_radio->text;
     my $slide = $widget->{slide};
     ... do something with that information ...
   },
   text => 'Pick starting point',
 },

=cut

# XXX Needs lots of work (along with bullets)
sub render_radio_buttons {
	my ($self, $content, $container) = @_;
	require Prima::Buttons;
	
	# Make sure we have some useful content
	if (ref($content) ne ref({})) {
		carp("button content type needs a hashref of options; rendering as a paragraph");
		return $self->render_par($container, $content);
	}
	if (not exists $content->{selections} or not ref($content->{selections})
		or ref($content->{selections}) ne ref([])
	) {
		carp('radio_buttons type needs an arrayref of selection texts; rendering as a paragraph');
		return $self->render_par($container, $content);
	}
	
	# Get the hash of content
	my %content = %$content;
	
	# Determine computed dimensions
	$content{height} = $self->slide_deck->calculate_size('inputline height' =>
		$content->{height}, $container) if exists $content{height};
	$content{width} = $self->slide_deck->calculate_size('inputline width' =>
		$content->{width}, $container) if exists $content{width};
	
	# Build the button group
	my $widget = $container->insert(GroupBox =>
		alignment => $self->alignment,
		color => $container->color,
		backColor => $container->backColor,
		pack => { side => 'top', fill => 'x' },
		%content,
	);
	$widget->{slide} = $self;
	Scalar::Util::weaken($widget->{slide});
	
	# Pack the radio buttons
	for my $text (@{$content{selections}}) {
		$widget->insert(Radio =>
			alignment => ta::Left,
			color => $container->color,
			backColor => $container->backColor,
			pack => { side => 'left' },
			text => $text,
		);
	}
	
	return $widget;
}


=back

=cut

sub transition {
	my ($self, $direction) = @_;
	
	$self->{stash}{transition_count} += $direction;
	
	# Act based on the keys supplied
	if ($self->{transition}) {
		return $self->{transition}->($self, $direction);
	}
	elsif ($self->{transitions}) {
		# Get the list of transitions and the current transition count
		my @transitions = @{$self->{transitions}};
		my $counter = $self->{stash}{transition_count};
		
		# If we are in the middle of a set of transitions and the current
		# transition has a leave callback, call it
		if ($direction != 0
			and ref($transitions[$counter - $direction]) eq 'HASH'
		) {
			my %trans_table = %{$transitions[$counter - $direction]};
			if ($direction == -1 and exists $trans_table{leave_backwards}) {
				$trans_table{leave_backwards}->($self);
			}
			elsif ($direction == 1 and exists $trans_table{leave_forwards}) {
				$trans_table{leave_forwards}->($self);
			}
			$trans_table{leave}->($self, $direction)
				if exists $trans_table{leave};
		}
		
		# We're done if trying to transition to something outside the list
		return 0 if $counter < 0 or $counter > $#transitions;
		
		# Call the transition.
		if (ref($transitions[$counter]) eq 'HASH') {
			$transitions[$counter]{enter}->($self, $direction)
				if exists $transitions[$counter]{enter};
		}
		else {
			$transitions[$counter]->($self, $direction);
		}
		
		return 1;
	}
	
	return 0;
}

sub tear_down {
	my $self = shift;
	
	# Call the supplied tear-down method
	$self->{tear_down}->($self)
		if exists $self->{tear_down}
		and ref($self->{tear_down}) eq ref( sub{} );
	
	if (Prima::Object::alive($self->slide_deck->notes_window)) {
		$_->destroy
			foreach (reverse $self->slide_deck->notes_window->get_components)
	}
	
	# Clear the stash
	$self->{stash} = {};
	
	# Finish by removing the widgets
	$_->destroy foreach (reverse $self->slide_deck->container->get_components);
}

package Prima::Talk::WideSlide;

our @ISA = qw(Prima::Talk::Slide);

sub set_toc_visibility {
	# Turn on the table of contents
	my $self = shift;
	$self->slide_deck->toc_visible(0);
}

package Prima::Talk::WideEmphasize;

our @ISA = qw(Prima::Talk::Slide);

sub init {
	my $self = shift;
	# Content is not necessary for title slides, so add a default of an
	# empty string
	$self->{content} = '' if not exists $self->{content};
	return $self->SUPER::init();
}

# Turn on the table of contents
sub set_toc_visibility { $_[0]->slide_deck->toc_visible(0) }
sub alignment { ta::Center }

sub title_font_size {
	my $self = shift;
	return $self->font_size * $self->title_font_ratio;
}

sub title_font_ratio {
	my $self = shift;
	
	# Called as a getter?
	if (@_ == 0) {
		# Return local ratio if it exists
		return $self->{title_font_ratio} if defined $self->{title_font_ratio};
		# Otherwise return the deck's ratio
		return $self->slide_deck->title_font_ratio;
	}
	
	# Called as a setter, so set the local ratio
	$self->{title_font_ratio} = $_[0];
}

sub render_title {
	my ($self, $title, $container) = @_;
	
	# Clear the default title
	$self->slide_deck->set_title('');
	
	# Display the title 2/5 of the way down
	my $title_label = $container->insert(Label =>
		text => $title,
		pack => { side => 'top', fill => 'x' },
		height => 0.4 * $container->height,
		valignment => ta::Bottom,
		alignment  => ta::Center,
		wordWrap => 1,
	);
	$title_label->font->size($self->title_font_size);
	return $title_label;
}

package Prima::Talk::Emphasize;
our @ISA = qw(Prima::Talk::WideEmphasize);
sub set_toc_visibility { $_[0]->slide_deck->toc_visible(1) }

package Prima::Talk::Section;
our @ISA = qw(Prima::Talk::Emphasize);

package Prima::Talk::WideSection;
our @ISA = qw(Prima::Talk::Section);
sub set_toc_visibility { $_[0]->slide_deck->toc_visible(0) }
