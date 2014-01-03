use strict;
use warnings;

package Prima::StretchyImage;
use Carp;

our @ISA = qw(Prima::Widget);

sub profile_default {
	my %def = %{$_[ 0]-> SUPER::profile_default};
	
	return {
		%def,
		preserveAspect => 0,
		alignment => ta::Center,
		valignment => ta::Middle,
		buffered => 1,
	};
}

sub init {
	my $self = shift;
	my %profile = $self->SUPER::init(@_);
	
	# Copy the provided properties
	for my $prop_name ( qw(preserveAspect image alignment valignmnet) ) {
		$self->{$prop_name} = $profile{$prop_name};
	}
}

sub on_paint {
	my ($self, $canvas) = @_;
	$canvas->clear;
	
	# If we don't have an image, just fill with the background color
	return unless defined $self->{image};
	my $image = $self->image;
	return if $image->height < 1 or $image->width < 1;
	
	my ($i_w, $i_h) = $image->size;
	my ($c_w, $c_h) = $canvas->size;
	my $i_aspect = $i_w / $i_h;
	my $c_aspect = $c_w / $c_h;
	
	# If we do not care to preserve the aspect ratio, then just stretch it
	# across the whole canvas.
	if (not $self->preserveAspect or $i_w/$i_h == $c_w/$c_h) {
		$canvas->stretch_image(0, 0, $canvas->size, $self->image);
		return;
	}
	
	# Calculate the values needed for stretch_image
	my ($x, $y, $width, $height) = (0, 0, $c_w, $c_h);
	if ($i_aspect > $c_aspect) {
		# Image is too wide. Adjust the vertical offset
		$height = int($i_h * $c_w / $i_w);
		my $v_align = $self->valignment;
		if ($v_align == ta::Top) {
			$y = $c_h - $height;
		}
		elsif ($v_align == ta::Middle) {
			$y = ($c_h - $height)/2;
		}
	}
	else {
		# Image is too tall. Adjust the horizontal offset
		$width = int($i_w * $c_h / $i_h);
		my $h_align = $self->alignment;
		if ($h_align == ta::Right) {
			$x = $c_w - $width;
		}
		elsif ($h_align == ta::Center) {
			$x = ($c_w - $width) / 2;
		}
	}
	
	$canvas->stretch_image($x, $y, $width, $height, $self->image); 
}

use Scalar::Util qw(looks_like_number refaddr);

sub image {
	return shift->{image} if @_ == 1;
	my ($self, $image) = @_;
	croak("$image is not a Prima image")
		unless eval { $image->isa('Prima::Image') };
	
	# don't repaint unless the image is changed
	return $image if defined $self->{image}
		and refaddr($image) == refaddr($self->{image});
	
	# Save and repaint
	$self->{image} = $image;
	$self->repaint;
	return $image;
}

sub preserveAspect {
	my $self = shift;
	if (@_ == 1) {
		my $new_aspect = shift;
		my $old_aspect = $self->{preserveAspect};
		eval {
			$self->{preserveAspect} = $new_aspect ? 1 : 0;
			1;
		} or croak("Unable to evaluate $new_aspect in boolean context");
		$self->repaint if ($self->{preserveAspect} != $old_aspect);
	}
	return $self->{preserveAspect};
}

sub alignment {
	# Speedy getter
	return shift->{alignment} if @_ == 1;
	
	my ($self, $new_alignment) = @_;
	no warnings 'uninitialized';
	$new_alignment = ta::Center if $new_alignment == ta::Middle;
	# Don't need to do anything if they're the same
	return $new_alignment if $self->{alignment} == $new_alignment;
	# Otherwise, validate and issue a repaint
	grep { $new_alignment == $_ } (ta::Left, ta::Center, ta::Right)
		or croak("Invalid (horizontal) alignment; expected ta::Left, ta::Center, or ta::Right");
	$self->{alignment} = $new_alignment;
	$self->repaint;
	return $new_alignment;
}

sub valignment {
	# Speedy getter
	return shift->{valignment} if @_ == 1;
	
	my ($self, $new_alignment) = @_;
	no warnings 'uninitialized';
	$new_alignment = ta::Middle if $new_alignment == ta::Center;
	# Don't need to do anything if they're the same
	return $new_alignment if $self->{valignment} == $new_alignment;
	# Otherwise, validate and issue a repaint
	grep { $new_alignment == $_ } (ta::Top, ta::Middle, ta::Bottom)
		or croak("Invalid (vertical) alignment; expected ta::Top, ta::Middle, or ta::Bottom");
	$self->{valignment} = $new_alignment;
	$self->repaint;
	return $new_alignment;
}

1;

__END__

=head1 NAME

Prima::StretchyImage - a widget for displaying an image within a given space

=head1 SYNOPSIS

 use Prima qw(StretchyImage);
 
 my $im = get_image();
 
 my $s_im = Prima::StretchyImage->new(
   height          => $height,
   width           => $width,
   preserverAspect => 1,          # default is 0
   alignment       => ta::Left,   # default is ta::Center
   valignment      => ta::Bottom, # default is ta::Middle
   image           => $im,
 );
 
 $s_im->image($new_image);
 if ($s_im->preserveAspect) {
     print "Won't fill the full space\n";
 }

=head1 WORKING EXAMPLE

 use strict;
 use warnings;
 use Prima qw(Application StretchyImage InputLine);
 
 my $window = Prima::MainWindow->new(
     text => 'Stretchy test',
     height => 300,
     width => 600,
 );
 
 # Place the inputline
 my $input = $window->insert(InputLine =>
     onKeyUp => \&repaint_image,
     pack => { side => 'top', expand => 0, fill => 'x', padx => 2, pady => 2, anchor => 'n' },
     text => 'width=50 height=30 fontsize=14 preserveAspect=1 alignment=ta::Center valignment=ta::Middle word=Hello'
 );
 
 # Place the stretchyimage
 my $s_image = $window->insert(StretchyImage =>
     backColor => cl::LightBlue,
     pack => { side => 'top', expand => 1, fill => 'both' },
 );
 
 my $old_text = '';
 sub repaint_image {
     my $text = $input->text;
     # Don't do anything if the text didn't change (i.e. cursor navigation)
     return if $text eq $old_text;
     
     $old_text = $text;
     my %args = split /\s*[\s=]\s*/, $text;
     
     # repaint
     my $im = Prima::Image->new(width => $args{width}, height => $args{height},
         color => cl::Black, backColor => cl::White);
     $im->font->size($args{fontsize});
     $im->begin_paint;
     $im->clear;
     $im->text_out($args{word}, 0, 0);
     $im->end_paint;
     
     $s_image->image($im);
     for my $method (qw(preserveAspect alignment valignment)) {
         $s_image->$method(eval $args{$method});
     }
 }
 
 # Initialize the canvas
 repaint_image();
 
 Prima->run;
 
=head1 DESCRIPTION

Yet to be written...

=cut
