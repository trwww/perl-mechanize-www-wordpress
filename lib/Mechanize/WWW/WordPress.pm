use strict;
use warnings;

package Mechanize::WWW::WordPress;

use base qw(WWW::Mechanize::Shell);

=head1 NAME

Mechanize::WWW::WordPress - programmatically fill out wordpress admin forms

=head1 SYNOPSIS

    my $wp = Mechanize::WWW::WordPress->new(
      domain => 'me.wordpress.com',
    #  path   => '/wp-admin/',
    #  ssl    => 0,
      login  => {
        log => 'me',
        pwd => 'pwd',
      },
      tasks => [{
        name    => 'Reading Settings | Front page displays | Front Page | Home',
        actions => [
          {
            action => 'get',
            args   => 'options-reading.php',
          }, {
            action => 'show_form',
          }, {
            action => 'values',
            args   => {
              show_on_front => 'page',
              page_on_front => 'Home',
            },
          }, {
            action => 'show_form',
          }, {
            action => 'click',
    #        args   => 'submit'
          }
        ]
      }],
    );

or

    my $wp = Mechanize::WWW::WordPress->new(
      domain => 'me.wordpress.com',
    #  path   => '/wp-admin/',
    #  ssl    => 0,
      login  => {
        log => 'me',
        pwd => 'pwd',
      },
      tasks => [{
        name => 'Reading Settings | Front page displays | Front Page | Home',
      }],
    );

then:
    
    $wp->run

=cut

=head1 DESCRIPTION

This libarary is a L<WWW::Mechanize::Shell> subclass allows you to manipulate
the WordPress wp-admin section programmatically.

Other WordPress API clients are more ad-hoc API tools. This utility is eaiser to
use for people who want to write their automation in terms of the WordPress
wp-admin UI.

Each task is a hash with two fields: name and actions. Actions are steps taken
in the UI. In general the pattern is to use the 'get' action to get a WordPress
admin page, the 'values' action to set field's on the page's HTML form, and
the 'click' action to submit the form. The 'show_form' action will dump the
current form's fields and values to the terminal.

ALPHA WARNING: very new, missing lots of stuff

=head1 TASKS and ACTIONS

The task in the SYNOPSIS sets some values in the Settings -> Reading screen
of the WordPress UI. When ran, the output of the program will look like this:

    -> Log In
    Retrieving http://me.wordpress.com/wp-admin/(200)
    Posting http://me.wordpress.com/wp-login.php(200)
    <- Log In
    
    -> Reading Settings | Front page displays | Front Page | Home
    Retrieving options-reading.php(200)
    VALUES: page_on_front => Home
    VALUES: show_on_front => page
    Posting http://me.wordpress.com/wp-admin/options.php(200)
    <- Reading Settings | Front page displays | Front Page | Home

After running the code look in the WordPress UI for the expected values.

=head1 VARIABLES

=head2 %prebuilt_actions

=cut

our %prebuilt_actions;

=over4

=item Reading Settings | Front page displays | Front Page | Home

=cut

$prebuilt_actions{'Reading Settings | Front page displays | Front Page | Home'} = [
  {
    action => 'get',
    args   => 'options-reading.php',
  }, {
    action => 'values',
     args   => {
      show_on_front => 'page',
      page_on_front => 'Home',
    },
  }, {
    action => 'click',
  }
];

=back

=head1 METHODS

=head2 new

=cut

sub new {
  my $class = shift; my %args = @_;
  my $self = $class->SUPER::new( 'shell' );

  my $wordpress_config = $self->{wordpress} = \%args;

  my $url = 'http' . ($wordpress_config->{ssl} ? 's' : '');
  $url   .= '://' .
    $wordpress_config->{domain} .
    ( $wordpress_config->{path} or '/wp-admin/' )
  ;
  $wordpress_config->{url} = $url;

  return $self;
}

=head2 wp_run

=cut

sub wp_run {
  my $self = shift;
  $self->wp_login;
  $self->wp_run_tasks;
}

=head2 wp_login

=cut

sub wp_login {
  my $self = shift;

  my $wp = $self->{wordpress};

  # log in via a task
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

=head2 wp_run_tasks

=cut

sub wp_run_tasks {
  my $self = shift;

  my $tasks = $self->{wordpress}{tasks};

  foreach my $task ( @$tasks ) {
    $self->wp_run_task( $task );
  }
}

=head2 wp_run_task

=cut

sub wp_run_task {
  my( $self, $task ) = @_;
  print '-> ' . $task->{name} . "\n";

  # make a shallow copy of the actions so we don't overwrite prebuit tasks when using splice
  my @actions = @{ $task->{actions} || $prebuilt_actions{ $task->{name} } || [] };

  # insert additional actions in to task if any
  my $splice = $task->{splice} || {};
  foreach my $index ( sort { $a <=> $b } keys %$splice ) {
    my $action = $splice->{ $index };
    splice @actions, $index, 0, $action;
  }

  foreach my $action ( @actions ) {
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

sub wp_show_form {
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
    printf "VALUES: %s => %s\n", $field, $value unless $task->{name} eq 'Log In';
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
