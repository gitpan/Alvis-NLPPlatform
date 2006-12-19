package Alvis::NLPPlatform::NLPWrappers;

#use diagnostics;
use strict;

use Alvis::NLPPlatform::Annotation;
use Alvis::TermTagger;

my @term_list;
my @regex_term_list;

=head1 NAME

Alvis::NLPPlatform - Perl extension for linguistically annotating XML documents in Alvis

=head1 SYNOPSIS

use Alvis::NLPPlatform::NLPWrappers;

Alvis::NLPPlatform::NLPWrappers::->tokenize($h_config,$doc_hash);

=head1 DESCRIPTION

This module provides defaults wrappers of the Natural Language
Processing (NLP) tools. These wrappers are called in the ALVIS NLP
Platform (see C<Alvis::NLPPlatform>).

Default wrappers can be overwritten by defining new wrappers in a new
and local UserNPWrappers module.

=head1 METHODS

=cut

=head2 tokenize()

    tokenize($h_config, $doc_hash);

This method carries out the tokenisation process on the input
document. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. 

The tokenization has been written for ALVIS. This is a task that
depends largely on the choice made as to what tokens are for our
purpose. Hence, this function is not a wrapper but the specific
tokenizing tool itself.  Its input is the plain text corpus, which is
segmented into tokens. Tokens are in fact a group of characters
belonging to the same category. Below is a list of the four possible
categories:

=over 

=item * alphabetic characters (all letters from 'a' to 'z', including accentuated characters)

=item * numeric characters (numbers from '0' to '9')

=item * space characters (carriage return, line feed, space and tab)

=item * symbols: all characters that do not fit in the previous categories

=back


During the tokenization process, all tokens are stored in memory via a
hash table (C<%hash_tokens>).

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

The method returns the number of tokens.


=cut


sub tokenize
{
###################################################
    my ($class, $h_config, $doc_hash) = @_;
    my $line;
    my @characters;
    my $char;

#    warn @{$doc_hash->{"log_processing0"}->{"comments"}};

#    my $nb_max_tokens = 0;
    my $offset;
    my $current_char;
    my $last_char;
    my $length;
    my $string;
    my $token_id;
    
#     my $alpha="[A-Za-zÃ Ã¢Ã¤ÃÃÃÃ©Ã¨ÃªÃ«ÃÃÃÃÃ¬Ã®Ã¯ÃÃÃÃ²Ã´Ã¶ÃÃÃÃ¹Ã»Ã¼ÃÃÃÃ§Ã]";
    my $alpha="[A-Za-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{FF}]";
    my $num="[0-9]";
    my $sep="[ \\s\\t\\n\\r]";
    
    my $canonical;
    my @lines;
###################################################


    $offset=0;
    $last_char=0;
    $length=0;
    $string="";
    $token_id=1;
    
    print STDERR "  Tokenizing...           ";
    
    $canonical=$Alvis::NLPPlatform::Annotation::canonicalDocument;
    Alvis::NLPPlatform::Canonical::CleanUp($canonical, $h_config->{"XML_INPUT"}->{"PRESERVEWHITESPACE"});
#     Alvis::NLPPlatform::Canonical::CleanUp($canonical, $h_config->{"PRESERVEWHITESPACE"});

    @lines=split /\n/,$canonical;


    map {$_ .= "\n"} @lines;

    if (($canonical =~ /\n$/) && ($#lines > -1)) {
	chomp $lines[$#lines];
    }

    foreach $line(@lines)
    {

	# convert UTF-8 nto Perl Native Bytes
 	utf8::decode($line);
	  # convert SGML into characters
	  Alvis::NLPPlatform::XMLEntities::decode($line);

	  # character spliting

	  @characters=split //,$line;
	  
	  foreach $char(@characters){

	      # determine the type of the current character
	      $current_char=4; # default type
	      if($char=~/$alpha/){$current_char=1;}
	      if($char=~/$num/){$current_char=2;}
	      if($char=~/$sep/){$current_char=3;}
	      # comparison with last seen character

	      # if it is the same ...
	      if(($current_char==$last_char) && ($current_char!=4)){
		  $string=$string.$char;
		  $length++;
	      }else{
		  if($length>0){
		      #######################################################
		      my $dtype;
		      if($last_char==1){$dtype="alpha";}
		      if($last_char==2){$dtype="num";}
		      if($last_char==3){$dtype="sep";}
		      if($last_char==4){$dtype="symb";}
		      $doc_hash->{"token$token_id"}={};
		      $doc_hash->{"token$token_id"}->{'datatype'}="token";
		      $doc_hash->{"token$token_id"}->{'type'}=$dtype;
		      $doc_hash->{"token$token_id"}->{'id'}="token$token_id";
		      $doc_hash->{"token$token_id"}->{'from'}=$offset;
		      $doc_hash->{"token$token_id"}->{'to'}=$offset+$length-1;
		      if($last_char==3){
			  $string=~s/\n/\\n/g;
			  $string=~s/\r/\\r/g;
			  $string=~s/\t/\\t/g;
		      }
		      $doc_hash->{"token$token_id"}->{"content"}=$string;	
		      $Alvis::NLPPlatform::hash_tokens{"token$token_id"}=$string;
		      $token_id++;
		      $offset+=$length;
		      #######################################################
		  }
		  $length=1;
		  $string=$char;
		  $last_char=$current_char;
	      }
	  }
      }
###################################################
    if ($#lines > -1) {
	my $dtype;
	if($last_char==1){$dtype="alpha";}
	if($last_char==2){$dtype="num";}
	if($last_char==3){$dtype="sep";}
	if($last_char==4){$dtype="symb";}
	$doc_hash->{"token$token_id"}={};
	$doc_hash->{"token$token_id"}->{"datatype"}="token";
	$doc_hash->{"token$token_id"}->{"type"}=$dtype;
	$doc_hash->{"token$token_id"}->{"id"}="token$token_id";
	$doc_hash->{"token$token_id"}->{"from"}=$offset;
	$doc_hash->{"token$token_id"}->{"to"}=$offset+$length-1;
	if($last_char==3){
	    $string=~s/\n/\\n/g;
	    $string=~s/\r/\\r/g;
	    $string=~s/\t/\\t/g;
	}
	$doc_hash->{"token$token_id"}->{"content"}=$string;
	$Alvis::NLPPlatform::hash_tokens{"token$token_id"}=$string;
	$token_id++;
	$offset+=$length;
###################################################

	$Alvis::NLPPlatform::Annotation::nb_max_tokens=$token_id-1;
    } else {
	$Alvis::NLPPlatform::Annotation::nb_max_tokens=0;
    }
    print STDERR "done - Found " . $Alvis::NLPPlatform::Annotation::nb_max_tokens ." tokens\n";

    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Tokens : " . $Alvis::NLPPlatform::Annotation::nb_max_tokens;

    return($Alvis::NLPPlatform::Annotation::nb_max_tokens);
}

=head2 scan_ne()

    scan_ne($h_config, $doc_hash);

This method wraps the default Named entity recognition and tags the
input document. C<$doc_hash> is the hashtable containing containing
all the annotations of the input document.  It aims at annotating
semantic units with syntactic and semantic types. Each text sequence
corresponding to a named entity will be tagged with a unique tag
corresponding to its semantic value (for example a "gene" type for
gene names, "species" type for species names, etc.). All these text
sequences are also assumed to be equivalent to nouns: the tagger
dynamically produces linguistic units equivalent to words or noun
phrases.

C<$hash_config> is the reference to the hashtable containing the
variables defined in the configuration file.

We integrated TagEn (Jean-Francois Berroyer. I<TagEN, un analyseur
d'entites nommees : conception, developpement et
evaluation>. Universite Paris-Nord, France. 2004. Memoire de
D.E.A. d'Intelligence Artificielle), as default named entity tagger,
which is based on a set of linguistic resources and grammars. TagEn
can be downloaded here:
http://www-lipn.univ-paris13.fr/~hamon/ALVIS/Tools/TagEN.tar.gz

=cut

sub scan_ne
{
    my ($class, $h_config, $doc_hash) = @_;

    my $corpus;
    my $token;
    my $line;
    my $id;
    my $tok_ct;

    my @tab_tokens; # experimental
    my $t; # experimental

    print STDERR "  Named entites tagging...     ";
    
    $corpus="";

    foreach $token(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_tokens)){
	$tok_ct=$Alvis::NLPPlatform::hash_tokens{$token};
	Alvis::NLPPlatform::XMLEntities::decode($tok_ct);
	$corpus.=$tok_ct;
	push @tab_tokens,$tok_ct;
    }
    
    open CORPUS,">" . $h_config->{'TMPFILE'} . ".corpus.txt";
    binmode(CORPUS,":utf8");
    print CORPUS $corpus;
    close CORPUS;
    print STDERR "done\n";
    
    my $command_line;
    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	$command_line = $h_config->{'NLP_tools'}->{'NETAG_FR'} . " " .  $h_config->{'TMPFILE'} . ".corpus.txt 2> /dev/null";
    } else {
	$command_line = $h_config->{'NLP_tools'}->{'NETAG_EN'} . " " .  $h_config->{'TMPFILE'} . ".corpus.txt 2> /dev/null";
    }
    print `$command_line`;
    unlink $h_config->{'TMPFILE'} . ".corpus.txt";
    @Alvis::NLPPlatform::en_start=();
    @Alvis::NLPPlatform::en_end=();
    @Alvis::NLPPlatform::en_type=();

    open REN,"<" . $h_config->{'TMPFILE'} . ".corpus.tag.txt"  or warn "Can't open the file " . $h_config->{'TMPFILE'} . ".corpus.tag.txt";;
    while($line=<REN>){
	$line=~m/(.+)\s+([0-9]+)\s+([0-9]+)/;
	push @Alvis::NLPPlatform::en_type,$1;
	if ((exists($h_config->{'XML_INPUT'}->{"PRESERVEWHITESPACE"})) && ($h_config->{'XML_INPUT'}->{"PRESERVEWHITESPACE"})) {
	    push @Alvis::NLPPlatform::en_start,($2-1);
	    push @Alvis::NLPPlatform::en_end,($3-1);
	} else {
	    push @Alvis::NLPPlatform::en_start,$2;
	    push @Alvis::NLPPlatform::en_end,$3;
	}
    }
    close REN;

    unlink $h_config->{'TMPFILE'} . ".corpus.tag.txt";

    print STDERR "  Matching EN with tokens...   ";

    # scan tokens and match with NE
    my $offset=0;
    my $i;
    my $en=0;
    my $j;
    my $start;
    my $end;
    my $ref_tab;
    my $refid_n;

    my $en_cont;
    my $number_of_tokens;
    my $last_en;

    @Alvis::NLPPlatform::en_tokens_start=();
    @Alvis::NLPPlatform::en_tokens_end=();
    %Alvis::NLPPlatform::en_tokens_hash=();
    $number_of_tokens=scalar @tab_tokens;

    $en=$Alvis::NLPPlatform::last_semantic_unit+1;
    $last_en=0;

    for($t=0;$t<$number_of_tokens;$t++){
	print STDERR "\r  Matching EN with tokens...   ".($t+1)."/".$number_of_tokens." ";
	for($i=$last_en;$i<scalar @Alvis::NLPPlatform::en_start;$i++){
	    if($Alvis::NLPPlatform::en_start[$i]==$offset){
		$last_en=$i;
		$Alvis::NLPPlatform::en_tokens_start[$en]="token".($t+1);
		$Alvis::NLPPlatform::en_tokens_hash{($t+1)}=$en;
		$start=$t+1;
		while($Alvis::NLPPlatform::en_end[$i]>$offset-1){
		    $Alvis::NLPPlatform::en_tokens_end[$en]="token".($t+1);
		    $end=$t+1;
		    $offset+=length($tab_tokens[$t]);
		    $t++;
		}

		$doc_hash->{"semantic_unit$en"}={};
		$doc_hash->{"semantic_unit$en"}->{"datatype"}="semantic_unit";
		$doc_hash->{"semantic_unit$en"}->{"named_entity"}={};
		$doc_hash->{"semantic_unit$en"}->{"named_entity"}->{"datatype"}="named_entity";
		$doc_hash->{"semantic_unit$en"}->{"named_entity"}->{"named_entity_type"}=$Alvis::NLPPlatform::en_type[$i];
		$doc_hash->{"semantic_unit$en"}->{"named_entity"}->{"id"}="named_entity$en";

		$ref_tab=$doc_hash->{"semantic_unit$en"}->{"named_entity"}->{"list_refid_token"}={};
		$ref_tab->{'datatype'}="list_refid_token";
		$en_cont="";
		$refid_n=1;
		my @tab_tokens;
		$ref_tab->{"refid_token"}=\@tab_tokens;
		for($j=$start;$j<=$end;$j++){
		    push @tab_tokens, "token$j";
		    $refid_n++;
		    $en_cont.=$Alvis::NLPPlatform::hash_tokens{"token$j"};
		}
		$doc_hash->{"semantic_unit$en"}->{"named_entity"}->{"form"}=$en_cont;

		$Alvis::NLPPlatform::hash_named_entities{"semantic_unit$en"}=$en_cont;

		$en++;
		last; # go out the Named Entity hash table scan
	    }
	}
	$offset+=length($tab_tokens[$t]);
    }
    $Alvis::NLPPlatform::last_semantic_unit=$en;
    print STDERR "done - Found ".$en." named entities\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Named Entities : $en";
}

=head2 word_segmentation()

    word_segmentation($h_config, $doc_hash);

This method wraps the default word segmentation step. C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.

We use simple regular expressions, based on the algorithm proposed in
G. Grefenstette and P. Tapanainen. I<What is a word, what is a
sentence? problems of tokenization>.  The 3rd International Conference
on Computational Lexicography. pages 79-87. 1994. Budapest.  The
method is a wrapper for the awk script implementing the approach, has
been proposed on the Corpora list (see the achives
http://torvald.aksis.uib.no/corpora/ ). The script carries out Word
segmentation as week the sentence segmentation. Information related to
the sentence segmentation will be used in the default
sentence_segmentation method.


C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

In the default wrapper, segmented words are then aligned with tokens
and named entities. For example, let ``Bacillus subtilis'' be a named
entity made of three tokens: ``Bacillus'', the space character and
``subtilis''. The word segmenter will find two words: ``Bacillus'' and
``subtilis''. The wrapper however creates a single word, since
``Bacillus subtilis'' was found to be a named entity, and should thus
be considered a single word, made of the three same tokens.


=cut


sub word_segmentation
{
    my ($class, $h_config, $doc_hash) = @_;
    my $token;
    my $id;
    my $nb_doc;
    my $command_line;
####
    print STDERR "  Word segmentation...    ";
    my $content;
    open CORPUS,">:utf8",$h_config->{'TMPFILE'} . ".corpus.tmp";
    foreach $token(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_tokens)){
	$content=$Alvis::NLPPlatform::hash_tokens{$token};
	$content=~s/\\n/\n/g;
	$content=~s/\\t/\t/g;
	$content=~s/\\r/\r/g;

	Alvis::NLPPlatform::XMLEntities::decode($content);
	print CORPUS $content;
    }
    close CORPUS;
    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	$command_line = $h_config->{"NLP_tools"}->{'WORDSEG_FR'} . " < " . $h_config->{'TMPFILE'} . ".corpus.tmp > " . $h_config->{'TMPFILE'} . ".words.tmp";
    }else{
	$command_line = $h_config->{"NLP_tools"}->{'WORDSEG_EN'} . " < " . $h_config->{'TMPFILE'} . ".corpus.tmp > " . $h_config->{'TMPFILE'} . ".words.tmp";
    }
    print `$command_line`;
    
    open MOTS, $h_config->{'TMPFILE'} . ".words.tmp";
    binmode(MOTS, ":utf8");
    my $proposedword;
    my $mot = "";
    my $token_id;
    my $word_id;
    my $ref_tab;
    my $elision;
    my $i;

    my $is_en;
    my $en_id;
    my $token_end;
    my $token_start;
    my $append;
    my $refid_n;

    my $token_tmp;

    $token_id=1;
    $word_id=1;
    
    while($proposedword=<MOTS>)
    {

	if ($proposedword !~ /^\s*\n$/) {
	    chomp $proposedword;

	    $mot="";
	    $doc_hash->{"word$word_id"}={};
	    $doc_hash->{"word$word_id"}->{'id'}="word$word_id";
	    $doc_hash->{"word$word_id"}->{'datatype'}='word';
	    $ref_tab=$doc_hash->{"word$word_id"}->{'list_refid_token'}={};
	    $ref_tab->{'datatype'}="list_refid_token";
	    my @tab_tokens;
	    $refid_n=1;
	    $ref_tab->{"refid_token"}=\@tab_tokens;

	    $is_en=0;
	    while(length($mot)<length($proposedword)){
		if($token_id>$Alvis::NLPPlatform::Annotation::nb_max_tokens){
		    $Alvis::NLPPlatform::dont_annotate=1;
		    return;
		}
		if($doc_hash->{"token$token_id"}->{'type'} ne "sep"){
		    if(exists $Alvis::NLPPlatform::en_tokens_hash{$token_id}){
			$en_id=$Alvis::NLPPlatform::en_tokens_hash{$token_id};
			$is_en=1;
		    }

		    $token_tmp=$Alvis::NLPPlatform::hash_tokens{"token$token_id"};
		    ################################
		    $token_tmp=~s/\\n/\n/g;
		    $token_tmp=~s/\\t/\t/g;
		    $token_tmp=~s/\\r/\r/g;
		    Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
		    ################################

		    $token_tmp=~s/\s+/ /g;
		    $mot=$mot.$token_tmp;
		    push @tab_tokens, "token$token_id";
		    if($refid_n==1){
			$Alvis::NLPPlatform::word_start[$word_id]=$token_id;
		    }
		    $Alvis::NLPPlatform::word_end[$word_id]=$token_id;
		    $refid_n++;
		}
		$token_id++;
	    }
	    #### is the rebuilt word a named entity ? is it fully built
	    my $append;
	    if($is_en){
		$Alvis::NLPPlatform::en_tokens_start[$en_id] =~ m/^token([0-9]+)/i;
		$token_start=$1;

		$Alvis::NLPPlatform::en_tokens_end[$en_id] =~ m/^token([0-9]+)/i;
		$token_end=$1;

		while($token_end>($token_id-1)){
		    $token_tmp=$Alvis::NLPPlatform::hash_tokens{"token$token_id"};
		    ################################
		    $token_tmp=~s/\\n/\n/g;
		    $token_tmp=~s/\\t/\t/g;
		    $token_tmp=~s/\\r/\r/g;
		    Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
		    ################################
		    $token_tmp=~s/\s+/ /g;
		    $mot=$mot.$token_tmp;

		    ########################################################
		    # TO BE CHECK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! (still necessary ?)
		    if(length($mot)>length($proposedword)){
			$append=<MOTS>;
			chomp $append;
			if($doc_hash->{"token$token_id"}->{'type'} eq "sep"){
			    $append=" ".$append;
			}
			$proposedword.=$append;
		    }
		    ########################################################

		    push @tab_tokens, "token$token_id";
		    $Alvis::NLPPlatform::word_end[$word_id]=$token_id; # Added by thierry (10/02/2006)
		    $refid_n++;
		    $token_id++;
		}
		########################################################################
		# Chech if the rebuilt word is not too short
		while(length($mot)<length($proposedword)){
		    if($doc_hash->{"token$token_id"}->{'type'} ne "sep"){
			$token_tmp=$Alvis::NLPPlatform::hash_tokens{"token$token_id"};
			################################
			$token_tmp=~s/\\n/\n/g;
			$token_tmp=~s/\\t/\t/g;
			$token_tmp=~s/\\r/\r/g;
			Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
			################################
			$token_tmp=~s/\s+/ /g;
			$mot=$mot.$token_tmp;
			push @tab_tokens, "token$token_id";
			$Alvis::NLPPlatform::word_end[$word_id]=$token_id;
			$refid_n++;
		    }
		    $token_id++;
		}
		########################################################################""
	    }

	    #### the rebuilt word is too long... elision?
	    my $mempos;
	    if(length($mot)>length($proposedword)){
		# read the next word
		$mempos=tell(MOTS);
		$elision=<MOTS>;
		chomp $elision;
		if($elision=~/(\'s|\'d|\'m|\'ll|\'re|\'ve|\'t)/i){
		    # Elision (english)
		    # Solution: going on the loop
		    $proposedword=$proposedword.$elision;
		}else{
		    # not a elision: going back (backtracking)
		    seek(MOTS,$mempos,0);
		}
	    }
	    ####

	    #### the rebuilt word is too short... it is not an elision
	    if (length($mot)<length($proposedword)){
		if(index($proposedword,$mot)==0){
		    # Tokens are missing
		    while(length($mot)<length($proposedword)){    
			if($doc_hash->{"token$token_id"}->{'type'} ne "sep"){
			    $token_tmp=$Alvis::NLPPlatform::hash_tokens{"token$token_id"};
			    ################################
			    $token_tmp=~s/\\n/\n/g;
			    $token_tmp=~s/\\t/\t/g;
			    $token_tmp=~s/\\r/\r/g;
			    Alvis::NLPPlatform::XMLEntities::decode($token_tmp);
			    ################################
			    $token_tmp=~s/\s+/ /g;
			    $mot=$mot.$token_tmp;
			    push @tab_tokens, "token$token_id";
			    $Alvis::NLPPlatform::word_end[$word_id]=$token_id;
			    $refid_n++;
			}
			$token_id++;
		    }
		}
	    }

	    $doc_hash->{"word$word_id"}->{'form'}="$mot";

	    if(length($mot)!=length($proposedword)){
		print STDERR "**** Alignment error between '$mot'(re-built word) and '$proposedword'(proposed by segmenter) ****\n";
		print STDERR "Length($mot)=".length($mot)."\n";
		print STDERR "Length($proposedword)=".length($proposedword)."\n";
		print STDERR "**** PROCESSING ABORTED ****\n";
		push @Alvis::NLPPlatform::tab_errors,"Word segmentation: alignment error\n";
		push @Alvis::NLPPlatform::tab_errors,"Re-built '$mot' not aligned with '$proposedword' proposed by used segmenter\n";
		push @Alvis::NLPPlatform::tab_errors,"Respective lengths:".length($mot)." and ".length($proposedword)."\n";
		push @Alvis::NLPPlatform::tab_errors,"* Processing aborted *\n";
		push @Alvis::NLPPlatform::tab_errors,"\n";
		last;
	    }

	    #####
	    ## Remove punctuation
	    if(($doc_hash->{"token".($token_id-1)}->{'type'} eq "symb") && (length($mot)==1)){
		if(index(".;:!?",$Alvis::NLPPlatform::hash_tokens{"token".($token_id-1)})>-1){
		    # This obviously marks the end of a sentence;
		    # store the "word" ID for sentence segmentation
		    $Alvis::NLPPlatform::last_words{"word".($word_id-1)}=1;
		}
		delete $doc_hash->{"word$word_id"};
		$word_id--;
	    }else{
	    }
	    $word_id++;
	    #####
	}
    }
    close MOTS;
    unlink $h_config->{'TMPFILE'} . ".corpus.tmp";
    unlink $h_config->{'TMPFILE'} . ".words.tmp";

    my $word;
    my $word_punct=1;
    # keys NEED to be sorted here, so we can insert punctuation in the 2ndary word hash table
    foreach $word (Alvis::NLPPlatform::Annotation::sort($doc_hash)){
	if($word=~/^(word[0-9]+)/){
	    $id=$1;
	    $Alvis::NLPPlatform::hash_words{$id}=$doc_hash->{$id}->{'form'};
	    $Alvis::NLPPlatform::hash_words_punct{"word".$word_punct}=$Alvis::NLPPlatform::hash_words{$id};
	    $word_punct++;
	    if(exists($Alvis::NLPPlatform::last_words{$id})){
		$Alvis::NLPPlatform::hash_words_punct{"word".$word_punct}=$Alvis::NLPPlatform::hash_tokens{"token".($Alvis::NLPPlatform::word_end[Alvis::NLPPlatform::Annotation::read_key_id($id)]+1)};
		$word_punct++;
	    }
	}
    }
    $Alvis::NLPPlatform::last_words{"word" . ($word_id - 1)} = 1;
    $Alvis::NLPPlatform::number_of_words=$word_id-1;
    print STDERR "done - Found ".$Alvis::NLPPlatform::number_of_words ." words\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Words: $Alvis::NLPPlatform::number_of_words";
}


=head2 sentence_segmentation()

    sentence_segmentation($h_config, $doc_hash);

This method wraps the default sentence segmentation step. C<$doc_hash>
is the hashtable containing containing all the annotations of the
input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

The sentence segmentation function does not invoke any external tool (
See the C<word_segmentation()> method for more explaination.) It scans
the token hash table for full stops, i.e. dots that were not
considered to be part of words. All of these full stops then mark the
end of a sentence.  Each sentence is then assigned an identifier, and
two offsets: that of the starting token, and that of the ending
token.

=cut


sub sentence_segmentation
{
    my ($class, $h_config, $doc_hash) = @_;
    my $word;
    my $sentence_id=1;
    my $min;
    my $max;

    my $btw_start;
    my $btw_end;
    my $i;
    my $token;
    my $sentence;
    my $sentence_cont="";

    my $start_token=$Alvis::NLPPlatform::word_start[1];

    print STDERR "  Sentence segmentation...";

    foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){

	# get starting and ending tokens for the word
	$min=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)];
	$max=$Alvis::NLPPlatform::word_end[Alvis::NLPPlatform::Annotation::read_key_id($word)];
	for($i=$min;$i<=$max;$i++){
	    $token = $Alvis::NLPPlatform::hash_tokens{"token".$i};
	    $sentence_cont .= $token;
	}

	# insert tokens between the current word and the next (spaces, punctuation, ...)
	$btw_start=$max+1;
	if(Alvis::NLPPlatform::Annotation::read_key_id($word)+1 > $Alvis::NLPPlatform::number_of_words){
	    # We've reached the end of the document
	    $btw_end=$Alvis::NLPPlatform::Annotation::nb_max_tokens;
	}else{
	    $btw_end=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1]-1;
	}
	for($i=$btw_start;$i<=$btw_end;$i++){
	    $token = $Alvis::NLPPlatform::hash_tokens{"token".$i};
	    $sentence_cont .= $token;
	}

	# if the current word is the last word of the sentence,
	# then create an entry in the hash

	if(exists($Alvis::NLPPlatform::last_words{$word})){
	    $doc_hash->{"sentence$sentence_id"}={};
	    $doc_hash->{"sentence$sentence_id"}->{'id'}="sentence$sentence_id";
	    $doc_hash->{"sentence$sentence_id"}->{'datatype'}='sentence';
	    $doc_hash->{"sentence$sentence_id"}->{'refid_start_token'}="token$start_token";
	    $doc_hash->{"sentence$sentence_id"}->{'refid_end_token'}="token$btw_end";
	    $sentence_cont =~s /\\n/\n/g;
	    $sentence_cont =~s /\\r/\r/g;
	    $sentence_cont =~s /\\t/\t/g;
	    $doc_hash->{"sentence$sentence_id"}->{'form'}="$sentence_cont";
	    $sentence_cont="";

	    $sentence_id++;
	    if($btw_end!=$Alvis::NLPPlatform::Annotation::nb_max_tokens){
		$start_token=$Alvis::NLPPlatform::word_start[Alvis::NLPPlatform::Annotation::read_key_id($word)+1];
	    }
	}

    }

    # create an entry for the last sentence, only if it isn't empty
    # (when the last sentence does not contain any ending punctuation)

    if($btw_end!=$Alvis::NLPPlatform::Annotation::nb_max_tokens){
	$doc_hash->{"sentence$sentence_id"}={};
	$doc_hash->{"sentence$sentence_id"}->{'id'}="sentence$sentence_id";
	$doc_hash->{"sentence$sentence_id"}->{'datatype'}='sentence';
	$doc_hash->{"sentence$sentence_id"}->{'refid_start_token'}="token$start_token";
	$doc_hash->{"sentence$sentence_id"}->{'refid_end_token'}="token$btw_end";
	$sentence_cont =~s /\\n/\n/g;
	$sentence_cont =~s /\\r/\r/g;
	$sentence_cont =~s /\\t/\t/g;
	$doc_hash->{"sentence$sentence_id"}->{'form'}="$sentence_cont";
	$sentence_cont="";
    }


    foreach $sentence(keys %$doc_hash){
	if($sentence=~/^(sentence[0-9]+)/){
	    $Alvis::NLPPlatform::hash_sentences{$1}=$doc_hash->{$1}->{'form'};
	}
    }
    $Alvis::NLPPlatform::number_of_sentences=$sentence_id-1;
    print STDERR "done - Found ".$Alvis::NLPPlatform::number_of_sentences." sentences\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Sentencess: $Alvis::NLPPlatform::number_of_sentences";
}


=head2 pos_tag()

    pos_tag($h_config, $doc_hash);

The method wraps the Part-of-Speech (POS) tagging. C<$doc_hash> is the
hashtable containing containing all the annotations of the input
document. It works as follows: every word is input to the external
Part-Of-Speech tagging tool. For every input word, the tagger outputs
its tag. Then, the wrapper creates a hash table to associate the tag
to the word.  It assumes that word and sentence segmentations have
been performed.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Be default, we are using the probabilistic Part-Of-Speech tagger
TreeTagger (Helmut Schmid. I<Probabilistic Part-of-Speech Tagging
Using Decision Trees>.  New Methods in Language Processing Studies in
Computational Linguistics.  1997.  Daniel Jones and Harold
Somers. http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger/ ).


As this POS tagger also carries out the lemmatization, the method also
adds annotation at this level step.


The GeniaTagger (Yoshimasa Tsuruoka and Yuka Tateishi and Jin-Dong Kim
and Tomoko Ohta and John McNaught and Sophia Ananiadou and Jun'ichi
Tsujii.  I<Developing a Robust Part-of-Speech Tagger for Biomedical
Text> Proceedings of Advances in Informatics - 10th Panhellenic
Conference on Informatics.  pages 382-392.  2005.  LNCS 3746.) can
also be used, by modifying column order (see defintion of the command
line in C<client.pl>).

=cut



sub pos_tag 
{
    my ($class, $h_config, $doc_hash) = @_;
    my $word;
    my $cont;
    my $i;
    my $line;
    my $word_id;
    my $tag;
    my $lemma;
    my %hash_validtags_en;
    my %hash_validtags_fr;
    my $inflected;

    # build hash of valid tags
    $hash_validtags_en{'CC'}=1;
    $hash_validtags_en{'CD'}=1;
    $hash_validtags_en{'DT'}=1;
    $hash_validtags_en{'EX'}=1;
    $hash_validtags_en{'FW'}=1;
    $hash_validtags_en{'IN'}=1;
    $hash_validtags_en{'JJ'}=1;
    $hash_validtags_en{'JJR'}=1;
    $hash_validtags_en{'JJS'}=1;
    $hash_validtags_en{'LS'}=1;
    $hash_validtags_en{'MD'}=1;
    $hash_validtags_en{'NN'}=1;
    $hash_validtags_en{'NNS'}=1;
    $hash_validtags_en{'NP'}=1;
    $hash_validtags_en{'NPS'}=1;
    $hash_validtags_en{'PDT'}=1;
    $hash_validtags_en{'POS'}=1;
    $hash_validtags_en{'PP'}=1;
    $hash_validtags_en{'PP$'}=1;
    $hash_validtags_en{'RB'}=1;
    $hash_validtags_en{'RBR'}=1;
    $hash_validtags_en{'RBS'}=1;
    $hash_validtags_en{'RP'}=1;
    $hash_validtags_en{'SYM'}=1;
    $hash_validtags_en{'TO'}=1;
    $hash_validtags_en{'UH'}=1;
    $hash_validtags_en{'VB'}=1;
    $hash_validtags_en{'VBD'}=1;
    $hash_validtags_en{'VBG'}=1;
    $hash_validtags_en{'VBN'}=1;
    $hash_validtags_en{'VBP'}=1;
    $hash_validtags_en{'VBZ'}=1;
    $hash_validtags_en{'WDT'}=1;
    $hash_validtags_en{'WP'}=1;
    $hash_validtags_en{'WP$'}=1;
    $hash_validtags_en{'WRB'}=1;

    $hash_validtags_fr{'ABR'}=1;
    $hash_validtags_fr{'ADJ'}=1;
    $hash_validtags_fr{'ADV'}=1;
    $hash_validtags_fr{'DET:ART'}=1;
    $hash_validtags_fr{'DET:POS'}=1;
    $hash_validtags_fr{'INT'}=1;
    $hash_validtags_fr{'KON'}=1;
    $hash_validtags_fr{'NAM'}=1;
    $hash_validtags_fr{'NOM'}=1;
    $hash_validtags_fr{'NUM'}=1;
    $hash_validtags_fr{'PRO'}=1;
    $hash_validtags_fr{'PRO:DEM'}=1;
    $hash_validtags_fr{'PRO:IND'}=1;
    $hash_validtags_fr{'PRO:PER'}=1;
    $hash_validtags_fr{'PRO:POS'}=1;
    $hash_validtags_fr{'PRO:REL'}=1;
    $hash_validtags_fr{'PRP'}=1;
    $hash_validtags_fr{'PRP:det'}=1;
    $hash_validtags_fr{'PUN'}=1;
    $hash_validtags_fr{'PUN:cit'}=1;
    $hash_validtags_fr{'SENT'}=1;
    $hash_validtags_fr{'SYM'}=1;
    $hash_validtags_fr{'VER:cond'}=1;
    $hash_validtags_fr{'VER:futu'}=1;
    $hash_validtags_fr{'VER:impe'}=1;
    $hash_validtags_fr{'VER:impf'}=1;
    $hash_validtags_fr{'VER:infi'}=1;
    $hash_validtags_fr{'VER:pper'}=1;
    $hash_validtags_fr{'VER:ppre'}=1;
    $hash_validtags_fr{'VER:pres'}=1;
    $hash_validtags_fr{'VER:simp'}=1;
    $hash_validtags_fr{'VER:subi'}=1;
    $hash_validtags_fr{'VER:subp'}=1;


    print STDERR "  Part-Of-Speech tagging..";
    open CORPUS,">" . $h_config->{'TMPFILE'} . ".corpus.tmp";
    binmode(CORPUS,":utf8");
    foreach $word(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){
	$cont=$Alvis::NLPPlatform::hash_words{$word};
	print CORPUS "$cont\n";
    }
    close CORPUS;

    my $command_line;
    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	$command_line = $h_config->{'NLP_tools'}->{'POSTAG_FR'} . " < " . $h_config->{'TMPFILE'} . ".corpus.tmp > " . $h_config->{'TMPFILE'} . ".tags.tmp 2> /dev/null";
    }else{
	$command_line = $h_config->{'NLP_tools'}->{'POSTAG_EN'} . " < " . $h_config->{'TMPFILE'} . ".corpus.tmp > " . $h_config->{'TMPFILE'} . ".tags.tmp 2> /dev/null";
    }
    print `$command_line`;

    open TAGS,"<" . $h_config->{'TMPFILE'} . ".tags.tmp";
    binmode(TAGS,":utf8");
    $word_id=1;
    while($line=<TAGS>){
	$line=~m/(.+)\t+(.+)\t+(.+)/;
	$inflected=$1;
	$tag=$2;
	$lemma=$3;

	if($inflected eq $Alvis::NLPPlatform::hash_words{"word".$word_id}){
	    #######################################################
	    # Correct funny outputs from treetagger
	    if((($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR") && (!exists($hash_validtags_fr{$tag})))||(($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE ne "FR") && (!exists($hash_validtags_en{$tag})))){
		if($inflected ne $tag){
		    $tag="NP";
		}
	    }
	    
	    if((index($lemma,"_")>-1)&&(index($inflected,"_")==-1)){
		$lemma=~s/\_/ /g;
		$tag="NP";
	    }
	    
	    if($lemma eq '@card@'){
		$lemma=$inflected;
	    }
	    #######################################################
	    
	    # POS tag
	    $doc_hash->{"morphosyntactic_features$word_id"}={};
	    $doc_hash->{"morphosyntactic_features$word_id"}->{'id'}="morphosyntactic_features$word_id";
	    $doc_hash->{"morphosyntactic_features$word_id"}->{'datatype'}="morphosyntactic_features";
	    $doc_hash->{"morphosyntactic_features$word_id"}->{'refid_word'}="word$word_id";
	    $doc_hash->{"morphosyntactic_features$word_id"}->{'syntactic_category'}="$tag";
	    
	    $Alvis::NLPPlatform::hash_postags{"word$word_id"}=$tag;

	    # lemma
	    $doc_hash->{"lemma$word_id"}={};
	    $doc_hash->{"lemma$word_id"}->{'id'}="lemma$word_id";
	    $doc_hash->{"lemma$word_id"}->{'datatype'}="lemma";
	    $doc_hash->{"lemma$word_id"}->{'refid_word'}="word$word_id";
	    $doc_hash->{"lemma$word_id"}->{'canonical_form'}="$lemma";
	    $word_id++;
	}else{
	    # Punctuation sign or PoS tagger output error:
	    # Skip this line for realignment
	}
    }
    close TAGS;

    unlink $h_config->{'TMPFILE'} . ".corpus.tmp";
    unlink $h_config->{'TMPFILE'} . ".tags.tmp";

    print STDERR "done - Found ".($word_id-1)." tags.\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found POS Tags: " . ($word_id-1);
}

# sub pos_tag # WRAPPER FOR BRILL
# {
#     my $word;
#     my $cont;

#     print STDERR "   Part-Of-Speech tagging...";
#     open CORPUS,">$TMPFILE.corpus.tmp";
#     binmode(CORPUS,":utf8");
#     foreach $word(sort Alvis::NLPPlatform::Annotation::sort_keys keys %Alvis::NLPPlatform::hash_words){
# 	$cont=$Alvis::NLPPlatform::hash_words{$word};
# 	print CORPUS "$cont ";
# 	if($cont eq "."){
# 	    print CORPUS "\n";
# 	}
#     }
#     close CORPUS;
# }

 
=head2 lemmatization()

    lemmatisation($h_config, $doc_hash);

This methods wraps the default lemmatizer. C<$doc_hash> is the
hashtable containing containing all the annotations of the input
document. However, as POS Tagger TreeTagger also gives lemma, this
method does ... nothing. It is here just for conformance.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut


sub lemmatization
{
    my ($class, $h_config, $doc_hash) = @_;

}

=head2 term_tag()

    term_tag($h_config, $doc_hash);

The method wraps the term tagging step of the ALVIS NLP
Platform. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. This step aims at recognizing terms
in the documents differing from named entities (see
C<Alvis::TermTagger>), like I<gene expression>, I<spore coat
cell>. Term lists can be provided as terminological resources such as
the Gene Ontology (http://www.geneontology.org/ ), the MeSH
(http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=mesh ) or more widely
UMLS (http://umlsinfo.nlm.nih.gov/ ). They can also be acquired through
corpus analysis.




The term matching in the document is carried out according to
typographical and inflectional variations. 
The typographical variation requires a slight preprocessing of the
terms.



We first assume a less strict use of the dash character. For instance,
the term I<UDP-glucose> can appear in the documents as I<UDP glucose>
and vice versa.  The inflectional variation requires a lemmatization
of the input documents. It makes it possible to identify
I<transcription factors> from I<transcription factor>.  Both variation
types can be taken into account altogether or separately during the
term matching.  Previous annotation levels, such as lemmatisation and
word segmentation but also named entities, are required.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

# TODO : Check that term tagging is only performed on english texts

sub term_tag
{
    my ($class, $h_config, $doc_hash) = @_;

    my $cont;
    my $word;
    my $sentence;
    my $i;
    my $s;
    my $line;
    my $tmp;
    my %tabh_sent_terms;
    my $key;
    my $sent;
    my $term;
    my $phrase_idx=1;
    my $canonical_form;
    my %corpus;
    my %lc_corpus;
    my $sent_id;
    my $command_line;
    my %corpus_index;
    my %idtrm_select;
    my @tab_results;


    print STDERR "  Term tagging...         ";

#     open CORPUS,">" . $h_config->{'TMPFILE'} . ".corpus.tmp" or die "Cannot create input file for term tagger";
#     binmode(CORPUS,":utf8");

    $sent_id = 1;
    foreach $sentence(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_sentences)){
	$tmp = "$Alvis::NLPPlatform::hash_sentences{$sentence}\n";
	$tmp=~s/\n/\\n/g;
	$tmp=~s/\r/\\r/g;
	$tmp=~s/\t/\\t/g;
	$corpus{$sent_id} = $tmp;
	$lc_corpus{$sent_id} = lc($tmp);
# 	print CORPUS "$tmp\n";
	$sent_id++;
    }
#     close CORPUS;


    # Term list loading 

    if (scalar(@term_list) == 0) {
	if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	    Alvis::TermTagger::load_TermList($h_config->{'NLP_misc'}->{'TERM_LIST_FR'},\@term_list);
	  } else {
	      Alvis::TermTagger::load_TermList($h_config->{'NLP_misc'}->{'TERM_LIST_EN'},\@term_list);
	    }
	Alvis::TermTagger::get_Regex_TermList(\@term_list, \@regex_term_list);
      }


    Alvis::TermTagger::corpus_Indexing(\%lc_corpus, \%corpus_index);
    Alvis::TermTagger::term_Selection(\%corpus_index, \@term_list, \%idtrm_select);
#     Alvis::TermTagger::term_tagging_offset(\@term_list, \@regex_term_list, \%idtrm_select, \%corpus, $h_config->{'TMPFILE'} . ".result.tmp");
     Alvis::TermTagger::term_tagging_offset_tab(\@term_list, \@regex_term_list, \%idtrm_select, \%corpus, \%tabh_sent_terms);

    
#     if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
# #  	$command_line = $h_config->{"NLP_tools"}->{"TERM_TAG_FR"} . " " . $h_config->{'NLP_misc'}->{'TERM_LIST_FR'} . " " . $h_config->{'TMPFILE'} . ".tempo " . $h_config->{'TMPFILE'} . ".result.tmp < " . $h_config->{'TMPFILE'} . ".corpus.tmp 2> /dev/null";
# 	$command_line = $h_config->{"NLP_tools"}->{"TERM_TAG_FR"} . " " . $h_config->{'TMPFILE'} . ".corpus.tmp " . $h_config->{'NLP_misc'}->{'TERM_LIST_FR'} . " " . $h_config->{'TMPFILE'} . ".result.tmp  2> /dev/null";
#     }else{
# #  	$command_line = $h_config->{"NLP_tools"}->{"TERM_TAG_EN"} . " " . $h_config->{'NLP_misc'}->{'TERM_LIST_EN'} . " " . $h_config->{'TMPFILE'} . ".tempo " . $h_config->{'TMPFILE'} . ".result.tmp < " . $h_config->{'TMPFILE'} . ".corpus.tmp 2> /dev/null";
# 	$command_line = $h_config->{"NLP_tools"}->{"TERM_TAG_EN"} . " " . $h_config->{'TMPFILE'} . ".corpus.tmp " . $h_config->{'NLP_misc'}->{'TERM_LIST_EN'} . " " . $h_config->{'TMPFILE'} . ".result.tmp  2> /dev/null";
#     }
#     `touch $h_config->{'TMPFILE'}.result.tmp`;
# #    print STDERR "\n\n$command_line\n\n";
#     `$command_line`;

#     open TERMS,"<:utf8", $h_config->{'TMPFILE'} . ".result.tmp" or die "File " . $h_config->{'TMPFILE'} . ".result.tmp not found\n";

#     while($line=<TERMS>){
# 	chomp $line;
# 	my @tab_line = split /\t/, $line;
# 	$tabh_sent_terms{$tab_line[0] . "_" . $tab_line[1]} = \@tab_line;
#     }
#     close TERMS;

    my $token_start;
    my $token_end;
    my $offset_start;
    my $offset_end;
    my $offset;

    my $token_term;
    my $token_term_end;
    my $j;

# TODO : tanking into account the case where terms appear at least twice in a sentence

    $i=0;
    for $key (keys %tabh_sent_terms) {
	$sent = $tabh_sent_terms{$key}->[0];
	$term = $tabh_sent_terms{$key}->[1];

        $canonical_form = $tabh_sent_terms{$key}->[2];

	# loot for the term in the sentence, compute the reference to the words
	$token_term = -1;
	$offset = 0;
	while (($offset != -1)&&($token_term == -1)) {
	    if ($Alvis::NLPPlatform::hash_sentences{"sentence$sent"} =~ /$term/igc) { # replace regex by index/subtring ?
		$offset = length($`);
	    } else {
		$offset = -1;
	    }
	    if ($offset != -1) {
		$doc_hash->{"sentence$sent"}->{"refid_start_token"}=~m/token([0-9]+)/i;
		$token_start=$1;
		$doc_hash->{"sentence$sent"}->{"refid_end_token"}=~m/token([0-9]+)/i;
		$token_end=$1;
		$offset_start=$doc_hash->{"token$token_start"}->{"from"};
		$offset_end=$doc_hash->{"token$token_end"}->{"to"};

		$offset+=$offset_start;

		for($j=$token_start;$j<$token_end;$j++){
		    if($doc_hash->{"token$j"}->{"from"}==$offset){
			$token_term=$j;
			last;
		    }
		}

		if ($token_term != -1) {
		    $cont="";
		    my @tab_tokens;
		    for($j=$token_term;length($cont)<length($term);$j++){
			$cont.=$Alvis::NLPPlatform::hash_tokens{"token$j"};
			push @tab_tokens, "token$j";
		    }
# 		    print STDERR join ":", @tab_tokens;
# 		    print STDERR "\n";
		    if (length($cont) == length($term)) {
# 			print STDERR "Passe\n"; 
			$token_term_end=$j-1;
			$Alvis::NLPPlatform::hash_sentences{"sentence$sent"} =~ /^/g;
			
			# Creation of a semantic unit
			$s=$Alvis::NLPPlatform::last_semantic_unit;
			$doc_hash->{"semantic_unit$s"}={};
			$doc_hash->{"semantic_unit$s"}->{"datatype"}="semantic_unit";
			$doc_hash->{"semantic_unit$s"}->{"term"}={};
			$doc_hash->{"semantic_unit$s"}->{"term"}->{"datatype"}="term";
			$doc_hash->{"semantic_unit$s"}->{"term"}->{"id"}="term" . $i++;
			$doc_hash->{"semantic_unit$s"}->{"term"}->{"form"}=$term;
			push @Alvis::NLPPlatform::found_terms,$term;
			push @Alvis::NLPPlatform::found_terms_smidx,($i-1);

			if (defined($canonical_form)) {
			    $doc_hash->{"semantic_unit$s"}->{"term"}->{"canonical_form"}=$canonical_form;
			}
			# XXX TO BE OPTIMIZED !!!

			my $k=1;
			my $term_word_start=-1;
			my $term_word_end=-1;
			my @tab_words;
			for($k=1;$k<$Alvis::NLPPlatform::number_of_words;$k++){
 			    if($Alvis::NLPPlatform::word_start[$k]==Alvis::NLPPlatform::Annotation::read_key_id($tab_tokens[0])){
 				$term_word_start=$k;
 			    }
 			    if($Alvis::NLPPlatform::word_end[$k]==Alvis::NLPPlatform::Annotation::read_key_id($tab_tokens[(scalar @tab_tokens)-1])){
 				$term_word_end=$k;
 				last;
 			    }
 			}
			if (($term_word_start != -1) && ($term_word_end != -1)) {
			    for($k=$term_word_start;$k<=$term_word_end;$k++){
				push @tab_words,"word$k";
			    }
			}
			# XXX
                        if (scalar @tab_words == 0) {
# 			    warn "No word found for the term $term\n";
			    $doc_hash->{"semantic_unit$s"}->{"term"}->{"list_refid_token"}={};
			    $doc_hash->{"semantic_unit$s"}->{"term"}->{"list_refid_token"}->{"datatype"} = "list_refid_token";
			    $doc_hash->{"semantic_unit$s"}->{"term"}->{"list_refid_token"}->{"refid_token"}=\@tab_tokens;
			    
			}
			if(scalar @tab_words==1){
			    $doc_hash->{"semantic_unit$s"}->{"term"}->{"refid_word"}=\@tab_words;
			}
			if(scalar @tab_words>1){
			    $doc_hash->{"phrase$phrase_idx"}={};
			    $doc_hash->{"phrase$phrase_idx"}->{'id'}="phrase$phrase_idx";
			    $doc_hash->{"phrase$phrase_idx"}->{'datatype'}="phrase";
			    $doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}={};
			    $doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}->{"datatype"}="list_refid_components";
			    $doc_hash->{"phrase$phrase_idx"}->{'list_refid_components'}->{"refid_word"}=\@tab_words;

			    $doc_hash->{"semantic_unit$s"}->{"term"}->{"refid_phrase"}="phrase$phrase_idx";
			    # At this point, we have created a term and a phrase. We need to commit this to memory,
			    # as it will come in handy!
			    push @Alvis::NLPPlatform::found_terms_phr,$phrase_idx;
			    push @Alvis::NLPPlatform::found_terms_words,\@tab_words;
			    
			    $phrase_idx++;
			}
			else{
			    push @Alvis::NLPPlatform::found_terms_phr,-666; # there is no phrase
			    push @Alvis::NLPPlatform::found_terms_words,\@tab_words;
			}

			$Alvis::NLPPlatform::last_semantic_unit++;
		    } else {
			if ($j <$token_end) {
			    $token_term = -1;
			} else {
			    warn "+++ Term content not found\n"; 

			}
# 			warn "+++ Term content not found\n"; 
		    }
		} else {
# 		    warn "*** Start token of the term \"$tab_term[$i]\"  not found\n"; 
		}
	    }
	}
    }
   #    print STDERR $h_config->{'TMPFILE'} . ".result.tmp\n";
    unlink $h_config->{'TMPFILE'} . ".corpus.tmp";
    unlink $h_config->{'TMPFILE'} . ".result.tmp";
    print STDERR "done - Found ". ($i) ." semantic units\n";
    push @{$doc_hash->{"log_processing1"}->{"comments"}},  "Found Terms: " . $i;
}

=head2 syntactic_parsing()

    syntactic_parsing($h_config, $doc_hash);

This method wraps the default sentence parsing. It aims at exhibiting
the graph of the syntactic dependency relations between the words of
the sentence. C<$doc_hash> is the hashtable containing containing all
the annotations of the input document.

C<$hash_config> is the reference to the hashtable containing the
variables defined in the configuration file.

The Link Grammar Parser (Daniel D. Sleator and Davy Temperley.
I<Parsing {E}nglish with a link grammar>. Third International Workshop
on Parsing Technologies. 1993. http://www.link.cs.cmu.edu/link/ ) is
actually integrated.


Processing time is a critical point for syntactic parsing, but we
expect that a good recognition of the terms can reduce significantly
the number of possible parses and consequently the parsing processing
time.  Term identification is therefore performed prior to parsing.
The word level of annotation is required. Depending on the choice of
the parser, the morphosyntactic level may be needed. 


=cut

# TODO : Check that parsing is only performed on english texts

# TODO TODO : Check this method

sub syntactic_parsing{
    my ($class, $h_config, $doc_hash) = @_;
    my $line;
    my $insentence;
    my $sentence;

    my $tokens;
    my $analyses;
    my $analysis;
    my $nsentence;
    my $token_start;
    my $token_end;
    my $relation;
    my $left_wall;
    my $right_wall;

    my $relation_id;

    my @arr_tokens;
    my $last_token;
    my $wordidshift=0;

    print STDERR "  Performing syntactic analysis...";
    open CORPUS,">" . $h_config->{'TMPFILE'}. ".corpus.tmp";
    print CORPUS "!whitespace\n";
    print CORPUS "!postscript\n";
    print CORPUS "!graphics\n";
    print CORPUS "!union\n";
    print CORPUS "!walls\n";
#    print CORPUS "!width=10000\n";

    my $word;
    my $word_cont;
    my $word_id;
    my $i;
    my $sentences_cont="";

    my @tab_word_punct;
    my @tab_word;
    my $idx_tab_word_punct=1;
    my $idx_tab_word=1;
    my @tab_mapping;
    my $inpostscript_output = 0;
    my $ingraphics_output = 0;

    # print out words+punct and fill in a tab
    push @tab_word_punct," ";
    push @tab_word," ";

    foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words_punct)){

	# print word
	$word_cont=$Alvis::NLPPlatform::hash_words_punct{$word};
	push @tab_word_punct,$word_cont;
	if($word_cont eq "."){
	    $sentences_cont.="\n";
	}else{
	    my $word_tmp=$word_cont;
	    $word_tmp=~s/ /\_/g;
	    $sentences_cont.="$word_tmp ";
	}
    }

    # fill words tab
    foreach $word (Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){
	push @tab_word,$Alvis::NLPPlatform::hash_words{$word};
    }

    # pre-compute mapping between words+punct and words
    my $idx_nopunct=1;
    for($i=0;$i<scalar @tab_word_punct;$i++){
	if(($idx_nopunct<scalar @tab_word)&&($tab_word_punct[$i] eq $tab_word[$idx_nopunct])){
#	    print STDERR "$tab_word_punct[$i] => $tab_word[$idx_nopunct] ($i => $idx_nopunct)    $Alvis::NLPPlatform::hash_words{'word'.$idx_nopunct}\n";
	    $tab_mapping[$idx_nopunct]=$idx_nopunct;
	    $idx_nopunct++;
	}
    }

    # remove whitespaces in NE
#     my $ne;
#     my $ne_cont;
#     my $ne_mod;
#     foreach $ne(keys %Alvis::NLPPlatform::hash_named_entities){
# 	$ne_cont=$Alvis::NLPPlatform::hash_named_entities{$ne};
# 	$ne_mod=$ne_cont;
# 	if($ne_cont=~/ /){
# 	    if($sentences_cont=~/$ne_cont/){
# 		print STDERR "Found NE $ne_cont in sentence\n";
# 		$ne_mod=~s/ /\_/g;
# 		$sentences_cont=~s/$ne_cont/$ne_mod/g;
# 	    }
# 	}
#     }
    
    print CORPUS $sentences_cont;
    close CORPUS;

    # generate input for syntactic analyser

    my $command_line;

    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	# French parser command line
    }else{
	$command_line = $h_config->{'NLP_tools'}->{'SYNTACTIC_ANALYSIS_EN'} . " < " . $h_config->{'TMPFILE'} . ".corpus.tmp > " . $h_config->{'TMPFILE'} . ".result.tmp 2> /dev/null";
    }

    `$command_line`;

    unlink $h_config->{'TMPFILE'} . ".corpus.tmp";

    # process syntactic analysis

    $insentence=0;
    $nsentence=0;
    $relation_id=1;

    open SYN_RES,"<" . $h_config->{'TMPFILE'} . ".result.tmp";

    while($line=<SYN_RES>)
    {
#  	print STDERR $line;
	if(index($line,"[(")==0){
	    $insentence=1;
            # XXX
	    $nsentence++;
	    $sentence="";
	    $tokens="";
	    $analyses="";
	    $left_wall=0;
	}
	if($insentence==1){
	    $sentence.=$line;
# 	    if ($h_config->{NLP_tools}->{'PARSING_IN_P0STSCRIPT'}) {
# 		if ($inpostscript_output) {
# 		    if (index($line,"[]")==0){
# 			$line =~ s/^\[\]/\[0\]/;
# 		    }
# 		    print PS_FILE "$line";
# 		    if (index($line, "%%EndDocument") == 0) {
# 			$inpostscript_output = 0;
# 			close PS_FILE;
# 		    }
# 		}
# 	    }
# 	}   else {
# 	    if ($h_config->{NLP_tools}->{'PARSING_IN_P0STSCRIPT'}) {
# 		if (index($line, "%!PS-Adobe") == 0) { 
# 		    open PS_FILE , ">" . $h_config->{NLP_tools}->{'PARSING_P0STSCRIPT_DIR'} . "/sentence" . ($nsentence+1) . ".eps";
# 		    $inpostscript_output = 1;

# 		}   
# 		if ($inpostscript_output) {
# 		    print PS_FILE "$line";
# 		}
# 	    }
# 	    if ($h_config->{NLP_tools}->{'PARSING_GRAPHICS'}) {
# 		if (index($line, "  Linkage") == 0) {
# 		    $ingraphics_output = 1;
# 		    open GRAPH_FILE, ">" . $h_config->{NLP_tools}->{'PARSING_P0STSCRIPT_DIR'} . "/sentence" . ($nsentence+1) . ".txt";
# 		} else {
# 		    if ($ingraphics_output) {
# 			print GRAPH_FILE "$line";
# 			if (index($line,"LEFT-WALL") == 0) {
# 			    close GRAPH_FILE;
# 			    $ingraphics_output = 0;
# 			}
# 		    }
# 		}

# 	    }
	}
	if(index($line,"[]")==0){
	    # process the line
	    $sentence=~s/\[Sentence\s+[0-9]+\]//sgo;
	    $sentence=~s/\[Linkage\s+[0-9]+\]//sgo;
	    $sentence=~s/\[\]//sgo;
	    $sentence=~s/\n//sgo;
# 	    $sentence=~s/\[[0-9\s]*\]diagram$//g;
	    if ($sentence=~m/^(.+)\[\[/) {
		$tokens=$1;
		$analyses = $';
	    # output'
		
		# search left-wall to shift identifiers
		if($tokens=~/LEFT\-WALL/so){
		    $left_wall=1;
		}else{
		    $left_wall=0;
		}
		
		# search right-wall, simply to ignore it
		if($tokens=~/RIGHT\-WALL/so){
		    $right_wall=1;
		}else{
		    $right_wall=0;
		}

		# parse tokens
		@arr_tokens=split /\)\(/,$tokens;
		$last_token=(scalar @arr_tokens)-1;
		$arr_tokens[0]=~s/^\[\(//sgo;
		$arr_tokens[$last_token]=~s/\)\]$//sgo;

# 	    my $tmpfdsf;
# 	    for($tmpfdsf=0;$tmpfdsf<=$last_token;$tmpfdsf++){
# 		#print STDERR "******\$\$\$\$\$\$****** ($tmpfdsf) $arr_tokens[$tmpfdsf]\n";
# 	    }

		# Parsing
		while($analyses=~/(\[[0-9]+\s[0-9]+\s[0-9]+\s[^\]]+\])/sgoc){
		    $analysis=$1;
		    $analysis=~m/\[([0-9]+)\s([0-9]+)\s([0-9]+)\s\(([^\]]+)\)\]/sgo;
		    $token_start=$1;
		    $token_end=$2;
		    $relation=$4;
		    if(
		       (($left_wall==1)&&(($token_start==0) || ($token_end==0)))
		       ||(($right_wall==1)&&(($token_start==$last_token) || ($token_end==$last_token)))
		       ){
			# ignore any relation with the left or right wall
		    }else{
			if($left_wall==0){
			    $token_start++;
			    $token_end++;
			}
			# make sure we're not dealing with punctuation, otherwise just ignore'
			if((defined($tab_mapping[$token_start+$wordidshift])) && (defined($tab_mapping[$token_end+$wordidshift]) ne "")){
#                        if($tab_mapping[($token_start+$wordidshift)]==14){
#                            if($tab_mapping[($token_end+$wordidshift)]==15){
#                                 print STDERR "\n";
#                                 print STDERR "Salete de bug:\n";
#                                 print STDERR "$token_start ; $token_end ; $wordidshift\n";
#                                 print STDERR "\n";
#                            }
#                        }
#                        print STDERR "$relation (".$tab_mapping[($token_start+$wordidshift)]." ; ".$tab_mapping[($token_end+$wordidshift)].")\n";
			    $doc_hash->{"syntactic_relation$relation_id"}={};
			    $doc_hash->{"syntactic_relation$relation_id"}->{'id'}="syntactic_relation$relation_id";
			    $doc_hash->{"syntactic_relation$relation_id"}->{'datatype'}="syntactic_relation";
			    $doc_hash->{"syntactic_relation$relation_id"}->{'syntactic_relation_type'}="$relation";
			    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'} = {};
			    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{'datatype'}="refid_head";
			    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{"refid_word"}="word".$tab_mapping[($token_start+$wordidshift)];
# 			$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}="word".$tab_mapping[($token_start+$wordidshift)];
			    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'} = {};
			    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{'datatype'}="refid_modifier";
			    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{"refid_word"}="word".$tab_mapping[($token_end+$wordidshift)];
# 			$doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}="word".$tab_mapping[($token_end+$wordidshift)];
			    
			    $relation_id++;
			}
		    }
		}
            }
	    # trash everything and continue the loop

	    $insentence=0;
#	    print STDERR "Word ID shift changing from $wordidshift to ";
	    $wordidshift+=$last_token-1;
#           print STDERR "$wordidshift\n";
	}
    }
    close SYN_RES;

    unlink $h_config->{'TMPFILE'} . ".result.tmp";

    $Alvis::NLPPlatform::nb_relations=$relation_id-1;

    print STDERR "done - Found $Alvis::NLPPlatform::nb_relations relations.\n";

}



=head2 semantic_feature_tagging()

    semantic_feature_tagging($h_config, $doc_hash)

The semantic typing function attaches a semantic type to the words,
terms and named-entities (referred to as lexical items in the
following) in documents according to the conceptual hierarchies of the
ontology of the domain. C<$doc_hash> is the hashtable containing
containing all the annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Currently, this step is not integrated in the platform.

=cut

sub semantic_feature_tagging
{

    my ($class, $h_config, $doc_hash) = @_;

}

=head2 semantic_relation_tagging()

    semantic_relation_tagging($h_config, $doc_hash)


This method wraps the semantic relation identification
step. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. In the Alvis project, the default
behaviour is the identification of domain specific semantic relations,
i.e. relations occurring between instances of the ontological concepts
in the document. These instances are identified and tagged accordingly
by the semantic typing. As a result, these semantic relation
annotations give another level of semantic representation of the
document that makes explicit the role that these semantic units
(usually named-entities and/or terms) play with respect to each other,
pertaining to the ontology of the domain.  However, this annotation
depends on previous document annotations and two different tagging
strategies, depending on the two different processing lines
(annotation of web documents and acquisition of resources used at the
web document annotation process) that impact the implementation of the
semantic relation tagging:

=over 

=item * If the document is syntactically parsed, the method can
exploit this information to tag relations mentioned explicitly. This
is achieved through the pattern matching of information extraction
rules. The rule matcher
that exploits them. The semantic relation tagger is therefore a mere
wrapper for the inference method.

=item * In the case where the document is not syntactically parsed,
the method will base its tagging on relations given by the ontology,
that is to say all known relations holding between semantic units
described in the document will be added, whether those relations be
explicitly mentioned in the document or not.

=back

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Currently, this step is not integrated in the platform.

=cut

sub semantic_relation_tagging
{

    my ($class, $h_config, $doc_hash) = @_;

}

=head2 anaphora_resolution()

    anaphora_resolution($h_config, $doc_hash)

The methods wraps the tool which aims at identifing and solving the
anaphora present in a document. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. We
restrict the resolution to the anaphoras for the pronoun I<it>.  The
anaphora resolution takes as input an annotated document coming from
the semantic type tagging, in the ALVIS format and produces an
augmented text with XML tags corresponding to anaphora relations
between antecedents and pronouns, in the ALVIS format.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Currently, this step is not integrated in the platform.

=cut

sub anaphora_resolution
{
    my ($class, $h_config, $doc_hash) = @_;


}

# =head1 ENVIRONMENT

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
