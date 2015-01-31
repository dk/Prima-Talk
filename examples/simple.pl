use strict;
use warnings;
use Prima qw(Talk Application);



my $title = 'Example talk!';
my $window = Prima::MainWindow->new(
	text => $title,
	place => { x => 0, relwidth => 1, y => 0, relheight => 1, anchor => 'sw' },
#	borderIcons => bi::SystemMenu,
);

my $talk = $window->insert(Talk =>
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
	toc_width => '10em',
	title_height => '10%height',
	backColor => cl::White,
#	aspect => 1,
);

###################
# The title slide #
###################

# For the title slide, I tend to use a WideSection. I always call the
# toc_entry "Introduction" because all of the slides after this slide
# usually contain introductory material, and this makes for a sensible Table
# of Contents on the left side of the screen.

$talk->add(WideSection =>
	title => $title,
	# The content is placed below the title. Here I just include my name.
	# Note that if you include multiple pieces of content, you need to use
	# a hashref, not a simple string.
	content => 'This is a WideSection slide, good for title slides',
	toc_entry => 'Introduction',
);


#####################   Introduction   #####################

$talk->add(Slide =>
	title => 'Basic slide',
	toc_entry => 'Basic',
	content => [
		par => 'This is a basic slide',
		spacer => '1em',
		bullets => [
			'Slide title above',
			'Footer below',
			'Table of Contents on the left',
			'Content (text) is left-justified by default',
			'This slide in particular illustrates a paragraph, a 1-em
			 spacer, and a set of bullets. One of the (longer) bullet points
			 illustrates text wrapping for bullets. :-)',
		],
	],
);

$talk->add(WideSlide =>
	title => 'Wide slide',
	content => [
		par => 'This is a wide slide',
		spacer => '1em',
		bullets => [
			'Slide title above',
			'Footer below',
			'Table of Contents is hidden, giving you more real-estate',
			'Content (text) is left-justified by default',
			'This slide illustrates a paragraph, a 1-em spacer, and a set of bullets',
			'Notice that the wider slide lets me use longer text strings without wrapping.',
		],
	],
);

$talk->add(Slide =>
	title => 'Another Basic Slide',
	content => 'Returning to a basic slide, we see that the table of
				contents is restored on the left.',
);

$talk->add(Section =>
	title => 'First section',
	content => [
		par => 'A Subtitle!',
		subref => sub {
			my ($slide, $container) = @_;
			# Pack a button
			$container->insert(Button =>
				text => 'Click for message',
				onClick => sub {
					Prima::MsgBox::message('Clicked!');
				},
				pack => { side => 'top', fill => 'x' },
			);
		},
	],
);


$talk->add(Slide =>
	title => 'subfoo',
	content => 'subbar',
);


$talk->add(Section =>
	title => 'Section section',
	content => 'A Subtitle!',
	transitions => [
		# Zeroeth transition does not need to render anything
		sub {},
		sub {
			my $self = shift;
			$self->render_content($self->slide_deck->container,
				par => 'Another paragraph',
			);
		},
		sub {
			my $self = shift;
			$self->render_content($self->slide_deck->container,
				par => 'And yet another!',
			);
		},
	],
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