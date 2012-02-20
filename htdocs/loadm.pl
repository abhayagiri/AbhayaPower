#!/usr/bin/perl
use strict;
use warnings;
use CGI qw(:cgi-lib :standard);

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
use AbhayaPower::HTML;

# get CGI parameters
my %param = Vars;

# get color schcme value
my $print;
if (defined $param{'print'}) {
	$print = $param{'print'};
} else {
	$print = "off"
}
# configure time to get data for
my %time  = getTime;
if (defined $param{'YEAR'} )
	{ $time{YEAR}  = sprintf("%04d",$param{'YEAR'}) }
if (defined $param{'MONTH'})
	{ $time{MONTH} = sprintf("%02d",$param{'MONTH'}) }
if (defined $param{'DAY'})
	{ $time{DAY}   = sprintf("%02d",$param{'DAY'}) }
if (defined $param{'HOUR'})
	{ $time{HOUR}  = sprintf("%02d",$param{'HOUR'}) }

## retrieve data from logs
my (%mlog,@ml);
@ml = loadMateLog($cfg{LOGDIR},\%time);
%mlog = parseMateLog(\@ml,$cfg{INVNUM});

## Configure graph function arguments
my %gCfg = graphMinutesConfig(
	"Wattage Log: by the minute",	# Graph Title
	\%mlog,				# hash reference to the data log
	"INV_CRNT",			# key to graph for in data log
	\%cfg,				# configuration hash reference
	\%time,				# time hash
	"W","FX",			# Voltage and graph legend prefix
	$print,				# Graph color scheme (print or not)
	0,4000);				# Default min and max y-axis values

## Start generating page here
print
	header,
	start_html(
		-title=>$cfg{WEBTITLE},
		-style=>{'src'=>'class.css'},
		-onLoad=>"graphData($gCfg{DATA},$gCfg{UNIT},$gCfg{TITLE},$gCfg{KEY},$gCfg{COLOR},$gCfg{YMIN},$gCfg{YMAX});",
		-script=>useJSLib(
			'RGraph/libraries/RGraph.common.core.js',
			'RGraph/libraries/RGraph.common.tooltips.js',
			'RGraph/libraries/RGraph.common.context.js',
			'RGraph/libraries/RGraph.line.js',
			'abhayaPower.js',		
		));

# Canvas graph will be drawn on (only if log exists)
if (%mlog) {
	print	
		div( '<canvas id="graph">[No Canvas Support]</canvas>'),br;
}

# Configuration inputs
print
	graphUserEntry(\%time,$print,'M'),br;

print
	linkToIndex,
	end_html;
