package Prima::Drawable::Subcanvas;

use strict;
use warnings;
use Prima qw(noX11 Application);
our @ISA = qw(Prima::Image);
use Carp;

# Supply a default subcanvas offset:
sub profile_default {
	my %def = %{ shift->SUPER::profile_default };

	return {
		%def,
		subcanvas_offset => [0, 0],
	};
}

# Graphics properties must be stored internally. Note the font attribute
# needs to be handled with a tied hash at some point.
my @easy_props = qw(backColor color fillWinding fillPattern font lineEnd
					lineJoin linePattern lineWidth rop rop2
					splinePrecision textOpaque textOutBaseline);
my @properties = (@easy_props, qw( palette region ));

sub init {
	my $self = shift;
	
	# We need to set up the parent canvas before calling the parent initializer
	# code. This is because the superclass will call the various setters during
	# its init, and our setters need the parent canvas.
	my %profile = @_;
	croak('You must provide a parent canvas')
		unless $self->{parent_canvas} = delete $profile{parent_canvas};

	# Set the dimensions; let @size override the others; use the setter methods
	# to ensure that we get validation and/or derived-class overrides.
	$self->subcanvas_offset(@{delete $profile{subcanvas_offset}});
	
	# OK, now we can call the SUPER's init()
	%profile = $self->SUPER::init(%profile);
	
	$self->{translate} = [0, 0];
	# Consider providing a paint state stack eventually, so that begin_paint
	# and end_paint can be handled correctly.
	
	# Set any properties specified in the constructor
#	for my $prop (#@properties, 
#		qw(width height)) {
#		$self->$prop($profile{$prop});
#	}
	
	return %profile;
}

sub fixup_rect {
	my ($name, @rect) = @_;
	# Validate the incoming rect
	croak("$name must be a four-element array") unless @rect == 4;
	($rect[2], $rect[0]) = ($rect[0], $rect[2]) if $rect[2] < $rect[0];
	($rect[3], $rect[1]) = ($rect[1], $rect[3]) if $rect[3] < $rect[1];
	return @rect;
}

# Use parent class's storage (and implementation) for these.
# sub width { ... }
# sub height { ... }
# sub size { ... }

sub subcanvas_offset {
	my ($self, @new_offset) = @_;
	# Handle the setter code, which is independent of vitality
	if (@new_offset) {
		$self->{subcanvas_offset} = \@new_offset;
		return @new_offset;
	}
	# Are we inquiring about the offset while setting up? If so, we may not have
	# set the offset:
	return (0, 0) if $self->alive == 2;
	# Otherwise, return the attribute.
	return @{$self->{subcanvas_offset}};
}

sub begin_paint {
	my $self = shift;
	
	# Prepare the parent canvas for painting
	$self->{parent_canvas}->begin_paint;
	$self->SUPER::begin_paint;
	
	# Set the default translate and cliprect values
	#; clipRect should also be reset, but that
	# is recorded (and reset) by the base class implementation.
	$self->translate(0, 0);
	$self->clipRect(0, 0, $self->size);
}

sub end_paint {
	my $self = shift;
	
	# Reset the default translate and clipRect values
	$self->{translate} = [0, 0];
	
	# finalize the state of the parent and base class
	$self->SUPER::end_paint;
	$self->{parent_canvas}->end_paint;
}

### For these methods, just call the method on the parent widget directly
for my $direct_method (qw(begin_paint_info
	end_paint_info font_match fonts get_bpp get_font_abc
	get_nearest_color get_paint_state get_physical_palette
	get_text_width text_wrap
)) {
	no strict 'refs';
	*{$direct_method} = sub {
		use strict 'refs';
		my $self = shift;
		
		# Indicate the property name subref we're writing (thanks to
		# http://www.perlmonks.org/?node_id=304883 for the idea)
		*__ANON__ = $direct_method;
		
		# use goto to make this as transparent (or hidden) as possible
		unshift @_, $self->{parent_canvas};
		goto &{$self->{parent_canvas}->can($direct_method)};
	};
}



# spcial handling: get_text_box, render_spline?

for my $prop_name (@easy_props) {
	# Build the sub to handle the getting and setting of the property.
	no strict 'refs';
	*{$prop_name} = sub {
		use strict 'refs';
		my $self = shift;
		
		# Indicate the property name subref we're writing (thanks to
		# http://www.perlmonks.org/?node_id=304883 for the idea)
		*__ANON__ = $prop_name;

		# Return the parent's value if called as getter
		return $self->{parent_canvas}->$prop_name() if @_ == 0;
		
		# Get the new value. undef has a special meaning for Subcanvases, so
		# only call the actual setter if the new value is defined...
		my $new_value = shift;
		if (defined $new_value) {
			# Called as setter. Backup unless we already have a backup
			$self->{"backup_$prop_name"}
				||= $self->{parent_canvas}->$prop_name()
				unless exists $self->{"backup_$prop_name"};
			return $self->{parent_canvas}->$prop_name($new_value);
		}
		
		# Called with undef, so restore the previous value.
		$self->{parent_canvas}->$prop_name(delete $self->{"backup_$prop_name"})
				if exists $self->{"backup_$prop_name"};
	};
}

# Primitives must apply the clipping and translating before calling on the
# parent.
my @primitives = qw(arc bar chord draw_text ellipse fill_chord
					fill_ellipse fillpoly fill_sector fill_spline flood_fill
					line lines polyline put_image put_image_indirect
					rect3d rect_focus rectangle sector spline stretch_image
					text_out clear
					); 

for my $primitive_name (@primitives) {
	no strict 'refs';
	*{$primitive_name} = sub {
		use strict 'refs';
		my ($self, @args_for_method) = @_;
		
		# Indicate the name of the subref we're writing (thanks to
		# http://www.perlmonks.org/?node_id=304883 for the idea)
		*__ANON__ = $primitive_name;

		# Do not perform the draw if we are in a null clip region.
		return if $self->{null_clip_region};
		
		# Otherwise apply the method, working under the assumption that the
		# clipRect and translate will do their job.
		$self->{parent_canvas}->$primitive_name(@args_for_method);
	};
}

sub pixel {
	my ($self, $x, $y, @color_arg) = @_;
	
	# This could be wrong since we could inquire about the pixel at a
	# covered location, in which case we don't have the value (it was
	# never stored in the first place if it was covered). But then
	# again, subcanvas is mostly meant for drawn output, not deep
	# inspection. The alternative, to use the factory-provided method above,
	# would return null in that case, and that wouldn't be very nice.
	return $self->{parent_canvas}->pixel($x, $y, @color_arg);
}

# Apply the subcanvas's clipRect, using the internal translation and boundaries
sub clipRect {
	my ($self, @new_rect) = @_;
	
	# Don't do anything if we're not painting
	return (0, 0, $self->size) unless $self->{parent_canvas}->get_paint_state;
	
	# If we are painting, and called as a getter, return what we have
	return $self->SUPER::clipRect unless @new_rect;
	
	# ignore the call to restore-to-previous
	if (@new_rect == 1 and not defined $new_rect[0]) {
		carp('Subcanvas is not capable of restoring the previous clipRect');
		return;
	}
	
	# Store (and fixup) the proper rectangle using the superclass's
	# implementation.
	$self->SUPER::clipRect(@new_rect);
	my ($left, $bottom, $right, $top) = $self->SUPER::clipRect();
	
	# This is slightly different from Prima's handling of negative translates
	# with clipRects, but is internally self-consistent. XXX
	my ($x_trans, $y_trans) = $self->translate;
	my ($w, $h) = $self->size;
	
	# Apply the translation. If the translated clipRect is outside the widget's
	# boundaries, set a flag that will prevent drawing operations.
	$left   += $x_trans;
	$bottom += $y_trans;
	$right  += $x_trans;
	$top    += $y_trans;
	return $self->{null_clip_region} = 1
		if $left >= $w or $right < 0 or $bottom < 0 or $top >= $h;
	
	# If we're here, we are going to clip, so remove that flag.
	delete $self->{null_clip_region};
	
	# Trim the translated boundaries so that they are clipped by the widget's
	# actual edges.
	$left  = 0    if $left  <  0;  $bottom = 0    if $bottom < 0;
	$right = 0    if $right <  0;  $top    = 0    if $top    < 0;
	$left  = $w-1 if $left  >= $w; $bottom = $h-1 if $bottom >= $h;
	$right = $w-1 if $right >= $w;  $top   = $h-1 if $top    >= $h;
	
	# Finally, calculate the clipping rectangle with respect to the parent's
	# origin. I would prefer to simply translate the parent to the subcanvas's
	# offset, but that might be negative, and Prima doesn't handle clipRects
	# together with negative translations correctly. So instead I translate the
	# parent to its origin temporarily and apply the adjusted clipRect.
	my ($x_off, $y_off) = $self->subcanvas_offset;
	$left  += $x_off; $bottom += $y_off;
	$right += $x_off; $top    += $y_off;
	my @old_parent_trans = $self->{parent_canvas}->translate;    # backup
	$self->{parent_canvas}->translate(0, 0);
	$self->{parent_canvas}->clipRect($left, $bottom, $right, $top);
	$self->{parent_canvas}->translate(@old_parent_trans);        # restore
}

sub translate {
	my ($self, @new_trans) = @_;
	
	# Don't do anything if we're not painting
	return (0, 0) unless $self->{parent_canvas}->get_paint_state;
	
	# As getter, return what we have
	return @{$self->{translate}} unless @new_trans;
	
	# Clearer will supply a single undefined value, but the previous translate
	# should not be restored.
	if (@new_trans == 1 and not defined $new_trans[0]) {
		carp('It does not make sense for Subcanvas to restore the previous translate');
		return;
	}
	
	# store the new translation in case it's inquired about
	$self->{translate} = [@new_trans];
	
	# Apply (to the parent's canvas)
	my ($left, $bottom) = $self->subcanvas_offset;
	$self->{parent_canvas}->translate(
		$new_trans[0] + $left, $new_trans[1] + $bottom);
}

sub region {
#	warn "subcanvas region is not yet implemented";
}

sub palette {
#	return warn "subcanvas palette is not yet implemented";
return
	my $self = shift;
	
	# Called as getter
	if (@_ == 0) {
		return $self->{palette} if exists $self->{palette};
		return $self->{parent_canvas}->palette();
	}
	
	my $new_palette = shift;
	
	# Called as a setter?
	if (defined $new_palette) {
		$self->{backup_palette} ||= [ @{$self->{parent_canvas}->palette()} ];
		return $self->{parent_canvas}->palette($new_palette);
	}
	
	# $new_palette is not defined, so it's called as restore-parent
	return $self->{parent_canvas}->palette(delete $self->{backup_palette})
		if exists $self->{backup_palette};
}

sub AUTOLOAD {
	my $self = shift;
	
	# Remove qualifier from original method name...
	(my $called = our $AUTOLOAD) =~ s/.*:://;
	
	my $parent_canvas = $self->{parent_canvas};
	if (my $subref = $parent_canvas->can($called)) {
		$subref->($parent_canvas, @_);
	}
	else {
		die "Don't know how to $called\n";
	}
}

sub restore_parent {
	my $self = shift;
	my @props = map { /^backup_(.*)/ ? ($1) : () } keys %$self;
	# Restore all the backed-up props; all properties have special handling for
	# a single undefined value.
	$self->$_(undef) for (@props);
}

sub Prima::Drawable::paint_with_widgets {
	my ($self, $canvas) = @_;
	
	# Always paint self directly on the canvas
	for my $property (@properties) {
		$canvas->$property($self->$property);
	}
	$canvas->begin_paint;
	$self->notify('Paint', $canvas);
	$::application->yield;
	$canvas->end_paint;
	
	for my $widget ($self->get_widgets) {
		next if not defined $widget;
		# Paint the children on their own subcanvases
		my $subcanvas = Prima::Drawable::Subcanvas->new(
			parent_canvas => $canvas,
			subcanvas_offset => [$widget->origin],
			width => $widget->width, height => $widget->height,
			size => [$widget->size],
			owner => $widget,
		);
		$widget->paint_with_widgets($subcanvas);
		$subcanvas->restore_parent;
	}
}

1;
