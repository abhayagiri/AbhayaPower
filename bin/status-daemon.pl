#!/usr/bin/perl
use strict;
use warnings;
use Device::ParallelPort;
use Device::ParallelPort::drv::auto;

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

my $delay=0.25; # delay in milliseconds for loop
my $port = Device::ParallelPort->new();
my $toggle = 0;
my $i = -1;
my $powerStatus = {
	VVWEAK => undef,
	VWEAK => undef,
	WEAK => undef,
	STRONG => undef,
	VSTRONG => undef,
	RECENT => undef,
	STATUS => undef,
};

#disable all data pins on parallel port to start
$port->set_byte(0,chr(0));
select(undef, undef, undef, 0.25);

### Subroutines for pin settings
# pin 1 = weak, pin 2 = normal, pin 3 = strong 
###
# Blink red fast
sub status_vvweak {
	if ($toggle == 1) {
		$port->set_byte(0,chr(0b001));
		$toggle = 0;
	}
	else {
		$port->set_byte(0,chr(0b000));
		$toggle = 1;
	}
	return 0;
}
# Blink red slow
sub status_vweak {
	if ($toggle >= 0 && $toggle <= 3) {
		$port->set_byte(0,chr(0b001));
		$toggle++;
	}
	elsif ($toggle >= 4 && $toggle <= 7) {
		$port->set_byte(0,chr(0b000));
		$toggle++;
		if ($toggle == 8) { $toggle = 0 }
	}
	return 0;
}
# Solid red
sub status_weak {
	$port->set_byte(0,chr(0b001));
	return 0;
}
# Solid blue
sub status_normal {
	$port->set_byte(0,chr(0b010));
	return 0;
}
# Solid green
sub status_strong {
	$port->set_byte(0,chr(0b100));
	return 0;
}
sub status_error {
	$port->set_byte(0,chr(0b101));
	return 0;
}

my (%log,$s,$minute,$lastMin);
$lastMin = -1;
# infinite loop
while (1) {
	
	# read power status every minute other than first minute of hour
	# first minute is ignored because that is when the data is
	# actually calculated.  Also uses $lastMin to check if the last check
	# happened during this minute to stop excessive reads of the log
	my $minute = `date +%M`;
	chomp $minute;
	if (($minute != 0 && $minute != $lastMin) || !defined $s) {
		%log = parseStatusLog(loadStatusLog($cfg{STATUSLOG}));
		$s = getStatus(\%log);
		$lastMin = $minute;
	}

	# use different subroutines defined above depending on status
	if    ($s == -3) { status_vvweak }
	elsif ($s == -2) { status_vweak  }
	elsif ($s == -1) { status_weak   }
	elsif ($s == 0)  { status_normal }
	elsif ($s == 1)  { status_strong }
	else  		 { status_error  }
	
	# use select for delay under one second
	select(undef, undef, undef, $delay);
}
