#!/usr/bin/perl -w -CSD


=head1 NAME

go.pl - Perl script for linguistically annotating a corpus contained in a file

=head1 SYNOPSIS

go.pl [options] < Input_document > Annotated_Output_Document

=head1 OPTIONS

=over 4

=item    B<--help>            brief help message

=item    B<--man>             full documentation

=item    B<--rcfile=file>     read the given configuration file

=back

=head1 DESCRIPTION

This script linguistically annotates the document given in the
standard input. The annotated document is sent to the standard
output.

The linguistic annotation depends on the configuration variables and
depndencies between annotation levels.

=cut

=head1 CONFIGURATION VARIABLES


=head1 FILES

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

use strict;

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


my %config = Alvis::NLPPlatform::load_config($rcfile);

# print STDERR Dumper(%config);

# document loading

my $line;
my $doc_xml = "";

while($line=<STDIN>) {
    $doc_xml .= $line;
}



Alvis::NLPPlatform::standalone_main(\%config, $doc_xml, \*STDOUT);

