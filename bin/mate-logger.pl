#!/usr/bin/perl

##
#
#	This script reads the serial port for data and assumes it is an OutBack
#	Mate on the other side.  It then parses the data and stores it in a log
#	organized by date and hour. The data in the logs are timestamped
#	by minute
#
##
use strict;
use warnings;
use File::Path qw(make_path);

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

# Request data from Mate
my $rx;
$rx = readMateDevice("/dev/ttyS0");
$rx = substr($rx,1);

# Setup Array for inverters and start with time stamp at index 0

my @inv;
my %time = getTime;
$inv[0]{TIME}  = $time{YEAR};
$inv[0]{TIME} .= $time{MONTH};
$inv[0]{TIME} .= $time{DAY};
$inv[0]{TIME} .= $time{HOUR};
$inv[0]{TIME} .= $time{MINUTE};


# This block checks for device address and parses the Mate's transmission
# and store them in subhashes of the hash %data
my @a = split /\r/,$rx;
foreach (@a) {	# Transmissions end with carriage return ("\r")
	my @buf = split /,/,$_;
	# Convert Inverter number to ordinal number or prefixed '\n' interferes
	$buf[0] += 0;
	if ($buf[0] >= 1 && $buf[0] <= 10) { # FX devices use range 1-10
		$inv[$buf[0]]{INV_ADDR}     = $buf[0]+0;
		$inv[$buf[0]]{INV_CRNT}     = $buf[1]+0;
		$inv[$buf[0]]{CHRG_CRNT}    = $buf[2]+0;
		$inv[$buf[0]]{BUY_CRNT}     = $buf[3]+0;
		$inv[$buf[0]]{AC_IN_V}      = $buf[4]+0;
		$inv[$buf[0]]{AC_OUT_V}     = $buf[5]+0;
		$inv[$buf[0]]{SELL_CRNT}    = $buf[6]+0;
		$inv[$buf[0]]{FX_OP_MODE}   = $buf[7]+0;
		$inv[$buf[0]]{FX_ERR_MODE}  = $buf[8]+0;
		$inv[$buf[0]]{FX_AC_MODE}   = $buf[9]+0;
		$inv[$buf[0]]{FX_BATT_V}    = $buf[10]/10;
		$inv[$buf[0]]{FX_MISC}      = $buf[11]+0;
		$inv[$buf[0]]{FX_WARN_MODE} = $buf[12]+0;
		$inv[$buf[0]]{CHKSUM}       = $buf[13]+0;
		$inv[$buf[0]]{CHKSUM_ERR}   = mateChksum(\%{$inv[$buf[0]]});
	}
}

## put all the data in a string
my $ret = "";
foreach (@inv) {
	my %h = %{$_};
	foreach (sort keys %h) {
		$ret .= "$_=$h{$_},";
	}
	chop $ret;
	$ret .= "\n";
}

# Output the final string to stdin
print $ret;
# ...and the log in the directory defined in /etc/abhayapower
my $logPath = "$cfg{LOGDIR}/$time{YEAR}/$time{MONTH}/$time{DAY}";
make_path($logPath);
open(FILE,">>$logPath/$time{HOUR}.log") or die "Can't open log.";
print FILE $ret;
close FILE;
