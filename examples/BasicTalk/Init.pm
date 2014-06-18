use strict;
use warnings;
use Prima qw(Talk Application);

my $window = Prima::MainWindow->new(
	text => 'Building a Basic Talk',
	place => { x => 0, relwidth => 1, y => 0, relheight => 1, anchor => 'sw' },
	($^O =~ /MS/ or $^O =~ /cywin/i) ? () : (borderIcons => bi::SystemMenu),
);

my $talk = $window->insert(Talk =>
   # Fill the application:
   place => {
		x => 0, relwidth => 1,
		y => 0, relheight => 1,
		anchor => 'sw',
	},
	font => {
		name => 'Helvetica',
	},
	
	# Set the em-width relative to the container size
	em_width => '2%width',
	toc_color => cl::White,
	toc_backColor => 0x242F52,
	toc_width => '20%width', #'12em',
	title_height => '10%height',
	backColor => cl::White,
	aspect => 8/5,
);

sub My::talk { $talk }

1;
