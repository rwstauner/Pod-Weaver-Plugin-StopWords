use strict;
use warnings;

use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use TestPW;

my $input = weaver_input();

#my $weaver = Pod::Weaver->new_with_default_config;
my $weaver = Pod::Weaver->new_from_config({ root => 't/eg' });

test_basic($weaver, $input);

done_testing;
