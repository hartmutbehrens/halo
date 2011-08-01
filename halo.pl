#!/usr/bin/env perl
#
# ALU OMC-R Historical Alarms reporting tool replacement 
# August 2011 Hartmut Behrens

# perl settings part
use strict;
use Time::Local 'timelocal';
use CGI qw/:standard :html3 *table/;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

# constants
use constant DEBUG 		=> 1;
use constant VERBOSE	=> 0;
 
require "./HtmlUtils.pl";

# global variables (for changing by the user)
my $StartDay = 14;	# N days back from today
my $EndDay = 1;	# until yesterday
my $MinOccurences = 3;
my $IncludeLastDay = 1;

# static global variables
$| = 1;				# set the output autoflush
my $cmd = undef;
my $file = 'HAL.tgz' || $ARGV[0];
if ($^O =~ /linux/i) {
	$cmd = 'gunzip -c '.$file;
}
elsif ($^O =~ /solaris/i) {
	$file ='/alcatel/var/share/AFTR/HALD/HAL.tgz';
	$cmd = 'gzcat -c '.$file;
}
die "No supported command to read .tgz file found on this system!\n" unless defined $cmd;

my %Alarms = ();
my %AlarmTotals = ();
my %Severities = ();

# code entry
main();
exit;

# subroutines
sub main {
	print header();
	print HtmlHeader();
	#warningsToBrowser(1) if (DEBUG);
	
	# pop all alarms from db in hash
	my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime(time - $StartDay*(3600*24));
	my $startdate = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);
	my @hal = `$cmd`;
	foreach my $alarm (@hal) {
		my @items = split(';',$alarm);
		my $date = substr $items[0], 0, 8;
		my ($bsc, $element) = ($items[1]," ");
		if ($items[1] =~ /^(\S+)\s(.*)$/) {
			($bsc, $element) = ($1,$2);
			$element =~ s/^\d\d\-//;
		}
		my $event = $items[3] || " ";
		$event =~ s/Alarm//;
		my $cause = $items[4] || " ";
		$cause =~ s/^X\d\d\d\-//;
		$cause =~ s/^GSM\-//;
		$cause =~ s/([A-Z])/ \l$1/g;
		
		my $specific = $items[5] || " ";
		$specific =~ s/^\d+\, //;
		
		my $alrm = $event.'|'.$cause.'|'.$specific;
		my $severity = lc($items[2]);
		$severity =~ s/ \(\d\)//;
		$severity = "undefined" if ($severity =~ /indeterminate/i);
		$Alarms{$bsc}{$element}{$alrm}{$date}{$severity}++;
		my $clear_status = $items[11];
		$Alarms{$bsc}{$element}{$alrm}{$date}{"cleared"}++ if ($clear_status =~ /clear/i);
		$AlarmTotals{$bsc}{$element}++;
	}
	
	generateReports();	
	print HtmlFooter();
}


sub generateReports() {
	print h3("Alcatel GSM Alarms");
	print p("Sorted by most problematic network elements. Last Run Time: ".scalar(localtime)." on host: ".`"hostname"`);

	print table({-align=>"CENTER", -border=>1,-cellpadding=>2,-cellspacing=>1},
					caption("Settings And Alarm Color Codes (ITU)"),
					Tr(	
						td({-class=>'arg'},"Minimum repetitions: ".strong($MinOccurences)), 
						td({-class=>'arg'},"Always show alarms for last day: ".strong($IncludeLastDay?"Yes":"No")),
						td({-class => 'critical'},"Critical"),
						td({-class => 'major'},"Major"),
						td({-class => 'minor'},"Minor"),
						td({-class => 'warning'},"Warning"),
						td({-class => 'cleared'},"Cleared"),
						td({-class => 'undefined'},"Undefined")
					)
				),br(),"\n";

	print start_table({-align=>"CENTER", -border=>0,-cellpadding=>1, -cellspacing=>1}),"\n";
	print caption("Number of Alarm Occurences"), "\n";

	my $hstr = "";
	for ($EndDay .. $StartDay) {
		my (undef,undef,undef,undef,$mon,undef,undef,undef,undef) = localtime(time - $_*(3600*24));
		$hstr = th(shortMonthName($mon)).$hstr;
	}
	print Tr(th({-colspan=>2},'Network Element'),th({-colspan=>3},'Alarm'),$hstr),"\n";

	$hstr = "";
	for ($EndDay .. $StartDay) {
		my (undef,undef,undef,$mday,undef,undef,undef,undef,undef) = localtime(time - $_*(3600*24));
		$hstr = th($mday).$hstr;
	}
	print Tr(th(["BSC","Element","Type", "Probable Cause", "Specific Problem"]),$hstr),"\n";

	for my $bsc (reverse sort {$AlarmTotals{$a} <=> $AlarmTotals{$b} } keys %Alarms) {

	for my $element (sort keys %{$Alarms{$bsc}}) {

		my $object_printed = 0;

		for my $alrm (sort keys %{$Alarms{$bsc}{$element}}) {
			my $hstr = td([ ($object_printed?('',''):($bsc,$element)),(split('\|',$alrm))]);

			my $occurences = 0;
			my $occuredLastDay = 0;
			for (my $i = $StartDay; $i >= $EndDay; $i--) {
				my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime(time - $i*(3600*24));
				$mon++;
				$year += 1900;
				my $datestr = sprintf("%04d%02d%02d", $year, $mon, $mday);

				if (exists $Alarms{$bsc}{$element}{$alrm}{$datestr}) {
					my $severity = "cleared";

					# too many "undetermineds" make this unsightly					
					$hstr .= '<td>'.start_table({-width=>"100%", -border=>0, -cellpadding=>0, -cellspacing=>0 });

					for my $sev (sort keys %{$Alarms{$bsc}{$element}{$alrm}{$datestr}} ) {
						$hstr .= Tr(td({-class=>$sev},$Alarms{$bsc}{$element}{$alrm}{$datestr}{$sev}))."\n";
					}

					$hstr .= end_table().'</td>';
					
					$occurences++;
					
					if (($i == $EndDay) && $IncludeLastDay) {
						$occuredLastDay++;
					}
				}
				else {
					$hstr .= td('');
				}
			}
			if (($occurences >= $MinOccurences) || ($occuredLastDay)) {
				print Tr($hstr),"\n";
				$object_printed++;
			}
		}
		print Tr()."\n" if ($object_printed);
	}
	}

	print end_table(),br(),"\n";
}

sub shortMonthName {
	my ($mindex) = @_;
	my @mnames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	if ($mindex < scalar @mnames) {
		return $mnames[$mindex];
	}
	return "???";
}

__END__
