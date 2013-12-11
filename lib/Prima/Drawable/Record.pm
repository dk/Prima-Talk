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
