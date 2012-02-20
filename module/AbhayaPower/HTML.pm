#!/usr/bin/perl
package AbhayaPower::HTML;

use strict;
use warnings;
use AbhayaPower;
use Exporter;
use CGI qw(:standard);
use vars qw(@ISA @EXPORT);

@ISA = ('Exporter');
@EXPORT = (qw(
	graphMinutesConfig
	graphHoursConfig
	pageIndexTable
	ledStatusImg
	ledStatusTable
	graphUserEntry
	linkToIndex
	useJSLib
));

# returns html for Configuration inputs for time and color
sub graphUserEntry {
	my %time = %{$_[0]};
	my $printCheck = $_[1];
	my $timeType = $_[2];
	my $ret;

	# Keep checkbox checked or not checked based on current setting
	if ($printCheck eq "on") {
		$printCheck = input( {-type=>'checkbox',
				-name=>'print',
				-checked=>'true'});
	} else {
		$printCheck = input( {-type=>'checkbox',
				-name=>'print',});
	}

	# Make a hash of the code for displaying the time fields
	my %timeInput = ();
	foreach (keys %time) {
		$timeInput{$_} = 
	       	        input(
        	                {-name=>$_,
                	        -value=>"$time{$_}",
                        	-size=>length $time{$_},
                        	-maxlength=>length $time{$_}});
	}


	# Create a new form for input
	$ret = 
		start_form(
				-name=>'graphCfg',
        	                -method=>'GET',);
	# add time inputs to the form
	$ret .=
			$timeInput{YEAR}.' / '.
			$timeInput{MONTH}.' / '.
			$timeInput{DAY}.'&nbsp;';
	# only include hours field for minutely graphs
	if ($_[2] eq "M") {
		$ret .= "$timeInput{HOUR}".tt(':00 UTC');
	}

	# Add print checkbox
	$ret .=	br.$printCheck.'Light Background<br>';

	# Add buttons.  One for normal submit, one for current time,
	# and one for reset
	$ret .= input(
			{-type=>'submit',
			-value=>'Submit'});
	$ret .=	input(
				{-type=>'submit',
				-value=>'Current',
				-onClick=>'javascript:disableTime()', });
	$ret .=	input(
			{-type=>'reset',
			-value=>'Reset'}),
			end_form;
	return div({-align=>'center'},$ret);
}


## Converts data into the format needed by the javascript library RGraph
# arguments as listed in the first lines of this subroutine.
sub graphMinutesConfig {
	my $title = $_[0];	# Name of graph
	my %log   = %{$_[1]};	# log to graph
	my $logKey   = $_[2];	# what part of the log to graph (IE: FX_BATT_V)
	my %cfg   = %{$_[3]};	# configuration hash used by all AbhayaPower
	my %time  = %{$_[4]};	# time hash returned by getTime
	my $unit  = $_[5];	# unit suffix to use for tooltips and axis
	my $graphKey  = $_[6];	# names for the legend on the graph
	my $print = $_[7];	# use print color scheme or not
	my $ymin = $_[8];	# default y axis bottom
	my $ymax = $_[9];	# ... and top

	my %ret;

	# Get locale's date for this log and finish title
	my $dateCall = "date -d \"$time{YEAR}-$time{MONTH}-$time{DAY} $time{HOUR} UTC\" +%D\\ %l:00\\ %p\\ %Z";
	$dateCall = `$dateCall`;
	chomp $dateCall;
	$ret{TITLE} = "'$title $dateCall'";

	# Get graph data in correct format
	$ret{DATA} = graphMinutesData(\%log, $logKey,$cfg{INVNUM});

	# Add unit to return hash...	
	$ret{UNIT} = "'$unit'";

	# Generate graph legend data
	$ret{KEY} = '';
	for (my $i = 1; $i <= $cfg{INVNUM}; $i++) {
		$ret{KEY} .= "['FX$i'],";
	}
	## Quick fix to make first line Average for minutely watts
	if ($unit eq "W") {
		$ret{KEY} = "[['TOTAL'],$ret{KEY}]";
	}
	else {
		$ret{KEY} = "[$ret{KEY}]";
	}
	# Generate color data
	my (%color,$sat,$lit);
	if ($print eq "on") {
	        $sat = '50%';
	        $lit = '35%';
	        $color{bg} = "'rgb(255,255,255)'";
	} else {
	        $sat = '75%';
	        $lit = '45%';
	        $color{bg} = "'rgb(32,32,32)'";
	}
	$color{fg} = "'rgb(95,95,95)'";
	$color{chart} = "[
	                'hsl(0,$sat,$lit',
	                'hsl(96,$sat,$lit',
	                'hsl(192,$sat,$lit)']";
	my $jsColor = '';
	foreach (keys %color) {
	        $jsColor .= "$_: $color{$_},";
	} 
	$ret{COLOR} = "{$jsColor}";

	# Y axis minimum/maximum defaults (will expand if needed to)
	$ret{YMIN} = $ymin;
	$ret{YMAX} = $ymax;

	return %ret;
}

# See graphMinutesConfig...
sub graphHoursConfig {
        my $title = $_[0];	# Name of graph
        my @log   = @{$_[1]};	# log to graph
	my $logKey   = $_[2];	# what part of the log to graph (IE: FX_BATT_V)
        my %time  = %{$_[3]};	# time hash returned by getTime
        my $unit  = $_[4];	# unit suffix for graph
        my @graphKey  = @{$_[5]};	# legend for graph
        my $print = $_[6];	# useing print colors or not?
        my $ymin = $_[7];	# y axis low default
        my $ymax = $_[8];	# and high default
	my %cfg = %{$_[9]};	# configuration hash

        my %ret;

        # Get locale's date for this log and finish title
	my $dateBuf = `date -d "$time{YEAR}$time{MONTH}$time{DAY} 00:00 UTC" "+%D %l:%M %p %Z"`;
	chomp $dateBuf;
	my $dispDate = "from $dateBuf through ";
	$dateBuf = `date -d "$time{YEAR}$time{MONTH}$time{DAY} 23:59 UTC" "+%D %l:%M %p %Z"`;
	chomp $dateBuf;
	$dispDate .= $dateBuf;
        $ret{TITLE} = "'$title $dispDate'";

        # Get graph data in correct format
        $ret{DATA} = graphHoursData(\@log, $logKey, \%time, \%cfg);

        # Add unit to return hash...    
        $ret{UNIT} = "'$unit'";

        # Generate graph legend data
        $ret{KEY} = '';
	foreach (@graphKey) {
                $ret{KEY} .= "'$_',";
        }
        $ret{KEY} = "[$ret{KEY}]";

        # Generate color data
        my (%color,$sat,$lit);
        if ($print eq "on") {
                $sat = '50%';
                $lit = '35%';
                $color{bg} = "'rgb(255,255,255)'";
        } else {
                $sat = '75%';
                $lit = '45%';
                $color{bg} = "'rgb(32,32,32)'";
        }
        $color{fg} = "'rgb(95,95,95)'";
        $color{chart} = "[
                        'hsl(0,$sat,$lit',
                        'hsl(96,$sat,$lit',
                        'hsl(192,$sat,$lit)']";
        my $jsColor = '';
        foreach (keys %color) {
                $jsColor .= "$_: $color{$_},";
        } 
        $ret{COLOR} = "{$jsColor}";

        # Y axis minimum/maximum defaults (will expand if needed to)
        $ret{YMIN} = $ymin;
        $ret{YMAX} = $ymax;

        return %ret;
}


## parses log data into arrays
sub graphMinutesData {
	my %h = %{$_[0]};
	my $key = $_[1];
	my $invNum = $_[2];
	my @data;

	for (my $i = 0; $i <= 60; $i++) {
		for (my $j = 0; $j <= $invNum; $j++) {
			$data[$j][$i] = "";
		}
	}

	my $l = $invNum;
	foreach (sort keys %h) {
		my $m = substr($_,10,2);
	        for (my $j = 0; $j < $l; $j++) {
			if (defined($h{$_}[$j+1]{$key}) && !$h{$_}[$j+1]{CHKSUM_ERR}) {
		                $data[$j][$m] = $h{$_}[$j+1]{$key};
				if ($key eq "INV_CRNT") {
					$data[$j][$m] = $data[$j][$m]*$h{$_}[$j+1]{AC_OUT_V};
				}
			} else {
		                $data[$j][$m] = "";
			}
				
			# remove any leadings zeros (else javascript reads as
			# as an octal number)
			if ($data[$j][$m] != 0 || $key eq "FX_BATT_V") {
				$data[$j][$m] =~ s/^0+//;
			}
	        }
	}

	# calculate totals for each battery
	for ( my $m = 0; $m < 60; $m++) {
		my $sum;
		for (my $j = 0; $j < $l; $j++) {
			$sum += $data[$j][$m] if ($data[$j][$m] ne "");
		}
		$data[$l][$m] = $sum;
	}

	my $ret = "";
	# format data as array for javascript
	if ($key eq "INV_CRNT") {
		$ret = '['.join(',',@{$data[$l]}).'],';
	}
	my $j = 0;
	foreach (@data) {
		if ($j < $l) {
			$ret .= '['.join(',',@{$_}).'],';
		}
		$j++;
	}
	$ret = "[$ret]";
	

	return $ret;
}

# returns arrays of hourly data
sub graphHoursData {
	my @a = @{$_[0]};
	my $key = $_[1];
	my %cfg = %{$_[3]};
	my %time = %{$_[2]};
	my %data;

	# load minutes log to get current hour running avg
	my @ml = loadMateLog($cfg{LOGDIR},\%time);
	my %mh = parseMateLog(\@ml,$cfg{INVNUM});

	my $i = 0;
	foreach (@a) {
		my %h = %{$_};
		foreach (keys %h) {
			my $j = 0;
			if ( $key eq substr($_,0,length $key)) {
				$data{$_}[$i] = $h{$_};	
				if ($key eq "INV_CRNT" && $data{$_}[$i]) {
					$data{$_}[$i] *= 120;
				}
			}
		#	if ( $key eq
		}
		$i++;
	}

	# get this hour's values
	if ($key eq "FX_BATT_V") {
		$data{FX_BATT_V_AVG}[$time{HOUR}] = getHourVolt(\%mh,"AVG");
		$data{FX_BATT_V_MIN}[$time{HOUR}] = getHourVolt(\%mh,"MIN");
		$data{FX_BATT_V_MAX}[$time{HOUR}] = getHourVolt(\%mh,"MAX");
	}
	if ($key eq "INV_CRNT") {
		$data{INV_CRNT_AVG}[$time{HOUR}] = getHourLoad(\%mh,"AVG","W");
		$data{INV_CRNT_MIN}[$time{HOUR}] = getHourLoad(\%mh,"MIN","W");
		$data{INV_CRNT_MAX}[$time{HOUR}] = getHourLoad(\%mh,"MAX","W");
	}

	my $ret = '';
	foreach (sort keys %data) {
		for (my $i = 0; $i <= 24; $i++) {
			if (!defined $data{$_}[$i]) {
				$data{$_}[$i] = "";
			}
		}
		$ret .= '['.join(',',@{$data{$_}}).'],';
	}
	$ret = "[$ret]";

	return $ret;
}

# return array of RGraph libs for start_html to use
sub useJSLib {
	my @a;
	my $i = 0;
	foreach(@_) {
		if (-e "lib/$_") {
			$a[$i++] = {	-type => 'text/javascript',
					-src => "lib/$_" };
		}
	}
	return [@a];
}

# return link to index page
sub linkToIndex {
	return
                div(	{-align=>'center'},
			a(      {href=>'.'},
                	'Return to Index'))
}
 
# subroutine for providing alt text and rollover text for LED simulation image
sub ledStatusString {
	# load and parse status log
	my ($s,%shash,$str);
	my $slog = loadStatusLog($_[0]);
	if ($slog ne '1') {
	        %shash = parseStatusLog($slog);
	        $s = getStatus(\%shash);
	}
        if    ($s == -3)        { $str =  "Fast Blinking Red"    }
        elsif ($s == -2)        { $str = "Slow Blinking Red"    }
        elsif ($s == -1)        { $str = "Solid Red"            }
        elsif ($s == 0)         { $str =  "Blue"                 }
        elsif ($s == 1)         { $str = "Green"                }
        else                    { $str = "UNKNOWN"              }
	
	return $s,$str;
}

# returns the code for the status led image on the index page, pass it
# the path to the status log file and a url to link to as the first and
# second arguments respectively
sub ledStatusImg {
	my @s = ledStatusString($_[0]);
	my $linkTo = $_[1];

	return 	a(	{href=>$linkTo},
			img( 	{src=>"gfx/status_$s[0].gif",
				align=>'CENTER',
				alt=>"Status is $s[1]",
				title=>"Status is $s[1]",}));
}

# table of status info for status.pl
sub ledStatusTable {
	# load and parse status log
	my $l = loadStatusLog($_[0]);
	my %h = parseStatusLog($l);
	return	
		table(
			Tr([
				td(['<div class="mouseover" title="Hours with average '.
					'less than 47.6V over the past 12 hours.">'.
					'VVWEAK</div>',
					$h{VVWEAK}]),
				td(['<div class="mouseover" title="Hours with average '.
					'less than 48.2V over the past 12 hours.">'.
					'VWEAK</div>',
					$h{VWEAK}]),
				td(['<div class="mouseover" title="Hours with average '.
					'less than 49.0V over the past 12 hours.">'.
					'WEAK</div>',
					$h{WEAK}]),
				td(['<div class="mouseover" title="Hours with average '.
					'greater than 50.0V over the past 24 hours.">'.
					'STRONG</div>',
					$h{STRONG}]),
				td(['<div class="mouseover" title="Hours with average '.
					'greater than 52.0V over the past 24 hours.">'.
					'VSTRONG</div>',
					$h{VSTRONG}]),
				td(['<div class="mouseover" title="Hours with average '.
					'greater than 50.0V over the past 4 hours.">'.
					'RECENT</div>',
					$h{RECENT}]),
				td(['<div class="mouseover" title="Status code calculated as'.
					' shown below.">STATUS</div>',
					$h{STATUS}]),]));
				
}

# reads a hash where keys are file names and values are descriptions
# and returns a list of links
sub pageIndexTable {
	my $ret = "";
	my %h = %{$_[0]};
	foreach (reverse sort keys %h) {
		if (-e $_) {
			$ret  .= a({-href=>$_},$h{$_}).br;	
		}
	}
	$ret;
}

1;
