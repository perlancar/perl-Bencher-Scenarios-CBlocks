package Bencher::Scenario::CBlocks::Numeric;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark numeric performance of C::Blocks',
    description => <<'_',

Each code generates random number (the `perl` participant using pure-perl code.

_
    precision => 6,
    participants => [
        {
            name => 'perl',
            code_template => <<'_',
my $a = 698769069;
my ($x, $y, $z, $c) = (123456789, 362436000, 521288629, 7654321);
my $rand;
for (1 .. <N>) {
    my $t;
    $x = 69069*$x+12345;
    $y ^= ($y<<13); $y ^= ($y>>17); $y ^= ($y<<5);
    $t = $a*$z+$c; $c = ($t>>32);
    $z = $t;
    $rand = $x+$y+$z;
}
return $rand;
_
        },
        {
            name => 'C::Blocks',
            module => 'C::Blocks',
            code_template => <<'_',
use C::Blocks;
use C::Blocks::Types qw(uint);
clex {
    /* Note: y must never be set to zero;
     * z and c must not be simultaneously zero */
    unsigned int x = 123456789,y = 362436000,
        z = 521288629,c = 7654321; /* State variables */

    unsigned int KISS() {
        unsigned long long t, a = 698769069ULL;
        x = 69069*x+12345;
        y ^= (y<<13); y ^= (y>>17); y ^= (y<<5);
        t = a*z+c; c = (t>>32);
        return x+y+(z=t);
    }
}

my uint $to_return = 0;
cblock {
    for (int i = 0; i < <N>; i++) $to_return = KISS();
}
return $to_return;

_
        },
    ],

    datasets => [
        {args=>{N=>int(10**1)}},
        {args=>{N=>int(10**1.5)}},
        {args=>{N=>int(10**2)}},
        {args=>{N=>int(10**2.5)}},
        {args=>{N=>int(10**3)}},
        {args=>{N=>int(10**3.51)}},
        {args=>{N=>int(10**4)}},
        {args=>{N=>int(10**4.5)}},
        {args=>{N=>int(10**5)}},
        {args=>{N=>int(10**5.5)}},
    ],
};

1;
# ABSTRACT:

=head1 SEE ALSO
