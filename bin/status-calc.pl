#!/usr/bin/perl

##
#
#	This script reads the current and previous hourly log files
#	and calculates a status number from -3 to 1 based on the voltage
#	averages.
#
##

use warnings;
use strict;

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

sub status_vvweak	{ return "-3"; }
sub status_vweak	{ return "-2"; }
sub status_weak		{ return "-1"; }
sub status_normal	{ return "0"; }
sub status_strong	{ return "1"; }
sub status_error	{ return "E"; }

# build Log array from yesterday and today
my $yesterday = `date -u -d \"yesterday\" +%Y-%m-%d-23`;
chomp $yesterday;
my %time = getTime($yesterday);
my @log = loadHourLog($cfg{LOGDIR},\%time);
my @tmpLog = loadHourLog($cfg{LOGDIR});
@log = parseHourLog(\@log);
@tmpLog = parseHourLog(\@tmpLog);
for (my $i = 0; $i < @tmpLog; $i++) {
	$tmpLog[$i]{HOUR} += 24;
	if ($tmpLog[$i]{FX_BATT_V_AVG} ne "") {
		$log[$i+24] = $tmpLog[$i];
	}
}
@log = reverse @log;

# calculate voltage strength values for testing against in if statements below
# $recent is incremented when voltage was recently high and is thus an
# indication of strong voltage
# W = Weak, V = Very, S = Strong, R = Recent
my %stats = (W=>0,VW=>0,VVW=>0,S=>0,VS=>0,R=>0);
my $i = 0;

foreach (@log) {
	if (defined %{$_}) {
		my %h = %{$_};
		if (defined $h{FX_BATT_V_AVG} && $i < 24) {
			#calculate 'weaks' for past 12 hours
			if ($i < 12 ) {
				if ($h{FX_BATT_V_AVG} < 49.0) {
					$stats{W}++;
				}
				if ($h{FX_BATT_V_AVG} < 48.2) {
					$stats{VW}++;
				}
				if ($h{FX_BATT_V_AVG} < 47.6) {
					$stats{VVW}++;
				}
			}
			#calculate 'strongs' every time (past 24 hours)
			if ($h{FX_BATT_V_AVG} > 50.0) {
				$stats{S}++;
			}
			if ($h{FX_BATT_V_AVG} > 52.0) {
				$stats{VS}++;
			}
			#calculate recent
			if ($i < 4) {
				if ($h{FX_BATT_V_AVG} > 50.0) {
					$stats{R}++;
				}
			}
		}
		$i++;
	}		
}

# Build a string of all the data
my $ret = "";
$ret .= "WEAK=$stats{W},VWEAK=$stats{VW},VVWEAK=$stats{VVW},"
	."STRONG=$stats{S},VSTRONG=$stats{VS},"
	."RECENT=$stats{R},STATUS=";

# decide on status for power system
if    ($stats{S} < 20 && $stats{R} > 1) {
	$ret .=  status_normal;
}
elsif ($stats{S} >= 20) {
	$ret .= status_strong;
}
elsif ($stats{VVW} > 2 && $stats{R} < 2) {
	$ret .= status_vvweak;
}
elsif ($stats{VW} > 2 && $stats{R} < 2) {
	$ret .= status_vweak;
}
elsif ($stats{W} > 2 && $stats{R} < 2) {
	$ret .= status_weak;
}
else {
	$ret .= status_normal;
}

# save the data to the status log defined in /etc/abhayapower
print "Saving to $cfg{STATUSLOG}\n";
open(FILE,">$cfg{STATUSLOG}") or die "Can't open log.";
print FILE $ret;
close FILE;

