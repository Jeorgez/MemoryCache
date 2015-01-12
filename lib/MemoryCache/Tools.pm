package MemoryCache::Tools;

    use strict;
    use Exporter qw/import/;
    use Data::Dumper;

    our @EXPORT_OK  = qw/smart_new check_symbols cdie error gen_random_string/;
    
    sub smart_new {
        my %args    = @_;
        my $c_args  = $args{a};
        my $package = $args{p};
        if (@$c_args) {
            my $c = $c_args->[0];
            my $found = 0;
            goto FOUND if ($c eq $package) and ($found = 1);
            my $c_ref = ref $c;
            goto FOUND if ($c_ref eq $package) and ($found = 1);
            my $isa;
            {
                no strict 'refs';
                if(($isa = \@{$c."::ISA"}) || ($isa = \@{$c_ref."::ISA"}) ) {
                    foreach my $parent (@$isa){
                        goto FOUND if ($parent eq $package) and ($found = 1);
                    }
                }
            }
            FOUND:
            if ($found) {
                shift @$c_args;
            }
        }
        return @$c_args;
    }
    
    sub gen_random_string {
        my $size    = shift || 10;
        my @chars   = ("A".."Z", "a".."z", 0..9);
        my $id;
        $id .= $chars[rand @chars] for 1..$size;
        return $id;
    }
    
    sub check_symbols {
        my $exp = shift;
        return 1 if($exp =~ /[a-zA-Z\-\_\.]/);
        undef;
    }
    
    sub cdie {
        my $msg         = shift;
        my $c_package   = (caller(1))[0];
        my $c_line      = (caller(1))[2];
        my $c_sub       = (caller(1))[3];
        my $stack_trace;
        my $i = 2;
        while ($i < 7) {
            my $stack_package   = (caller($i))[0];
            my $stack_line      = (caller($i))[2];
            my $stack_sub       = (caller($i))[3];
            $stack_trace        .= $stack_package. " [ ".$stack_sub." ] ( line: ".$stack_line." )\n";
            $i ++;
        }
        die "FATAL ERROR : ".$c_package." [ ".$c_sub." ] ( line: ".$c_line." ) : ".$msg."\n".$stack_trace."\n";
    }
    
    sub error {
        my $msg         = shift;
        my $c_package   = (caller(1))[0];
        my $c_line      = (caller(1))[2];
        my $c_sub       = (caller(1))[3];
        my @c_args      = (caller(1))[4];
        print STDERR "ERROR: in package ".$c_package." sub ".$c_sub." line ".$c_line.":\nMESSAGE: ".$msg."\n\n";
    }
    
1;