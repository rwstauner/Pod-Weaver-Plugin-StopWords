use strict;
use warnings;

use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use TestPW;

my $input = weaver_input();

my $weaver = Pod::Weaver->new_from_config({ root => 't/eg' });

my $stopwords = 1;

test_basic($weaver, $input, 'MyExtraWord1 exword2');

done_testing;
