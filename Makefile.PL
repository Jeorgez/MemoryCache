use ExtUtils::MakeMaker;

my %dependencies = (
    "DBD::SQLite"       => "1.46",
    "AnyEvent::HTTPD"   => "0.93",
    "AnyEvent::Tools"   => "0.12",
    "Coro"              => "6.41",
    "MIME::Types"       => "2.09",
    
);


# use lib 'inc';
# use ExtUtils::AutoInstall (
    # -core           => [
        # %dependencies
    # ],
# );

WriteMakefile (
    AUTHOR          => "Yurii Voronenko, gsr-vyi@yandex.ru",
    NAME            => "MemoryCache",
    VERSION         => 0.01,
    PREREQ_PM       => {
        %dependencies
    },
    PREREQ_PRINT    => 1,
    NO_META         => 1,
    EXE_FILES       => [],
);


