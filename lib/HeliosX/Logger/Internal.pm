package HeliosX::Logger::Internal;

use 5.008;
use base qw(HeliosX::Logger);
use strict;
use warnings;

use Error qw(:try);

use HeliosX::LogEntry::Levels qw(:all);

our $VERSION = '0.02_0771';

=head1 NAME

HeliosX::Logger::Internal - HeliosX::Logger subclass reimplementing Helios internal logging

=head1 SYNOPSIS

 #in your service class
 package MyService;
 use base qw(HeliosX::ExtLoggerService);
 
 #in helios.ini, enable internal Helios logging (this is default)
 internal_logger=on
 
 #in helios.ini, turn off internal logging
 internal_logger=off


=head1 DESCRIPTION

HeliosX::Logger::Internal is a refactor of the logging functionality found in 
Helios::Service->logMsg().  This allows HeliosX::ExtLoggerService-based services to retain 
logging functionality found in the core Helios system while also taking advantage of external 
logging systems implemented by other subclasses of HeliosX::Logger.

=head1 IMPLEMENTED METHODS

=head2 init()

HeliosX::Logger::Internal->init() is empty, as an initialization step is unnecessary.

=cut

sub init { }


=head2 logMsg($job, $priority_level, $message)

Implementation of the Helios::Service internal logging code refactored into a 
HeliosX::Logger class.  

=cut

sub logMsg {
	my $self = shift;
	my $job = shift;
	my $level = shift;
	my $msg = shift;

	my $params = $self->getConfig();
	my $jobType = $self->getJobType();
	my $hostname = $self->getHostname();

	my $retries = 0;
	my $retry_limit = 3;
	RETRY: {
		try{
			my $driver = $self->getDriver();
			my $log_entry;
			if ( defined($job) ) {
				$log_entry = Helios::LogEntry->new(
					log_time   => time(),
					host       => $self->getHostname,
					process_id => $$,
					jobid      => $job->getJobid,
					funcid     => $job->getFuncid,
					job_class  => $jobType,
					priority   => $level,
					message    => $msg
				);
			} else {
				$log_entry = Helios::LogEntry->new(
					log_time   => time(),
					host       => $self->getHostname,
					process_id => $$,
					jobid      => undef,
					funcid     => undef,
					job_class  => $jobType,
					priority   => $level,
					message    => $msg
				);
			}
			$driver->insert($log_entry);		

		} otherwise {
			my $e = shift;
			if ($retries > $retry_limit) {
				throw Helios::Error::DatabaseError($e->text());
			} else {
				# we're going to give it another shot
				$retries++;
				sleep 5;
				next RETRY;
			}
		};
	}
	# retry block end
	return 1;
}

=head1 OTHER METHODS

=head2 getDriver()

Returns a Data::ObjectDriver object for use with the Helios database.

=cut

sub getDriver {
    my $self = shift;
    my $config = $self->getConfig();
    my $driver = Data::ObjectDriver::Driver::DBI->new(
        dsn      => $config->{dsn},
        username => $config->{user},
        password => $config->{password}
    );  
    return $driver; 
}


1;
__END__


=head1 SEE ALSO

L<HeliosX::ExtLoggerService>, L<HeliosX::Logger>

=head1 AUTHOR

Andrew Johnson, E<lt>ajohnson at ittoolbox dotcomE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

