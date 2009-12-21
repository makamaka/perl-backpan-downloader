#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok "BackPAN::Downloader";
    plan skip_all => "Cannot load BackPAN::Downloader" if $@;
}
