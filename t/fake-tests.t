# $Id: fake-tests.t,v 1.4 2007/03/20 16:27:25 drhyde Exp $
use strict;

my $warning;
BEGIN {
    $^W=1;
    $SIG{__WARN__} = sub {
        $warning = join('', @_);
        die("Caught a warning, making it fatal:\n$warning\n")
            if($warning !~ /^Net::Random: /);
    };
}

use Test::More tests => 500;
use Test::MockObject;
use Data::Dumper;

my @statuses;
my @content;

my $lwp = Test::MockObject->new();
$lwp->fake_new('LWP::UserAgent');
$lwp->mock(get => sub { return HTTP::Response->new(); });
my $httpresponse = Test::MockObject->new();
$httpresponse->fake_new('HTTP::Response');
$httpresponse->mock(is_success => sub { return shift(@statuses); });
$httpresponse->mock(content    => sub { return shift(@content); });

use_ok('Net::Random');

my $rand = Net::Random->new(src => 'fourmilab.ch');

# Errors talking to fourmilab.ch
$warning = ''; @statuses = (0); @content = ();
$rand->get();
ok($warning =~ /^Net::Random: Error talking to fourmilab.ch/,
    "error talking to fourmilab.ch detected OK");

# Can talk to fourmilab, but we're bein' rationed
open(FILE, 't/fourmilab-outofdata') || die("Can't open t/fourmilab-outofdata\n");
$warning = ''; @statuses = (1); @content = (join('', <FILE>));
close(FILE);
$rand->get();
ok($warning =~ /Net::Random: fourmilab.ch/,
    "fourmilab.ch rationing detected OK");

$rand = Net::Random->new(src => 'random.org');

# Errors talking to random.org
$warning = ''; @statuses = (0); @content = ();
$rand->get();
ok($warning =~ /^Net::Random: Error talking to random.org/,
    "early error talking to random.org detected OK");
$warning = ''; @statuses = (1, 0); @content = ("25%\n");
$rand->get();
ok(!@statuses && $warning =~ /^Net::Random: Error talking to random.org/,
    "late error talking to random.org buffer detected OK");

# random.org buffer nearly empty
$warning = ''; @statuses = (1); @content = ("5%\n");
$rand->get();
ok($warning =~ /^Net::Random: random.org/,
    "random.org buffer nearly empty detected OK");

# shouldn't ever get any more warnings, so make 'em all fatal
$SIG{__WARN__} = sub {
    die("Caught a warning, making it fatal:\n", join('', @_));
};

# now grab some real data from random.org
open(FILE, 't/random.org-data') || die("Can't open t/random.org-data\n");
$warning = ''; @statuses = (1, 1); @content = ("50%\n", join('', <FILE>));
close(FILE);
is_deeply([$rand->get()], [0xe8], "we can get data from random.org");
is_deeply(
    [$rand->get(15)],
    [0x1a,0xd3,0xb7,0x01,0x85,0x5c,0x4d,0x19,0x24,0x54,0x15,0x91,0xa8,0x64,0x0d],
    "numbers between 0 and 255 are kosher"
);

# from now on we use fourmilab.ch
$rand = Net::Random->new(src => 'fourmilab.ch', min => 300, max => 555);
open(FILE, 't/fourmilab-data') || die("Can't open t/fourmilab-data\n");
$warning = ''; @statuses = (1); @content = (join('', <FILE>));
close(FILE);
is_deeply(
    [$rand->get(16)], # 16 bytes
    [map { 300 + hex } qw(37 53 04 13 AF 32 91 E4 CF D0 36 8E 6A C7 D0 19)],
    "complete one byte numbers (ie working on byte boundaries) with offset"
);

$rand = Net::Random->new(src => 'fourmilab.ch', max => 65535);
is_deeply(
    [$rand->get(5)], # 10 bytes
    [map { hex } qw(F6E5 6744 1117 ADDB 5531)],
    "complete two byte numbers without offset"
);

$rand = Net::Random->new(src => 'fourmilab.ch', min => 5, max => 65540);
is_deeply(
    [$rand->get(3)], # 6 bytes
    [map { 5 + hex } qw(6C95 4422 20D1)],
    "complete two byte numbers with offset"
);

$rand = Net::Random->new(src => 'fourmilab.ch', max => 16777215);
is_deeply(
    [$rand->get(4)], # 12 bytes
    [map { hex } qw(0A9E4A CFE035 6143F0 A8812F)],
    "complete three byte numbers without offset"
);

$rand = Net::Random->new(src => 'fourmilab.ch', min => -2, max => 16777213);
is_deeply(
    [$rand->get(4)], # 12 bytes
    [map { -2 + hex } qw(9B08CF 1434D4 DF9194 911823)],
    "complete three byte numbers with -ve offset"
);

$rand = Net::Random->new(src => 'fourmilab.ch', min => 0, max => 4294967295);
is_deeply(
    [$rand->get(1)], # 4 bytes
    [hex("F05E6AE3")],
    "complete four byte numbers without offset"
);

$rand = Net::Random->new(src => 'fourmilab.ch', min => -100, max => 4294967195);
is_deeply(
    [$rand->get(1)], # 4 bytes
    [hex("0984D65E") -100],
    "complete four byte numbers with offset"
);
