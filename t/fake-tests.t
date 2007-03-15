# $Id: fake-tests.t,v 1.2 2007/03/15 15:55:06 drhyde Exp $
use strict;
local $^W = 0;

my $warning;
$SIG{__WARN__} = sub { $warning = join('', @_) };

use Test::More skip_all => "not written yet"; # tests => 500
use Test::Mock::LWP;
use Net::Random;


