package Net::Random;

use strict;
local $^W = 1;
use vars qw($VERSION);

$VERSION = '1.4';

require LWP::UserAgent;
use Sys::Hostname;

my $ua = LWP::UserAgent->new(
    agent   => 'perl-Net-Random/'.$VERSION,
    from    => "userid_$<\@".hostname(),
    timeout => 120,
    keep_alive => 1,
    env_proxy => 1
);

my %randomness = (
    'fourmilab.ch' => { pool => [], retrieve => sub {
        my $response = $ua->get(
	    'http://www.fourmilab.ch/cgi-bin/uncgi/Hotbits?nbytes=1024&fmt=hex'
	);
	unless($response->is_success) {
	    warn "Net::Random: Error talking to fourmilab.ch\n";
            return ();
	}
        my $content = $response->content();
        if($content =~ /Error Generating HotBits/) {
            warn("Net::Random: fourmilab.ch ran out of randomness for us\n");
            return ();
        }
	map { map { hex } /(..)/g } grep { /^[0-9A-F]+$/ } split(/\s+/, $content);
    } },
    'random.org'   => { pool => [], retrieve => sub {
        my $response = $ua->get('http://www.random.org/cgi-bin/checkbuf');
	if(!$response->is_success) {
	    warn "Net::Random: Error talking to random.org\n";
            return ();
	} else {
	    $response->content() =~ /^(\d+)/;
	    if($1 < 20) {
	        warn "Net::Random: random.org buffer nearly empty\n";
	        return ();
            }
	}
        $response = $ua->get(
	    'http://random.org/cgi-bin/randbyte?nbytes=1024&format=hex'
	);
	unless($response->is_success) {
	    warn "Net::Random: Error talking to random.org\n";
            return ();
	}
	map { hex } split(/\s+/, $response->content());
    } }
);

# recharges the randomness pool
sub _recharge {
    my $self = shift;
    $randomness{$self->{src}}->{pool} = [
        @{$randomness{$self->{src}}->{pool}},
        &{$randomness{$self->{src}}->{retrieve}}
    ];
}

=head1 NAME

Net::Random - get random data from online sources

=head1 SYNOPSIS

    my $rand = Net::Random->new( # use fourmilab.ch's randomness source,
        src => 'fourmilab.ch',   # and return results from 1 to 2000
	min => 1,
	max => 2000
    );
    @numbers = $rand->get(5);    # get 5 numbers
    
    my $rand = Net::Random->new( # use random.org's randomness source,
        src => 'random.org',     # with no explicit range - so values will
    );                           # be in the default range from 0 to 255

    $number = $rand->get();      # get 1 random number

=head1 OVERVIEW

The two sources of randomness above correspond to
L<http://www.fourmilab.ch/cgi-bin/uncgi/Hotbits?nbytes=1024&fmt=hex> and
L<http://random.org/cgi-bin/randbyte?nbytes=1024&format=hex>.  We always
get chunks of 1024 bytes at a time, storing it in a pool which is used up
as and when needed.  The pool is shared between all objects using the
same randomness source.  When we run out of randomness we go back to the
source for more juicy random goodness.

If you have set a http_proxy variable in your environment, this will be
honoured.

While we always fetch 1024 bytes, data can be used up one, two, three or
four bytes at a time, depending on the range between the minimum and
maximum desired values.  There may be a noticeable delay while more
random data is fetched.

The maintainers of both randomness sources claim that their data is
*truly* random.  A some simple tests show that they are certainly more
random than the C<rand()> function on this 'ere machine.

=head1 METHODS

=over 4

=item new

The constructor returns a Net::Random object.  It takes named parameters,
of which one - 'src' - is compulsory, telling the module where to get its
random data from.  The 'min' and 'max' parameters are optional, and default
to 0 and 255 respectively.  Both must be integers, and 'max' must be at
least min+1.  The minimum value of 'min' is 0.  The maximum value of 'max'
is 2^32-1, the largest value that can be stored in a 32-bit int, or
0xFFFFFFFF.

Currently, the only valid values of 'src' are 'fourmilab.ch' and
'random.org'.

=cut

sub new {
    my($class, %params) = @_;

    exists($params{min}) or $params{min} = 0;
    exists($params{max}) or $params{max} = 255;

    die("Bad parameters to Net::Random->new()") if(
        (grep {
            $_ !~ /^(src|min|max)$/
        } keys %params) ||
	!exists($params{src}) ||
	$params{src} !~ /^(fourmilab\.ch|random\.org)$/ ||
	$params{min} =~ /\D/ ||
	$params{max} =~ /\D/ ||
	$params{min} < 0 ||
	$params{max} > 2 ** 32 - 1 ||
	$params{min} >= $params{max}
    );

    bless({ %params }, $class);
}

=item get

Takes a single optional parameter, which must be a positive integer.
This determines how many random numbers are to be returned and, if not
specified, defaults to 1.

If it fails to retrieve data, we return undef.  Note that fourmilab.ch
rations random data and you are only permitted to retrieve a certain
amount of randomness in any 24 hour period, and random.org asks software
authors to not empty their randomness pool entirely.  In both these cases
we spit out a warning.  See the section on ERROR
HANDLING below.

=cut

sub get {
    my($self, $results) = @_;
    defined($results) or $results = 1;
    die("Bad parameter to Net::Random->get()") if($results =~ /\D/);

    my $bytes = 5; # MAXBYTES + 1
    foreach my $bits (32, 24, 16, 8) {
        $bytes-- if($self->{max} - $self->{min} < 2 ** $bits);
    }
    die("Out of cucumber error") if($bytes == 5);

    my @results = ();
    while(@results < $results) {
        $self->_recharge() if(@{$randomness{$self->{src}}->{pool}} < $bytes);
	return undef if(@{$randomness{$self->{src}}->{pool}} < $bytes);

	my $random_number = 0;
	$random_number = ($random_number << 8) + $_ foreach (splice(
	    @{$randomness{$self->{src}}->{pool}}, 0, $bytes
	));
	
	my $range = $self->{max} + 1 - $self->{min};
	my $max_multiple = $range * int((2 ** (8 * $bytes)) / $range);
	push @results, $self->{min} + ($random_number % $range)
	    unless($random_number > $max_multiple);
    }
    @results;
}

=back

=head1 BUGS

Doesn't handle really BIGNUMs.  Patches are welcome to make it use
Math::BigInt internally.  Note that you'll need to calculate how many
random bytes to use per result.  I strongly suggest only using BigInts
when absolutely necessary, because they are slooooooow.

Tests are a bit lame.  Really needs to test the results to make sure
they're as random as the input (to make sure I haven't introduced any bias) and
in the right range.  The current tests for whether the distributions
look sane suck donkey dick.

=head1 SECURITY CONCERNS

True randomness is very useful for cryptographic applications.  Unfortunately,
I can not recommend using this module to produce such random data.  While
some simple testing shows that we can be fairly confident that it is random,
and the published methodologies on both sites used looks sane, you can not,
unfortunately, trust that you are getting unique data (ie, someone else might
get the same bytes as you) or that they don't log who gets what data.

Be aware that if you use an http_proxy - or if your upstream uses a transparent
proxy like some of the more shoddy consumer ISPs do - then that is another place
that your randomness could be compromised.

I should stress that I *do* trust both site maintainers to give me data that
is sufficiently random and unique for my own uses, but I can not recommend
that you do too.  As in any security situation, you need to perform your own
risk analysis.

=head1 ERROR HANDLING

There are two types of error that this module can emit which aren't your
fault.  Those are network
errors, in which case it emits a warning:

    Net::Random: Error talking to [your source]

and errors generated by the randomness sources, which look like:

    Net::Random: [your source] [message]

Once you hit either of these errors, it means that either you have run
out of randomness and can't get any more, or you are very close to
running out of randomness.  Because this module's raison d'&ecirc;tre
is to provide a source of truly random data when you don't have your
own one available, it does not provide any pseudo-random fallback.

If you want to implement your own fallback, you can catch those warnings
by using C<$SIG{__WARN__}>.  See C<perldoc perlvar> for details.

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

I do *not* welcome automated bug reports from people who haven't read
the README.  Yes, CPAN-testers, that means you.

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Thanks are also due to the maintainers of the randomness sources.  See
their web sites for details on how to praise them.

Suggestions from the following people have been included:
  Rich Rauenzahn, for using an http_proxy;
  Wiggins d Anconia suggested I mutter in the docs about security concerns

=head1 COPYRIGHT

Copyright 2003 - 2007 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=cut

1;
