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
use namespace::autoclean;

with 'Pod::Weaver::Role::Finalizer';

# TODO: attribute for removing words

sub mvp_multivalue_args { qw(stopwords) }
sub mvp_aliases { return { collect => 'gather' } }

has include_authors => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1
);

has gather => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1
);

has stopwords => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has wrap => (
	is      => 'ro',
	isa     => 'Int',
	default => 76
);


sub finalize_document {
    my ($self, $document, $input) = @_;

	my @stopwords = @{$self->stopwords};

	if( $input->{authors} ){
		unshift(@stopwords, $self->author_stopwords($input->{authors}))
			if $self->include_authors;
	}

	if( my $zilla = ($input && $input->{zilla}) ){
		# TODO: get stopwords from zilla
		# these are probably the same authors as above, but just in case
		# we'll add these, too (we remove duplicates later so it's ok)
		unshift(@stopwords, $self->author_stopwords($zilla->{authors}))
			if $self->include_authors;
	}

	# TODO: keep different sections as separate lines
	push(@stopwords, $self->splice_stopwords_from_children($document->children))
		if $self->gather;

	my %seen;
	#$seen{$_} = 1 foreach $self->remove;
	@stopwords = grep { $_ && !$seen{$_}++ } map { split /\s+/ } @stopwords;
	return unless @stopwords;

    $document->children->unshift(
        Pod::Elemental::Element::Pod5::Command->new({
            command => 'for :stopwords',
            content => $self->format_stopwords(\@stopwords)
        }),
    );
}

sub author_stopwords {
	my $self = shift;
	# ignore email addresses since Pod::Spell will ignore them anyway
	return grep { !/^<\S+\@\S+\.\S+>$/ }
		map { split /\s+/ } map { ref($_) ? @$_ : $_ } @_;
}

sub format_stopwords {
	my ($self, $stopwords) = @_;
	my $paragraph = join(' ', @$stopwords);

	return $paragraph
		unless $self->wrap && eval "require Text::Wrap";

	local $Text::Wrap::columns = $self->wrap;
	return Text::Wrap::wrap('', '', $paragraph);
}

sub splice_stopwords_from_children {
    my ($self, $children) = @_;
	my @stopwords;

	CHILDREN: foreach my $i ( 0 .. (@$children - 1) ){
		next unless my $para = $children->[$i];
		next unless $para->isa('Pod::Elemental::Element::Pod5::Region')
			and $para->format_name eq 'stopwords';

		push(@stopwords,
			map { split(/\s+/, $_->content) } $para->children->flatten);

		# remove paragraph from document since we've copied all of its stopwords
		splice(@$children, $i, 1);

		redo CHILDREN; # don't increment the counter
	}

	return @stopwords;
}

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage finalize_document format_stopwords
mvp_aliases mvp_multivalue_args

=head1 DESCRIPTION

This is a L<Pod::Weaver> plugin for dynamically adding stopwords
to help pass the Pod Spelling test.
It does the L<Pod::Weaver::Role::Finalizer> role.

Author names will be included along with any
L</stopwords> specified in the plugin config (F<weaver.ini>).

Additionally the plugin can gather any other stopwords
listed in the POD and compile them all into one paragraph
at the top of the document.

=attr gather

Gather up all other C< =for stopwords > sections and combine them into a
single paragraph at the top of the document.

If set to false the plugin will not search the document but will simply
put any new stopwords in a new paragraph at the top.

Defaults to true.

Aliased as I<collect>.

=attr stopwords

List of stopwords to include.

This can be set multiple times.

=attr wrap

This is an integer for the number of columns at which to wrap the resulting
paragraph.  It defaults to I<76> which is the default in
L<Text::Wrap> (version 2004.0305).

No wrapping will be done if L<Text::Wrap> is not found
or if you set this value to I<0>.

=cut
