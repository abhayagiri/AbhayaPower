#!/usr/bin/perl
#####
# Prints inverter data for a given time
#####
# command line flags:
# x = send data over serial with serial prefix and suffix of ~
# V = Current minute's avg voltage from all inverters
# H = Average voltage for the hour thus far
# L = Current minute's load in amperes
# S = LED's state
#####

use strict;
use warnings;
use Device::SerialPort 0.05;
use Getopt::Std;

## Open and parse config file
our %cfg;
BEGIN {
	open (INPUT,'<',"/etc/abhayapower") or die "err"; 
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



# call some functions depending on what flags were passed on the command line
my $ret = "~XB=SNA,PT=PING~";

# If sending over Serial do the required steps
## find first USB serial port
my $dev = glob "/dev/ttyUSB*";

my $ob = Device::SerialPort->new ($dev) || die "Canâopen $dev:$!";
$ob->baudrate (9600) || die "fail setting baudrate";
$ob->parity ("none") || die "fail setting parity";
$ob->databits (8) || die "fail setting databits";
$ob->stopbits (1) || die "fail setting stopbits";
$ob->handshake ("none") || die "fail setting handshake";
$ob->dtr_active (1) || die "fail setting dtr_active";
$ob->rts_active (0) || die "fail setting rts_active";
$ob->write ($ret);
sleep 2;
undef $ob;


# print the final string
print "$ret\n";
