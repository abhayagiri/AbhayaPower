#!/usr/bin/perl

##
#	This script is intended to be fun at the start of the hour by cron
#	It makes sure the hourly calculations are done and then the status log
#	updated.
##

use strict;
use warnings;

## Open and parse config file
our %cfg;
BEGIN {
        open (INPUT,'<',"/etc/abhayapower");
        foreach (<INPUT>) {
                chomp;
                if (substr($_,0,1) ne "#") {
                        my ($key,$val) = split /===/,$_;
                        $cfg{$key} = $val;
                }
        }
        close INPUT;
}

# Here's the main part of the script
print("Sending XBee Data\n");
system("killall ping-listen.pl");
system("$cfg{BINDIR}/data-tx.pl -xVHLS");
system("$cfg{BINDIR}/data-tx.pl -xVHLS");
system("$cfg{BINDIR}/ping-listen.pl &");

print("Grabbing Mate Log\n");
system("$cfg{BINDIR}/mate-logger.pl");
