package HeliosX::ExtLoggerService;

use 5.008;
use base qw(Helios::Service);
use strict;
use warnings;

use Helios::Error;
use HeliosX::LogEntry::Levels qw(:all);
use HeliosX::Logger::LoggingError;

our $VERSION = '0.02_0761';

our %INIT_LOG_CLASSES;

=head1 NAME

HeliosX::ExtLoggerService - Alternative Helios::Service class to log to external logging systems

=head1 SYNOPSIS

  package YourHeliosService;
  use base qw(HeliosX::ExtLoggerService);
  use strict;
  use warnings;
  ...etc...

=head1 DESCRIPTION

This module is not yet complete, thus the documentation is not yet complete.



=cut


=head1 METHODS

=head2 logMsg()

=cut

sub logMsg {
	my $self = shift;
	my @args = @_;
	my $job;
	my $level;
	my $msg;

	# were we called with 3 params?  ($job, $level, $msg)
	# 2 params?                      ($level, $msg) or ($job, $msg)
	# or just 1?                     ($msg)

	# is the first arg is a Helios::Job object?
	if ( ref($args[0]) && $args[0]->isa('Helios::Job') ) {
		$job = shift @args;
	}

	# if there are 2 params remaining, the first is level, second msg
	# if only one, it's just the message 
	if ( defined($args[0]) && defined($args[1]) ) {
		$level = $args[0];
		$msg = $args[1];
	} else {
		$level = LOG_INFO;	# default the level to LOG_INFO
		$msg = $args[0];
	}
	
	my $config = $self->getConfig();
	my $jobType = $self->getJobType();
	my $hostname = $self->getHostname();

	my @extLoggers = split(/,/, $config->{loggers});
	# if no loggers configured, this whole section will be skipped
	foreach my $logger (@extLoggers) {
		# init the logger if it hasn't been initialized yet
		unless ( defined($INIT_LOG_CLASSES{$logger}) ) {
			# attempt to init the class
			unless ( $logger->can('init') ) {
		        eval "require $logger";
		        throw HeliosX::Logger::LoggingError($@) if $@;
			}
			$logger->setConfig($config);
			$logger->init();
			$INIT_LOG_CLASSES{$logger} = 1;
		}
		$logger->logMsg($job, $level, $msg);				
	}
	
	return 1;	
}





1;
__END__


=head1 SEE ALSO

L<Helios::Service>

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
