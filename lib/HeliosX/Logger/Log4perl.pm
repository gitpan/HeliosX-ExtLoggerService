package HeliosX::Logger::Log4perl;

use 5.008;
use base qw(HeliosX::Logger);
use strict;
use warnings;

use Log::Log4perl;

use HeliosX::LogEntry::Levels qw(:all);
use HeliosX::Logger::LoggingError;

our $VERSION = '0.02_0761';

=head1 NAME

HeliosX::Logger::Log4perl - HeliosX::Logger subclass implementing logging to Log4perl for Helios

=head1 SYNOPSIS

 # helios.ini
 loggers=HeliosX::Logger::Log4perl
 log4perl_conf=/path/to/log4perl.conf
 log4perl_category=logging.category
 log4perl_watch_interval=10
 


=head1 DESCRIPTION

This module is not yet complete, thus the documentation is not yet complete.


=head1 CONFIGURATION

Config options:

=over 4

=item log4perl_conf [REQUIRED]


=item log4perl_category [REQUIRED]


=item log4perl_watch_interval



=back

=head1 METHODS

=head2 init($config, $jobType)

The init() method verifies that the required helios.ini parameters (log4perl_conf, 
log4perl_category) are set for HeliosX::Logger::Log4perl.    


=cut


sub init {
	my $self = shift;
	my $config = shift;
	my $jobtype = shift;

	unless ( defined($config->{log4perl_conf}) && defined($config->{log4perl_category}) ) {
		throw HeliosX::Logger::LoggingError('CONFIGURATION ERROR: log4perl_conf not defined');
	}
	
	if ( defined($config) && defined($jobtype) ) {
		$self->setConfig($config);
		$self->setJobType($jobtype);
	}

	if ( defined($config->{log4perl_watch_interval}) ) {
		Log::Log4perl::init_and_watch($config->{log4perl_conf}, $config->{log4perl_watch_interval});
	} else {
		Log::Log4perl::init($config->{log4perl_conf});
	}
}


sub logMsg {
	my $self = shift;
	my $job = shift;
	my $level = shift;
	my $msg = shift;

	# has log4perl been initialized yet?
	unless ( Log::Log4perl->initialized() ) {
		$self->init();
	}
		
	my $logger = Log::Log4perl->get_logger();	#[]
	
	if ( defined($level) ) {
		SWITCH: {
			if ($level eq LOG_DEBUG) { $logger->debug($msg); last SWITCH; }
			if ($level eq LOG_INFO || $level eq LOG_NOTICE) { $logger->info($msg); last SWITCH; }
			if ($level eq LOG_WARNING) { $logger->warn($msg); last SWITCH; }
			if ($level eq LOG_ERR) { $logger->error($msg); last SWITCH; }
			if ($level eq LOG_CRIT || $level eq LOG_ALERT || $level eq LOG_EMERG) { 
				$logger->fatal($msg); 
				last SWITCH; 
			}
			throw HeliosX::Logger::LoggingError('Invalid log level '.$level);			
		}
	} else {
		# $level wasn't defined, so we'll default to INFO
		$logger->info($msg);
	}
	return 1;
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
