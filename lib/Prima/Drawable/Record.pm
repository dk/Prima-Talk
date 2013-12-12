package Prima::Drawable::Record;

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

sub new {
	my $class = shift;
	croak('Prima::Drawable::Record::new expects key/value pairs')
		unless @_ % 2 == 0;
	my %self = @_;
	croak('Prima::Drawable::Record::new expects a canvas key')
		unless exists $self{canvas};
	croak('Prima::Drawable::Record::new expects a Prima::Drawable canvas')
		unless blessed $self{canvas} and $self{canvas}->isa('Prima::Drawable');
	
	# the record of method calls starts off empty, initially
	$self{record} = [];
	
	return bless \%self, $class;
}

sub AUTOLOAD {
	# Remove qualifier from original method name...
	(my $called = our $AUTOLOAD) =~ s/.*:://;
	# append the methdo and switch context to store_and_run
	unshift @_, $called;
	goto &store_and_run;
}

sub store_and_run {
	my $method_name = shift;
	my $self = shift;
	
	push @{$self->{record}}, [$method_name, @_];
	
	# Call it on the parent, if the parent can do it
	if (my $method = $self->{canvas}->can($method_name)) {
		unshift @_, $self->{canvas};
		goto &$method;
	}
	
	# otherwise mark the method as bad and croak
	croak("Prima::Drawable::Record unable to call `$method_name' on class " . ref($self->{canvas}));
}

sub get_record {
	my $self = shift;
	return $self->{record};
}

my %apply_translate = (
	(map { $_ => \&trans_first_pair } qw( arc chord ellipse fill_chord
		fill_ellipse fill_sector flood_fill pixel put_image sector stretch_image )),
	(map { $_ => \&trans_rect } qw( bar line rect3d rect_rocus rectangle )),
	(map { $_ => \&trans_array_ref } qw( fillpoly fill_spline lines polyline spline )),
	draw_text => sub {
		my ($dx, $dy, $canvas, $text, $x1, $y1, $x2, $y2, @args) = @_;
		return ($canvas, $text, $x1 + $dx, $y1 + $dy, $x2 + $dx, $y2 + $dy, @args);
	},
	put_image_indirect => sub {
		my ($dx, $dy, $object, $x, $y, @args) = @_;
		return ($object, $x + $dx, $y + $dy, @args);
	},
	text_out => sub {
		my ($dx, $dy, $text, $x, $y) = @_;
		return ($text, $x + $dx, $y + $dy);
	},
);
sub trans_first_pair {
	my ($dx, $dy, $x, $y, @args);
	return ($x + $dx, $y + $dy, @args);
}
sub trans_rect {
	my ($dx, $dy, $left, $bottom, $right, $top, @args) = @_;
	return ($left + $dx, $bottom + $dy, $right + $dx, $top + $dy, @args);
}
sub trans_array_ref {
	my ($dx, $dy, $array_ref) = @_;
	my ($d_this, $d_next) = ($dx, $dy);
	my @to_return;
	for my $position (@$array_ref) {
		push @to_return, $position + $d_this;
		($d_this, $d_next) = ($d_next, $d_this);
	}
	return \@to_return;
}

sub search_record {
	my ($self, $draw_command, %preferences) = @_;
	my @record = @{$self->{record}};
	my %state;
	my @to_return;
	for my $line (@record) {
		# Unpack the line; skip if it's only an accessor
		my ($command, @args) = @$line;
		next if not @args;
		# Apply translation if this is a command, requested and appropriate
		if (exists $apply_translate{$command}
			and $preferences{apply_translate}
			and exists $state{translate}
		) {
			@args = $apply_translate{$command}->(@{$state{translate}}, @args);
		}
		# Store the arguments (both for state and for the command)
		$state{$command} = \@args;
		# Push a copy of the state if this line is a command we want
		push @to_return, {%state} if $command eq $draw_command;
	}
	return @to_return;
}

sub clear_record {
	my $self = shift;
	$self->{record} = [];
}

sub can {
	my ($self, $method_name) = @_;
	
	# Special case our own methods
	return \&get_record if $method_name eq 'get_record';
	return \&clear_record if $method_name eq 'clear_record';
	
	# Return a subref that will perform the store and function call for us.
	my $parent = blessed($self) ? $self->{canvas} : 'Prima::Drawable';
	if ($parent->can($method_name)) {
		return sub {
			unshift @_, $method_name;
			goto &store_and_run;
		};
	}
	# If the parent class can't do it, return undef
	return undef;
}

sub isa {
	my ($self, $class_name) = @_;
	
	# It's easy to emulate object-based isa:
	return $self->{canvas}->isa($class_name) if blessed $self;
	
	# otherwise work with Prima::Drawable return value
	return 'Prima::Drawable'->isa($class_name);
}

1;
