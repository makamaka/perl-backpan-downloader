package BackPAN::Downloader;

use Mouse;
use Parse::BACKPAN::Packages;
use CPAN::Inject;
use LWP::UserAgent;
use CPAN::Debug;
use CPAN::Shell;
use Path::Class;
use Try::Tiny;
use Cwd;

our $VERSION = '0.01';

has distfile => ( is => 'rw', isa => 'Parse::BACKPAN::Packages::Distribution|Undef' );

has filedata => ( is => 'rw', isa => 'Parse::BACKPAN::Packages::File|Undef' );

has dist_is_found => ( is => 'rw', isa => 'Bool' );

has temp_dir => ( is => 'rw', isa => 'Str', default => './' );

has ua => ( is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new } );

has error => ( is => 'rw', isa => 'Str|Undef' );

no Mouse;


sub reset {
    my ( $self ) = @_;
    $self->dist_is_found( 0 );
    $self->distfile( undef );
    $self->filedata( undef );
    $self->error( undef );
}


sub lookup {
    my ( $self, $distname ) = @_;
    my $check_version;

    $self->reset;

    if ( $distname =~ /^(.+?)-([_.\d]+)$/ ) { # バージョン指定なので正式名称
        $check_version = $2;
        $distname = $1;
    }
    else {
        $distname =~ s/::/-/g; # Foo-BarだけでなくFoo::Barでも検索できるように
    }

    my $p = Parse::BACKPAN::Packages->new();

    # リストは日付の古い順
    my @dists = $p->distributions( $distname );
    my $found;

    if ( defined $check_version ) {
        for my $dist ( @dists ) {
            if ( $dist->version == $check_version ) {
                $found = $dist;
                last;
            }
        }
    }
    else {
        $found = $dists[ -1 ] if ( @dists );
    }

    if ( $found ) {
        $self->distfile( $found );
        $self->filedata( $p->file( $found->prefix ) );
        $self->dist_is_found( 1 );
    }
    else {
        $self->error( "Can't find $distname." );
    }

    return $found;
}


sub download {
    my ( $self ) = @_;

    unless ( $self->dist_is_found ) {
        $self->error('donwload() must be called after the dist file was found.');
        return;
    }

    my $url  = $self->filedata->url;
    my $file = Path::Class::File->new( $self->temp_dir, $self->distfile->filename );

    return 1 if ( -s $file );

    my $ua   = $self->ua;
    my $res  = $ua->get( $url );

    if ( $res->is_success ) {
        my $fh = $file->openw();
        unless ( $fh ) {
            $self->error( "Can't open file." );
            return;
        }
        print $fh $res->content;
    }
    else {
        $self->error( "Can't download, status line is " . $res->status_line );
        return;
    }
}


sub install {
    my ( $self, %opts ) = @_;

    unless ( $self->dist_is_found ) {
        $self->error('donwload() must be called after the dist file was found.');
        return;
    }

    my $distfile = $self->distfile;
    my $cpan_inject = CPAN::Inject->from_cpan_config( author => $distfile->cpanid );

    my $installed;
    my $file = Path::Class::File->new( $self->temp_dir, $distfile->filename );
    my $cwd  = getcwd;

    try {
        my $inst_path = $cpan_inject->add( file => $file );
        CPAN::Shell->install( $inst_path );
        $installed = 1;
    } catch {
        $self->error( @_ );
    };

    chdir( $cwd );

    if ( $installed and $opts{ delete_saved_file } ) {
        unlink($file) or Carp::carp("Can't delete saved file $file. $!");
    }

    return $installed;
}


1;
__END__

=pod

=head1 NAME

BackPAN::Downloader - an installer of BackPAN modules

=head1 SYNOPSYS

    use strict;
    use BackPAN::Downloader;
    
    my $backpan  = BackPAN::Downloader->new( temp_dir => './tmp' );
    my $distname = 'NOT::IN::CPAN::MODULE';
    
    $backpan->lookup( $distname ) or die $backpan->error;
    $backpan->download() or die sprintf("Can't download. (%s)", $backpan->error);
    $backpan->install()  or die "Can't install, " . $backpan->error;

=head1 DESCRIPTION

This is a BackPAN module installer.

=head1 METHODS

=head2 new

    $backpan = BackPAN::Downloader->new;

Creates a new object.
It can take an named option:

=over

=item temp_dir

A directory for saving downloaded file.

=back

=head2 lookup

    $backpan->lookup( $distribution );

Check a distribution. If the distribution is found, returns L<Parse::BACKPAN::Packages::Distribution>.
Otherwise C<undef>.

The found L<Parse::BACKPAN::Packages::Distribution> and L<Parse::BACKPAN::Packages::File> object
are set into C<distfile> and C<filedata>.

=head2 download

Downloads the lookuped distribution file.

=head2 install

    $backpan->install();

Installs the downloaded distribution file.
If set C<delete_saved_file> option, it will delete the downloaded file after install.

    $backpan->install( delete_saved_file => 1 );

This method returns false if an explicit error is raised.
But a return of a true vaule does not mean that the installation was sucessful.

=head2 reset

Resets a found distribution data.

=head2 temp_dir

    $backpan->temp_dir( $dir );
    $dir = $backpan->temp_dir();

A directory for saving downloaded file.

=head2 dist_is_found

    $bool = $backpan->dist_is_found;

Returns the result of C<lookup> method.

=head2 ua

Returns a L<LWP::UserAgent> object getting C<backpan.txt.gz>.

=head2 error

Returns an error message.

=head2 distfile

Returns a found L<Parse::BACKPAN::Packages::Distribution>.

=head2 filedata

Returns a found L<Parse::BACKPAN::Packages::File>.

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<Parse::BACKPAN::Packages>,
L<CPAN::Inject>,
L<CPAN::Shell>,
L<LWP::UserAgent>

=cut

