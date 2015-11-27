use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'mbserverd',
    VERSION_FROM      => 'scripts/mbserverd', # finds $VERSION
    EXE_FILES         => [qw(scripts/mbserverd)],
    LICENSE           => 'MIT',
    MIN_PERL_VERSION  => '5.006_001',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/sourceperl/mbserverd.git',
                web  => 'https://github.com/sourceperl/mbserverd',
            },
        },
    },
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Lefebvre Loic <lle@cpan.org>') : ()),
);

