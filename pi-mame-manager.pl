#!/usr/bin/perl
use strict;
use warnings;

#
# Get the number of seconds since a file was last updated
# Accepts path to file
#
sub SecondsSinceFileUpdated
{
  my $file = shift;
  return ( stat ( $file ) )[9];
}

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
  print "called shutdownmame\n";
  #my $mame_pid = `pidof mame`;
  #kill( "SIGTERM", $mame_pid );
}

#
# Power down the system
#
sub ShutdownPi()
{
  print "called shutdownpi\n";
  #exec( 'sudo shutdown -h now' );
}

#
# Launch the Mame process
#
sub StartMame()
{
  print "starting mame\n";
  #exec( '/home/pi/mame/mame trackfld' );
}

#
# Update file timestamp used to track last known powered run
#
sub UpdateLastPoweredRunTime()
{
  #exec( 'touch /home/pi/.lastpoweredrun' );
  exec( 'touch /home/parallels/.lastpoweredrun' );
}

#
# Update file timestamp used to track last known unpowered run
#
sub UpdateLastUnpoweredRunTime()
{
  #exec( 'touch /home/pi/.lastunpoweredrun' );
  exec( 'touch /home/parallels/.lastunpoweredrun' );
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

#  my $seconds_down = SecondsSinceFileUpdated( '/home/pi/.lastpoweredrun' ) - SecondsSinceFileUpdated( '/home/pi/.lastunpoweredrun' );
  my $seconds_down = SecondsSinceFileUpdated( '/home/parallels/.lastpoweredrun' ) - SecondsSinceFileUpdated( '/home/parallels/.lastunpoweredrun' );
  if ( $seconds_down >=  9900 ) { #9900 = 2.75 hrs
     ShutdownPi();
  } 
}

#EOF
