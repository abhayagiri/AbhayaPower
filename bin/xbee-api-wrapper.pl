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
use integer;
use Device::SerialPort;

my $tx;
my @hex = (0x7E,0x00,0x0F,0x10,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0xFF,0xFF,0xFE,0x00,0x00);

my @strArr = unpack "a1" x (length($ARGV[0])),$ARGV[0];
my $i = @hex;
foreach (@strArr) {
	$hex[$i] = ord("$_");
	$i++;
}

$hex[2] = @hex-3;

my $j;
my $chksum = 0;
for ($j = 3; $j < $i; $j++) {
	$chksum += $hex[$j];
}
$chksum = 255-($chksum & 0b11111111);
$hex[$i] = $chksum;

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

foreach (@hex) {
	$_ = sprintf("%c",$_);
	$ob->write($_);
}
#my $rx;
#while (1) {
#	$rx = "";
#	if (($rx = $ob->input) ne "") {
#		printf "%s\n",$rx;
#	}
#}
undef $ob;
