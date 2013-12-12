use strict;
use warnings;

# A module with testing utilities for Prima systems.

package Test::Prima;

our $VERSION = "0.01"; # or "0.001_001" for a dev release
$VERSION = eval $VERSION;

use base 'Test::Builder::Module';
our @EXPORT = qw( is_prima_color );
use Scalar::Util qw(looks_like_number);

sub is_prima_color {
	my ($got, $expected, $message) = @_;
	$message ||= 'Prima colors are equal';
	my $tb = Test::Prima->builder;
	
	# Make sure $got makes sense:
	if (not defined $got) {
		my $to_return = $tb->ok(0, $message);
		$tb->diag('    Got undefined value where expected a defined value');
		return $to_return;
	}
	if (not looks_like_number($got)) {
		my $to_return = $tb->ok(0, $message);
		$tb->diag("    Got value ($got) that does not look like a Prima color");
		return $to_return;
	}
	
	# I allow the user to specify a color by name, which makes the diagnostics
	# a lot cleaner. But we have to make sure that the name exists.
	my $expected_number = $expected;
	$expected_number = eval "cl::$expected" if $expected =~ /^[A-Za-z]+$/;
	$tb->croak("Unkown expected color name $expected") if $@;
	
	# OK, we have a numeric color value. Now let's see if they agree
	my $to_return = $tb->ok($got == $expected_number, $message);
	return $to_return if $to_return;
	
	# If we're here, it means that the comparison failed. Let's give diagnostic
	# output
	$tb->diag(	"    Prima color mismatch\n",
		sprintf('         got: %06x', $got), "\n",
		sprintf('    expected: %06x%s', $expected_number,
			($expected_number eq $expected ? '' : " ($expected)")));
	
	return $to_return;
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

=head1 DESCRIPTION

This module provides a useful function for testing Prima software. At the moment
it only provides a single test function, but this is likely to grow over time.

=over

=item is_prima_color

  is_prima_color($got, $expected, $test_name);

Performs a few sanity checks on C<$got>, then compares the two arguments for
numerical equality. The C<$expected> value can be a Color, or it can be a color
name, i.e. the string C<'Black'> for the color C<cl::Black>. If the values
disagree, having the color I<name> makes for a slightly clearer diagnostic
message.

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
