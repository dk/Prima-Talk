use strict;
use warnings;
use Prima qw(Talk Application);



my $title = 'Physics-inspired techniques for segmenting human self-reported weight loss time series';
my $window = Prima::MainWindow->new(
	text => $title,
#	place => { x => 0, relwidth => 1, y => 0, relheight => 1, anchor => 'sw' },
#	borderIcons => bi::SystemMenu,
);



#                      red         green        blue
my $reversed_purple = ( 70 << 16) | ( 15 << 8) |  94;

# 70, 15, 94

my $talk = #Prima::Talk->new(#
		$window->insert(Talk =>
   # Fill the application:
   place => {
		x => 0, relwidth => 1,
		y => 0, relheight => 1,
		anchor => 'sw',
	},
	
	# Set the em-width relative to the container size
	em_width => '2%width',
	toc_color => cl::White,
	toc_backColor => cl::Black,
	toc_width => '12%width',
	title_height => '10%height',
	backColor => cl::White,
#	place => {
#		x => 0, relwidth => 1,
#		y => 0, relheight => 1,
#		anchor => 'sw',
#	},
#	font => {
#		name => 'Georgia',
#	},
#	em_width => '2%width',
#	toc_color => cl::White,
#	toc_backColor => $reversed_purple,
##	toc_width => 210,
#	toc_width => '12%width',
#	title_height => 122,
#	backColor => cl::White,
#	aspect => 1,
);


#####################   Introduction   #
####################


# The title slide
$talk->add(WideSection =>
	title => $title,
	content => 'by David Mertens',
	toc_entry => 'Introduction',
);


$talk->add(Slide =>
	toc_entry => 'Why?',
	title => 'Physicists are unusually quantitative.',
	content => [
		par => q{
			
		},
	],
);


$talk->add(Slide =>
	title => 'intro slide 2',
	content => 'bar',
);


$talk->add(WideSlide =>
	title => 'Another foo!',
	content => 'wide text!',
);

$talk->add(Section =>
	title => 'First section',
	content => 'A Subtitle!',
);


$talk->add(Slide =>
	title => 'subfoo',
	content => 'subbar',
);


$talk->add(Section =>
	title => 'Section section',
	content => 'A Subtitle!',
	transition_counter => 0,
	transition_content => [
		par => 'Another paragraph',
		par => 'And yet another!',
	],
	transition => sub {
		my ($self, $direction) = @_;
		my $counter = $self->{transition_counter};
		my @content = @{$self->{transition_content}};
		
		# First, do we have any more transitioning to do in this direction?
		return 0 if $direction < 0 and $counter == 0;
		return 0 if $direction > 0 and $counter == @content;
		
		# If we're here, we're ready to render or remove the latest content
		if ($direction > 0) {
			$self->render_content($self->slide_deck->container, 
				@content[$counter, $counter+1]);
			$self->{transition_counter} += 2;
		}
		else {
			my @components = $self->slide_deck->container->get_components;
			$components[-1]->destroy;
			$self->{transition_counter} -= 2;
		}
		return 1;
	},
	tear_down => sub {
		# tear-down needs to reset the transition_counter. However, all the
		# component removal was already handled.
#		print "Calling tear-down\n";
		my $self = shift;
		$self->{transition_counter} = 0;
	},
);


use PDL;
use PDL::Constants qw(PI);
use PDL::Graphics::Prima;my $xs = sequence(100)/2;
$talk->add(Slide =>
	title => 'secfoo',
	content => [
		par => 'The solution to',
		tex => '\[\sqrt{x} = 5\]',
		par => 'is',
		tex => '\[x=25.\]',
		my_plot => {
			-data => ds::Pair($xs, $xs->sqrt),
			-twenty5 => ds::Note(
				pnote::Line(x1 => 25, x2 => 25, linePattern => lp::ShortDash)
			),
			height => 600,
		},
	],
	# Capture the plot object for later manipulation
	render_my_plot => sub {
		my ($self, $content, $container) = @_;
		$self->{plot_widget} = $self->render_plot($content, $container);
	},
	transition_counter => 0,
	transition => sub {
		my ($self, $direction) = @_;
		my $counter = $self->{transition_counter} + $direction;
		return 0 if $counter > 1 or $counter < 0;
		
		if ($direction > 0) {
			# zoom in on a forward-transition
			my ($init_x_min, $init_x_max) = $self->{plot_widget}->x->minmax;
			my ($init_y_min, $init_y_max) = $self->{plot_widget}->y->minmax;
			my $dx_min = 20 - $init_x_min;
			my $dx_max = 30 - $init_x_max;
			my $dy_min = 4 - $init_y_min;
			my $dy_max = 6 - $init_y_max;
			Prima::Talk::animate(41, 500/40, sub {
				my ($frame_number, $N_frames) = @_;
				$N_frames--;
				$frame_number++ unless $frame_number == $N_frames;
				# Calculate how big a change we want
				my $delta = sin(PI / 2 * $frame_number / $N_frames)**2;
				# Set the new min/max based on this delta
				$self->{plot_widget}->x->minmax($init_x_min + $dx_min * $delta
					, $init_x_max + $dx_max * $delta);
				$self->{plot_widget}->y->minmax($init_y_min + $dy_min * $delta
					, $init_y_max + $dy_max * $delta);
				$self->{plot_widget}->notify('Replot');
			});
		}
		else {
			# snap out on a backward transition
			$self->{plot_widget}->x->minmax(lm::Auto, lm::Auto);
			$self->{plot_widget}->y->minmax(lm::Auto, lm::Auto);
		}
		
		$self->{transition_counter} = $counter;
		return 1;
	},
	tear_down => sub {
		$_[0]->{transition_counter} = 0;
	},
);

# Set to the opening slide
$talk->slide(0);


Prima->run;