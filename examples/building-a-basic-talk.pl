use strict;
use warnings;
use Prima qw(Talk Application);

use BasicTalk::Init;

###################
# The title slide #
###################

# For the title slide, I tend to use a WideSection. I always call the
# toc_entry "Introduction" because all of the slides after this slide
# usually contain introductory material, and this makes for a sensible Table
# of Contents on the left side of the screen.

My::talk->add(WideSection =>
	title => 'Your Guide to Writing Talks using Prima::Talk',
	# The content is placed below the title. Here I just include my name.
	# Note that if you include multiple pieces of content, you need to use
	# a hashref, not a simple string.
#	content => 'This is a WideSection slide, good for title slides',
	toc_entry => 'Introduction',
);
require BasicTalk::Introduction;

# Getting started material
require BasicTalk::Hello;
require BasicTalk::BasicContent;

# Advanced topics
require BasicTalk::Tweaking;
require BasicTalk::CustomContent;
require BasicTalk::Transitions;

# Best practices
require BasicTalk::BestPractices;

#####################   Introduction   #####################

My::talk->add(Slide =>
	title => 'Another Basic Slide',
	content => 'Returning to a basic slide, we see that the table of
				contents is restored on the left.',
);

My::talk->add(Section =>
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


My::talk->add(Slide =>
	title => 'subfoo',
	content => 'subbar',
);


My::talk->add(Section =>
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


# Set to the opening slide
My::talk->slide(0);


Prima->run;
