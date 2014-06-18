use strict;
use warnings;

My::talk->add(Slide =>
	title => 'What you will learn',
	toc_entry => 'Learning goals',
	content => [
		par => 'As you step through this slide, you will learn the basics,
				including',
		bullets => [
			'how to build a "Hello Prima::Talk" and',
			'the basic types of content.',
		],
		par => 'Then we will move on to the many ways you can tweak your talks,
				including',
		bullets => [
			'tweaking the layout, including custom footers',
			'creating custom content types, and',
			'making your own transitions and animations.',
		],
		par => 'After that, you should be in great shape to write some pretty
				awesome talks. However, there is one more point worth covering:',
		bullets => [
			'Best practices for organizing talk material.',
		],
	],
);

My::talk->add(Slide =>
	title => 'What is on a typical slide?',
	toc_entry => 'Layout Basics',
	contnet => [
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

My::talk->add(WideSlide =>
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

1;
