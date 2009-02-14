package HeliosX::Logger;

use 5.008;
use strict;
use warnings;

use Error qw(:try);

use Helios::Job;
use Helios::Error;
use HeliosX::Logger::LoggingError;

our $VERSION = '0.02_0761';

=head1 NAME

HeliosX::Logger - Interface class for sending Helios logging information to external loggers

=head1 SYNOPSIS

#[]


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
	throw HeliosX::Error::LoggingError('init() not defined for '. __PACKAGE__);
}


=head2 logMsg()

=cut

sub logMsg {
	throw HeliosX::Error::LoggingError('logMsg() not defined for '. __PACKAGE__);
}


1;
__END__


=head1 SEE ALSO

L<Helios::ExtLoggerService>

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
