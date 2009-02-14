package HeliosX::Logger;

use 5.008;
use base qw(HeliosX::Logger);
use strict;
use warnings;

use Error qw(:try);

use HeliosX::LogEntry::Levels qw(:all);
use HeliosX::Logger::LoggingError;

our $VERSION = '0.02_0761';

=head1 NAME

HeliosX::Logger::Internal - HeliosX::Logger subclass reimplementing Helios internal logging

=head1 SYNOPSIS

 loggers=HeliosX::Logger::Internal

=head1 DESCRIPTION

This module is not yet complete, thus the documentation is not yet complete.



=cut

=head1 ACCESSOR METHODS

=cut

sub setConfig { $_[0]->{config} = $_[1]; }
sub getConfig { return $_[0]->{config}; }

sub setJobType { $_[0]->{jobtype} = $_[1]; }
sub getJobType { return $_[0]->{jobtype}; }



=head1 METHODS

=head2 init()

=cut

sub init {
	# no initialization required for the Helios internal logging system
}


=head2 logMsg()

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


1;
__END__


=head1 SEE ALSO

L<Helios::ExtLoggerService>

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

