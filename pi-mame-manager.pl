#!/usr/bin/perl
use strict;
use warnings;
use POSIX();

my $USER = "parallels";  # user account this will run as
my $ETHERNET_DEVICE = "eth0"; # ethernet port connected to switch
my $PATH_TO_MAME = "/home/$USER/mame"; # path to the folder containing mame exe
my $MAME_EXE = "mame";   # name of the mame executable
my $GAME = "trackfld";   # name of the game to run
my $BATTERY_LIFE = 9900; # expected battery life in seconds
my $SLEEP_INTERVAL = 15; # seconds to wait between each run
my $IS_DEBUG = 1;        # 1 to print debugging statements, 0 for silent

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
# Debug
# Accepts string to print
# 
# If debugging is enabled, print the message passed in
# Prepends a timestamp, appends new line.
#
sub Debug
{
  return unless( $IS_DEBUG );

  my $statement = shift;
  print POSIX::strftime( "%Y-%m-%d %H:%M:%S ", localtime() );
  print "$statement\n";
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
# Returns 1 (true) if mame has a pid, 0 (false) otherwise
#
sub IsMameRunning()
{
  my $pid = `pidof $MAME_EXE`;
  if ( !defined( $pid ) or ( $pid eq "" ) ) {
    return 0;
  } else {
    return 1;
  }
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
  my $mame_pid = `pidof $MAME_EXE`;
  kill( "SIGTERM", $mame_pid );
  waitpid( $mame_pid, 0 );
}

#
# Power down the system
#
sub ShutdownPi()
{
  system( 'sudo shutdown -h now' );
}

#
# Launch Mame in a new process
#
sub StartMame()
{
  # Based on fork() sample in Learning Perl 5th Ed.
  my $run_mame = "$PATH_TO_MAME/$MAME_EXE $GAME";
  defined( my $pid = fork() ) or die( "ERROR: Could not fork: $!\n" ); 
  unless( $pid ) {
    exec( $run_mame );
  }
}

#
# Update file timestamp used to track last known powered run
#
sub UpdateLastPoweredRunTime()
{
  system( "touch /home/$USER/.lastpoweredrun" );
}

#
# Update file timestamp used to track last known unpowered run
#
sub UpdateLastUnpoweredRunTime()
{
  system( "touch /home/$USER/.lastunpoweredrun" );
}

### Start Main Program ###

while ( 1 ) {
  if ( IsEthernetUp() ) { # power up
    Debug( "Power is on" );
    UpdateLastPoweredRunTime();
    # UpdateChargeLevel
    # DateDiff lastDownTime, curTime minus expected charge time
    if ( !IsMameRunning() ) {
      Debug( "Mame is not running. Trying to start." );
      StartMame();
    }
  } else { # power loss
    Debug( "Power is off" );

    if ( IsMameRunning() ) {
      Debug( "Mame is running. Trying to stop." );
      ShutdownMame();
    }

    UpdateLastUnpoweredRunTime();
    my $down_time = CalculateDownTime();
    Debug( "Down for $down_time seconds" );

    if ( $down_time >= $BATTERY_LIFE ) {
      Debug( "Battery limit. Initiate shutdown." );
      ShutdownPi();
    }
  }
  sleep( $SLEEP_INTERVAL );
}

#EOF
