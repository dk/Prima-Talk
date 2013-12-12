use strict;
use warnings;

# A module with testing utilities for Prima systems.

package Test::Prima;
use Prima;

our $VERSION = "0.01"; # or "0.001_001" for a dev release
$VERSION = eval $VERSION;

use base 'Test::Builder::Module';
our @EXPORT = qw( is_prima_color is_prima_image );
use Scalar::Util qw(looks_like_number blessed);

sub is_prima_color {
	my ($got, $expected, $message) = @_;
	$message ||= 'Prima colors are equal';
	my $tb = Test::Prima->builder;
	
	# Make sure $got makes sense:
	if (not defined $got) {
		$tb->ok(0, $message);
		return $tb->diag('    Got undefined value where expected a defined value');
	}
	if (not looks_like_number($got)) {
		$tb->ok(0, $message);
		return $tb->diag("    Got value ($got) that does not look like a Prima color");
	}
	
	# Get the color number and pass if they agree.
	my ($expected_number, $expected_name)
		= _get_color_number_and_name($expected);
	$tb->ok($got == $expected_number, $message) and return 1;
	
	# If we're here, it means that the comparison failed. Let's give diagnostic
	# output
	return $tb->diag(	"    Prima color mismatch\n",
		_describe_color_mismatch($got, $expected_number, $expected_name)
	);
}

sub _get_color_number_and_name {
	my $expected = shift;
	
	# I allow the user to specify a color by name, which makes the diagnostics
	# a lot cleaner. But we have to make sure that the name exists, and then get
	# the correct number for it.
	my $expected_number = $expected;
	my $expected_name = '';
	if ($expected =~ /^[A-Za-z]+$/) {
		# Make sure that the named color exists in the cl package. Note that
		# 'constant' and 'AUTOLOAD' are incredibly unlikely as intentional
		# color names, but are possible, so we special-case them.
		if (not exists $cl::{$expected}
			or $expected eq 'constant'
			or $expected eq 'AUTOLOAD'
		) {
			Test::Prima->builder->croak("Unkown color name $expected");
		}
		# I wish I could get rid of this string eval, but I don't know how to
		# get at the value of a compile-time constant otherwise. :-(
		$expected_number = eval "cl::$expected";
		Test::Prima->builder->croak("Unkown color name $expected") if $@;
		
		$expected_name = $expected;
	}
	
	return ($expected_number, $expected_name);
}

sub _describe_color_mismatch {
	my ($got, $expected_number, $expected_name) = @_;
	
	return '' if $got == $expected_number;
	return sprintf('         got: %06x', $got), "\n",
			sprintf('    expected: %06x%s', $expected_number,
				($expected_name ? " ($expected_name)" : ''));
}

sub is_prima_image {
	my ($got, $expected, $message) = @_;
	$message ||= 'Prima images look the same';
	my $tb = Test::Prima->builder;
	
	# Make sure $expected is a Prima::Image
	$tb->croak('Expected value is not defined')
		unless defined $expected;
	$tb->croak('Expected value is not a Prima::Image')
		unless blessed($expected) and $expected->isa('Prima::Image');
	
	# Sanity-check $got: must be defined, must be a Prima::Image
	if (not defined $got) {
		$tb->ok(0, $message);
		return $tb->diag('    Got undefined value where expected a defined value');
	}
	unless (blessed($got) and $got->isa('Prima::Image')) {
		$tb->ok(0, $message);
		return $tb->diag("    Got value ($got) is not a Prima::Image");
	}
	
	# Check that the dims match
	if ($got->width != $expected->width or $got->height != $expected->height) {
		$tb->ok(0, $message);
		return $tb->diag("    Image size mismatch\n",
			"         got: ", $got->width, 'x', $got->height, "\n",
			"    expected: ", $expected->width, 'x', $expected->height);
	}
	
	# Check each pixel
	for my $i (0 .. $got->width-1) {
		for my $j (0 .. $got->height-1) {
			my $got_px = $got->pixel($i, $j);
			my $expected_px = $expected->pixel($i, $j);
			if ($got_px != $expected_px) {
				$tb->ok(0, $message);
				return $tb->diag("    Pixel values disagree at ($i, $j)\n",
					_describe_color_mismatch($got_px, $expected_px));
			}
		}
	}
	
	# By process of elimination, the test passes.
	return $tb->ok(1, $message);
}

1;

__END__

=head1 NAME

Test::Prima - a module for testing aspects of the Prima GUI toolkit.

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Prima;
 use Test::More;
 use Test::Prima;
 ...
 
 # Compare color values
 is_prima_color($image->pixel(10, 50), cl::White,
     'Properly clears background');
 # Can use color name strings for clearer diagnostic output
 is_prima_color($image->pixel(10, 10), 'Black',
     'Pixels on the diagonal are black');
 
 # Compare two images
 is_prima_image($got, $expected, 'The two images look alike');

=head1 DESCRIPTION

This module provides useful functions for testing Prima software. Presently it
provides tests for comparing two pixels and comparing two Prima images.

=over

=item is_prima_color

  is_prima_color($got, $expected, $test_name);

Performs a few sanity checks on C<$got>, then compares the two arguments for
numerical equality. The C<$expected> value can be a Color, or it can be a color
name, i.e. the string C<'Black'> for the color C<cl::Black>. If the values
disagree, having the color I<name> makes for a slightly clearer diagnostic
message.

=item is_prima_image

  is_prima_image($got, $expected, $test_name);

Checks that C<$got> is a L<Prima::Image>, ensures that the dimensions of the
two images agree, and compares the color value at each coordinate. This will
throw an exception if C<$expected> is not a Prima image.

=back

=head1 BUGS

None known at this point.

=head1 SEE ALSO

L<Test::More>, L<Prima>

=head1 AUTHOR, COPYRIGHT, LICENSE

This module was written by David Mertens. The documentation is copyright (C)
David Mertens, 2013. The source code is copyright (C) Dickinson College, 2013.
All rights reserved.

This module is distributed under the same terms as Perl itself.

=CUT
