package TestPW;
use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(test_basic weaver_input);
our $Data = do { local $/; <DATA> };

use Test::More;
use Test::Differences;
use Moose::Autobox 0.10;

use PPI;

use Pod::Elemental;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

use Pod::Weaver;
require Software::License::Perl_5;

sub test_basic {
	my ($weaver, $input, $stopwords) = @_;
	my $expected = $input->{expected};

	my ($paragraphs, $versionp, @nestedh1s) = (10, 1, qw(0 1 3 4 5 6 8 9));
	if( $stopwords ){
		++$_ for $paragraphs, $versionp, @nestedh1s;
		$expected =~ s/\A=pod\n\n/=pod\n\n=for :stopwords $stopwords\n\n/;
	}

	# copied/modified from Pod::Weaver tests (Pod-Weaver-3.101632/t/basic.t)
	my $woven = $weaver->weave_document($input);

	is($woven->children->length, $paragraphs, "we end up with a $paragraphs-paragraph document");

	for ( @nestedh1s ) {
	  my $para = $woven->children->[ $_ ];
	  isa_ok($para, 'Pod::Elemental::Element::Nested', "element $_");
	  is($para->command, 'head1', "... and is =head1");
	}

	is(
	  $woven->children->[$versionp]->children->[0]->content,
	  'version 1.002003',
	  "the version is in the version section",
	);

	# XXX: This test is extremely risky as things change upstream.
	# -- rjbs, 2009-10-23
	eq_or_diff(
	  $woven->as_pod_string,
	  $expected,
	  "exactly the pod string we wanted after weaving!",
	);
}

sub weaver_input {
	# copied from Pod::Weaver tests (Pod-Weaver-3.101632/t/basic.t)
	my $in_pod   = do { local $/; open my $fh, '<', 't/eg/basic.in.pod'; <$fh> };
	my $expected = do { local $/; open my $fh, '<', 't/eg/basic.out.pod'; <$fh> };
	my $document = Pod::Elemental->read_string($in_pod);

	my $perl_document = $Data;
	my $ppi_document  = PPI::Document->new(\$perl_document);

	return {
	  pod_document => $document,
	  ppi_document => $ppi_document,
	  # below configuration modified by rwstauner
	  expected => $expected,

	  version  => '1.002003',
	  authors  => [
		'Randy Stauner <rwstauner@cpan.org>',
	  ],
	  license  => Software::License::Perl_5->new({
		holder => 'Randy Stauner',
		year   => 2010,
	  }),
	};
}

1;

__DATA__

package Module::Name;
# ABSTRACT: abstract text

my $this = 'a test';
