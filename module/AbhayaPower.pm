#!/usr/bin/perl

##
#
#	These are the main functions for data manipulation for the AbhayaPower
#	monitoring system.
#
##

package AbhayaPower;

use strict;
use warnings;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = ('Exporter');
@EXPORT = (qw(
	readMateDevice
	mateChksum
	getTime
	parseMateLog	
	parseStatusLog
	parseHourLog
	getHourVolt
	getCrntVoltAvg
	getStatus
	getHourLoad
	getCrntLoad
	loadMateLog
	loadHourLog
	loadStatusLog
));

# This function returns a time hash with the keys YEAR,MONTH,DAY,HOUR,MINUTE
# It takes as an argument a string in the format YYYY-MM-DD-HH-MM
# the minutes are optional
sub getTime {
	my %t = (
		YEAR    => `date -u +%Y`,
		MONTH   => `date -u +%m`,
		DAY     => `date -u +%d`,
		HOUR    => `date -u +%H`,
		MINUTE	=> `date -u +%M`,);
	foreach ( keys %t ) { chomp $t{$_} }
	if ($_[0]) {
		my @a = split /-/,$_[0];
		$t{YEAR}  = $a[0];
		$t{MONTH} = $a[1];
		$t{DAY}   = $a[2];
		$t{HOUR}  = $a[3];
		if (defined $a[4]) { $t{MINUTE} = $a[4] }
	}
	return %t;
}

# log parser for matelogger logs, returns reference to hash
# call this way: parseLog(@log,$cfg{INVNUM})
sub parseMateLog {
        my %d;
        my @a;
        my %h;
	my $numOfInv = $_[1];
        # $keyTime will hold the value of TIME=VALUE
        my $keyTime;
        my $inv = 0;
        foreach (@{$_[0]}) {
                #erase newline character and extra comma leftover in log
                chomp;
                if ($_[-1] eq ",") {
                        chop;
                }
                # split the X=Y pairs seperated by commas into an array
                my @a = split /,/,$_;
                foreach (@a) {
                        my @s = split /=/,$_;
			# Ignore hash keys without values
			if (defined $s[1]) {
                        	if ($s[0] eq "TIME") {
                        	        $keyTime = $s[1];
                        	        $d{$keyTime} = [];
                        	        $d{$keyTime}[$inv] = {};
					$inv = 0;
                        	}
				$d{$keyTime}[$inv]{$s[0]} = $s[1];
			}
                }
                $inv++;
        }
        return %d;
}


# Parses the status log.  Takes a scalar as an argument and returns a hash.
# probably called like so: my %statusLog = parseStatusLog($cfg{STATUSLOG});
sub parseStatusLog {
        my %d;
        my @a = split /,/,$_[0];
        foreach (@a) {
                my ($key,$val) = split /=/,$_;
                $d{$key} = $val;
        }
        return %d;
}

## Returns MIN,MAX,or AVG voltage for the minutely values in a hash of the type
# returned by the parseMateLog subroutine.
sub getHourLoad {
        my $sum = 0;
	my $vSum = 0;
	my $tmpSum = 0;
       	my ($min,$max);
        my %h = %{$_[0]};
	my $unit = "A";
        my $divisor = 0;
	my $vDiv = 0;
	my $timeVal = 0;
	
	if (defined $_[2]) {
		$unit = $_[2];
	}

        foreach (sort keys %h) {
                foreach (@{$h{$_}}) {
                        if (defined $_) {
                                my %h = %{$_};
				if ($h{TIME}) {
					$sum += $tmpSum;
                               		if (!defined $min || $min >= $tmpSum) {
                        		        $min = $tmpSum
                                        }
                                        if (!defined $max || $max <= $tmpSum) {
                                        	$max = $tmpSum
                                        }
					$tmpSum = 0;
					$divisor++;
				}
                                if (defined $h{INV_CRNT} && !$h{CHKSUM_ERR}) {
                                        $tmpSum += $h{INV_CRNT};
                                }
				if (defined $h{AC_OUT_V} && !$h{CHKSUM_ERR}) {
					$vSum += $h{AC_OUT_V};
					$vDiv++;
				}
                        }
                }
        }
	$sum += $tmpSum;

	### Changed by SVB ###
	# Line below had && instead of ||, resulted in
	# a division by zero, hourly data not being
	# created, and status led going out of sync w/actual voltage
        if ($divisor == 0 || $vDiv == 0) { return '' };
	###################

        my $avgLoad = $sum/$divisor;
        my $avgACOutV = $vSum/$vDiv;
	if ($unit eq "A") {
	        if ($_[1] eq 'AVG') {
	                return sprintf("%0.1f",$avgLoad);
	        }
	        if ($_[1] eq 'MIN') {
	                return $min;
	        }
	        if ($_[1] eq 'MAX') {
	                return $max;
	        }
	}
	if ($unit eq "W") {
	        if ($_[1] eq 'AVG') {
	                return sprintf("%0.1f",$avgLoad*$avgACOutV);
	        }
	        if ($_[1] eq 'MIN') {
	                return $min*$avgACOutV;
	        }
	        if ($_[1] eq 'MAX') {
	                return $max*$avgACOutV;
	        }
	}
}

## Returns MIN,MAX,or AVG voltage for the minutely values in a hash of the type
# returned by the parseMateLog subroutine.
sub getHourVolt {
        my $sum = 0;
        my ($min,$max);
        my %h = %{$_[0]};
        my $divisor = 0;
        foreach (sort keys %h) {
                foreach (@{$h{$_}}) {
			if (defined $_) {
                        	my %h = %{$_};
                                if ($h{FX_BATT_V} && !$h{CHKSUM_ERR}) {
                                        if (!$min || $min > $h{FX_BATT_V} ) {
                                                $min = $h{FX_BATT_V}
                                        }
                                        if (!$max || $max < $h{FX_BATT_V} ) {
                                                $max = $h{FX_BATT_V}
                                        }
                                        $sum += $h{FX_BATT_V};
                                        $divisor++;
                               	}
			}
                }
        }
	if ($divisor == 0) { return '' };
        my $avgVolt = $sum/$divisor;
        if ($_[1] eq 'AVG') {
                return sprintf("%0.1f",$avgVolt);
        }
        if ($_[1] eq 'MIN') {
                return sprintf("%0.1f",$min);
        }
        if ($_[1] eq 'MAX') {
                return sprintf("%0.1f",$max);
        }
}

## returns the average voltage over all inverters for the most recent logged
# minute in the log it is passed.  Takes a hash reference as an argument like so
#	getCrntVoltAvg(\%mateLog);
sub getCrntVoltAvg {
        my %h = %{$_[0]};
        my $divisor = 0;
        my $sum = 0;
	foreach (reverse sort keys %h) {
		foreach (@{$h{$_}}) {
			if (${$_}{TIME} && $divisor) {
				return sprintf("%0.1f",$sum/$divisor);
			}
			elsif (${$_}{FX_BATT_V} && !${$_}{CHKSUM_ERR}) {
				$sum += ${$_}{FX_BATT_V};
				$divisor++;
			}
		}
        }
	return 1;
}

# conveniece subroutine for returning the current LED status
sub getStatus {
        return $_[0]{STATUS};
}

########
# If you want amps call with
#       getCrntLoad(\%h,$inverter)
# if you want watts use
#       getCrntLoad(\%h,$inverter,'W')
########
sub getCrntLoad {
        my %h = %{$_[0]};
	my $a = 0;
	my $w = 0;
	my $stop = 0;
	foreach (reverse sort keys %h) {
		foreach (@{$h{$_}}) {
			if ($stop && ${$_}{TIME}) {
	        		if ( defined $_[1] && $_[1] eq 'W' ) {
					return $w;
       		 		} else {
					return $a;
       				}
			}
			if (defined ${$_}{INV_CRNT} && !${$_}{CHKSUM_ERR}) {
				$w += ${$_}{INV_CRNT}*${$_}{AC_OUT_V};
				$a += ${$_}{INV_CRNT};
				$stop = 1;
			}
		}
	}	
	return "Error";
}

#########
# Loads a matelogger log file and returns it as an array
# If wanting to use a time other than the current hour call with:
#       loadMateLog($logDirPath,\%timeHash)
# or use this if you want the current log:
#       loadMateLog($logDirPath)
#########
# If calling with \%timeHash make sure follows the format shown in this function
#########
sub loadMateLog {
        my %t;
        if (defined $_[1]) {
                %t = %{$_[1]};
        } else {
                %t = getTime;
        }
        my $logPath = "$_[0]/$t{YEAR}/$t{MONTH}/".
                        "$t{DAY}/$t{HOUR}.log";
        open (INPUT, '<', $logPath) or return 1;
	my @ret = <INPUT>;
	close INPUT;
        return @ret;
}

# Load Hour log
sub loadHourLog {
	my %t;
        if (defined $_[1]) {
                %t = %{$_[1]};
        } else {
		%t = getTime;
        }
	open(INPUT, '<', "$_[0]/$t{YEAR}/$t{MONTH}/$t{DAY}/hours.log") or return 1;
	my @ret = <INPUT>;
	close INPUT;
        return @ret;
}

## returns array with hashes at each hour index (0-23)
sub parseHourLog {
	my %h;
	my @a;
	foreach (@{$_[0]}) {
		chomp;
		my @entry = split /,/,$_;
		foreach (@entry) {
			my ($key,$val) = split /=/,$_;
			$h{$key} = $val;
		}
		foreach (keys %h) {
			my %newh = %h;
			$a[$h{HOUR}] = \%newh;
		}
	}
	return @a;
}

# same thing for LED status log (using scalar because it is only one line)
sub loadStatusLog {
        open(INPUT, '<', $_[0]) or return 1;
        my $statusLog = <INPUT>;
        chomp $statusLog;
	close INPUT;
        return $statusLog;
}


# Reads serial data from a serial device
sub readMateDevice {
	use Device::SerialPort 0.05;
	my $mate = $_[0];
	my $ob = Device::SerialPort->new ($mate) || die "Canâopen $mate:$!";
	
	$ob->baudrate (19200) || die "fail setting baudrate";
	$ob->parity ("none") || die "fail setting parity";
	$ob->databits (8) || die "fail setting databits";
	$ob->stopbits (1) || die "fail setting stopbits";
	$ob->handshake ("none") || die "fail setting handshake";
	$ob->dtr_active (1) || die "fail setting dtr_active";
	$ob->rts_active (0) || die "fail setting rts_active";

	sleep 1;

	my $i = 0;
	my $return;
	while(($return = $ob->input) eq "" && $i < 10)
	{
	        $i++;
	        sleep 1;
	}
	undef $ob;
	return $return;
}

# Verify Checksum
sub mateChksum {
	my $c = 0;
	my %h = %{$_[0]};
	foreach (keys %h) {
		if ($_ ne "CHKSUM") {
			my $n = $h{$_};
			if ($_ eq "FX_BATT_V") {
				$n = $n*10;
			}
			$c +=	($n%10)
				+(($n/10)%10)
				+(($n/100)%10);
		}
	}
	return $h{CHKSUM}-$c;
}

1;
