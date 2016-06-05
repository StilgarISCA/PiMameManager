#!/usr/bin/perl
use strict;
use warnings;

#
# Determine if the physical ethernet adapter is up (or not)
#
# Returns non-zero (true) if ethernet functional, false otherwise
#
sub IsEthernetUp()
{
  my $ethernet_response = `cat /sys/class/net/eth2/operstate`;
  chomp( $ethernet_response );
  return ( $ethernet_response eq 'up' );
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

#
# Stops the Mame process from running
#
sub ShutdownMame()
{
  my $mame_pid = `pidof mame`;
  kill( "SIGTERM", $mame_pid );
}

#
# Power down the system
#
sub ShutdownPi()
{
  exec( 'sudo shutdown -h now' );
}

#
# Launch the Mame process
#
sub StartMame()
{
  exec( '/home/pi/mame/mame trackfld' );
}

### Start Main Program ###

my $is_power_up = IsEthernetUp();
my $is_mame_running = IsMameRunning();

if ( $is_power_up ) {
  if ( !$is_mame_running ) {
    StartMame();
  }
} else { # power loss
  if ( $is_mame_running ) {
    ShutdownMame();
  }
  # if battery low
    # ShutdownPi();
}

#EOF
