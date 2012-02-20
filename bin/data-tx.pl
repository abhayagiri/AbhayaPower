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


# Get command line options
my %opt;
getopts('xXVHLS',\%opt);

# Setup some variables we need first
my %time;
if (!$opt{x} && $ARGV[0])	{%time = getTime($ARGV[0]);}
else		{%time = getTime;}

# load data logs into memory and parse them into their data types
my (%mh,%sh,@ml,$sl);
@ml = loadMateLog($cfg{LOGDIR},\%time);
$sl = loadStatusLog($cfg{STATUSLOG});
%mh = parseMateLog(\@ml,$cfg{INVNUM});
%sh = parseStatusLog($sl);

# call some functions depending on what flags were passed on the command line
my $ret = "";
if ($opt{x}) { $ret .= "~XB=SNA,PT=PWR,"; } # XBee ID "SNA" means Sauna
if ($opt{X}) { $ret .= "XB=SNA,PT=PWR,"; }  # PT (Packet Type) PWR for "Power"
if ($opt{H}) { $ret .= "H=".getHourVolt(\%mh,"AVG").",";} # average of batts now
if ($opt{V}) { $ret .= "V=".getCrntVoltAvg(\%mh).",";	} # hourly avg so far
if ($opt{L}) { $ret .= "L=".getCrntLoad(\%mh,'W').",";	} # load in watts
if ($opt{S}) { $ret .= "S=".getStatus(\%sh).",";}	  # status code used
							  # for LED display
chop $ret;

# If sending over Serial do the required steps
if ($opt{x}) {
	## find first USB serial port
	my $dev = glob "/dev/ttyUSB*";
	
	$ret .= "~";
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
}

# print the final string
print "$ret\n";
