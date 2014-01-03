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