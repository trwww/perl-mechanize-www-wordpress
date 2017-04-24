use warnings;
use strict;

use Test::More qw(no_plan);
use Mechanize::WWW::WordPress;

my $wp = Mechanize::WWW::WordPress->new(
  domain => 'me.wordpress.com',
  ssl    => 1,
  login  => {
    log => 'me',
    pwd => 'pwd',
  },
  tasks => [{
    name   => 'Reading Settings | Front page displays | Front Page | Home',
  }],
);

isa_ok( $wp => 'Mechanize::WWW::WordPress' => '$wp' );

is(
  $wp->{wordpress}{url},
  'https://me.wordpress.com/wp-admin/',
  'got expected url'
);
