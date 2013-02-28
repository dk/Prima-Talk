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

sub subcanvas_rect {
	my $self = shift;
	return @{$self->{subcanvas_rect}} if @_ == 1;
	my @rect = @_;
	# Validate the incoming rect
	croak("Subcanvas rect must be a four-element array")
		unless @rect == 4;
	/^\d+$/ or croak("Subcanvas rect must contain only positive integers")
		for (@rect);
	$rect[0] < $rect[2] or croak("Subcanvas rect's left must be less than right");
	$rect[1] < $rect[3] or croak("Subcanvas rect's bottom must be less than top");
	$rect[2] < $self->{parent_canvas}->width
		or croak("Subcanvas rect's right must be less than parent canvas's width");
	$rect[3] < $self->{parent_canvas}->height
		or croak("Subcanvas rect's top must be less than parent canvas's height");
	# If we're here then the subcanvas is good to go.
	$self->{subcanvas_rect} = \@rect;
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
	$_[0]->{parent_canvas}->begin_paint;
}

sub end_paint {
	$_[0]->{parent_canvas}->end_paint;
}

sub clipRect {
}

sub AUTOLOAD {
	my $self = shift;
	
	# Remove qualifier from original method name...
	(my $called = $AUTOLOAD) =~ s/.*:://;
	
	my $parent_canvas = $self->{parent_canvas};
	if (my $subref = $parent_canvas->can($called)) {
		# Open the painting "brackets"
		$parent_canvas->begin_paint;
		# Set the clip rectangle and translation
		$self->prepare_canvas;
		# Perform the drawing operation
		$subref->($parent_canvas, @_);
		# Done; close the painting "brackets"
		$parent_canvas->end_paint;
	}
}

1;
