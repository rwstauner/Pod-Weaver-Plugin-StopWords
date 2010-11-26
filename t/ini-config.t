use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use TestPW;

foreach my $eg ( ['t/eg'], ['t/eg2', 'MyExtraWord1 exword2 sw3'] ){
	my ($dir, $words) = @$eg;
	my $input = weaver_input();
	my $weaver = Pod::Weaver->new_from_config({ root => $dir });
	test_basic($weaver, $input, $words);
}



done_testing;
