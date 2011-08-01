#!/usr/bin/perl -w
#!c:/Perl/bin/Perl.exe -w

# HTML settings
use constant CLR_BG_TH			=> "#dcdcdc";
use constant CLR_BG_TD			=> "#FFFFFF";
use constant CLR_BG_TD_ARG		=> "#e0ffff";
use constant CLR_FONT			=> "#000000";
use constant CLR_BG				=> "#77ccff";
use constant TABLE_WIDTH		=> 780;

# itu spec:
use constant CLR_WARNING		=> "#FFFF00";
use constant CLR_MAJOR			=> "#FFA500";
use constant CLR_MINOR			=> "#00FFFF";
use constant CLR_CLEARED		=> "#90EE90";
use constant CLR_CRITICAL		=> "#FF0000";
use constant CLR_UNDEFINED		=> "#87CEFA";

sub HtmlHeader() {
	return start_html(-title=>'Alarms History',
				-author=>'hartmut.behrens@gmail.com',
				-age=>'0',
				-meta=>{'http-equiv'=>'no-cache','copyright'=>'H Behrens'},
				-BGCOLOR=>(CLR_BG),
				-style=>{'code'=>
				"p {font-size: 75%; font-family: sans-serif; text-align: center}\n".
				"h2 {font-family: sans-serif; font: italic; text-align: center}\n".
				"h3 {font-family: sans-serif; font: italic; text-align: center}\n".
				"th {background: ".(CLR_BG_TH)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif}\n".
				"th.warning {background-color: ".(CLR_WARNING).";}\n".
				"td {background-color: ".(CLR_BG_TD)."; color: ".(CLR_FONT)."; font-size: 75%; font-family: sans-serif; text-align: left}\n".
				"td.blank {background: transparent;}\n".

				"td.warning {background-color: ".(CLR_WARNING).";}\n".
				"td.critical {background-color: ".(CLR_CRITICAL).";}\n".
				"td.major {background-color: ".(CLR_MAJOR).";}\n".
				"td.minor {background-color: ".(CLR_MINOR).";}\n".
				"td.undefined {background-color: ".(CLR_UNDEFINED).";}\n".
				"td.cleared {background-color: ".(CLR_CLEARED).";}\n".

				"td.arg {background-color: ".(CLR_BG_TD_ARG).";}\n".
				"table.cl {width: \"100%\"; border: 0; cellspacing: 0; cellpadding: 0}\n".
				"caption {font-family: sans-serif; font: bold italic; font-size: 75%; text-align: center}\n"
		}); 
}

sub HtmlFooter() {
	return end_html();
}

sub HtmlItuColors() {
	return table({-align=>"CENTER", -border=>1,-cellpadding=>1, -cellspacing=>1} ,caption("ITU Alarm Color Codes"),
		Tr(
			td({-class => 'critical'},"Critical"),
			td({-class => 'major'},"Major"),
			td({-class => 'minor'},"Minor"),
			td({-class => 'warning'},"Warning"),
			td({-class => 'cleared'},"Cleared"),
			td({-class => 'undefined'},"Undefined"),
		)
		),"\n";
}

1;
