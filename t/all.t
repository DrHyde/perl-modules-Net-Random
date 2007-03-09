use strict; # use warnings;
my($loaded, $test) = (0, 0);

BEGIN { $| = 1; print "1..20\n"; }
END { print "not ok 1\n" unless $loaded; }

my $warning;
$SIG{__WARN__} = sub { $warning = join('', @_) };

use Net::Random;
$loaded++;

print 'ok '.(++$test)." module loaded\n";

my $r;

eval { $r = Net::Random->new(); };
print 'not ' unless($@ =~ /Bad parameters to Net::Random->new/);
print 'ok '.(++$test)." dies with no params\n";

eval { $r = Net::Random->new(src => 'rubbish'); };
print 'not ' unless($@ =~ /Bad parameters to Net::Random->new/);
print 'ok '.(++$test)." dies with bad source\n";

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 1.2); };
print 'not ' unless($@ =~ /Bad parameters to Net::Random->new/);
print 'ok '.(++$test)." dies with non-integer max\n";

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 12, min => 1.2); };
print 'not ' unless($@ =~ /Bad parameters to Net::Random->new/);
print 'ok '.(++$test)." dies with non-integer min\n";

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 12, min => 13); };
print 'not ' unless($@ =~ /Bad parameters to Net::Random->new/);
print 'ok '.(++$test)." dies with min > max\n";

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 12, min => -1); };
print 'not ' unless($@ =~ /Bad parameters to Net::Random->new/);
print 'ok '.(++$test)." dies with min < 0\n";

eval { $r = Net::Random->new(src => 'fourmilab.ch', max => 2 ** 32); };
print 'not ' unless($@ =~ /Bad parameters to Net::Random->new/);
print 'ok '.(++$test)." dies with max > 2^32-1\n";

my %dist = ();
$r = Net::Random->new(src => 'random.org');
my @data = $r->get(512);
if($warning) {
    print "ok ".(++$test)." # skip not enough random bytes\n";
    print "ok ".(++$test)." # skip not enough random bytes\n";
    $warning = '';
} else {
    %dist = (); $dist{$_}++ foreach (@data);
    print 'not ' if(grep { $_ < 0 || $_ > 255 } @data);
    print 'ok '.(++$test)." generates bytes in correct range\n";
    print 'not ' if(grep { $_ > 10 } values %dist);
    print 'ok '.(++$test)." distribution looks sane\n";
}

$r = Net::Random->new(min => 1, max => 6, src => 'random.org');
@data = $r->get(128);
if($warning) {
    print "ok ".(++$test)." # skip not enough random bytes\n";
    print "ok ".(++$test)." # skip not enough random bytes\n";
    $warning = '';
} else {
    %dist = (); $dist{$_}++ foreach (@data);
    print 'not ' if(grep { $_ < 1 || $_ > 6 } @data);
    print 'ok '.(++$test)." generates values from 1 to 6 in correct range\n";
    print 'not ' if(grep { $_ > 35 } values %dist);
    print 'ok '.(++$test)." distribution looks sane\n";
}

$r = Net::Random->new(min => 301, max => 306, src => 'random.org');
@data = $r->get(128);
if($warning) {
    print "ok ".(++$test)." # skip not enough random bytes\n";
    print "ok ".(++$test)." # skip not enough random bytes\n";
    $warning = '';
} else {
    %dist = (); $dist{$_}++ foreach (@data);
    print 'not ' if(grep { $_ < 301 || $_ > 306 } @data);
    print 'ok '.(++$test)." generates values from 301 to 306 in correct range\n";
    print 'not ' if(grep { $_ > 35 } values %dist);
    print 'ok '.(++$test)." distribution looks sane\n";
}

$r = Net::Random->new(max => 300, src => 'random.org');
@data = $r->get(1024);
if($warning) {
    print "ok ".(++$test)." # skip not enough random bytes\n";
    print "ok ".(++$test)." # skip not enough random bytes\n";
    $warning = '';
} else {
    %dist = (); $dist{$_}++ foreach (@data);
    print 'not ' if(grep { $_ < 0 || $_ > 300 } @data);
    print 'ok '.(++$test)." generates values from 0 to 300 in correct range\n";
    print 'not ' if(grep { $_ > 15 } values %dist);
    print 'ok '.(++$test)." distribution looks sane\n";
}

$r = Net::Random->new(max => 70000, src => 'random.org');
@data = $r->get(10240);
if($warning) {
    print "ok ".(++$test)." # skip not enough random bytes\n";
    print "ok ".(++$test)." # skip not enough random bytes\n";
    $warning = '';
} else {
    %dist = (); $dist{$_}++ foreach (@data);
    print 'not ' if(grep { $_ < 0 || $_ > 70000 } @data);
    print 'ok '.(++$test)." generates values from 0 to 70000 in correct range\n";
    print 'not ' if(grep { $_ > 6 } values %dist);
    print 'ok '.(++$test)." distribution looks sane\n";
}
$r = Net::Random->new(max => 2 ** 30, src => 'random.org');
@data = $r->get(1024);
if($warning) {
    print "ok ".(++$test)." # skip not enough random bytes\n";
    print "ok ".(++$test)." # skip not enough random bytes\n";
    $warning = '';
} else {
    %dist = (); $dist{$_}++ foreach (@data);
    print 'not ' if(grep { $_ < 0 || $_ > 2 ** 30 } @data);
    print 'ok '.(++$test)." generates values from 0 to 2^30 in correct range\n";
    print 'not ' if(grep { $_ > 2 } values %dist);
    print 'ok '.(++$test)." distribution looks sane\n";
}
