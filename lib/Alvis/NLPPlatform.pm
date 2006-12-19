#!/usr/bin/perl



package Alvis::NLPPlatform;

=head1 NAME

Alvis::NLPPlatform - Perl extension for linguistically annotating XML documents in Alvis

=head1 SYNOPSIS

=over 

=item * Standalone mode:

    use Alvis::NLPPlatform;

    Alvis::NLPPlatform::standalone_main(\%config, $doc_xml, \*STDOUT);

=item * Distributed mode:

    # Server process

    use Alvis::NLPPlatform;

    Alvis::NLPPlatform::server($rcfile);

    # Client process

    use Alvis::NLPPlatform;

    Alvis::NLPPlatform::client($rcfile);

=back

=head1 DESCRIPTION

This module is the main part of the Alvis NLP platform. It provides
overall methods for the linguistic annotation of web documents.
Linguistic annotations depend on the configuration variables and
dependencies between linguistic steps.

Input documents are assumed to be in the ALVIS XML format
(C<standalone_main>) or to be loaded in a hashtable
(C<client_main>). The annotated document is recorded in the given
descriptor (C<standalone_main>) or returned as a hashtable
(C<client_main>).

=head1 Linguistic annotation: requirements

=over 4

=item 1

 Tokenized: this step has no dependency. It is required for
         any following annotation level.

=item 2

 Named Entity Tagging: this step requires tokenization. 

=item 3

 Word segmentation: this step requires tokenization.
         The  Named Entity Tagging step is recommended to improve the segmentation.

=item 4

 Sentence segmentation: this step requires tokenization.
         The  Named Entity Tagging step is recommended to improve the segmentation. 

=item 5

 Part-Of-Speech Tagging: this step requires tokenization, and word and
 sentence segmentation.

=item 6

 Lemmatization: this step requires tokenization, 
word and sentence segmentation, and Part-of-Speech tagging.

=item 7

 Term Tagging: this step requires tokenization, 
word and sentence segmentation, and Part-of-Speech tagging. Lemmatization is recommended to improve the term recognition.


=item 8

 Parsing: this step requires tokenization, word and sentence
segmentation.  Term tagging is recommended to improve the parsing of noun phrases.

=item 9

 Semantic feature tagging: To be determined

=item 10

 Semantic relation tagging: To be determined

=item 11

 Anaphora resolution: To be determined

=back

=head1 METHODS

=cut

our $VERSION='0.3';


use strict;
use Alvis::NLPPlatform::XMLEntities;
use Alvis::NLPPlatform::Canonical;
use Alvis::NLPPlatform::Annotation;
use Alvis::NLPPlatform::UserNLPWrappers;
use Time::HiRes qw(gettimeofday tv_interval);
use IO::Socket;
use Sys::Hostname;
use XML::LibXML;
use IO::Socket;
use IO::Socket::INET;
use Fcntl qw(:DEFAULT :flock :seek);
use Alvis::Pipeline;

use Data::Dumper;

my $cur_doc_nb;
my $done_parsing;

our %hash_tokens;
our %hash_words;
our %hash_words_punct;
our %hash_sentences;
our %hash_postags;
our %hash_named_entities;


our $number_of_words;
our $number_of_sentences;
our $nb_relations;
our $dont_annotate;

our @word_start;
our @word_end;

our @en_start;
our @en_end;
our @en_type;

our @en_tokens_start;
our @en_tokens_end;
our %en_tokens_hash;

our $last_semantic_unit;

our %last_words;
our @found_terms;
our @found_terms_tidx;
our @found_terms_smidx;
our @found_terms_phr;
our @found_terms_words;

my $id;

# Timer 

my $timer_mem;


# ENVIRONMENT VARIABLES
my $NLPTOOLS;
my $ALVISTMP;
my $HOSTNAME;
my $TMPFILE;
my $ALVISRSC;

my $ENABLE_TOKEN;
my $ENABLE_NER;
my $ENABLE_WORD;
my $ENABLE_SENTENCE;
my $ENABLE_POS;
my $ENABLE_LEMMA;
my $ENABLE_TERM_TAG;
my $ENABLE_SYNTAX;

# Dependencies mask
my $MASK_TOKEN=1;
my $MASK_NER=2;
my $MASK_WORD=4;
my $MASK_SENTENCE=8;
my $MASK_POS=16;
my $MASK_LEMMA=32;
my $MASK_TERM_TAG=64;
my $MASK_SYNTAX=128;

# LOG MANAGEMENT
our @tab_errors;
my $log_entry;

# BENCHMARKING
my $time_load;
my $time_tok;
my $time_ne;
my $time_word;
my $time_sent;
my $time_pos;
my $time_lemm;
my $time_term;
my $time_synt;
my $time_render;
my $time_total;



=head2 compute_dependencies()

    compute_dependencies($hashtable_config);

This method processes the configuration variables defining the
linguistic annotation steps. C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.  The dependencies of the linguistic
annotations are then coded. For instance, asking for POS annotation will
imply tokenization, word and sentence segmentations.

=cut 

sub compute_dependencies{
    my $h_config = $_[0];
    my $val=0;
    if($h_config->{'linguistic_annotation'}->{'ENABLE_TOKEN'}){
	$val|=1;
    }
    if($h_config->{'linguistic_annotation'}->{'ENABLE_NER'}){
	$val|=3;
    }
    if($h_config->{'linguistic_annotation'}->{'ENABLE_WORD'}){
	$val|=5;
    }
    if($h_config->{'linguistic_annotation'}->{'ENABLE_SENTENCE'}){
	$val|=13;
    }
    if($h_config->{'linguistic_annotation'}->{'ENABLE_POS'}){
	$val|=29;
    }
    if($h_config->{'linguistic_annotation'}->{'ENABLE_LEMMA'}){
	$val|=61;
    }
    if($h_config->{'linguistic_annotation'}->{'ENABLE_TERM_TAG'}){
	$val|=77;
    }
    if($h_config->{'linguistic_annotation'}->{'ENABLE_SYNTAX'}){
	$val|=157;
    }

    print STDERR "Dependency mask: $val\n";

    if($val&$MASK_TOKEN){$ENABLE_TOKEN=1;}else{$ENABLE_TOKEN=0;}
    if($val&$MASK_NER){$ENABLE_NER=1;}else{$ENABLE_NER=0;}
    if($val&$MASK_WORD){$ENABLE_WORD=1;}else{$ENABLE_WORD=0;}
    if($val&$MASK_SENTENCE){$ENABLE_SENTENCE=1;}else{$ENABLE_SENTENCE=0;}
    if($val&$MASK_POS){$ENABLE_POS=1;}else{$ENABLE_POS=0;}
    if($val&$MASK_LEMMA){$ENABLE_LEMMA=1;}else{$ENABLE_LEMMA=0;}
    if($val&$MASK_TERM_TAG){$ENABLE_TERM_TAG=1;}else{$ENABLE_TERM_TAG=0;}
    if($val&$MASK_SYNTAX){$ENABLE_SYNTAX=1;}else{$ENABLE_SYNTAX=0;}

    print STDERR "TOKENS: "; if($ENABLE_TOKEN){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    print STDERR "NER: "; if($ENABLE_NER){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    print STDERR "WORDS: "; if($ENABLE_WORD){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    print STDERR "SENTENCES: "; if($ENABLE_SENTENCE){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    print STDERR "POS: "; if($ENABLE_POS){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    print STDERR "LEMMA: "; if($ENABLE_LEMMA){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    print STDERR "TERM_TAG: "; if($ENABLE_TERM_TAG){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    print STDERR "SYNTAX: "; if($ENABLE_SYNTAX){print STDERR "Enabled\n";}else{print STDERR "Disabled\n";}
    return;
}


###########################################################################

=head2 starttimer()

    starttimer()

This method records the current date and time. It is used to compute
the time of a processing step.

=cut

sub starttimer(){
    my $sec;
    my $usec;
    ($sec,$usec)=gettimeofday();
    $usec/=1000000;
    $timer_mem=($sec+$usec);
}

=head2 endtimer()

    endtimer();

This method ends the timer and returns the time of a processing step, according to the time recorded by C<starttimer()>.


=cut

sub endtimer(){
    my $sec;
    my $usec;
    ($sec,$usec)=gettimeofday();
    $usec/=1000000;
    return (($sec+$usec)-$timer_mem);
}

=head2 linguistic_annotation()
    
    linguistic_annotation($h_config,$doc_hash);

This methods carries out the lingsuitic annotation according to the list
of required annotations. Required annotations are defined by the
configuration variables (C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file).

The document to annotate is passed as a hash table (C<$doc_hash>). The
method adds annotation to this hash table.

=cut


sub linguistic_annotation {
    my $h_config = $_[0];
    my $doc_hash = $_[1];

    my $nb_max_tokens = 0;

    starttimer();
    if ($ENABLE_TOKEN) {
	
	# Tokenize
	Alvis::NLPPlatform::UserNLPWrappers->tokenize($h_config,$doc_hash);
	# print STDERR $Alvis::NLPPlatform::Annotation::nb_max_tokens. "\n";
	$time_tok+=endtimer();
	print STDERR "\tTokenization Time : $time_tok\n";
	push @{$doc_hash->{"log_processing0"}->{"comments"}},  "Tokenization Time : $time_tok";
	
	if ($Alvis::NLPPlatform::Annotation::nb_max_tokens >0) {
	    # Scan for NE
	    if($ENABLE_NER==1){
		starttimer();
		Alvis::NLPPlatform::UserNLPWrappers->scan_ne($h_config, $doc_hash);
		$time_ne+=endtimer();
		print STDERR "\tNamed Entity Recognition Time : $time_ne\n";
		push @{$doc_hash->{"log_processing0"}->{"comments"}},  "Named Entity Recognition Time : $time_ne";
	    }

	    # Word segmentation
	    if($ENABLE_WORD==1){
		starttimer();
		Alvis::NLPPlatform::UserNLPWrappers->word_segmentation($h_config, $doc_hash);
		$time_word+=endtimer();
		print STDERR "\tWord Segmentation Time : $time_word\n";
		push @{$doc_hash->{"log_processing0"}->{"comments"}},  "Word Segmentation Time : $time_word";
	    }

	    if($dont_annotate==1){
		print STDERR "Skipped document\n";
		undef %$doc_hash;
		%$doc_hash=();
		$doc_hash=0;
		push @tab_errors,"SKIPPED DOCUMENT\n";
		push @tab_errors,"URL: ".$Alvis::NLPPlatform::Annotation::documenturl."\n";
		push @tab_errors,"Language tag: ".$Alvis::NLPPlatform::Annotation::ALVISLANGUAGE."\n";
		push @tab_errors,"Temporary files can be found with the following prefix: $TMPFILE\n";
	    }

	    # Sentence segmentation
	    if($ENABLE_SENTENCE==1){
		starttimer();
		if(!$dont_annotate){Alvis::NLPPlatform::UserNLPWrappers->sentence_segmentation($h_config, $doc_hash)};
		$time_sent+=endtimer();
		print STDERR "\tSentence Segmentation Time : $time_sent\n";
		push @{$doc_hash->{"log_processing0"}->{"comments"}},  "Sentence Segmentation Time : $time_sent";
	    }

	    # PoS tagging / Lemmatization
	    if($ENABLE_POS==1){
		starttimer();
		if(!$dont_annotate){Alvis::NLPPlatform::UserNLPWrappers->pos_tag($h_config, $doc_hash)};
		$time_pos+=endtimer();
		print STDERR "\tPart of Speech Tagging Time : $time_pos\n";
		push @{$doc_hash->{"log_processing0"}->{"comments"}},  "Part of Speech Tagging Time : $time_pos";
	    }

	    # Term tagging
	    if($ENABLE_TERM_TAG==1){
		starttimer();
		if(!$dont_annotate){Alvis::NLPPlatform::UserNLPWrappers->term_tag($h_config, $doc_hash)};
		$time_term+=endtimer();
		print STDERR "\tTerm Tagging Time : $time_term\n";
		push @{$doc_hash->{"log_processing0"}->{"comments"}},  "Term Tagging Time : $time_term";
	    }

	    # Syntactic parsing
	    if($ENABLE_SYNTAX==1){
		starttimer();
		if(!$dont_annotate){Alvis::NLPPlatform::UserNLPWrappers->syntactic_parsing($h_config, $doc_hash)};
		$time_synt+=endtimer();
		print STDERR "\tSyntactic Parsing Time : $time_synt\n";
		push @{$doc_hash->{"log_processing0"}->{"comments"}},  "Syntactic Parsing Time : $time_synt";
	    }

	}	    
    }
}


###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################

=head2 standalone_main()

    standalone_main($hash_config, $doc_xml, \*STDOUT);


This method is used to annotate a document in the standalone mode of
the platform. The document (C<%doc_xml>) is given in the ALVIS XML
format.

The document is loaded into memory and then annotated according to the
steps defined in the configuration variables (C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file). The annotated document is printed to the file
defined by the descriptor given as parameter (in the given example,
the standard output). C<$printCollectionHeaderFooter> indicates if the
C<documentCollection> header and footer have to be printed.

The function returns the time of the XML rendering.

=cut

sub standalone_main {
    my $h_config = $_[0];
    my $doc_xml = $_[1];
    my $descriptor = $_[2];
    my $printCollectionHeaderFooter = $_[3];

    my $xmlhead="";#"<?xml version=\"1.0\" encoding=\"$charset\"?>\n<documentCollection xmlns=\"http://alvis.info/enriched/\" version=\"1.1\">\n";
    my $xmlfoot="";#</documentCollection>\n";


    my $doc_hash;

    $last_semantic_unit=1;
    $cur_doc_nb=1;
    compute_dependencies($h_config);
    $NLPTOOLS=$h_config->{'NLP_tools_root'};
    $ALVISTMP=$h_config->{'ALVISTMP'};
    $HOSTNAME=hostname
    $ALVISRSC=$h_config->{'NLP_misc'}->{'NLP_resources'};
    if (!exists $h_config->{'TMPFILE'}) {
	$h_config->{'TMPFILE'}="$ALVISTMP/$HOSTNAME.$$";
    }

    print STDERR "\n";

    open LOGERRORS,">$ALVISTMP/alvis.log";

    $time_load=0;
    $time_tok=0;
    $time_ne=0;
    $time_word=0;
    $time_sent=0;
    $time_pos=0;
    $time_lemm=0;
    $time_term=0;
    $time_render=0;

    # Load document record
    warn "Loading DR... ";
    undef %$doc_hash;
    %$doc_hash=();
    $doc_hash=0;

    %hash_tokens=();

    $dont_annotate=0;
    %hash_words=();
    %hash_words_punct=();
    %hash_sentences=();
    %hash_postags=();
    @word_start=();
    @word_end=();

    %last_words=();
    @found_terms=();
    @found_terms_tidx=();
    @found_terms_smidx=();
    @found_terms_phr=();
    @found_terms_words=();

    @tab_errors=();

    starttimer();

#     $doc_xml =~ s/("<\?xml version=\"1.0\" encoding=\"$charset\"?>\n
    $doc_hash=Alvis::NLPPlatform::Annotation::load_xml($doc_xml, $h_config);
    $time_load+=endtimer();

    # Recording computing data (time and entity size)
    # init
    $doc_hash->{"log_processing0"}->{"datatype"}="log_processing";
    $doc_hash->{"log_processing0"}->{"log_id"} = "time";
    $doc_hash->{"log_processing1"}->{"datatype"}="log_processing";
    $doc_hash->{"log_processing1"}->{"log_id"} = "element_size";
    $doc_hash->{"log_processing2"}->{"datatype"}="log_processing";
    $doc_hash->{"log_processing2"}->{"log_id"} = "host";
    $doc_hash->{"log_processing2"}->{"comments"} = $HOSTNAME;

    # Recording statistical data (time and entity size)
    # XML loading time
    my @tmp_c;
    $doc_hash->{"log_processing0"}->{"comments"} = \@tmp_c;

    push @{$doc_hash->{"log_processing0"}->{"comments"}},  "XML loading Time : $time_load";
    print STDERR "\tXML loading Time : $time_load\n";
    my @tmp_d;
    $doc_hash->{"log_processing1"}->{"comments"} = \@tmp_d;
    

    if($doc_hash!=0)
    {
	print STDERR "done - documentRecord ".$Alvis::NLPPlatform::Annotation::document_record_id;
	print STDERR " (document $cur_doc_nb)\n";


	Alvis::NLPPlatform::linguistic_annotation($h_config, $doc_hash);

	# Save to XML file
	$cur_doc_nb++;
	print STDERR "Rendering XML...  ";

	starttimer();
	push @{$doc_hash->{"log_processing0"}->{"comments"}},  "XML rendering Time : \@RENDER_TIME_NOT_SET\@";
	Alvis::NLPPlatform::Annotation::render_xml($doc_hash, $descriptor, $printCollectionHeaderFooter);
	$time_render+=endtimer();

# TODO : recording the xml rendering time

	# Recording statistical data (time and entity size)
	# XML rendering (unsuable)
	print STDERR "done\n";
	print STDERR "\tXML rendering Time : $time_render\n";
	
    }else{
	print STDERR "done parsing - no more documents.\n";
	last;
    }
    print STDERR "\n";

    # log errors
    if(scalar @tab_errors>0){
	print LOGERRORS "Document $Alvis::NLPPlatform::Annotation::document_record_id (number $cur_doc_nb)\n";
	foreach $log_entry(@tab_errors){
	    print LOGERRORS "$log_entry";
	}
    }
#     }

    close LOGERRORS;

#     $time_total=$time_load+$time_tok+$time_ne+$time_word+$time_sent+$time_pos+$time_lemm+$time_term+$time_render;

    return($time_render);
}

=head2 client_main()

    client_main($doc_hash, $r_config);


This method is used to annotate a document in the distributed mode of
the NLP platform. The document  given in the ALVIS XML
format is already is loaded into memory (C<$doc_hash>).

The document is annotated according to the steps defined in the
configuration variables. The annotated document is returned to the
calling method.


=cut

sub client_main {
    

    my $doc_hash = $_[0];
    my $r_config = $_[1];

    $last_semantic_unit=1;
    $cur_doc_nb=1;
    compute_dependencies($r_config);
    $NLPTOOLS=$r_config->{'NLP_tools_root'};
    $ALVISTMP=$r_config->{'ALVISTMP'};
    $HOSTNAME=hostname
    $ALVISRSC=$r_config->{'NLP_misc'}->{'NLP_resources'};
    if (!exists $r_config->{'TMPFILE'}) {
	$r_config->{'TMPFILE'}="$ALVISTMP/$HOSTNAME.$$";
    }

    print STDERR "\n";


    open LOGERRORS,">$ALVISTMP/alvis.log";

    $time_load=0;
    $time_tok=0;
    $time_ne=0;
    $time_word=0;
    $time_sent=0;
    $time_pos=0;
    $time_lemm=0;
    $time_term=0;
    $time_synt=0;
    $time_render=0;

    $doc_hash->{"log_processing2"}->{"datatype"}="log_processing";
    $doc_hash->{"log_processing2"}->{"log_id"} = "host";
    $doc_hash->{"log_processing2"}->{"comments"} = $HOSTNAME;

    # Load document record
    warn "Loading DR... ";

    %hash_tokens=();

    $dont_annotate=0;
    %hash_words=();
    %hash_words_punct=();
    %hash_sentences=();
    %hash_postags=();
    @word_start=();
    @word_end=();

    %last_words=();
    @found_terms=();
    @found_terms_smidx=();
    @found_terms_tidx=();
    @found_terms_phr=();
    @found_terms_words=();

    @tab_errors=();


    if($doc_hash!=0)
    {
	print STDERR "done - documentRecord ".$Alvis::NLPPlatform::Annotation::document_record_id;
	print STDERR " (document $cur_doc_nb)\n";

	&linguistic_annotation($r_config, $doc_hash);

    }else{
	print STDERR "done parsing - no more documents.\n";
	last;
    }
    print STDERR "\n";

    # log errors
    if(scalar @tab_errors>0){
	print LOGERRORS "Document $Alvis::NLPPlatform::Annotation::document_record_id (number $cur_doc_nb)\n";
	foreach $log_entry(@tab_errors){
	    print LOGERRORS "$log_entry";
	}
    }
#     }

    close LOGERRORS;


    return($doc_hash);
    
}

=head2 load_config()

    load_config($rcfile);

The method loads the configuration of the NLP Platform by reading the
configuration file given in argument.


=cut

sub load_config 
{

    my ($rcfile) = @_;
 
# Read de configuration file

    if ($rcfile eq "") {
	$rcfile = "/etc/alvis-nlpplatform/nlpplatform.rc";
    }
    
    my $conf = new Config::General('-ConfigFile' => $rcfile,
				   '-InterPolateVars' => 1,
				   '-InterPolateEnv' => 1
				   );
    
    my %config = $conf->getall;
    `mkdir -p $config{'ALVISTMP'}`; # to put in a specific method
    return(%config);
}


=head2 client()

=cut

sub client
{

    my ($rcfile) = @_;

    my %config = Alvis::NLPPlatform::load_config($rcfile);

    my $nlp_host = $config{"NLP_connection"}->{"SERVER"};
    my $nlp_port = $config{"NLP_connection"}->{"PORT"};

    my $line;
    my $doc_xml_size;
    my $doc_xml;
    my $connection_retry;
    my $sock=0;
    my $time_render;
    my $sig_handler = "";

    while(1) {
	
	# to not stop the connection (should crash the server)
	$sig_handler = $SIG{'INT'};
	$SIG{'INT'}='IGNORE'; # to prevent zombification
	
	$connection_retry=$config{"alvis_connection"}->{"RETRY_CONNECTION"};
	do {
	    $sock=new IO::Socket::INET( PeerAddr => $nlp_host,
					PeerPort => $nlp_port,
					Proto => 'tcp');
	    
	    warn "Could not create socket: $! \n" unless $sock;
	    $connection_retry--;
	    sleep(1);
	} while(!defined($sock) && ($connection_retry >0));
	
	if ($connection_retry ==0) {
	    die "Timeout. Could not create socket: $! \n";
	}
#     $sock=new IO::Socket::INET( PeerAddr => $nlp_host,
# 				PeerPort => $nlp_port,
# 				Proto => 'tcp');

#     die "Could not create socket: $!\n" unless $sock;
	$sock -> autoflush(1); ###############
	binmode($sock, ":utf8");
	print STDERR `date`;
	print STDERR "Established connection to server.\n";
	
	print STDERR "Requesting document...";
	print $sock "REQUEST\n";
	print STDERR "done.\n";

	print STDERR "Receiving document...\n";

# SENDING $id
			    
	while($line = <$sock>) {
	    print STDERR "$line";
	    $line=uc $line;
	    if ($line =~ /SENDING ([^\n]+)\n/) {
		$id = $1;
		last;
	    } else {
		warn "Out of protocol message\n";
		close $sock;
		next;
	    }
	}
	
	print STDERR "GETTING $id\n";

# SIZE of $doc_xml

	while ($line = <$sock>) {
	    print STDERR "$line";
	    $line=uc $line;
	    if ($line =~ /SIZE ([^\n]+)\n/) {
		$doc_xml_size = $1;
		last;
	    } else {
		warn "Out of protocol message\n";
		close $sock;
		next;
	    }
	}
	
	print STDERR "READING $doc_xml_size bytes\n";
	$doc_xml = "";
	print STDERR length($doc_xml) . "\r";
	while ((defined $sock) && ($line = <$sock>) &&  ($line ne "<DONE>\n")) { #  (length($doc_xml) < $doc_xml_size) &&
	    print STDERR length($doc_xml) . "\r";
	    $doc_xml .= $line;
	}
	if (length($doc_xml) > $doc_xml_size) {
	    warn "Received more bytes than expected\n";
	}
	print STDERR length($doc_xml) . "\n";
	print STDERR "\n";
	print STDERR "READING $id done.\n";
	print STDERR "Sending ACK...";
	print $sock "ACK\n";
	print STDERR "done.\n";
	
	close $sock;

	# restore the normal behaviour
	$SIG{'INT'} = \&sigint_handler;

	print STDERR "Processing $id";
	
	my $doc_hash;
    
	Alvis::NLPPlatform::starttimer();
	$doc_hash=Alvis::NLPPlatform::Annotation::load_xml($doc_xml, \%config);
	my $time_load+=Alvis::NLPPlatform::endtimer();

	# Recording computing data (time and entity size)
	# init
#     $doc_hash->{"log_processing"} = {};
	$doc_hash->{"log_processing0"}->{"datatype"}="log_processing";
	$doc_hash->{"log_processing0"}->{"log_id"} = "time";
	$doc_hash->{"log_processing1"}->{"datatype"}="log_processing";
	$doc_hash->{"log_processing1"}->{"log_id"} = "element_size";
	
    # Recording statistical data (time and entity size)
    # XML loading time
	my @tmp_c;;
	$doc_hash->{"log_processing0"}->{"comments"} = \@tmp_c;
	
	push @{$doc_hash->{"log_processing0"}->{"comments"}},  "XML loading Time : $time_load";
	
	my @tmp_d;;
	$doc_hash->{"log_processing1"}->{"comments"} = \@tmp_d;
	
	
	$doc_hash = Alvis::NLPPlatform::client_main($doc_hash, \%config);
	
	# to not stop the connection (should crash the server)
	$sig_handler = $SIG{'INT'};
	$SIG{'INT'}='IGNORE'; # to prevent zombification

	$connection_retry=$config{"alvis_connection"}->{"RETRY_CONNECTION"};
	do {
	    $sock=new IO::Socket::INET( PeerAddr => $nlp_host,
					PeerPort => $nlp_port,
					Proto => 'tcp');
	    
	    warn "Could not create socket: $! \n" unless $sock;
	    $connection_retry--;
	    sleep(1);
	} while(!defined($sock) && ($connection_retry >0));
	
	if ($connection_retry ==0) {
	    die "Timeout. Could not create socket: $! \n";
	}
	binmode $sock, ":utf8";
	
	print STDERR "Established connection to server.\n";
	
	print STDERR "Giving back annotated document...\n";
	# Communitation with the server
	print $sock "GIVEBACK\n$id\n";
	
	# Save to XML file

	print STDERR "\tRendering XML...  ";

	starttimer();
	push @{$doc_hash->{"log_processing0"}->{"comments"}},  "XML rendering Time : \@RENDER_TIME_NOT_SET\@";
	Alvis::NLPPlatform::Annotation::render_xml($doc_hash, $sock, 1);
	$time_render+=endtimer();

# TODO : recording the xml rendering time
	print STDERR "done\n";
    
	print $sock "<DONE>\n";
	
	print STDERR "done.\n";
	
	# the render time is sent

	print $sock "RENDER TIME\n$time_render\n";

	print STDERR "Awaiting acknowledgement...";
	my $line;
	while($line=<$sock>){
	    chomp $line;
	    $line=uc $line;
	    if($line=~/ACK/gi){
		close($sock);
		last;
	    }
	}
	print STDERR "OK.\n";

	close($sock);

	# restore the normal behaviour
	$SIG{'INT'} = $sig_handler;
	print STDERR "Closed connection to server.\n";
    }
    return($time_render);
}


=head2 sigint_handler()

    sigint_handler($signal, $r_config);

This method is used to catch the INT signal and send a ABORTING
message to the server.

=cut

sub sigint_handler {

    my ($signal, $r_config) = @_;
    my $sock;

    my $nlp_host = $r_config->{"NLP_connection"}->{"SERVER"};
    my $nlp_port = $r_config->{"NLP_connection"}->{"PORT"};


    warn "Receiving SIGINT -- Aborting NL processing\n";


    my $connection_retry=$r_config->{"alvis_connection"}->{"RETRY_CONNECTION"};
    do {
	$sock=new IO::Socket::INET( PeerAddr => $nlp_host,
				    PeerPort => $nlp_port,
				    Proto => 'tcp');

	warn "Could not create socket: $! \n" unless $sock;
	$connection_retry--;
	sleep(1);
    } while(!defined($sock) && ($connection_retry >0));

    if ($connection_retry ==0) {
	die "Timeout. Could not create socket: $! \n";
    }
    $sock -> autoflush(1); ###############
    binmode $sock, ":utf8";


    print STDERR "Established connection to server.\n";

    print STDERR "Sending aborting message\n";

    print $sock "ABORTING\n$id\n";

    print STDERR "Aborting message sent\n";

    print STDERR "Awaiting acknowledgement...";
    my $line;
    while($line=<$sock>){
	chomp $line;
	$line=uc $line;
	if($line=~/ACK/gi){
	    close($sock);
	    last;
	}
    }
    print STDERR "OK.\n";

    close($sock);
    exit;
}

=head2 server()

=cut

sub server 
{
    my ($rcfile) = @_;

    print STDERR "config File : $rcfile \n";

    my %config = Alvis::NLPPlatform::load_config($rcfile);


#    print STDERR Dumper(\%config);

    my $charset = 'UTF-8';

    #  header and footer

    my $xmlhead="<?xml version=\"1.0\" encoding=\"$charset\"?>\n<documentCollection xmlns=\"http://alvis.info/enriched/\" version=\"1.1\">\n";
    my $xmlfoot="</documentCollection>\n";

    # connection to the crawler

    my $pipe = new Alvis::Pipeline::Read(port => $config{"alvis_connection"}->{"HARVESTER_PORT"}, spooldir => $config{"alvis_connection"}->{"SPOOLDIR"},
					 loglevel=>10)
	or die "can't create read-pipe on port " . $config{"alvis_connection"}->{"HARVESTER_PORT"} . ": $!";

    $|=1;

    system("touch " . $config{"ALVISTMP"} . "/.proc_id");

    &init_server(\%config);

    system("rm -f " . $config{"ALVISTMP"} . "/.proc_id");
    system("touch " . $config{"ALVISTMP"} . "/.proc_id");
    system("mkdir -p " . $config{"alvis_connection"}->{"OUTDIR"} );
    my $n=1;

    my $annotated_xml;

    $SIG{'CHLD'}='IGNORE'; # to prevent zombification

    my $sock=new IO::Socket::INET(LocalPort => $config{"NLP_connection"}->{"PORT"},
				  Proto => 'tcp',
				  Listen => 10,
				  Reuse => 1);

    die "Could not create socket: $!\n" unless $sock;

    $sock -> autoflush(1); ###############

    my $client_sock=0;
    my $name;
    my @records;
    my $id;
    my $sub_dir;
    my %processing_id;

    while(1){
	warn "beginning of the loop\n";
	# await client connection
	if ($client_sock=$sock->accept()) {
	    warn "Accepting a connection\n";
	    if (fork() == 0) {
		close($sock);
		binmode($client_sock, ":utf8");
		my ($client_port,$client_iaddr) = sockaddr_in(getpeername($client_sock));
		warn "Getting information about remote host\n";
		$name=gethostbyaddr($client_iaddr,AF_INET);
		&disp_log($name,"Client (".inet_ntoa($client_iaddr).":".$client_port.") has connected.");
		$client_sock -> autoflush(1); ###############
		
		##############################
		# CLIENT HANDLING CODE
		my $line;
		$line=<$client_sock>;
		chomp $line;
		$line=uc $line;
		$line=~m/^\s*([A-Z]+)$/g;
		
		## CLIENT IS REQUESTING A DOCUMENT
		if($1 eq "REQUEST"){
		    &disp_log($name,"Client is requesting a document.");
		    # send document
		    
		    &disp_log($name,"Sending document to client.");

		    my $xml = "";
		    warn "Reading the pipe\n";
		    if ($xml = $pipe->read(1)) {
			$xml .= "\n" if $xml !~ /\n$/;
			
			@records=&split_to_docRecs($xml);
			if (scalar(@records))
			{
			    my $rec = shift (@records);
			    ($id,$xml)=@$rec;
			    if (scalar (@records)) {
				# if there is more than one records other are store again in the pipeline
				# use of combineExport code
				my $pipe_out = new Alvis::Pipeline::Write(host => "localhost", 
									  port => $config{"alvis_connection"}->{"HARVESTER_PORT"},
									  loglevel => 10)
				    or die "can't create ALVIS write-pipe for port '" . $config{"alvis_connection"}->{"HARVESTER_PORT"} . "': $!";
				foreach my $rec_out (@records) {
				    $pipe_out->write($xmlhead . $rec_out . $xmlfoot);
				}
			    }

			    if (defined($id))
			    {
				warn "Received\t$n\t$id\n";
				
				`date`;
				if (defined(open(I,">:utf8",$config{"ALVISTMP"} . "/${id}.xml")))
				{
				    print I $xml;
				    close(I);		
				}
				else
				{
				    die("Unable to open " .  $config{"ALVISTMP"} . "/${id}.xml for writing.");
				}
				
				my $xml2 = $xml;
				&disp_log($name,"Sending Document sent to client ("  . (length($xml2) + 1 ) . " bytes).");
				&disp_log($name, "SENDING $id");
				&record_id($id,\%config);
				print $client_sock "SENDING $id\n";
				print $client_sock "SIZE " . (length($xml2) + 1 ) . "\n";
				$xml2 = "";
				print $client_sock "$xml\n";
				print $client_sock "<DONE>\n";
				# await acknowledgement
				&disp_log($name,"Document sent to client.");
				&disp_log($name,"Awaiting ACK from client...");
				while($line=<$client_sock>){
				    chomp $line;
				    $line=uc $line;
				    if($line=~/ACK/gi){
					close($client_sock);
					last;
				    }
				}
				&disp_log($name,"Received ACK from client - Request fulfilled.");
				close($client_sock);
			    }
			    else
			    {
				warn "No id for record #$id of record \"$rec\"\n";
				}
			}
			else
			{
			    my $doc_text;
			    if (ref($xml))
			    {
				$doc_text=$xml->toString();
			    }
			    else
			    {
				$doc_text=$xml;
			    }
			    warn "Could not split into documentRecords document $doc_text";
			}
		    } else {
			$pipe->close();
			warn "No documents in pipeline\n"
			    if $n == 0;
		    }
		    
		    $n++;
		    close($client_sock);
		}   
		
		
		## CLIENT IS ABOUT TO GIVE BACK AN ANNOTATED DOCUMENT
		if($1 eq "GIVEBACK"){
		    &disp_log($name,"Client is giving back a document.");
		    # receive document
		    &disp_log($name,"Receiving annotated document from client...");
		    
		    $id = <$client_sock>;
		    chomp $id;
		    
		    # Recording the annotation document (local)
		    $sub_dir=&sub_dir_from_id($id);
		    if ($config{"NLP_misc"}->{"SAVE_IN_OUTDIR"}) {system("mkdir -p " . $config{"alvis_connection"}->{"OUTDIR"} . "/$sub_dir");}
		    my $xml = "";
		    if (($config{"NLP_misc"}->{"SAVE_IN_OUTDIR"} == 0) || (defined(open(O,">:utf8", $config{"alvis_connection"}->{"OUTDIR"} . "/$sub_dir/${id}.xml"))))
		    {
			while((defined $sock) && ($line=<$client_sock>) && ($line ne "<DONE>\n")) {
			    # recording the annotation document (local)
			    # building xml string for sending to the next step
			    $xml .= $line;
			}
			# get the RENDER TIME
			if ((defined $sock) && ($line = <$client_sock>) && ($line eq "RENDER TIME\n")) {
			    if ((defined $sock) && ($line = <$client_sock>)) {
				chomp $line;
				$xml =~ s/\@RENDER_TIME_NOT_SET\@/$line/;
			    } else {
				warn "\n***\nValue of nrender time is not sent\n***\n\n";
			    }
		        } else {
			    warn "\n***\nRender time is not sent\n***\n\n";
			}
			if ($config{"NLP_misc"}->{"SAVE_IN_OUTDIR"}) {
			    print O $xml;
			    close(O);
			}
			# sending the annotated document to the newt step
			if ($config{"alvis_connection"}->{"NEXTSTEP"}) {
			    warn "Sending the annotated document to the next step... \n";
			    my $pipe_out_nextstep = new Alvis::Pipeline::Write(host => $config{"alvis_connection"}->{"NEXTSTEP_HOST"}, 
									       port => $config{"alvis_connection"}->{"NEXTSTEP_PORT"}, 
									       loglevel => 10)
				or die "can't create ALVIS write-pipe for '" . $config{"alvis_connection"}->{"NEXTSTEP_HOST"} . "' port '" . $config{"alvis_connection"}->{"nextstep_port"} . "': $!";
			    $pipe_out_nextstep->write($xml);
			    warn "done\n";
			} else {
			    warn "Not sending to a nextstep\n";
			}
		    } else {
			if ($config{"NLP_misc"}->{"SAVE_IN_OUTDIR"}) {
			    $sub_dir=&sub_dir_from_id($id);
			    die("Unable to open " . $config{"alvis_connection"}->{"OUTDIR"}. " //$sub_dir/${id}.xml for writing.");
			}
		    }
		    
		    &disp_log($name,"Received annotated document from client.");
		    
		    warn "deleting $config{ALVISTMP}/${id}.xml\n";
		    unlink "$config{ALVISTMP}/${id}.xml";
		    &delete_id($id, \%config);
		    # send acknowledgement
		    &disp_log($name,"Sending ACK to client...");
		    print $client_sock "ACK\n";
		    &disp_log($name,"Sent ACK to client - Finished giving back.");
		    close($client_sock);
		}
		#  CLIENT INFORMS SERVER FOR ABORTING NL PROCESSING
		if ($1 eq "ABORTING") {
		    &disp_log($name,"Client is aborting NL processing of a document.");
		    $line = <$client_sock>;
		    chomp $line;
		    # use of combineExport code
		    my $pipe_out = new Alvis::Pipeline::Write(host => "localhost", 
							      port => $config{"alvis_connection"}->{"HARVESTER_PORT"},
							      loglevel => 10)
			or die "can't create ALVIS write-pipe for port '" . $config{"alvis_connection"}->{"HARVESTER_PORT"} . "': $!";
		    $id = $line;
		    open ABORTING_FILE, "$config{ALVISTMP}/${id}.xml" or die "Cannot open file  $config{ALVISTMP}/${id}.xml \n";
		    my $rec_out = "";
		    while($line = <ABORTING_FILE>) {
			$rec_out .= $line;
		    }
		    $pipe_out->write($xmlhead . $rec_out . $xmlfoot);
		    close ABORTING_FILE;
		    &delete_id($id,%config);
		    &disp_log($name,"Sending ACK to client...");
		    print $client_sock "ACK\n";
		    &disp_log($name,"Sent ACK to client - Finished aborting.");
		}
		## CLIENT REQUESTS TO BE DISCONNECTED BY THE SERVER
		if(
		   ($1 eq "QUIT") ||
		   ($1 eq "LOGOUT") ||
		   ($1 eq "EXIT")){
		    &disp_log($name,"Disconnecting client.");
		}
		&disp_log($name,"Disconnecting client.");
		close($client_sock);
		exit;
	    } else {
		close($client_sock);
	    }
	}
	warn "End of loop\n";
    }
    # END OF CLIENT HANDLING CODE
    ##############################

}


=head2 disp_log()

    disp_log($hostname,$message);

This method prints the message (C<$message>) on the standard error
output, in a formatted way: 

C<date: (client=hostname) message>

=cut

sub disp_log{
    my $date=`date`;
    chomp $date;
    print STDERR "$date: ";
    print STDERR "(client=".$_[0].") ";
    print STDERR $_[1]."\n";
}

=head2 split_to_docRecs()

    split_to_docRecs($xml_docs);

This method splits a list of documents into a table and return
it. Each element of the table is a two element table containing the
document id and the document.

=cut

sub split_to_docRecs
{
    my $xml=shift;

    my @recs=();
    
    my $doc;
    my $Parser=XML::LibXML->new();


    eval
    {
	$doc=$Parser->parse_string($xml);
    };
    if ($@)
    {
	warn "Parsing the doc failed: $@. Trying to get the IDs..\n";
	eval
	{
	    $xml=~s/<documentRecord\s(xmlns=[^\s]+)*\sid\s*=\s*\"([^\"]*?)\">/&unparseable_id($2)/esgo;
	};
    }
    else
    {
	if ($doc)
	{

	    my $root=$doc->documentElement();
	    for my $rec_node ($root->getChildrenByTagName('documentRecord'))
	    {
		my $id=$rec_node->getAttribute("id");
		if (defined($id))
		{
		    $xml=$rec_node->toString();
		    push(@recs,[$id,$xml]);
		}
		else
		{
		    my $rec_str=$rec_node->toString();
		    $rec_str=~s/\n/ /sgo;
		    warn "No id for record $rec_str\n";
		}
	    }
	}
	else
	{
	    my $doc_str=$xml;
	    $doc_str=~s/\n/ /sgo;
	    warn "Parsing the doc failed. Doc: $doc_str\n";
	}
    }

    return @recs;
}


sub unparseable_id
{
    my $id=shift;
    
    warn "$id is in an unparseable chunk\n";
}


=head2 sub_dir_from_id()


    sub_dir_from_id($doc_id)

Ths method returns the subdirectory where annotated document will
stored. It computes the subdirectory from the two first characters of
the document id (C<$doc_id>).

=cut

sub sub_dir_from_id
{
    my $id=shift;

    return substr($id,0,2);
}

=head2 record_id()

    record_id($doc_id, $r_config);


This method records in the file C<$ALVISTMP/.proc_id>, the id of the
document that has been sent to the client.

=cut


sub record_id {
    my ($doc_id, $r_config) = @_;

    my $file_id = $r_config->{"ALVISTMP"} . "/.proc_id";
    my $fh = new IO::File("+>$file_id")
	or die "can't read '$file_id': $!";
    $fh->print("$doc_id\n") or die "can't write in '$file_id': $!";

    flock($fh, LOCK_EX) or die "can't lock '$file_id': $!";
    
    flock($fh, LOCK_UN) or die "can't unlock '$file_id': $!";
    $fh->close() or die "Truly unbelievable";
    
}

=head2 delete_id()

    delete_id($doc_id,$r_config);


This method delete the id of the document that has been sent to the
client, from the file C<$ALVISTMP/.proc_id>.

=cut

sub delete_id {
    my ($doc_id, $r_config) = @_;
    my $line;
    my @tab_proc_id;

    my $file_id = $r_config->{"ALVISTMP"} . "/.proc_id";
    my $fh = new IO::File("+<$file_id")
	or die "can't read '$file_id': $!";
    flock($fh, LOCK_EX) or die "can't lock '$file_id': $!";
    while($line = $fh->getline()) {
	if ($line ne "$doc_id\n") {
	    push @tab_proc_id, $line;
	}
    }
    seek($fh, 0, SEEK_SET) or die "can't seek to start of '$file_id': $!";
    foreach $line (@tab_proc_id) {
	$fh->print("$line") or die "can't write in '$file_id': $!";
    }
    
    flock($fh, LOCK_UN) or die "can't unlock '$file_id': $!";
    $fh->close() or die "Truly unbelievable";
    
}

=head2 init_server()


    init_server($r_config);


This method initializes the server. It reads the document id from the
file C<$ALVISTMP/.proc_id> and loads the corresponding documents
i.e. documents which have been annotated but not recorded due to a
server crash.

=cut

sub init_server {
    my $r_config = $_[0];
    my $doc_id;
    my $line;
    my $rec_out = "";
    my @tab_proc_id;

    my $xmlhead=""; #<?xml version=\"1.0\" encoding=\"$charset\"?>\n<documentCollection xmlns=\"http://alvis.info/enriched/\" version=\"1.1\">\n";
    my $xmlfoot=""; #</documentCollection>\n";

    print STDERR "Starting Server Initialisation ...\n";

#     warn "Receiving SIGINT -- Aborting any NL processing\n";

    my $pipe_out = new Alvis::Pipeline::Write(host => "localhost", 
					       port => $r_config->{"alvis_connection"}->{"HARVESTER_PORT"}, 
					       loglevel => 10)
	    or die "can't create ALVIS write-pipe for port '" . $r_config->{"alvis_connection"}->{"HARVESTER_PORT"} . "': $!";
    my $file_id = $r_config->{ALVISTMP} . "/.proc_id";
    my $fh = new IO::File("+<$file_id")
	or die "can't read '$file_id': $!";
    flock($fh, LOCK_EX) or die "can't lock '$file_id': $!";
    while($line = $fh->getline()) {
	chomp $line;
	push @tab_proc_id, $line;
    }

    warn "Recording " . scalar(@tab_proc_id) ." documents in the pipe...";

    foreach $doc_id (@tab_proc_id) {
	warn "Recording $doc_id in the pipe...";
	# use of combineExport code
	open ABORTING_FILE, $r_config->{ALVISTMP} . "/$doc_id.xml" ;
	$rec_out = "";
	while($line = <ABORTING_FILE>) {
	    $rec_out .= $line;
	}
	$pipe_out->write($xmlhead . $rec_out . $xmlfoot);
	close ABORTING_FILE;
	unlink $r_config->{ALVISTMP} . "/$doc_id.xml" ;
	
	warn "$doc_id recorded in the pipe";
	
    }
    flock($fh, LOCK_UN) or die "can't unlock '$file_id': $!";
    $fh->close() or die "Truly unbelievable";
    print STDERR "Server Initialisation Done\n";
}

=head1 PLATFORM CONFIGURATION

The configuration file of the NLP Platform is composed of global
variables and divided into several sections:

=over 

=item * Global variables.

The two mandatory variables are C<ALVISTMP> and C<PRESERVEWHITESPACE>
 (in the XML_INPUT section). C<ALVISTMP> defines the temporary
 directory used during the annotation process. It must be writable to
 the user the process is running as. C<$preserveWhiteSpace> is a
 boolean indicating if the linguistic annotation will be done by
 preserving white space or not, i.e. XML blank nodes and white space
 at the beginning and the end of any line.

Additional variables and environement variables can be used if they
are interpolated in the configuration file. For instance, in the
default configuration file, we add C<PLATFORM_ROOT>,
C<NLP_tools_root>, and C<AWK>.

=over 8

=item * 

C<ALVISTMP> : temporary directory where files are recorded
(XML files and input/output of the NLP tools) during the annotation
step.

=back

=item * Section C<alvis_connection>

=over 8

=item * 

C<HARVESTER_PORT>: the port of the  harverster/crawler (C<combine>) that the platform will read from to get  the documents to annotate.

=item * 

C<NEXTSTEP>: indicates if there is a next step in the pipeline
(for instance, the indexer IdZebra). the value is C<0> or C<1>.

=item * 

C<NEXTSTEP_HOST>: the host name of the component that the platform will send the annotated document to.

=item * 

C<NEXTSTEP_PORT>: the port of the component that the platform will send the annotated document to.

=item * 

C<SPOOLDIR>: the directory where the documents coming from the harvester are stored.

It must be writable to the user the process is running as.

=item * 

C<OUTDIR>: the directory where are stored the annotated documents if C<SAVE_IN_OUTDIR> (in Section C<NLP_misc>) is set.

It must be writable to the user the process is running as.

=back


=item * Section C<NLP_connection>

=over 8

=item * 

C<SERVER>: The host name where the NLP server is running, for
the connections with the NLP clients.

=item * 

C<PORT>: The listening port of the NLP server, for the
connections with the NLP clients.

=item * 

C<RETRY_CONNECTION>: The number of  times that
the clients attempts to connect to the server.

=back

=item * C<XML_INPUT>

=over 8

=item C<PRESERVEWHITESPACE>: this option takes into account or xml
blank nodes and indentation of the text in the
canonicalDocument. Default value is C<0> or false (blank nodes and
indentation characters are removed).


=item C<LINGUISTIC_ANNOTATION_LOADING>: The linguistic annotations
already existing in the input documents are loaded or not. Default
value is c<1> or true (linguistic annotations are loaded).

=back


=item * C<XML_OUTPUT>

=over 8

=item FORM

=item ID

=back


=item * Section C<linguistic_annotation>

the section defines the NLP steps that will be used for annotating documents. The values are C<0> or C<1>.

=over 8

=item * 

C<ENABLE_TOKEN>: toggles the tokenization step.

=item * 

C<ENABLE_NER>: toggles the named entity recognition step.

=item * 

C<ENABLE_WORD>: toogles the word segmentation step.

=item * 

C<ENABLE_SENTENCE>: toogles the sentence segmentation step.

=item * 

C<ENABLE_POS>: toogles the Part-of-Speech tagging step.

=item * 

C<ENABLE_LEMMA>: toogles the lemmatization step.

=item * 

C<ENABLE_TERM_TAG>: toogles the term tagging step.

=item * 

C<ENABLE_SYNTAX>: toogles the parsing step.

=back


=item * Section C<NLP_misc>

the section defines miscellenous variables for NLP annotation steps.

=over 8

=item * 

C<NLP_resources>: the root directory where NLP resources  can be found.

=item * 

C<SAVE_IN_OUTDIR>: enable or not to save the annotated documents in the I<outdir> directory.

=item * 

C<TERM_LIST_EN>: the path of the term list for English.

=item * 

C<TERM_LIST_FR>: the path of the term list for French.

=back


=item * Section C<NLP_tools>

This section defines the command line for the NLP tools integrated in the platform.

Additional variables and environment variables can be used for interpolation.

=over 8

=item * 

C<NETAG_EN>: command line for the Named Entity Recognizer for English.

=item * 

C<NETAG_FR>: command line for the Named Entity Recognizer for French.

=item * 

C<WORDSEG_EN>: command line for the word segmentizer for English.

=item * 

C<WORDSEG_FR>: command line for the word segmentizer for French.

=item * 

C<POSTAG_EN>: command line for the Part-of-Speech tagger for English.

=item * 

C<POSTAG_FR>: command line for the Part-of-Speech tagger for French.

=item * 

C<SYNTACTIC_ANALYSIS_EN>: command line for the parser for English.

=item * 

C<SYNTACTIC_ANALYSIS_FR>: command line for the parser for French.

=item * 

C<TERM_TAG_EN>: command line for the term tagger for English.

=item * 

C<TERM_TAG_FR>: command line for the term tagger for French.


=back


=back

=head1 DEFAULT INTEGRATED/WRAPPED NLP TOOLS

Several NLP tools have been integrated in wrappers. In this section,
we summarize how to download and install the NLP tools used by default
in the C<Alvis::NLPPlatform::NLPWrappers.pm> module. We also give
additional information about the tools.



=head2 Named Entity Tagger

We integrated TagEn as the default named entity tagger.

=over

=item * Form: 

sources, binaries and Perl scripts

=item * Obtain: 

http://www-lipn.univ-paris13.fr/~hamon/ALVIS/Tools/TagEN.tar.gz

=item * Install: 

   untar TagEN.tar.gz in a directory
   go to  src directory
   run compile script

=item * Licence: 

GPL

=item * Version number required: 

any

=item * Additional information: 

This named entity tagger can be run
according to various mode. A mode is defined by Unitex
(http://www-igm.univ-mlv.fr/~unitex/) graphs. The tagger can be used for English and French texts.


=back


=head2 Word and sentence segmenter

The Word and sentence segmenter we use by default is a awk script sent
by Gregory Grefenstette on the Corpora mailing list. We modified it to
segmentize French texts.

=over

=item * Form:

 AWK script

=item * Obtain:

 http://www-lipn.univ-paris13.fr/~hamon/ALVIS/Tools/WordSeg.tar.gz

=item * Install:



   untar WordSeg.tar.gz in a directory

=item * Licence:

 GPL

=item * Version number required:

 any (mods for French by Paris 13)

=back

=head2 Part-of-Speech Tagger

The default wrapper call the TreeTagger. This tool is a Part-of-Speech tagger and lemmatizer.

=over 4

=item *  Form:

 binary+resources

=item * Obtain:

 links and instructions at http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger/DecisionTreeTagger.html

=item * Install:

  Information are given on the web site. To summarize, you need to:

=over 8

=item *  

make a directory named, for instance, TreeTagger

=item *  

Download archives in tools/TreeTagger

=item *  

go in the directory tools/TreeTagger

=item *  

Run install-tagger.sh

=back

=item * Licence:

 free for research only

=item * Version number required:

 (by date) >= 09.04.1996

=back

=head2 Term Tagger

We have integrated a tool developed specifically for the Alvis
project. It will be available as Perl script soon.

=over

=item * Form:

 Perl script

=item * Obtain:

 http://www-lipn.univ-paris13.fr/~hamon/ALVIS/Tools/TermTagger.tar.gz

=item * Install:

   untar TermTagger.tar.gz in a directory

=item *  Licence:

 GPL

=item *  Version number required:

 any

=back

=head2 Part-of-Speech  specialized for Biological texts

GeniaTagger (POS and lemma tagger):

=over

=item * Form:

 source+resources

=item *  Obtain:

 links and instructions at
http://www-tsujii.is.s.u-tokyo.ac.jp/~genia/postagger/geniatagger-2.0.1.tar.gz

=item *  Install: 

  untar geniatagger-2.0.1.tar.gz in a directory

  cd tools/geniatagger-2.0.1

  Run make

=item *  Licence:

 free for research only (and Wordnet licence for the dictionary)

=item *  Version number required:

 2.0.1

=back

=head2 Parser

Link Grammar Parser:


=over

=item * Form:

 sources + resources

=item * Obtain:

 http://www.link.cs.cmu.edu/link/ftp-site/link-grammar/link-4.1b/unix/link-4.1b.tar.gz

=item * Install: 

    untar link-4.1b.tar.gz

    See the Makefile for configuration

    run make

    Apply the additional patch for the Link Grammar parser (lib/Alvis/NLPPlatform/patches).

        cd link-4.1b
        patch -p0 < lib/Alvis/NLPPlatform/patches/link-4.1b-WithWhiteSpace.diff
 
     Similar patch exists for the version 4.1a of the Link Grammar parser

=item * Licence:

 Compatible with GPL

=item * Version number required:

 4.1a or 4.1b

=back

=head2 Parser specialized for biological texts

BioLG:



=over

=item * Form:

 sources + resources

=item * Obtain:


  http://www.it.utu.fi/biolg/

=item * Install:

 

    untar
    
    See the Makefile for configuration

    run make


=item * Licence:

 Compatible with GPL

=item * Version number required:

 1.1.10

=back


=head1 TUNING THE NLP PLATFORM


The main characteristic of the NLP platform is its tunability according to the domain (language specificity of the documents to be annotated) and the user requirements. The tuning can be done at two levels:

=over 

=item *

 either resources adapted or describing more precisely the
domain can be exploited. 

In that respect, tuning concerns the
integration of these resources in the NLP tools used in the
plaform. The command line in the configuration file can be modified. 

Example of resource switching can be found at the named entity
recognition step. The default Named Entity tagger can use either
bio-medical resources, or more general, according to the value of the
parameter C<-t>.

=item * 

either other NLP tools can be integrated in the NLP
platform. 

In that case, new wrappers should be written. To make easier,
the integration of a new NLP tools, we used the polymorphism to
override default wrappers. NLP platform package is defined as a three
level hierarchy. The top is the C<Alvis::NLPPlatform> package. The
C<Alvis::NLPPlatform::NLPWrappers> package is the deeper. We define
the package C<Alvis::NLPPlatform::UserNLPWrappers> as between the
both. In that respect, integrating a new NLP tool, and then writing a
new wrapper requires to modify methods in the 
C<Alvis::NLPPlatform::UserNLPWrappers>, and calling or not the default
methods.


NB: If the package C<Alvis::NLPPlatform::UserNLPWrappers> is not
writable to the user, the tuning can be done by copying the
C<Alvis::NLPPlatform::UserNLPWrappers> in a local directory, and by
adding this local directory to the C<PERL5LIB> variable (before the
path of C<Alvis::NLPPlatform>).


NB: A template for the package C<Alvis::NLPPlatform::UserNLPWrappers>
can be found in C<Alvis::NLPPlatform::UserNLPWrappers-template>.


Example of such tuning can be fouond at the parsing level. We
integrate a parser designed for biological documents in
C<Alvis::NLPPlatform::UserNLPWrappers>.



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

1;
