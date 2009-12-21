use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'BackPAN::Downloader',
    'VERSION_FROM'	=> 'lib/BackPAN/Downloader.pm', # finds $VERSION
    'PREREQ_PM' => {
        'Test::More'                => 0,
        'Mouse'                     => 0,
        'Parse::BACKPAN::Packages'  => 0.36,
        'CPAN::Inject'              => 0.11,
        'LWP::UserAgent'            => 0,
        'CPAN::Shell'               => 1.93,
        'Path::Class'               => 0,
        'Try::Tiny'                 => 0.02,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/BackPAN/Downloader.pm', # retrieve abstract from module
       AUTHOR     => 'Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>') : ()),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : () ),
);
