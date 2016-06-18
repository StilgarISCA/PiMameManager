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
  my $pid = `pidof mame`;
  return 0 if ( not defined $pid or $pid eq "" );
  return $pid;
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
  system( 'sudo shutdown -h now' );
}

#
# Launch the Mame process
#
sub StartMame()
{
  system( '/home/pi/mame/mame trackfld' );
}

#
# Update file timestamp used to track last known powered run
#
sub UpdateLastPoweredRunTime()
{
  system( 'touch /home/pi/.lastpoweredrun' );
}

#
# Update file timestamp used to track last known unpowered run
#
sub UpdateLastUnpoweredRunTime()
{
  system( 'touch /home/pi/.lastunpoweredrun' );
}

### Start Main Program ###

my $is_power_up = IsEthernetUp();
my $is_mame_running = IsMameRunning();

if ( $is_power_up ) {
  UpdateLastPoweredRunTime();
  # UpdateChargeLevel
  # DateDiff lastDownTime, curTime minus expected charge time
  if ( !$is_mame_running ) {
    StartMame();
  }
} else { # power loss
  if ( $is_mame_running ) {
    ShutdownMame();
  }
  UpdateLastUnpoweredRunTime();
  # if battery low
  # TimeDiff down, up minus expected battery life
    # ShutdownPi();
}

#EOF
