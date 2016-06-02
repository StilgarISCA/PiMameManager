#!/usr/bin/perl
use strict;
use warnings;

my $is_up = IsEthernetUp();

return 0;

### End Main Body ###

#
# Determine if the physical ethernet adapter is up (or not)
#
# Returns 1 (true) if ethernet functional, false otherwise
#
sub IsEthernetUp()
{
  my $ethernet_response = `cat /sys/class/net/eth2/operstate`;
  chomp( $ethernet_response );
  return ($ethernet_response eq 'up');
}

#EOF
