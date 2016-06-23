#!/usr/bin/perl
use strict;
use warnings;

my $USER = "pi"; # user account this will run as
my $ETHERNET_DEVICE = "eth0"; # ethernet port connected to switch
my $PATH_TO_MAME = "/home/$USER/mame"; # path to the folder containing mame exe
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
  my $pid = `sudo pidof mame`;
  print "my pid is $pid";
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
  #print "\npower loss, shutdown mame\n";
  my $mame_pid = `pidof mame`;
  kill( "SIGTERM", $mame_pid );
  #system( 'sudo killall mame' );
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
# Launch the Mame process
#
sub StartMame()
{
  my $run_mame = "$PATH_TO_MAME/mame $GAME";
  defined( my $pid = fork() ); 
  unless( $pid ) {
    exec( $run_mame );
  }
}
# From Learning Perl 5th ed.
#defined(my $pid= fork) or die "Cannot fork: $!";
#unless ($pid) {
#  # Child process is here
#  exec "date";
#  die "cannot exec date: $!";
#}
## Parent process is here
#waitpid($pid, 0);

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
print "starting up\n";
while ( 1 ) {
  if ( IsEthernetUp() ) { # power up
    UpdateLastPoweredRunTime();
    # UpdateChargeLevel
    # DateDiff lastDownTime, curTime minus expected charge time
    if ( !IsMameRunning() ) {
      StartMame();
    }
  } else { # power loss
    print "power is out\n";
    if ( IsMameRunning() ) {
      print "shutdown mame\n";
      ShutdownMame();
    }
    UpdateLastUnpoweredRunTime();
    if ( CalculateDownTime >= $BATTERY_LIFE ) {
      ShutdownPi();
    }
  }
  sleep( 15 );
}
#EOF
