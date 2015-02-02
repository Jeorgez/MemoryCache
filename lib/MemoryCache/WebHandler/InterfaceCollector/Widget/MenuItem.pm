package MemoryCache::WebHandler::InterfaceCollector::Widget::MenuItem;
{
	use base "MemoryCache::WebProcessor::InterfaceCollector::Widget";
    use MemoryCache::HTMLContentCollector::Widget;
    use strict;
    use MemoryCache::Tools qw/smart_new/;
    use Data::Dumper;
    
    #our @ISA = ("MemoryCache::HTMLContentCollector::Widget");
    
	sub new {
        my %args = smart_new( a => \@_, p => __PACKAGE__);
        my $self = __PACKAGE__->SUPER::new(%args);
		$self->{text} = $args{text} || "undefined";
		bless $self, __PACKAGE__;
		return $self;
	}

	sub set_link {
		my $self = shift;
		my $link = shift;
		$self->{link} = $link;
	}

	sub get_html {
		my $self = shift;
		my $link = $self->{link} || "javascript:;";
		my $html = '<a href="'.$link.'">'.$self->{text}.'</a>';
		return $self->SUPER->get_html($html);
	}
}
1;