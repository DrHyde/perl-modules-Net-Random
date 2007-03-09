# $Id: param-checking.t,v 1.1 2007/03/09 17:27:27 drhyde Exp $
use strict;

local $^W = 0;

my $warning;
$SIG{__WARN__} = sub { $warning = join('', @_) };

use Test::More tests => 7;
use Net::Random;

my $r;

eval { $r = Net::Random->new(); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with no params");

eval { $r = Net::Random->new(src => 'rubbish'); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with bad source");

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 1.2); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with non-integer max");

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 12, min => 1.2); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with non-integer min");

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 12, min => 13); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with min > max");

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 12, min => -1); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with min < 0");

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 2 ** 32); };
ok($@ =~ /Bad parameters to Net::Random->new/, "dies with max > 2^32-1");
