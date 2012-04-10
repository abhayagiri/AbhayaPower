#!/usr/bin/perl
use strict;
use warnings;
use Device::SerialPort 0.05;
use Getopt::Std;

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

my $count_in;
my $ret = "";

while(1) {
	sleep 1;
	($count_in, $ret) = $ob->read(128);
	if ( $ret =~ /PT=PING/ && ($ret !~ /DST/ || $ret =~ /DST=SNA/)) {
	    $ob->write("~XB=SNA,PT=PONG~");
	    sleep 1;
	    system("$cfg{BINDIR}/data-tx.pl -xVHLS");
	}
}
