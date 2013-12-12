package Prima::Drawable::Subcanvas;

use strict;
use warnings;
use Prima qw(noX11 Application);
our @ISA = qw(Prima::Drawable);
use Carp;

# Supply a default subcanvas offset:
sub profile_default {
	my %def = %{$_[ 0]-> SUPER::profile_default};

	return {
		%def,
		subcanvas_offset => [0, 0],
		width => 1, height => 1, size => [],
#		color => cl::Black,
#		backColor => cl::Gray,
	};
}

# Graphics properties must be stored internally. Note the font attribute
# needs to be handled with a tied hash at some point.
my @properties = qw(backColor color fillWinding fillPattern font lineEnd
					lineJoin linePattern lineWidth palette rop rop2
					splinePrecision textOpaque textOutBaseline);

sub init {
	my $self = shift;
	
	# We need to set up the parent canvas before calling the parent initializer
	# code. This is because the superclass will call the various setters during
	# its init, and our setters need the parent canvas.
	my %profile = @_;
	croak('You must provide a parent canvas')
		unless $self->{parent_canvas} = delete $profile{parent_canvas};

# Set the dimensions; let @size override the others
$self->width($profile{width});
$self->height($profile{height});
$self->size(@{$profile{size}});
$self->subcanvas_offset(@{$profile{subcanvas_offset}});
	
	
	# OK, now we can call the SUPER's init()
	%profile = $self->SUPER::init(%profile);
	
	# For the important properties that follow, use the setters to ensure that
	# we get validation and/or derived-class overrides.
	
	# Set the dimensions; let @size override the others
	$self->width($profile{width});
	$self->height($profile{height});
	$self->size(@{$profile{size}});
	$self->subcanvas_offset(@{$profile{subcanvas_offset}});
	
	# Set any properties specified in the constructor
#	for my $prop (@properties) {
#		$self->$prop($profile{$prop}) if exists $profile{$prop};
#print "Setting $prop to $profile{$prop}\n" if exists $profile{$prop};
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

sub width {
	return shift->{width} if @_ == 1;
	my ($self, $new_width) = @_;
	croak("subcanvas width must be positive") unless $new_width > 0;
	$self->{width} = $new_width;
}

sub height {
	return shift->{height} if @_ == 1;
	my ($self, $new_height) = @_;
	croak("subcanvas height must be positive") unless $new_height > 0;
	$self->{height} = $new_height;
}

sub size {
	my $self = shift;
	return ($self->width, $self->height) if @_ == 0;
	croak('subcanvas size must have two arguments') unless @_ == 2;
	my ($width, $height) = @_;
	$self->width($width);
	$self->height($height);
	return ($width, $height);
}

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

sub subcanvas_rect {
	my ($self, @new_rect) = @_;
	if (@new_rect) {
		@new_rect = fixup_rect('Subcanvas rect', @new_rect);
		$self->subcanvas_offset(@new_rect[0,1]);
		$self->size($new_rect[2] - $new_rect[0], $new_rect[3] - $new_rect[1]);
		return @new_rect;
	}
	else {
		my ($left, $bottom) = $self->subcanvas_offset;
		return ($left, $bottom, $left + $self->width, $bottom + $self->height);
	}
}

sub begin_paint {
	# Ideally, this should record the parent's paint state and ensure that the
	# paint state is on. When end_paint is called, it restores the previous
	# paint state, turning it off only if it was previously on.
	$_[0]->{parent_canvas}->begin_paint;
}

sub end_paint {
	$_[0]->{parent_canvas}->end_paint;
}

for my $prop_name (@properties) {
	# Build the sub to handle the getting and setting of the property.
	no strict 'refs';
	*{$prop_name} = sub {
		use strict 'refs';
		my $self = shift;
		
		# Indicate the property name subref we're writing (thanks to
		# http://www.perlmonks.org/?node_id=304883 for the idea)
		*__ANON__ = $prop_name;

		# Called as getter?
		if (@_ == 0) {
			# Return the internal value, or the parent's value if not set
			return $self->{$prop_name} if exists $self->{$prop_name};
			return $self->{parent_canvas}->$prop_name();
		}
		# Called as setter/clearer?
		else {
			# Get the new value. Undef means "clear"
			my $new_value = shift;
			if (defined $new_value) {
				# Called as setter. Backup unless we already have a backup
				$self->{"backup_$prop_name"}
					||= $self->{parent_canvas}->$prop_name()
					unless exists $self->{"backup_$prop_name"};
				$self->{parent_canvas}->$prop_name($new_value);
			}
			else {
				# Called as clearer
				delete $self->{$prop_name};
				return $self->{parent_canvas}->$prop_name(
					delete $self->{"backup_$prop_name"}
				) if exists $self->{"backup_$prop_name"};
			}
		}
	};
}

# Primitives must apply the clipping and translating before calling on the
# parent.
my @primitives = qw(arc bar chord draw_text ellipse fill_chord
					fill_ellipse fillpoly fill_sector fill_spline flood_fill
					line lines pixel polyline put_image put_image_indirect
					rect3d rect_focus rectangle sector spline stretch_image
					text_out
					); 

for my $primitive_name (@primitives) {
	no strict 'refs';
	*{$primitive_name} = sub {
		use strict 'refs';
		my ($self, @args_for_method) = @_;
		
		# Indicate the name of the subref we're writing (thanks to
		# http://www.perlmonks.org/?node_id=304883 for the idea)
		*__ANON__ = $primitive_name;

		# Begin by ensuring that the clipping and translation are enforced:
		$self->clipRect($self->clipRect);
		$self->translate($self->translate);
		
		# Apply the method
		$self->{parent_canvas}->$primitive_name(@args_for_method);
	};
}

# These have to be handled specially:
sub clear {
	my $self = shift;
	my @subcanvas_rect = $self->subcanvas_rect;
	if (@_ == 0) {
		# Clear the full subcanvas
		$self->{parent_canvas}->clear(@subcanvas_rect);
	}
	else {
		my @to_clear = @_;
		$to_clear[0] += $subcanvas_rect[0];
		$to_clear[2] += $subcanvas_rect[0];
		$to_clear[1] += $subcanvas_rect[1];
		$to_clear[3] += $subcanvas_rect[1];
		# Clip upper end
		$to_clear[0] = $subcanvas_rect[0] if $to_clear[0] < $subcanvas_rect[0];
		$to_clear[1] = $subcanvas_rect[1] if $to_clear[1] < $subcanvas_rect[1];
		$to_clear[2] = $subcanvas_rect[2] if $to_clear[2] > $subcanvas_rect[2];
		$to_clear[3] = $subcanvas_rect[3] if $to_clear[3] > $subcanvas_rect[3];
		$self->{parent_canvas}->clear(@to_clear);
	}
}

# Apply the subcanvas's clipRect, using the internal translation
sub clipRect {
	my ($self, @new_rect) = @_;
	
	# As getter, return what we have
	if (not @new_rect) {
		return @{$self->{clipRect}} if $self->{clipRect};
		return (0, 0, $self->size);
	}
	
	# Clearer will supply a single undefined value:
	if (@new_rect == 1 and not defined $new_rect[0]) {
		delete $self->{clipRect};
		# Don't do anything unless we *have* something to restore
		return $self->{parent_canvas}->clipRect
			unless exists $self->{backup_clipRect};
		# Clear the backed-up value from our memory and restore it.
		my $restored_rect = delete $self->{backup_clipRect};
		return $self->{parent_canvas}->clipRect(@{$restored_rect});
	}
	
	# Don't set unless we're in paint mode
	return unless $self->{parent_canvas}->get_paint_state;
	
	# As a setter, run the basic check:
	@new_rect = fixup_rect('clipRect', @new_rect);
	
	# Backup and store
	$self->{backup_clipRect} ||= [$self->{parent_canvas}->clipRect];
	$self->{clipRect} = \@new_rect;
	
	# Apply (to the parent's canvas)
	my @subcanvas_rect = $self->subcanvas_rect;
	my $left = $subcanvas_rect[0] + $new_rect[0];
	my $bottom = $subcanvas_rect[1] + $new_rect[1];
	my $right = $subcanvas_rect[2] + $new_rect[0];
	my $top = $subcanvas_rect[3] + $new_rect[1];
	# Clip if they are out of bounds:
	if ($left > $subcanvas_rect[2] or $right < $subcanvas_rect[0]
		or $bottom > $subcanvas_rect[3] or $top < $subcanvas_rect[1]
	) {
		# Clipping falls outside the region; kludge another set of clipping
		# bounds that achieve the same end for us
		$left = $right = $bottom = $top = -1;
	}
	else {
		# Clip to the subcanvas rectangle.
		$left = $subcanvas_rect[0] if $left < $subcanvas_rect[0];
		$bottom = $subcanvas_rect[1] if $bottom < $subcanvas_rect[1];
		$right = $subcanvas_rect[2] if $right > $subcanvas_rect[2];
		$top = $subcanvas_rect[3] if $top > $subcanvas_rect[3];
	}
	$self->{parent_canvas}->clipRect($left, $bottom, $right, $top);
}

sub translate {
	my ($self, @new_trans) = @_;
	
	# As getter, return what we have
	if (not @new_trans) {
		return @{$self->{translate}} if $self->{translate};
		return (0, 0);
	}
	
	# Clearer will supply a single undefined value:
	if (@new_trans == 1 and not defined $new_trans[0]) {
		delete $self->{translate};
		# Don't do anything unless we *have* something to restore
		return $self->{parent_canvas}->translate
			unless exists $self->{backup_translate};
		# Clear the backed-up value from our memory and restore it.
		my $restored_trans = delete $self->{backup_translate};
		return $self->{parent_canvas}->translate(@{$restored_trans});
	}
	
	# Don't set unless we're in paint mode
#	return unless $self->{parent_canvas}->get_paint_state;
	
	# Backup and store
	$self->{backup_translate} ||= [$self->{parent_canvas}->translate];
	$self->{translate} = [@new_trans];
	
	# Apply (to the parent's canvas)
	my @subcanvas_rect = $self->subcanvas_rect;
	$new_trans[0] += $subcanvas_rect[0];
	$new_trans[1] += $subcanvas_rect[1];
	
	$self->{parent_canvas}->translate(@new_trans);
}

sub region {
	warn "subcanvas region is not yet implemented";
}

sub AUTOLOAD {
	my $self = shift;
	
	# Remove qualifier from original method name...
	(my $called = our $AUTOLOAD) =~ s/.*:://;
	
	my $parent_canvas = $self->{parent_canvas};
	if (my $subref = $parent_canvas->can($called)) {
#		# Set the clip rectangle and translation
#		$self->prepare_canvas;
		# Perform the drawing operation
		$subref->($parent_canvas, @_);
#		# Restore the previous clip rectangle and translation
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
	$canvas->begin_paint;
	$self->notify('Paint', $canvas);
	$::application->yield;
	
	for my $widget ($self->get_widgets) {
		next if not defined $widget;
		# Paint the children on their own subcanvases
		my $subcanvas = Prima::Drawable::Subcanvas->new(
			parent_canvas => $canvas,
			subcanvas_offset => [$widget->origin],
			size => [$widget->size],
			owner => $widget,
#			(map { $_ => $widget->$_ } (@properties)),
		);
		$widget->paint_with_widgets($subcanvas);
		$subcanvas->restore_parent;
	}
	$canvas->end_paint;
}

1;
