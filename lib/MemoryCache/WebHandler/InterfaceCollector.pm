package MemoryCache::WebHandler::InterfaceCollector;

use strict;
use MemoryCache::Tools qw/smart_new/;


sub new {
    my %args = smart_new( a => \@_, p => __PACKAGE__);
    my $self = {
        popup_windows   => [],
        menu_items      => [],
        body_content    => []
    };
    bless $self, __PACKAGE__;
    return $self;
}

sub add_popup_window {
    my $self = shift;
    my %args = @_;
    my $html = $args{html};
    my $widget = $args{widget_to_open};
    my $sysId = $self->gen_rand_id();

    $widget->onClick("show_popup('".$sysId."')");

    my $pw_html = '<div class="popup_window_substrate" id="'.$sysId.'">'.
                '<div class="popup_window_body">'.$html.'</div>'.
                '</div>';
    my $pw = {
        sysId => $sysId,
        pw_html => $pw_html
    };
    
    push @{$self->{popup_windows}}, $pw;
}

sub add_menu_item {
    my $self = shift;
    my $menu_item = shift;
    if (ref $menu_item eq "MemoryCache::WebHandler::InterfaceCollector::Widget::MenuItem"){
        push @{$self->{menu_items}}, $menu_item;
    }
}

sub add_body_content {
    my $self = shift;
    push @{$self->{body_content}}, shift;
}

sub gen_rand_id {
    my @chars = ("A".."Z", "a".."z");
    my $id;
    $id .= $chars[rand @chars] for 1..10;
    return $id;
}

sub get_html {

}

1;