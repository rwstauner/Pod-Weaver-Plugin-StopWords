# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
package TestPWEncoding;

# a tiny version of Pod::Weaver::Plugin::Encoding

use Moose;
use Moose::Autobox;
with 'Pod::Weaver::Role::Finalizer';

use Pod::Elemental::Element::Pod5::Command;

sub finalize_document {
  my ($self, $document) = @_;

  $document->children->unshift(
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'encoding',
      content => 'utf-8',
    }),
  );
}

__PACKAGE__->meta->make_immutable;

1;
