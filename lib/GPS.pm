#
# Written by Travis Kent Beste
# Fri Aug  6 14:26:05 CDT 2010

package GPS;

use strict 'refs';
use vars qw( );

use RingBuffer;
use GPS::Serial;
use GPS::NMEA::GP::GSA;
use GPS::NMEA::GP::GLL;
use GPS::NMEA::GP::GGA;
use GPS::NMEA::GP::GSV;
use GPS::NMEA::GP::RMC;
use GPS::NMEA::GP::VTG;

use Data::Dumper;
use IO::File;

our @ISA     = qw(RingBuffer GPS::Serial GPS::NMEA::GP::RMC GPS::NMEA::GP::GSA GPS::NMEA::GP::GGA GPS::NMEA::GP::GSV GPS::NMEA::GP::GLL GPS::NMEA::GP::VTG);

our $VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

#----------------------------------------#
# capture control-c
#----------------------------------------#
my $control_c_counter = 0;
$SIG{INT} = \&my_control_c;
sub my_control_c {
	$SIG{INT} = \&my_control_c;

	print "finishing up...";

	$control_c_counter++;
	if ($control_c_counter == 1) {
		print "done\n";
		exit();
	}
}

#----------------------------------------#
#
#----------------------------------------#
sub new {
	my $class = shift;
	my %args = @_;

	my %fields = (
		log_fh         => '',
		log_filename   => '',

		serial         => '',
		serialport     => $args{'Port'},
		serialbaud     => $args{'Baud'},
		serialtimeout  => 5,  # 5 second timeout
		serialline     => '', # the line that we're parsing, so it doesn't get lost

		ringbuffer     => '',
		ringbuffersize => 4096,
		verbose        => 1,
	);

	my $self = {
		%fields
	};
	bless $self, $class;

	# initialize the ringbuffer
	my $buffer            = [];
	my $ringsize          = $self->{ringbuffersize};
	my $overwrite         = 0;
	my $printextendedinfo = 0;
	my $r = new RingBuffer(
		Buffer            => $buffer,
		RingSize          => $ringsize,
		Overwrite         => $overwrite,
		PrintExtendedInfo => $printextendedinfo,
	);
	$r->ring_init();
	$r->ring_clear();
	$self->{ringbuffer} = $r;

	# connect to serial port
	$self->connect();

	return $self;
}

#----------------------------------------#
#
#----------------------------------------#
sub DESTROY {
	my $self = shift;

	if ($self->{serial}) {
		$self->{serial}->close || die "failed to close serialport";
		undef $self->{serial}; # frees memory back to perl
	}

	$self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

#----------------------------------------#
#
#----------------------------------------#
sub log {
	my $self     = shift;
	my $filename = shift;

	# set the filename in the object
	$self->{log_filename} = $filename;

	# create a new file handle object because the other objects use this and 
	# they end up sharing the same handle if we use a glob
	my $fh = new IO::File->new;

	# generic open and unbuffered I/O
	open($fh, ">" . $self->{log_filename});
	select($fh), $| = 1; # set nonbuffered mode, gets the chars out NOW
	$self->{log_fh} = (*$fh);
	select(STDOUT);
}

#----------------------------------------#
#
#----------------------------------------#
sub get_sentances {
	my $self = shift;

	my $sentances = $self->GPS::Serial::_readlines();

	# if we're logging, save data to filehandle
	if ($self->{log_fh}) {
		foreach my $sentance (@$sentances) {
			print { $self->{log_fh} } $sentance . "\n";
		}
	}

	return $sentances;
}

1;

__END__

=head1 NAME

GPS - Perl interface to GPS equipment that output data on a serial port.

=head1 SYNOPSIS

use GPS;

# overall gps object
my $gps = new GPS( 'Port' => '/dev/ttyS0', 'Baud' => 9600 );

# gga object
my $gga = new GPS::NMEA::GP::GGA;

while (1) {

	my $sentances = $gps->get_sentance();

	foreach my $sentance (@sentances) {

		if ($sentance =~ /^\$GPGGA/) {
			$gga->parse($sentance);
			$gga->print();
		}
	}
}

=head1 DESCRIPTION

GPS allow the connection and use of of a GPS receiver in perl scripts.
Currently only the NMEA is implemented.

This module currently works with all gps devies that output a serial stream of
NMEA data

=head1 KNOWN LIMITATIONS

There is no port to Windows.

=head1 BUGS

none known

=head1 AUTHOR

Travis Kent Beste, travis@tencorners.com

=head1 COPYRIGHT

Copyright 2010 Tencorners, LLC.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
        
=head1 SEE ALSO

Travis Kent Beste's GPS www site
http://www.travisbeste.com/software/gps

perl(1).

RingBuffer.pm.

Device::SerialPort.pm.

=cut
