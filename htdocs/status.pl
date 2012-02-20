#!/usr/bin/perl
use strict;
use warnings;
use CGI qw(:standard);

## Open and parse config file
our %cfg;
BEGIN {
        open (INPUT,'<',"/etc/abhayapower");
        foreach (<INPUT>) {
                if (substr($_,0,1) ne "#") {
			chomp $_;
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
		);
print
	div(	{class=>'title'},
		'Status',),
	br,
	div(	ledStatusImg($cfg{STATUSLOG},'index.pl')),
	br,
	div(	{class=>'statusTable'},
		ledStatusTable($cfg{STATUSLOG})),
	br,
	div(	{class=>'statusNotes'},
			table(Tr([
			td([" $cfg{'STATUS_-3_TEXT'} "]),
			td([" $cfg{'STATUS_-2_TEXT'} "]),
			td([" $cfg{'STATUS_-1_TEXT'} "]),
			td([" $cfg{'STATUS_0_TEXT'} "]),
			td([" $cfg{'STATUS_1_TEXT'}"]),
			]))),
	br,
	div(	linkToIndex),
	end_html;
