#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok "BACKPAN::Downloader";
    plan skip_all => "Cannot load BACKPAN::Downloader" if $@;
}

my $backpan = BACKPAN::Downloader->new;

SKIP: {
    skip "coludn't create BACKPAN::Downloader.", 3 unless $backpan;

    diag('Please wait a minuts');

    for my $dist ( qw( Acme::Tiny Acme-ManekiNeko-0.01 Acme::BabyEater ) ) {
        $backpan->reset;
        my $found = $backpan->lookup( $dist );
        ok( $found, $found->prefix );
    }

}

