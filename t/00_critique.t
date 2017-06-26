#!/usr/bin/perl -w

use strict;
use warnings 'all';

use English qw(-no_match_vars);
#use File::Spec;
use Test::More;

# Initialize the test counter
my $tests = 0;

# Make sure the source code is clean and sane (as sane can be)
# Note: Attempts to use $ROOTDIR failed so this test must be
#       called from the build root or via ./Build test.
eval { require Test::Perl::Critic; };
if ( $EVAL_ERROR ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}
Test::Perl::Critic->import( -profile => 't/perlcriticrc' );

my @FILES = qw(
    sbin/ssh-sc-auth
);

for my $FILE ( @FILES ) {
    critic_ok( $FILE, "critique of $FILE" );
    $tests++;
}

done_testing( $tests );
