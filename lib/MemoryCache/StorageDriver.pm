package MemoryCache::StorageDriver;
{
    use strict;
    use MemoryCache::StorageDriver::Static;
    use MemoryCache::StorageDriver::StorageMod;
    use MemoryCache::Tools qw/smart_new check_symbols cdie/;
    use Exporter qw/import/;
    use MemoryCache::StorageDriver::StorageMod::Memory;
    use MemoryCache::StorageDriver::StorageMod::SQLite;
    use Data::Dumper;
    
    my @_allowed_methods = (
        METHOD_GET,
        METHOD_SET,
        METHOD_DELETE,
        METHOD_LIST,
    );
    
    my $STORAGES_INIT = 0;
    my @STORAGES_LIST = (
        STORAGE_CLEAN,
        STORAGE_MEMORY,
        STORAGE_SQLITE,
    );
    my $STORAGES_INST = {};
    
    my $DATA = {};
    
    my $D_GET_ADDR = sub {
        my $self = shift;
        my $ref     = $self;
        my $pack    = __PACKAGE__;
        $ref        =~ s/$pack=HASH\((.+)\)/$1/;
        return $ref;
    };
    
    my $D = sub {
        my $self        = shift;
        my %args        = @_;
        my $ref         = $self->$D_GET_ADDR;
        $DATA->{$ref}   = {} unless exists $DATA->{$ref};
        if (%args) {
            foreach my $k (keys %args) {
                $DATA->{$ref}->{$k} = $args{$k};
            }
        }
        return $DATA->{$ref};
    };
    
    my $D_DELETE = sub {
        my $self = shift;
        my $ref         = $self->$D_GET_ADDR;
        delete $DATA->{$ref} if exists $DATA->{$ref};
    };
    
    my $p_storage = sub {
        my $self = shift;
        return $self->$D->{storage} || $self->$D->{default_storage};
    };
    
    my $p_table = sub {
        my $self = shift;
        return $self->$D->{table} || $self->$D->{default_table};
    };
    
    my $p_get_storage = sub {
        my $self = shift;
        return $STORAGES_INST->{$self->$p_storage};
    };
    
    my $INIT = sub {
        my $self            = shift;
        my %object_data = (
            default_storage => "memory",
            storage         => undef,
            default_table   => "default",
            table           => undef
        );
        
        $self->$D(%object_data);

        unless ($STORAGES_INIT) {
            while (my $storage = shift @STORAGES_LIST) {
                my $storage_instance;
                my $storage_package = $storage->{p};
                my $storage_name    = $storage->{name};
                my $mod_exists      = eval "require $storage_package;";
                if ($mod_exists) {
                    $storage_instance               = new $storage_package;
                    $STORAGES_INST->{$storage_name} = $storage_instance;
                    $storage_instance->run_handler();
                }
            }
            $STORAGES_INIT = 1;
        }
    };
    
    sub new {
        my %args = smart_new( a => \@_, p => __PACKAGE__);
        my $self = {};
        bless $self, __PACKAGE__;
        $self->$INIT();
        return $self;
    }
    
    sub DESTROY {
        my $self = shift;
        $self->$D_DELETE;
    }
    
    sub reset {
        my $self = shift;
        $self->$D->{storage} = undef;
        $self->$D->{table} = undef;
    }
    
    sub set_storage_name {
        my $self            = shift;
        my $storage_name    = shift;
        if ($STORAGES_INST->{$storage_name}) {
            $self->$D->{storage} = $storage_name;
            return $self;
        }
        return undef;
    }
    
    sub get_storage_name {
        my $self = shift;
        return $self->$p_storage;
    }
    
    sub set_def_storage_name {
        my $self            = shift;
        my $storage_name    = shift;
        if ($STORAGES_INST->{$storage_name}) {
            $self->$D->{default_storage} = $storage_name;
            return $self;
        }
        return undef;
    }
    
    sub set_table_name {
        my $self        = shift;
        my $table_name  = shift;
        if (check_symbols($table_name)){
            $self->$D->{table} = $table_name;
            return $self;
        }
        return undef;
    }
    
    sub get_table_name {
        my $self = shift;
        return $self->$p_table;
    }
    
    sub set_def_table_name {
        my $self        = shift;
        my $table_name  = shift;
        if (check_symbols($table_name)){
            $self->$D->{default_table} = $table_name;
            return $self;
        }
        return undef;
    }
    
    sub queue {
        my $self        = shift;
        my $method_name = shift;
        my $method 		= check_const_method_name($method_name) || cdie("Method \"$method_name\" isn't method of storage");
        my $method_args = shift;
        my $expires     = get_expires($method_args->{time});
        my $callback    = shift;
		check_method_args ($method, $method_args) || return undef;
        $self->$p_get_storage->add_task (
            method  => $self->$p_get_storage->can($method->{name}),
            method_args => {
                %$method_args,
                table       => $self->$p_table,
                storage     => $self->$p_storage,
                expires     => $expires
            },
            callback    => $callback
        );
		return 1;
    }
    
    sub open {
        my $self = shift;
        return $self->$p_get_storage;
    }
    
    sub get_available_storage_names {
        my @storages = grep { $_ ne STORAGE_CLEAN->{name}} keys %$STORAGES_INST;
        return @storages;
    }
    
    sub get_allowed_methods {
        return @_allowed_methods;
    }
    
    sub get_expires {
        my $seconds = shift || 3600;
        return time + $seconds;
    }
    
    sub check_method_args {
        my $method_name = shift;
    }
}
1;