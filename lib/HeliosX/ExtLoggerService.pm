package HeliosX::ExtLoggerService;

use 5.008;
use base qw(Helios::Service);
use strict;
use warnings;

use Error qw(:try);

use Helios::Error;
use HeliosX::LogEntry::Levels qw(:all);
use HeliosX::Logger::Internal;      # we're going to load Internal in case of logging errors as a last resort
use HeliosX::Logger::LoggingError;

our $VERSION = '0.02_0771';

our %INIT_LOG_CLASSES;

=head1 NAME

HeliosX::ExtLoggerService - Helios::Service class to allow Helios logging to external logging systems

=head1 SYNOPSIS

  # in your service class
  package YourHeliosService;
  use base qw(HeliosX::ExtLoggerService);
  use strict;
  use warnings;
  ...etc...

  # in helios.ini
  [YourHeliosService]
  loggers=HeliosX::Logger::Log4perl
  internal_logger=off

=head1 DESCRIPTION

HeliosX::ExtLoggerService is a Helios::Service subclass providing a more advanced logging 
subsystem to Helios applications.  It overrides the Helios::Service->logMsg() method with a 
new, more advanced method.  It also provides a standard base class, HeliosX::Logger, that can 
be extended to write interface shims to various logging systems.  The logging to these systems 
can be controlled through several new helios.ini options globally or on an application-by-
application basis.    

To take advantage of HeliosX::ExtLoggerService's functionality, use it rather than Helios::Service 
as your service's base class.  

 # normal Helios service
 package MyService;
 use base qw(Helios::Service);
 ...etc...
 
 # Helios service w/advanced logging
 package MyService;
 use base qw(HeliosX::ExtLoggerService);
 ...etc...
 
HeliosX::ExtLoggerService itself extends Helios::Service, so all of the normal Helios service 
methods and features are still available to your service.  In fact, swapping the 'use base' lines 
above in your service class will cause no visible changes in your application; all log messages 
will continue to be sent to the internal Helios logging subsystem.  HeliosX::ExtLoggingService 
will, however, allow you to reconfigure your Helios collective to send log messages to external 
logging systems and even disable Helios's internal logging, if you prefer.  

=head1 HELIOS.INI CONFIGURATION PARAMETERS

HeliosX::ExtLoggerService adds support for several Helios configuration options not present in the 
base Helios system.  Though these options can be set either in helios.ini or in HELIOS_PARAMS_TB, 
it is B<strongly> recommended these options only be set in helios.ini as changing logging 
configurations on-the-fly could potentially cause a Helios service (and possibly your whole 
collective) to become unstable.

The following options can be set in either a [global] section or in an application section of your 
helios.ini file.  Keep in mind that even if you set your configuration parameters globally, only 
Helios services that extend HeliosX::ExtLoggerService will recognize the new parameters.  Services 
that only extend Helios::Service will be unaffected. 

=head2 loggers

 loggers=HeliosX::Logger::Syslog,HeliosX::Logger::Log4perl

A comma delimited list of interface classes to external logging systems.  Each of these classes 
should implement (or otherwise extend) the HeliosX::Logger class.  Each class will most likely 
have its own configuration parameters to set; consult the documentation for the interface class 
you're trying to configure.

=head2 internal_logger 

 internal_logger=on|off 

Whether to enable the internal Helios logging system as well as the loggers specified with the 
'loggers=' line above.  The default is on, so the default behavior for a service based on 
HeliosX::ExtLoggerService will match behavior of those based on Helios::Service.  If set to off, 
the only logging your service will do will be to the external logging systems.

NOTE:  Even though we are referring to the internal Helios logging system, the code that 
implements that system has been extracted from the base Helios distribution and refactored here 
as HeliosX::Logger::Internal.  The log data itself still goes to the same place, and the code is 
practically identical, but this allows HeliosX::ExtLoggerService to easily override logMsg().  The 
copyright information for this code has been preserved. 

=head1 METHODS

=head2 logMsg([$job,] [$priority_level,] $message)

Given a message to log, an optional priority level, and an optional Helios::Job object, logMsg() 
will record the message in the logging systems that have been configured.  If the internal logging 
system is enabled, logMsg() will automatically add HeliosX::Logger::Internal to the list of 
systems to which to log the message.  If the priority level isn't specified, LOG_INFO is the 
default.  If a Helios::Job object isn't specified, the jobid will not be associated with the log 
message.  

This method returns a true value if successful and throws an exception if errors occur.   

=cut

sub logMsg {
	my $self = shift;
	my @args = @_;
	my $job;
	my $level;
	my $msg;
	my @loggers;

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

    # grab the names of all the configured loggers to try
    @loggers = split(/,/, $config->{loggers});

    # inject the internal logger automatically
    # UNLESS it has been specifically turned off
    unless ( defined($config->{internal_logger}) && 
        ( $config->{internal_logger} eq 'off' || $config->{internal_logger} eq '0') ) {
    	push(@loggers, 'HeliosX::Logger::Internal');
    }

	# if no loggers configured, this whole section will be skipped
	foreach my $logger (@loggers) {
		# init the logger if it hasn't been initialized yet
		unless ( defined($INIT_LOG_CLASSES{$logger}) ) {
			# attempt to init the class
			unless ( $logger->can('init') ) {
		        eval "require $logger";
		        throw HeliosX::Logger::LoggingError($@) if $@;
			}
			$logger->setConfig($config);
			$logger->setJobType($jobType);
			$logger->setHostname($hostname);
            try {
    			$logger->init();
            } otherwise {
            	# our only resort is to use the internal logger
            	my $e = shift;
            	print $e->text(),"\n"; #[]
                HeliosX::Logger::Internal->setConfig($config);
                HeliosX::Logger::Internal->setJobType($jobType);
                HeliosX::Logger::Internal->setHostname($hostname);
                HeliosX::Logger::Internal->init();
            	HeliosX::Logger::Internal->logMsg(undef, LOG_EMERG, $logger.' CONFIGURATION ERROR: '.$e->text());
            };
			$INIT_LOG_CLASSES{$logger} = $logger;
		}
		try {
		  $logger->logMsg($job, $level, $msg);
		} otherwise {
            my $e = shift;
            print $e->text(),"\n"; #[]
            HeliosX::Logger::Internal->setConfig($config);
            HeliosX::Logger::Internal->setJobType($jobType);
            HeliosX::Logger::Internal->setHostname($hostname);
            HeliosX::Logger::Internal->init();
            HeliosX::Logger::Internal->logMsg(undef, LOG_EMERG, $logger.' LOGGING FAILURE: '.$e->text());
		};			
	}
	
	return 1;	
}





1;
__END__


=head1 SEE ALSO

L<Helios::Service>, L<HeliosX::Logger>

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
