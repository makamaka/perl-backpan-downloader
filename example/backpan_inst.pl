#!/usr/bin/perl

use strict;
use warnings;
use strict;
use BACKPAN::Downloader;

@ARGV or die "Distribution name?";

my $backpan  = BACKPAN::Downloader->new( temp_dir => './tmp' );

for my $distname ( @ARGV ) {

    $backpan->reset;

    unless ( $backpan->lookup( $distname ) ) {
        printf( "%s was not found.\n", $distname );
        next;
    }

    printf( "Found %s in %s\n", $distname, $backpan->filedata->url );

    $backpan->download() or die sprintf("Can't download. (%s)", $backpan->error);
    $backpan->install( delete_saved_file => 1 )  or die "Can't install, " . $backpan->error;
}

