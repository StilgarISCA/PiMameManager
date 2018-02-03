#!/usr/bin/perl
##############################################################################
# Script: pi-mame-manager.pl
# Author: Glenn Hoeppner
# License: MIT
# Repository: https://github.com/StilgarISCA/PiMameManager
# Homepage: http://www.classicarcadeprojects.com/
#
# A script to help facilitate using a Raspberry Pi and Raspbian OS as a
# dedicated arcade game cabinet.
##############################################################################
use strict;
use warnings;
use POSIX();

my $USER = "pi";  # user account this will run as
my $ETHERNET_DEVICE = "eth0"; # ethernet port connected to switch
my $PATH_TO_MAME = "/usr/local/bin"; # path to the folder containing mame exe
my $MAME_EXE = "advmame";   # name of the mame executable
my $GAME = "trackfld";   # name of the game to run
my $BATTERY_LIFE = 72;   # expected battery life in hours
my $SLEEP_INTERVAL = 15; # seconds to wait between each run
my $IS_DEBUG = 1;        # 1 to print debugging statements, 0 for silent

#
# Measure how long the system has been unpowered
#
# Returns the number of seconds the system has been without power
#
sub CalculateDownTime()
{
  return SecondsSinceFileUpdated( "/home/$USER/.lastunpoweredrun" ) - SecondsSinceFileUpdated( "/home/$USER/.lastpoweredrun" );
}

#
# If debugging is enabled, print the message passed in
# Prepends a timestamp, appends new line.
#
# Accepts string to print
#
sub Debug
{
  return unless( $IS_DEBUG );

  my $statement = shift();
  print POSIX::strftime( "%Y-%m-%d %H:%M:%S ", localtime() );
  print "$statement\n";
}

#
# Converts hours to seconds
#
# Accepts integer time in hours
# Returns hours as seconds integer
#
sub HoursToSeconds
{
  my $hours = shift();
  return $hours * 3600;
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
#
# Accepts path to file
# Returns seconds since file manipulation
#
sub SecondsSinceFileUpdated
{
  my $file = shift();
  return ( stat ( $file ) )[9];
}

#
# Converts time in seconds to a more human-readable format
#
# Accepts time in seconds
# Returns string of N days N hours N minutes N seconds
#
sub SecondsToHumanReadableTime
{
  my $time_in_seconds = shift();
  my @time_array = gmtime( $time_in_seconds );
  return sprintf ( "%1u days %1u hours %1u minutes %1u seconds", @time_array[7, 2, 1, 0] );
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
# Turn off video output
#
sub TurnOffDisplay()
{
  system( 'sudo vcgencmd display_power 0' );
}

#
# Turn on video output
#
sub TurnOnDisplay()
{
  system( 'sudo vcgencmd display_power 1' );
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

my $battery_life_in_seconds = HoursToSeconds( $BATTERY_LIFE );

while ( 1 ) {
  if ( IsEthernetUp() ) { # power is up
    Debug( "Power is on" );
    UpdateLastPoweredRunTime();
    # UpdateChargeLevel()
    # DateDiff lastDownTime, curTime minus expected charge time
    if ( !IsMameRunning() ) {
      Debug( "Turn on display." );
      TurnOnDisplay();
      Debug( "Mame is not running. Trying to start." );
      StartMame();
    }
  } else { # power loss
    Debug( "Power is off" );

    if ( IsMameRunning() ) {
      Debug( "Turn off display." );
      TurnOffDisplay();
      Debug( "Mame is running. Trying to stop." );
      ShutdownMame();
    }

    UpdateLastUnpoweredRunTime();
    my $down_time = CalculateDownTime();
    my $readable_down_time = SecondsToHumanReadableTime( $down_time );
    Debug( "Down for $readable_down_time seconds" );

    if ( $down_time >= $battery_life_in_seconds ) {
      Debug( "Battery limit. Initiate shutdown." );
      ShutdownPi();
    }
  }
  sleep( $SLEEP_INTERVAL );
}

#EOF
