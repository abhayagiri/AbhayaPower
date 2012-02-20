#!/usr/bin/perl
use strict;
use warnings;
use CGI qw(:standard);

##
#	To add a new page to be linked to on this page just add
#	the file's name below with it's link text by it like the others.
##
my %pages = (
	"voltm.pl" => "Volt Log: by minute.",
	"volth.pl" => "Volt Log: by hour.",
	"loadm.pl" => "Watt Log: by minute.",
	"loadh.pl" => "Watt Log: by hour.",
);

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

## Start generating page here
print
	header,
	start_html(
		-title=>$cfg{WEBTITLE},
		-style=>{'src'=>'class.css'},
		); print
	div(
		{-class=>'title'},
		$cfg{WEBTITLE}),
	br,
	div(
		{-class=>'index'},
		pageIndexTable(\%pages)),
	br,
	div(
		{-class=>'status'},
		ledStatusImg($cfg{STATUSLOG},'status.pl')),
	end_html;
