# $Id: fake-tests.t,v 1.3 2007/03/16 15:34:35 drhyde Exp $
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
$rand = Net::Random->new(src => 'fourmilab.ch');
