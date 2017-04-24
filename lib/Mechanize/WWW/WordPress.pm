use strict;
use warnings;

use WWW::Mechanize::FormFiller;

package Mechanize::WWW::WordPress;

use base qw(WWW::Mechanize::Shell);

=head1 NAME

Mechanize::WWW::WordPress - programmatically fill out wordpress admin forms

=head1 SYNOPSIS

    my $wp = Mechanize::WWW::Wordpress->new(
      domain => 'me.wordpress.com',
    #  path   => '/wp-admin/',
    #  ssl    => 1,
      login  => {
        log => 'me',
        pwd => 'pwd',
      },
      tasks => [{
        name   => 'Reading Settings | Front page displays | Front Page | Home',
        get    => 'options-reading.php',
    #    click  => 'submit',
        values => {
          show_on_front => 'page',
          page_on_front => 'Home',
        },
      }],
    );
    
    $wp->run

=cut

=head1 DESCRIPTION

This libarary is a L<WWW::Mechanize::Shell> subclass allows you to manipulate
the WordPress wp-admin section programmatically.

Other WordPress API clients are more ad-hoc API tools. This utility is eaiser to
use for people who want to write their automation in terms of the WordPress
wp-admin UI.

=head1 METHODS

=head2 new

=cut

sub new {
  my $class = shift; my %args = @_;
  my $self = $class->SUPER::new( 'shell' );

  my $wordpress_config = $self->{wordpress} = \%args;

  my $formfiller = WWW::Mechanize::FormFiller->new();
  $self->{wordpress}{formfiller} ||= $formfiller;

  my $url = 'http' . ($wordpress_config->{ssl} ? 's' : '');
  $url   .= '://' .
    $wordpress_config->{domain} .
    ( $wordpress_config->{path} or '/wp-admin/' )
  ;
  $wordpress_config->{url} = $url;

  return $self;
}

=head2 new

=cut

sub wp_run {
  my $self = shift;
  $self->wp_login;
  $self->wp_run_tasks;
}

=head2 new

=cut

sub wp_login {
  my $self = shift;

  my $wp = $self->{wordpress};

  $self->wp_run_task({
    name    => 'Log In',

    actions => [{
      action => 'get',
      args   => $wp->{url}
    }, {
      action => 'values',
      args   => {
        log => $wp->{login}{log},
        pwd => $wp->{login}{pwd},
      },
    }, {
      action => 'click',
      args   => 'wp-submit'
    }]
  });
}

=head2 new

=cut

sub wp_run_tasks {
  my $self = shift;

  my $tasks = $self->{wordpress}{tasks};

  foreach my $task ( @$tasks ) {
    $self->wp_run_task( $task );
  }
}

=head2 new

=cut

sub wp_run_task {
  my( $self, $task ) = @_;

  print '-> ' . $task->{name} . "\n";

  my $actions     = $task->{actions} || [];

  foreach my $action ( @$actions ) {
    $self->wp_run_action( $task, $action );
  }

  print '<- ' . $task->{name} . "\n\n";
}

=head2 wp_run_action

=cut

sub wp_run_action {
  my( $self, $task, $action ) = @_;
  my $action_method = $action->{action};
  my $method        = "wp_$action_method";
  $self->$method( $task, $action->{args} );
}

=head2 wp_unknown

=cut

sub wp_unknown {
  my( $self, $task ) = @_;

}

=head2 wp_get

=cut

sub wp_get {
  my( $self, $task, $url ) = @_;
  $self->run_get( $url );
}

=head2 wp_dump

=cut

# quiets 'wide character in print' warnings from run_dump
binmode STDERR, ":encoding(utf8)";

sub wp_dump {
  my( $self, $task ) = @_;
  $self->run_dump;
}

=head2 wp_click

=cut

sub wp_click {
  my( $self, $task, $button ) = @_;
  print 'Posting ' . $self->agent->current_form->action;
  $self->run_click( $button or 'submit' );
}

=head2 wp_values

=cut

sub wp_values {
  my( $self, $task, $values ) = @_;
  $self->wp_run_values( $task, $values );
}

=head2 wp_run_values

=cut

sub wp_run_values {
  my( $self, $task, $values ) = @_;

  $values ||= {};
  while( my( $field, $value ) = each %$values ) {
    $self->run_value( $field => $value );
  }
}

=back

=head1 AUTHOR

trwww

=head1 COPYRIGHT

Copyright (c) 2017, trwww.  All rights reserved.  This module is distributed
under the same terms as Perl itself, in the hope that it is useful but certainly
under no guarantee.

=cut

1;
