#!/usr/bin/perl
use strict;
use warnings;

my $USER = "parallels"; # user account this will run as
my $ETHERNET_DEVICE = "eth1"; # ethernet port connected to switch
my $PATH_TO_MAME = "/home/$USER/mame/"; # path to the folder containing mame exe
my $GAME = "trackfld"; # name of the game to run
my $BATTERY_LIFE = 9900; # expected battery life in seconds

#
# CalculateDownTime
#
# Returns the number of seconds the system has been without power
#
sub CalculateDownTime()
{
  return SecondsSinceFileUpdated( "/home/$USER/.lastunpoweredrun" ) - SecondsSinceFileUpdated( "/home/$USER/.lastpoweredrun" );
}

#
# Determine if the physical ethernet adapter is up (or not)
#
# Returns non-zero (true) if ethernet functional, false otherwise
#
sub IsEthernetUp()
{
  my $ethernet_response = `cat /sys/class/net/$ETHERNET_DEVICE/operstate`;
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
# Get the number of seconds since a file was last updated
# Accepts path to file
#
sub SecondsSinceFileUpdated
{
  my $file = shift;
  return ( stat ( $file ) )[9];
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
  system( '$PATH_TO_MAME/mame $GAME' );
}

#
# Update file timestamp used to track last known powered run
#
sub UpdateLastPoweredRunTime()
{
  system( 'touch /home/$USER/.lastpoweredrun' );
}

#
# Update file timestamp used to track last known unpowered run
#
sub UpdateLastUnpoweredRunTime()
{
  system( 'touch /home/$USER/.lastunpoweredrun' );
}

### Start Main Program ###

if ( IsEthernetUp() ) { # power up
  UpdateLastPoweredRunTime();
  # UpdateChargeLevel
  # DateDiff lastDownTime, curTime minus expected charge time
  if ( !IsMameRunning() ) {
    StartMame();
  }
} else { # power loss
  if ( IsMameRunning ) {
    ShutdownMame();
  }
  UpdateLastUnpoweredRunTime();
  if ( CalculateDownTime >= $BATTERY_LIFE ) {
    ShutdownPi();
  }
}

#EOF
