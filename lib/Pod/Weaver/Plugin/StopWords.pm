package Pod::Weaver::Plugin::StopWords;
# ABSTRACT: Dynamically add stopwords to your woven pod

=head1 SYNOPSIS

	# weaver.ini
	[-StopWords]
	gather = 1     ; default
	stopwords = MyExtraWord1 exword2

=cut

use strict;
use warnings;
use Moose;
use Moose::Autobox;
use namespace::autoclean -also => 'splice_stopwords_from_children';

with 'Pod::Weaver::Role::Finalizer';

# TODO: attribute for removing words

sub mvp_multivalue_args { qw(stopwords) }
sub mvp_aliases { return { collect => 'gather' } }

has gather => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1
);

has stopwords => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub finalize_document {
    my ($self, $document, $input) = @_;

	my @stopwords = @{$self->stopwords};

	# TODO: ignore email address
	if( my $zilla = ($input && $input->{zilla}) ){
		push(@stopwords, split(/\s+/)) foreach @{ $zilla->{authors} };
		# TODO: get stopwords from zilla
	}

	# TODO: keep different sections as separate lines
	push(@stopwords, splice_stopwords_from_children($document->children))
		if $self->gather;

	@stopwords = grep { $_ } @stopwords;
	return unless @stopwords;

	# TODO: use a hash to verify uniqueness
	# TODO: use Text::Wrap
    $document->children->unshift(
        Pod::Elemental::Element::Pod5::Command->new({
            command => 'for :stopwords',
            content => join(' ', @stopwords)
        }),
    );
}

sub splice_stopwords_from_children {
    my ($children, @stopwords) = @_;

	CHILDREN: foreach my $i ( 0 .. (@$children - 1) ){
		next unless my $para = $children->[$i];
		next unless $para->isa('Pod::Elemental::Element::Pod5::Region')
			and $para->format_name eq 'stopwords';

		push(@stopwords,
			map { split(/\s+/, $_->content) } $para->children->flatten);
		splice(@$children, $i, 1);

		redo CHILDREN; # don't increment the counter
	}

	return @stopwords;
}

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage finalize_document

=head1 DESCRIPTION

This is a L<Pod::Weaver> plugin for dynamically adding stopwords
to help pass the Pod Spelling test.
It does the L<Pod::Weaver::Role::Finalizer> role.

Author names will be included along with any
stopwords specified in the plugin config (F<weaver.ini>).

Additionally the plugin can gather any other stopwords
listed in the POD and compile them all into one paragraph
at the top of the document.

=cut
