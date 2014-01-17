use strict;
use warnings;

# Set up the container packing constants
package
cp;
use constant { qw(
	FromTop      1
	FromLeft     2
	FromBottom   3
	FromRight    4
	Default      5
	RotateLeft   6
	Opposite     7
	RotateRight  8
)};
my @pack_names = map {"cp::$_" } ( qw( NONE FromTop FromLeft FromBottom
	FromRight Default RotateLeft Opposite RotateRight) );
my @pack_side_for_abs = (undef, qw( top left bottom right ));

############################################################################
                   package Prima::Container::Role;
############################################################################
use Carp;
use Scalar::Util qw( looks_like_number );
use Exporter 'import';
our @EXPORT = qw(packChildren packChildrenAbsolute repack insert);

# Implements a set of functions to be used by multiple classes. Note that
# profile_default and init both use inheritance, which I cannot quite get to
# work right, so they have to be copied to all consumers of this role.

sub packChildren {
	# Handle the getter
	return shift->{packChildren} if @_ == 1;
	
	# If a change, repack the children and issue a repack on any children
	# who also have a relative value for packChildren
	my ($self, $new_pack) = @_;
	croak('Unknown packChildren value') unless name_for($new_pack);
	my $old_pack_abs = $self->packChildrenAbsolute;
	$self->{packChildren} = $new_pack;
	my $new_pack_abs = $self->packChildrenAbsolute;
	# No need to do anything if the new absolute pack is the same as the
	# old absolute pack
	return if $new_pack_abs == $old_pack_abs;
	$self->repack($new_pack_abs);
}

sub packChildrenAbsolute {
	my $self = shift;
	my $packChildren = $self->{packChildren};
	my $parent_packChildren = $self->owner->packChildrenAbsolute
		if $self->owner->can('packChildrenAbsolute');
	$parent_packChildren ||= cp::FromTop;
	return abs_from_pair($parent_packChildren, $packChildren);
}

sub repack {
	my $self = shift;
	my $new_pack_abs = shift || $self->packChildrenAbsolute;
	CHILD: for my $child ($self->get_widgets) {
		# Retrieve the previously set packing info. If there is none, then
		# this child was not packed
		my $pack_side = $child->{'Prima::Container::pack_side'}
			or next CHILD;
		my $pack_abs = abs_from_pair($new_pack_abs, $pack_side);
		my %pack_options = (side => side_string_for_abs($pack_abs));
		$pack_options{fill} = fill_string_for_abs($pack_abs)
			if $child->{'Prima::Container::pack_fill'};
		$child->pack(%pack_options);
	}
}

sub insert {
	croak('Prima::Container::insert expects a class name and key/value pairs')
		if @_ % 2 == 1;
	my ($self, $class_name, %args) = @_;
	
	# If this insert does not specify a cp::XXX, then use the normal
	# insertion process. If there is no packing hash at all, then use the
	# defaults for Container children.
	$args{pack} ||= {side => cp::Default} unless $args{place};
	my $pack = $args{pack};
	return $self->Prima::Widget::insert($class_name, %args)
		unless exists $pack->{side} and looks_like_number($pack->{side});
	croak("Invalid Prima::Container pack side")
		unless name_for($pack->{side});
	
	# Sanity check their fill option (default is 'none', so this doesn't
	# hurt anything)
	$pack->{fill} ||= 'none';
	croak("Prima::Container::insert found invalid pack fill [$pack->{fill}]")
		if $pack->{fill} =~ /^[xy]$/;
	
	# It looks like the widget wants to be packed by the Container. Good.
	# Next we'll replace these fields in the hash with normal packer values,
	# so we copy them to seperate scalars first.
	my $pack_side = $pack->{side};
	my $pack_fill = 1 if $pack->{fill} eq '1';
	
	# Construct the correct pack arguments based on $pack_side and $pack_fill
	my $pack_abs = abs_from_pair($self->packChildrenAbsolute, $pack_side);
	$pack->{side} = side_string_for_abs($pack_abs);
	$pack->{fill} = fill_string_for_abs($pack_abs) if $pack_fill;
	
	# Build the widget (note we've manipulated $args{pack} throughout)
	my $widget = $self->Prima::Widget::insert($class_name, %args);
	
	# Finally, store these settings in the newly created widget's hash so we
	# can repack later, if necessary:
	$widget->{'Prima::Container::pack_side'} = $pack_side;
	$widget->{'Prima::Container::pack_fill'} = $pack_fill;
	
	return $widget;
}

############################################################################
#                        Utilities for cp::

sub name_for {
	my $packing = shift;
	return unless looks_like_number($packing);
	return if $packing < cp::FromTop or $packing > cp::RotateRight;
	return $pack_names[$packing];
}

sub side_string_for_abs {
	my $packing = shift;
	return unless looks_like_number($packing);
	return if $packing <= 0;
	return $pack_side_for_abs[$packing];
}

sub is_absolute {
	my $packing = shift;
	return unless looks_like_number($packing);
	return if $packing < cp::FromTop or $packing > cp::RotateRight;
	return 1 if $packing <= cp::FromRight;
	return 0;
}

sub is_relative {
	my $packing = shift;
	return unless looks_like_number($packing);
	return if $packing < cp::FromTop or $packing > cp::RotateRight;
	return 1 if $packing >= cp::Default;
	return 0;
}

sub abs_from_pair {
	my ($abs, $rel) = @_;
	return unless looks_like_number($abs) and looks_like_number($rel);
	return $rel if $rel >= cp::FromTop and $rel <= cp::FromRight;
	return if $abs < cp::FromTop or $abs > cp::FromRight
		or $rel < cp::Default or $rel > cp::RotateRight;
	return ($abs + $rel - 2) % 4 + 1;	
}

sub fill_string_for_abs {
	my $packing = shift;
	return unless looks_like_number($packing);
	return 'x' if $packing == cp::FromTop or $packing == cp::FromBottom;
	return 'y' if $packing == cp::FromRight or $packing == cp::FromLeft;
	return;
}

############################################################################
                   package Prima::GroupContainer;
############################################################################

our @ISA = qw(Prima::GroupBox);
use Prima qw(noX11);
Prima::Container::Role->import;

sub profile_default {
	return {
		%{$_[ 0]-> SUPER::profile_default},
		packChildren => cp::Default,
	};
}

sub init {
	my $self = shift;
	my %profile = $self->SUPER::init(@_);
	$self->{packChildren} = $profile{packChildren};
}

############################################################################
                      package Prima::Container;
############################################################################

our @ISA = qw(Prima::Widget);
use Prima qw(noX11);
Prima::Container::Role->import;

sub profile_default {
	return {
		%{$_[ 0]-> SUPER::profile_default},
		packChildren => cp::Default,
	};
}

sub init {
	my $self = shift;
	my %profile = $self->SUPER::init(@_);
	$self->{packChildren} = $profile{packChildren};
}

1;

__END__

=head1 NAME

Prima::Container - a packing widget with enhanced packing order specifications

=head1 SYNOPSIS

 use Prima qw(Container);
 
 my $container = Prima::Container->new(
   height => 300, width => 400
   packChildren => cp::FromTop,
 );
 
 # Packed at the top due packChildren
 $container->insert(Widget =>
   ...
 );
 # Packed at the bottom
 $container->insert(Widget =>
   pack => { side => cp::Opposite },
 );
 
 my $container = Prima::Container->new(
   ...
   packChildren => cp::FromLeft,
 );
 # Packed from the left; fill y
 $container->insert(Widget =>
   pack => { side => cp::Default, fill => 1 },
 );
 # Same thing, but more rigid:
 $container->insert(Widget =>
   pack => { side => 'left', fill => 'y' },
 );
 # Packed from the *bottom*, fills x
 $container->insert(Widget =>
   pack => { side => cp::RotateLeft, fill => 1 },
 );
 
 # Dynamically updates children
 $container->packChildren(cp::Right);

=head1 DESCRIPTION

This module provides a widget with a preferred packing direction, and an
enhanced C<insert> method to implement that packing direction.

=head1 CONSTANTS

In the spirit of other Prima modules, the configuration is specified using
constants. In this case, the constants have the C<cp::> prefix. The absolute
packing direcions are

 cp::FromTop
 cp::FromLeft
 cp::FromBottom
 cp::FromRight

while the relative packing directions are

 cp::Default
 cp::RotateLeft
 cp::Opposite
 cp::RotateRight

You can use either relative or absolute packing directions for both the
C<packChildren> value and for the C<side> key of the C<pack> hash for
child widgets. For example, suppose a parent container will
C<< packChildren => cp::FromLeft >> and one of the children is itself a
container that will C<< packChildren => cp::RotateRight >>. Widgets rendered
in the child container will be packed from the top. The difference between
specifying C<cp::FromTop> is that if the parent's direction changes to
something else, the child container will change also so that it is still
rotated right compared to its parent.

=cut
