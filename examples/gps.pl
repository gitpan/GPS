#!/usr/bin/perl
#
# Written by Travis Kent Beste
# Fri Aug  6 07:53:53 CDT 2010

use lib qw( ./lib ../lib );
use GPS;
use strict;
use warnings;
use Data::Dumper;

$|++; # unbuffered i/o

#----------------------------------------#
# new objects
#----------------------------------------#
my $g = new GPS(
	Port => '/dev/tty.BT-GPS-38BD5D-BT-GPSCOM',
	Baud => '115200',
);
my $rmc = new GPS::NMEA::GP::RMC();
my $gsa = new GPS::NMEA::GP::GSA();
my $gga = new GPS::NMEA::GP::GGA();
my $gsv = new GPS::NMEA::GP::GSV();
my $gll = new GPS::NMEA::GP::GLL();
my $vtg = new GPS::NMEA::GP::VTG();

$g->GPS::log('./log/all.log');
$rmc->GPS::log('./log/rmc.log');
$gsa->GPS::log('./log/gsa.log');
$gsv->GPS::log('./log/gsv.log');
$gll->GPS::log('./log/gll.log');
$vtg->GPS::log('./log/vtg.log');
$gga->GPS::log('./log/gga.log');

#----------------------------------------#
# parse...
#----------------------------------------#
while(1) {
	my $sentances = $g->get_sentances();

	foreach my $sentance (@$sentances) {
		if ($sentance =~ /^\$GPGSA/) {
			$gsa->parse($sentance);
			#$gsa->print();
		} elsif ($sentance =~ /^\$GPRMC/) {
			$rmc->parse($sentance);
			#$rmc->print();
		} elsif ($sentance =~ /^\$GPGGA/) {
			$gga->parse($sentance);
			#$gga->print();
		} elsif ($sentance =~ /^\$GPGSV/) {
			$gsv->parse($sentance);
			#$gsv->print();
		} elsif ($sentance =~ /^\$GPGLL/) {
			$gll->parse($sentance);
			#$gll->print();
		} elsif ($sentance =~ /^\$GPVTG/) {
			$vtg->parse($sentance);
			#$vtg->print();
		} else {
			#print "sentance : $sentance\n";
		}
	}

}

exit(0);
