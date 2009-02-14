package HeliosX::Logger::Syslog;

use 5.008;
use base qw(HeliosX::Logger);
use strict;
use warnings;

use Sys::Syslog;

our $VERSION = '0.02_0761';

=head1 NAME

HeliosX::Logger::Syslog - HeliosX::Logger subclass implementing logging to syslogd for Helios

=head1 SYNOPSIS

 # helios.ini
 loggers=HeliosX::Logger::Syslog
 syslog_facility=user
 syslog_options=nofatal,pid 
 


=head1 DESCRIPTION

This module is not yet complete, thus the documentation is not yet complete.


=head1 CONFIGURATION

Config options:

=over 4

=item syslog_facility [REQUIRED]



=item syslog_options



=back

=head1 METHODS

=head2 init($config, $jobType)

The init() method verifies that the required helios.ini parameters (syslog_facility) are set for 
HeliosX::Logger::Syslog.  Without the proper parameter(s), HeliosX::Logger::Syslog will not 
function properly.

=cut

sub init {
	my $self = shift;
	my $config = shift;
	my $jobType = shift;
	$self->setConfig($config);
	$self->setJobType($jobType);
	unless ( defined($config->{syslog_facility}) ) {
		throw HeliosX::Error::LoggingError("CONFIGURATION ERROR: syslog_facility not defined"); 
	}
	return 1;
}


=head2 logMsg($job, $log_level, $message)

=cut

sub logMsg {
	my $self = shift;
	my $job = shift;
	my $priority = shift;
	my $msg = shift;
	
	openlog($self->getJobType(), $self->getConfig()->{syslog_options}, $self->getConfig()->{syslog_facility});
	syslog($priority, $msg);
	closelog();
}


1;
__END__


=head1 SEE ALSO

L<HeliosX::ExtLoggerService>, L<Helios::Service>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Andrew Johnson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut
