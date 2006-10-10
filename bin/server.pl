#!/usr/bin/perl -w -CSD

=head1 NAME

server.pl - Perl script for the server of the Alvis NLP Platform. 

=head1 SYNOPSIS

server.pl [options]

=head1 OPTIONS

=over 4

=item    B<--help>            brief help message

=item    B<--man>             full documentation

=item    B<--rcfile=file>     read the given configuration file

=back

=head1 DESCRIPTION


This script is the server part of the ALVIS NLP Platform in 
distributed mode. The document is sent to the requesting client and
then back to the server after the annotation process. One document is processed at
a time. According the configuration, document can be stored in a local
directory or sent to the next step of the Alvis pipeline.

During the annotation, the documents are saved in the ALVISTMP
directory, and their id in ALVISTMP/.proc_id file.

=head1 METHODS


=cut 

use strict;
use warnings;
# use Alvis::Pipeline;
# use XML::LibXML;
# use IO::Socket;
# use IO::File;
# use IO::Socket::INET;
# use Fcntl qw(:flock);

use Alvis::NLPPlatform;

use Getopt::Long;
use Pod::Usage;
use Config::General;
use Data::Dumper;

# Process Option

my $man = 0;
my $help = 0;
my $rcfile = "";

GetOptions('help|?' => \$help, man => \$man, "rcfile=s" => \$rcfile) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;




# die "Usage: $0 <harvester_port> <spooldir> <out dir> <NLP_port> <Next-step_host> <Nextstep_port>" if @ARGV != 6;

Alvis::NLPPlatform::server($rcfile);


=head1 PROTOCOL

=over 4

=item * Requesting a document:

=over 8

=item 1. I<from the client, to the server>: 

=over 12

=item C<REQUEST>

=back

=item 2. I<from the server, to the client>:

=over 12

=item C<SENDING> I<id> (I<id> is the document id)

=item C<SIZE> I<size> (I<size> is the document size)

=item I<document> (I<document> is the XML document)

=item E<lt>C<DONE>E<gt>

=back

=item 3. I<from the client, to the server>:

=over 12

=item C<ACK>

=back

=back

=item * Returning a document:

=over 8

=item 1. I<from the client, to the server>: 

=over 12

=item C<GIVEBACK>

=item I<id> (I<id> is the document id)

=item I<document> (I<document> is the annotated document)

=item E<lt>C<DONE>E<gt>

=back

=item 2. I<from the server, to the client>: 

=over 12

=item C<ACK>

=back 

=back

=item * Aborting the annotation process: 

=over 8

=item 1. I<from the client, to the server>: 

=over 12

=item C<ABORTING>

=item I<id> (I<id> is the document id)

=back

=back

=item * Exiting: 

the server understands the following messages C<QUIT>, C<LOGOUT> and
C<EXIT>. However, this is not been implemented in the client yet.


=back


=head1 SEE ALSO


Alvis web site: http://www.alvis.info

=head1 AUTHORS

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr> and Julien Deriviere <julien.deriviere@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2005 by Thierry Hamon and Julien Deriviere

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut