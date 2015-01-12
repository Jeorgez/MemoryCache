package MemoryCache::StorageDriver::StorageMod::SQLite;

use strict;
use Coro;
use base "MemoryCache::StorageDriver::StorageMod";
use DBI;
use DBD::SQLite;

use Data::Dumper;

my $_dbh = DBI->connect("dbi:SQLite:dbname=MemoryCache.db","","");

my $_check_table_exists = sub {
    my $table_name = shift;
    my $query = $_dbh->prepare( "SELECT `name` FROM `sqlite_master` ".
                                "WHERE `type`='table' AND `name`='".$table_name."';");
    $query->execute();
    if ( $query->fetchrow_array()) {
        return 1;
    }
    return 0;
};

my $_get_or_create_table_id = sub {
    my $self        = shift;
    my $table_name  = shift;
    GET_ID:
    my $query = $_dbh->prepare( "SELECT `id` FROM `tables` ".
                                "WHERE `name`='".$table_name."';");
    $query->execute();
    if ( my ($id) = $query->fetchrow_array()) {
        return $id;
    }
    $_dbh->do(  "INSERT INTO `tables` (`name`) ".
                "VALUES ('".$table_name."');");
    goto GET_ID;
};

my $_get_total = sub {
    my $self        = shift;
    my $table_name  = shift;
    my $table_id    = $self->$_get_or_create_table_id($table_name);
    my $query       = $_dbh->prepare(   "SELECT COUNT(*) FROM `data` ".
                                        "WHERE `table_id` = ".$table_id.";");
    $query->execute();
    if ( my ($count) = $query->fetchrow_array()) {
        return $count;
    }
    return 0;
};

sub new {
    my $class   = shift;
    $class      = ref $class || $class;
    my $self    = $class->SUPER::new();
    bless $self, $class;
    &init();
    return $self;
}

sub init {
    $_dbh->do(  "CREATE TABLE `tables` ( ".
                "`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,".
                "`name` varchar(255) NOT NULL".
                ");") unless &$_check_table_exists("tables");
                
    $_dbh->do(  "CREATE TABLE `data` ( ".
                "`id` INTEGER PRIMARY KEY, ".
                "`table_id` INTEGER, ".
                "`var` TEXT, ".
                "`value` TEXT, ".
                "`expires` INTEGER".
                ");") unless &$_check_table_exists("data");
}

sub set {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $var         = $args{var};
    my $value       = $args{value};
    my $expires     = $args{expires};
    my $table_id    = $self->$_get_or_create_table_id($table_name);
    $_dbh->begin_work;
    $_dbh->do(  "INSERT OR REPLACE INTO `data` (".
                "`id`, `table_id`, `var`, `value`, `expires`) VALUES (".
                "( SELECT `id` FROM `data` WHERE `var` = '".$var."'), ".
                $table_id.", ".
                "'".$var."', ".
                "'".$value."', ".
                $expires.
                ");");
    $_dbh->commit;
    return {
        total       => $self->$_get_total($table_name),
        expires     => scalar $expires
    };
}

sub get {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $var         = $args{var};
    my $query       = $_dbh->prepare(   "SELECT `var`, `value`, `expires` FROM `data` ".
                                        "WHERE ".
                                        "`table_id` = (SELECT `id` FROM `tables` WHERE `name`='".$table_name."') AND ".
                                        "`var` = '".$var."';");
    $query->execute();
    my $array = $_dbh->selectall_arrayref($query, { Slice => {} });
    print Dumper($array);
    if (@$array) {
        return $array->[0];
    }
    return undef;
}

sub delete {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $var         = $args{var};
    $_dbh->begin_work;
    $_dbh->do(  "DELETE FROM `data` ".
                "WHERE ".
                "`table_id` = (SELECT `id` FROM `tables` WHERE `name`='".$table_name."') AND ".
                "`var` = '".$var."';");
    $_dbh->commit;
    return $self->$_get_total($table_name);
}

sub list {
    my $self        = shift;
    my %args        = @_;
    my $table_name  = $args{table};
    my $query       = $_dbh->prepare(   "SELECT `var`, `value`, `expires` FROM `data` ".
                                        "WHERE ".
                                        "`table_id` = (SELECT `id` FROM `tables` WHERE `name`='".$table_name."');");
    $query->execute();
    my $array = $_dbh->selectall_arrayref($query, { Slice => {} });
    return @$array;
}

1;