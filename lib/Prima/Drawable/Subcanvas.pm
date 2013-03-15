package Prima::Drawable::Subcanvas;

use strict;
use warnings;
use Prima::Drawable;
our @ISA = qw(Prima::Drawable);

sub init {
	my $self = shift;
	my %profile = $self->SUPER::init(@_);
	
	# Ensure there is a parent canvas
	croak('You must supply a parent canvas')
		unless exists $self->{parent_canvas};
	if (not exists $self->{subcanvas_rect}) {
		# Set the subcanvas_rect if not supplied
		$self->subcanvas_rect(0, 0, $self->{parent_canvas}->size);
	}
	else {
		# Run through the setter to be sure that everything is ok
		$self->subcanvas_rect(@{$self->{subcanvas_rect}});
	}
	
	return $self;
}

sub fixup_rect {
	my ($name, @rect) = @_;
	# Validate the incoming rect
	croak("$name must be a four-element array") unless @rect == 4;
	($rect[2], $rect[0]) = ($rect[0], $rect[2]) if $rect[2] < $rect[0];
	($rect[3], $rect[1]) = ($rect[1], $rect[3]) if $rect[3] < $rect[1];
	return @rect;
}

sub subcanvas_rect {
	my ($self, @new_rect) = @_;
	return @{$self->{subcanvas_rect}} unless @new_rect;
	@new_rect = fixup_rect('Subcanvas rect', @new_rect);
	$self->{subcanvas_rect} = \@new_rect;
}

sub size {
	croak("Cannot change the size of a subcanvas") if @_ > 1;
	my @sub_rect = @{$_[0]->{subcanvas_rect}};
	return ($sub_rect[2] - $sub_rect[0], $sub_rect[3] - $sub_rect[1]);
}

sub height {
	croak("Cannot change the size of a subcanvas") if @_ > 1;
	my @sub_rect = @{$_[0]->{subcanvas_rect}};
	return $sub_rect[3] - $sub_rect[1];
}

sub width {
	croak("Cannot change the size of a subcanvas") if @_ > 1;
	my @sub_rect = @{$_[0]->{subcanvas_rect}};
	return $sub_rect[2] - $sub_rect[0];
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

# These properties must be stored internally
my @properties = qw(backColor color fillWinding fillPattern font lineEnd
					lineJoin linePattern lineWidth palette rop rop2
					splinePrecision textOpaque textOutBaseline);
for my $prop_name (@properties) {
	# Build the sub to handle the getting and setting of the property.
	*{$prop_name} = sub {
		my $self = shift;
		
		# Called as getter?
		if (@_ == 0) {
			# Return the internal value, or the parent's value if not set
			return $self->{$prop_name} if exists $self->{$prop_name};
			return $self->{parent_canvas}->$prop_name();
		}
		# Called as setter?
		else {
			# Clear if sent undef; otherwise set the internal value
			my $new_value = shift;
			return $self->{$prop_name} = $new_value if defined $new_value;
			return delete $self->{$prop_name};
		}
	};
}

# These have to be handled specially:

# Apply the subcanvas's clipRect, using the internal translation
sub clipRect {
	my ($self, @new_rect) = @_;
	
	# As getter, return what we have
	if (not @new_rect) {
		return @{$self->{clipRect}} if $self->{clipRect};
		return (0, 0, $self->size);
	}
	
	# Don't set unless we're in paint mode
	return unless $self->{parent_canvas}->get_paint_state;
	
	# As a setter, run the basic check:
	@new_rect = fixup_rect('clipRect', @new_rect);
	
	# Backup and store
	$self->{backup_clipRect} = [$self->{parent_canvas}->clipRect];
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
	$self->{parent_canvas}->clipRect($left, $bottom, $right, $top)
}

sub translate {
	
}

sub region {
	
}

sub AUTOLOAD {
	my $self = shift;
	
	# Remove qualifier from original method name...
	(my $called = $AUTOLOAD) =~ s/.*:://;
	
	my $parent_canvas = $self->{parent_canvas};
	if (my $subref = $parent_canvas->can($called)) {
		# Set the clip rectangle and translation
		$self->prepare_canvas;
		# Perform the drawing operation
		$subref->($parent_canvas, @_);
		# Restore the previous clip rectangle and translation
	}
}

1;
