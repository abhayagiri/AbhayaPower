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
use lib $cfg{MODDIR};
use AbhayaPower;

my $timeStr = `date -u -d " 12 hours  ago" +%Y-%m-%d-%H`;
chomp $timeStr;

# Here's the main part of the script
print("Calculating Hourly Data\n");
system("$cfg{BINDIR}/hourly-data-calc.pl -d $timeStr");
system("$cfg{BINDIR}/hourly-data-calc.pl");
print("Calculating LED Status\n");
system("$cfg{BINDIR}/status-calc.pl");
