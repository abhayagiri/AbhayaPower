#!/usr/bin/perl

####
#
#	This script calculates the hourly voltage averages and saves to a log
#	pass it the '-d' flag and a date in the format of YYYY-MM-DD-HH
#	with HH as the last hour to calculate for (full day should be 23)
#	This script can be modified fairly easily to include other data. To
#	do so see comments below.
#
###

use strict;
use warnings;
use Getopt::Std;

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

# Get command line options
my %opt;
getopt('d',\%opt);

# Setup time variables
my %time;
my $finalHour;
if ($opt{d})    {
	%time = getTime($opt{d});
} else {
	%time = getTime;
}
$finalHour = 23;
$time{HOUR} = "00";

my %hash;
my $ret = "";
while ($time{HOUR} <= $finalHour) {
	my @log = loadMateLog($cfg{LOGDIR},\%time);
	%hash = parseMateLog(\@log,$cfg{INVNUM});
	
	##
	#	Here is where the functions are called to get the logged data.
	#	If you want to log more data than this add another function with
	#	A key before it like below.
	##
	$ret .= "HOUR=$time{HOUR},";
	$ret .= "FX_BATT_V_AVG=".getHourVolt(\%hash,"AVG").",";
	$ret .= "FX_BATT_V_MAX=".getHourVolt(\%hash,"MAX").",";
	$ret .= "FX_BATT_V_MIN=".getHourVolt(\%hash,"MIN").",";
	$ret .= "INV_CRNT_AVG=".getHourLoad(\%hash,"AVG").",";
	$ret .= "INV_CRNT_MAX=".getHourLoad(\%hash,"MAX").",";
	$ret .= "INV_CRNT_MIN=".getHourLoad(\%hash,"MIN").",";
	#print "Amps:\t\t\t".getCrntLoad(\%hash,1)."\n";
	#print "Watts:\t\t\t".getCrntLoad(\%hash,1,'W')."\n";
	$time{HOUR} = sprintf("%02d",$time{HOUR}+1);
	$ret .= "\n";
}

# Save data to log in directory defined by /etc/abhayapower
my $logPath = $cfg{LOGDIR};
$logPath .= "/$time{YEAR}/$time{MONTH}/$time{DAY}/hours.log";
print "Saving to $logPath\n";
open(FILE,">$logPath") or die "Can't open log.";
print FILE $ret;
close FILE;
