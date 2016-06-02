#!/usr/bin/perl
use strict;
use warnings;

my $is_up = IsEthernetUp();
my $is_mame_running = IsMameRunning();
return 0;

### End Main Body ###

#
# Determine if the physical ethernet adapter is up (or not)
#
# Returns non-zero (true) if ethernet functional, false otherwise
#
sub IsEthernetUp()
{
  my $ethernet_response = `cat /sys/class/net/eth2/operstate`;
  chomp( $ethernet_response );
  return ($ethernet_response eq 'up');
}

#
# Determine if Mame is running (or not)
#
# Returns non-zero (true) if mame running, false otherwise
#
sub IsMameRunning()
{
  return `pidof mame`;
}

#EOF
