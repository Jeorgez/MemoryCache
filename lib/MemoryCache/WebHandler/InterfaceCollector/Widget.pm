package MemoryCache::WebHandler::InterfaceCollector::Widget;
{
    use strict;
    use MemoryCache::Tools qw/smart_new/;
    use Data::Dumper;
    
	sub new {
		my %args = smart_new( a => \@_, p => __PACKAGE__);
		my $classes = $args{classes} || [];
		my $self = {
			classes => $classes,
			on_click => $args{on_click}
		};
        my $self = {};
		bless $self, __PACKAGE__;
		return $self;
	}

	sub get_html {
		my $self = shift;
		my $html = shift;
		# Classes
		my $classes = "";
		foreach my $class (@{$self->{classes}}){
			$classes .= " ".$class;
		}
		# onClick event
		my $on_click = "";
		if($self->{on_click}){
			$on_click = ' onClick="'.$self->{on_click}.'"'
		} 
		# HTML
		return '<div'.$on_click.' class="widget'.$classes.'">'.$html.'</div>';
	}

	sub add_class_name {
		my $self = shift;
		push @{$self->{classes}}, @_;
	}

	sub onClick {
		my $self = shift;
		$self->{on_click} = shift;
	}
}
1;