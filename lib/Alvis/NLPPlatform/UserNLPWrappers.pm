package Alvis::NLPPlatform::UserNLPWrappers;


use Alvis::NLPPlatform::NLPWrappers;

use strict;

use Data::Dumper;

our @ISA = ("Alvis::NLPPlatform::NLPWrappers");


=head1 NAME

Alvis::NLPPlatform::UserNLPWRapper - User interface for customizing
the NLP wrappers used to linguistically annotating of XML documents
in Alvis

=head1 SYNOPSIS

use Alvis::NLPPlatform::UserNLPWrapper;

Alvis::NLPPlatform::UserNLPWrappers->tokenize($h_config,$doc_hash);

=head1 DESCRIPTION

This module is a mere interface for allowing the cutomisation of the
NLP Wrappers. Anyone who wants to integrated a new NLP tool has to
overwrite the default wrapper. The aim of this module is to simplify
the development a specific wrapper, its integration and its use in the
platform.


Before developing a new wrapper, it is necessary to copy and modify
this file in a local directory and add this directory to the PERL5LIB
variable.

=head1 METHODS


=head2 tokenize()

    tokenize($h_config, $doc_hash);

This method carries out the tokenisation process of the input
document. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. See documentation in
C<Alvis::NLPPlatform::NLPWrappers>.  It is not recommended to
overwrite this method.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

The method returns the number of tokens.

=cut


sub tokenize {
    my @arg = @_;

    my $class = shift @arg;

    return($class->SUPER::tokenize(@arg));

}

=head2 scan_ne()

    scan_ne($h_config, $doc_hash);

This method wraps the Named entity recognition and tagging
step. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.  It aims at annotating semantic
units with syntactic and semantic types. Each text sequence
corresponding to a named entity will be tagged with a unique tag
corresponding to its semantic value (for example a "gene" type for
gene names, "species" type for species names, etc.). All these text
sequences are also assumed to be equivalent to nouns: the tagger
dynamically produces linguistic units equivalent to words or noun
phrases.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut


sub scan_ne 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::scan_ne(@arg);

}

=head2 word_segmentation()

    word_segmentation($h_config, $doc_hash);

This method wraps the default word segmentation step.  C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.  

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub word_segmentation 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::word_segmentation(@arg);

}

=head2 sentence_segmentation()

    sentence_segmentation($h_config, $doc_hash);

This method wraps the default sentence segmentation step.
C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub sentence_segmentation 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::sentence_segmentation(@arg);

}

=head2 pos_tag()

    pos_tag($h_config, $doc_hash);

The method wraps the Part-of-Speech (POS) tagging.  C<$doc_hash> is
the hashtable containing containing all the annotations of the input
document.  For every input word, the wrapped Part-Of-Speech tagger
outputs its tag.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub pos_tag 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::pos_tag(@arg);

}

=head2 lemmatization()

    lemmatization($h_config, $doc_hash);

This methods wraps the lemmatizer. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. For
every input word, the wrapped lemmatizer outputs its lemma i.e. the
canonical form of the word..

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub lemmatization 
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::lemmatization(@arg);

}


=head2 term_tag()

    term_tag($h_config, $doc_hash);

The method wraps the term tagging step of the ALVIS NLP
Platform. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document. This step aims at recognizing terms
in the documents differing from named entities, like I<gene
expression>, I<spore coat cell>.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub term_tag
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::term_tag(@arg);

}

=head2 syntactic_parsing()

    syntactic_parsing($h_config, $doc_hash);

This method wraps the sentence parsing. It aims at exhibiting the
graph of the syntactic dependency relations between the words of the
sentence. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

Here is a example of how to tune the platform according to the
domain. We integrated and wrapped the BioLG parser, specialized for
biology text parsing.

=cut


sub syntactic_parsing
{
    my @arg = @_;

    
    my $class = shift @arg;

       $class->SUPER::syntactic_parsing(@arg);
#        &bio_syntactic_parsing(@arg);
}


=head2 bio_syntactic_parsing()

    bio_syntactic_parsing($h_config, $doc_hash);

This method wraps the sentence parsing tuned for biology texts. As the
default wrapper (C<syntactic_parsing>), it aims at exhibiting the
graph of the syntactic dependency relations between the words of the
sentence. C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$h_config> is the reference to the hashtable containing the
variables defined in the configuration file.

We actually integrage a version of the Link Parser tuned for the
biology: BioLG (Sampo Pyysalo, Tapio Salakoski, Sophie Aubin and
Adeline Nazarenko. I<Lexical Adaptation of Link Grammar to the
Biomedical Sublanguage: a Comparative Evaluation of Three
Approaches>. Proceedings of the Second International Symposium on
Semantic Mining in Biomedicine (SMBM 2006). Pages 60-67. Jena,
Germany, 2006).

=cut

# TODO : Check that parsing is only performed on english texts

sub bio_syntactic_parsing {
    my ($h_config, $doc_hash) = @_;

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
    open CORPUS, ">" . $h_config->{"TMPFILE"} . ".corpus.tmp";
    print CORPUS "<sentences>\n\n";
    print CORPUS "<sentence>\n";

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

    # print out words+punct and fill in a tab
    push @tab_word_punct," ";
    push @tab_word," ";
    my $decal=1;

    my $searchterm;
    my $sti;
    my $word_np;
	    
    my @tab_tmp;
    my $tmp_sp;
    my $spi=0;

    my $termsfound=0;
    my $stubs=0;

    my $skip=0;

    my @tab_start_term=();
    my @tab_end_term=();


    foreach $word(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words_punct)){
	if($skip>0){
	    $skip--;
#	    next;
	}
	# print word
	$word_cont=$Alvis::NLPPlatform::hash_words_punct{$word};
	push @tab_word_punct,$word_cont;

	my $postag=$Alvis::NLPPlatform::hash_postags{"word$decal"};
	if((exists $Alvis::NLPPlatform::hash_words{"word$decal"})&&($word_cont ne $Alvis::NLPPlatform::hash_words{"word$decal"})){
	    # punctuation, delay incrementation of index "decal"
	    $decal--;
	    $postag="PUNCT";
	}

	if($word_cont eq "."){
	    $sentences_cont.="<w c=\"SENT\">.</w>\n";
	    $sentences_cont.="</sentence>\n";
	    $sentences_cont.="<sentence>\n";
	}else{
	    # determine if current word is part of a term
	    $searchterm="";
	    @tab_tmp=();
	    $tmp_sp=0;

	    $word_np=$Alvis::NLPPlatform::hash_words{"word$decal"};
	    for($sti=0;$sti<scalar @Alvis::NLPPlatform::found_terms;$sti++){
		my $ref_tab_tmp_words;
		$searchterm=$Alvis::NLPPlatform::found_terms[$sti];
#		print STDERR "Searching for term $searchterm / comparing with word ".$Alvis::NLPPlatform::hash_words{"word$decal"}."\n";
		$ref_tab_tmp_words=$Alvis::NLPPlatform::found_terms_words[$sti];
#		print STDERR "word$decal- Searching for term ($sti) $searchterm / words ";
#		print STDERR join ",",@$ref_tab_tmp_words;
#		print STDERR "\n";

		if(lc($Alvis::NLPPlatform::hash_words{"word$decal"}) eq lc($searchterm)){
		    # look for one-word terms
#		    print STDERR "\n--== Found term $searchterm ==--\n";
#		    print STDERR "word$decal makes up '$searchterm' on its own (single word/NE).\n";
		    $termsfound++;
		    push @Alvis::NLPPlatform::found_terms_tidx,$sti;
		    $sti=scalar @Alvis::NLPPlatform::found_terms;
		    $tmp_sp=1;
		    last;
		}else{
		    # look for multiple word terms (they have to be phrases)
		    if($Alvis::NLPPlatform::found_terms_phr[$sti] != -666){
			# determine if the current word ($decal) is part of it
			# then set $tmp_sp to the nb of words involved
			if(@$ref_tab_tmp_words[0] eq "word$decal"){
			    # the current word is the first word of the term
#			    print STDERR "word$decal is the first word of the term '$searchterm'.\n";
			    $termsfound++;
			    push @Alvis::NLPPlatform::found_terms_tidx,$sti;
			    $sti=scalar @Alvis::NLPPlatform::found_terms;
			    $tmp_sp=scalar @$ref_tab_tmp_words;
			    last;
			}
		    }
		    
###############################################
# 		    if($searchterm=~/^$word_np/i){
# 			print STDERR "\n--== $word_np is the beginning of $searchterm ==--\n";
# 			$stubs++;

# 			@tab_tmp=split / /,$searchterm;
# 			$tmp_sp=scalar @tab_tmp;
#		        print STDERR "--== $tmp_sp words, right? ==--\n";
# 			$skip=$tmp_sp;

# 			for($spi=$decal+1;$spi<$decal+$tmp_sp;$spi++){
# 			    $word_np.=" ".$Alvis::NLPPlatform::hash_words{"word$spi"};
# 			}
# 			print STDERR "--== Rebuilt term to $word_np ==--\n";
# 			$termsfound++;
# 			push @Alvis::NLPPlatform::found_terms_tidx,$sti;
# 			$sti=scalar @Alvis::NLPPlatform::found_terms;
# 			last;
# 		    }
###############################################
		}
		$searchterm="";
	    }
	    #
	    if($searchterm eq ""){
		# there was no term
		$sentences_cont.="<w c=\"$postag\">$word_cont</w>\n";
	    }else{
		# there was a term
#		print STDERR "Searchterm : $searchterm\n";
#		print STDERR "word_np : $word_np\n";
		$sentences_cont.="<term c=\"$postag\" parse_as=\"$word_cont.n\" internal=\"\" head=\"0\">\n";
		# insert all the words that make up this term
		my $nbsteps=$decal+$tmp_sp;
		if($nbsteps==$decal){
		    $nbsteps++;
		}
		push @tab_start_term,$decal;
		push @tab_end_term,($nbsteps-1);
		for($spi=$decal;$spi<$nbsteps;$spi++){
		    $sentences_cont.="<w c=\"NN\">".$Alvis::NLPPlatform::hash_words{"word$spi"}."</w>\n";
#		    print STDERR "Adding ".$Alvis::NLPPlatform::hash_words{"word$spi"}."\n";
		}
		##
		$sentences_cont.="</term>\n";
	    }
	}

	$decal++;

    }

    # fill words tab
    foreach $word(Alvis::NLPPlatform::Annotation::sort(\%Alvis::NLPPlatform::hash_words)){
	push @tab_word,$Alvis::NLPPlatform::hash_words{$word};
    }

    # pre-compute mapping between words+punct and words
    my $idx_nopunct=1;
    for($i=0;$i<scalar @tab_word_punct;$i++){
	if(($idx_nopunct<scalar @tab_word)&&($tab_word_punct[$i] eq $tab_word[$idx_nopunct])){
	    $tab_mapping[$i]=$idx_nopunct;
	    $idx_nopunct++;
	}
    }
#     for($i=0;$i<scalar @tab_mapping;$i++){
# 	print STDERR "$i : " . $tab_mapping[$i] . "\n";
#     }

    # remove whitespaces in NE
    my $ne;
    my $ne_cont;
    my $ne_mod;
    foreach $ne(keys %Alvis::NLPPlatform::hash_named_entities){
	$ne_cont=$Alvis::NLPPlatform::hash_named_entities{$ne};
	$ne_mod=$ne_cont;
	if($ne_cont=~/ /){
	    if($sentences_cont=~/\Q$ne_cont\E/){
		$ne_mod=~s/ /\_/g;
		$sentences_cont=~s/$ne_cont/$ne_mod/g;
	    }
	}
    }

    $sentences_cont=~s/<sentence>\n$//sgo;
    print CORPUS $sentences_cont;
    print CORPUS "\n\n</sentences>\n";
    close CORPUS;

    my $command_line;

    if($Alvis::NLPPlatform::Annotation::ALVISLANGUAGE eq "FR"){
	# French parser command line
    }else{
	$command_line = $h_config->{'NLP_tools'}->{'SYNTACTIC_ANALYSIS_EN'} . " < " . $h_config->{'TMPFILE'} . ".corpus.tmp > " . $h_config->{'TMPFILE'} . ".result.tmp 2> /dev/null";
    }
    `$command_line`;

    # process syntactic analysis

    $insentence=0;
    $nsentence=0;
    $relation_id=1;

    open SYN_RES, "<" . $h_config->{'TMPFILE'}. ".result.tmp";

    while($line=<SYN_RES>)
    {
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
	}
# 	if(index($line,"diagram")==0){
	if(index($line,"[]")==0){
	    # process the line
	    $sentence=~s/\[Sentence\s+[0-9]+\]//sgo;
	    $sentence=~s/\[Linkage\s+[0-9]+\]//sgo;
	    $sentence=~s/\[\]//sgo;
	    $sentence=~s/\n//sgo;
# 	    $sentence=~s/\[[0-9\s]*\]diagram$//g;
	    if ($sentence=~m/^(.+)\[\[/) {
		$tokens=$1;
	#	print STDERR "\n\n--> $sentence\n\n";
		$analyses = $';
            # '
		# output
		# search left-wall to shift identifiers
		if($tokens =~ /LEFT\-WALL/so){
		    $left_wall=1;
		}else{
		    $left_wall=0;
		}
		
		# search right-wall, simply to ignore it
		if($tokens =~ /RIGHT\-WALL/so){
		    $right_wall=1;
		}else{
		    $right_wall=0;
		}

		# parse tokens
		@arr_tokens=split /\)\(/,$tokens;
		$last_token=(scalar @arr_tokens)-1;
		$arr_tokens[0]=~s/^\[\(//sgo;
		$arr_tokens[$last_token]=~s/\)\]$//sgo;

#	    my $tmpfdsf;
# 	    for($tmpfdsf=0;$tmpfdsf<=$last_token;$tmpfdsf++){
# 		#print STDERR "******\$\$\$\$\$\$****** ($tmpfdsf) $arr_tokens[$tmpfdsf]\n";
# 	    }

		# Parsing
		my $valid_analysis;
		while($analyses=~/(\[[0-9]+\s[0-9]+\s[0-9]+\s[^\]]+\])/sgoc){
		    my $kref=0;
		    $analysis=$1;
		    if($analysis=~m/\[([0-9]+)\s([0-9]+)\s([0-9]+)\s\(([^\]]+)\)\]/sgo){ # m??
			$valid_analysis=1;
		    }else{
			$valid_analysis=0;
		    }
		    $token_start=$1;
		    $token_end=$2;
		    $relation=$4;
		    if(
		       (($left_wall==1)&&(($token_start==0) || ($token_end==0)))
		       ||(($right_wall==1)&&(($token_start==$last_token) || ($token_end==$last_token)))
			|| ($valid_analysis==0)
		       ){
			# ignore any relation with the left or right wall
#		    print STDERR "$relation [$token_start $token_end] ==> ignored\n";
		    }else{
			if($left_wall==0){
			    $token_start++;
			    $token_end++;
			}
			# make sure we're not dealing with punctuation, otherwise just ignore
			my $tmp1=$token_start+$wordidshift;
			my $tmp2=$token_end+$wordidshift;
			my $tmp1_within=0;
			my $tmp2_within=0;
			if(($tmp1 < scalar @tab_mapping) && ($tmp2 < scalar @tab_mapping)){
# 			print STDERR "$tmp1 $tmp2\n";
# 			if (defined($tab_mapping[$tmp1])) { print STDERR $tab_mapping[$tmp1] . "\n";}
# 			if (defined($tab_mapping[$tmp2])) { print STDERR $tab_mapping[$tmp2] . "\n";}
			    if ((defined($tab_mapping[$tmp1])) && (defined($tab_mapping[$tmp2])) && ($tab_mapping[$tmp1] ne "") && ($tab_mapping[$tmp2] ne "")){
				# determine if there is a relation between a word inside a term and another word not inside a term
				my $lft;
				for($lft=0;$lft<scalar @tab_start_term;$lft++){
				    # is head within term?
				    if(
				    ($tab_mapping[$tmp1]>=$tab_start_term[$lft] &&
					$tab_mapping[$tmp1]<=$tab_end_term[$lft])
					){
					$tmp1_within=1;
				    }

				    # is modifier within term?
				    if(
				    ($tab_mapping[$tmp2]>=$tab_start_term[$lft] &&
					$tab_mapping[$tmp2]<=$tab_end_term[$lft])
					){
					$tmp2_within=1;
				    }

				    # rules set here:
				    # relation between two words in a term: W-W relation
				    # relation between two words outside of a term: W-W relation
				    # relation between a word in a term and another word outside this term: W-P relation
				    if(($tmp1_within+$tmp2_within)==1){
					# one of them is in, the other is out
#					print STDERR "\n";
					# find term id
					$kref=$Alvis::NLPPlatform::found_terms_tidx[$lft];
					$kref++; # it's always >0
					last;
				    }
				}
				$doc_hash->{"syntactic_relation$relation_id"}={};
				$doc_hash->{"syntactic_relation$relation_id"}->{'id'}="syntactic_relation$relation_id";
				$doc_hash->{"syntactic_relation$relation_id"}->{'datatype'}="syntactic_relation";
				$doc_hash->{"syntactic_relation$relation_id"}->{'syntactic_relation_type'}="$relation";
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'} = {};
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{'datatype'}="refid_head";
				if(($kref>0)&&($tmp1_within==1)&&($Alvis::NLPPlatform::found_terms_phr[($kref-1)]!=-666)){
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{"refid_phrase"}="phrase".$Alvis::NLPPlatform::found_terms_phr[($kref-1)];
#				    print STDERR "\n\nSize: ".scalar @Alvis::NLPPlatform::found_terms_phr."\n";
#				    print STDERR "Index: $kref\n\n";
				}else{
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}->{"refid_word"}="word".$tab_mapping[($token_start+$wordidshift)];
				}
# 				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_head'}="word".$tab_mapping[($token_start+$wordidshift)];
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'} = {};
				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{'datatype'}="refid_modifier";
				if(($kref>0)&&($tmp2_within==1)&&($Alvis::NLPPlatform::found_terms_phr[($kref-1)]!=-666)){
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{"refid_phrase"}="phrase".$Alvis::NLPPlatform::found_terms_phr[($kref-1)];
#				    print STDERR "\n\nIndex: $kref\n\n";
				}else{
				    $doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}->{"refid_word"}="word".$tab_mapping[($token_end+$wordidshift)];
				}
# 				$doc_hash->{"syntactic_relation$relation_id"}->{'refid_modifier'}="word".$tab_mapping[($token_end+$wordidshift)];
				
				$relation_id++;
			    }
			}
		    }
		}
		
		# trash everything and continue the loop

		$insentence=0;
		$wordidshift+=$last_token-1;
	    }
	}
    }
    close SYN_RES;

#    print STDERR $h_config->{'TMPFILE'}. ".corpus.tmp" . "\n";
    unlink $h_config->{'TMPFILE'}. ".corpus.tmp";
    unlink $h_config->{'TMPFILE'} . ".result.tmp";

    $Alvis::NLPPlatform::nb_relations=$relation_id-1;

    print STDERR "done - Found $Alvis::NLPPlatform::nb_relations relations, $termsfound full terms, $stubs stubs.\n";
}



=head2 semantic_feature_tagging()

    semantic_feature_tagging($h_config, $doc_hash)

The method wraps the semantic typing step, that is the attachment of a
semantic type to the words, terms and named-entities (referred to as
lexical items in the following) in documents according to the
conceptual hierarchies of the ontology of the domain.

C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub semantic_feature_tagging
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::semantic_feature_tagging(@arg);

}

=head2 semantic_relation_tagging()

    semantic_relation_tagging($h_config, $doc_hash)


This method wraps the semantic relation identification step. These
semantic relation annotations give another level of semantic
representation of the document that makes explicit the role that these
semantic units (usually named-entities and/or terms) play with respect
to each other, pertaining to the ontology of the domain.

C<$doc_hash> is the hashtable containing containing all the
annotations of the input document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub semantic_relation_tagging
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::semantic_relation_tagging(@arg);

}

=head2 anaphora_resolution()

    anaphora_resolution($h_config, $doc_hash)

The methods wraps the anaphora solver. C<$doc_hash> is the hashtable
containing containing all the annotations of the input document. It
aims at identifing and solving the anaphora present in a document.

C<$hash_config> is the
reference to the hashtable containing the variables defined in the
configuration file.

=cut

sub anaphora_resolution
{
    my @arg = @_;

    my $class = shift @arg;

    $class->SUPER::anaphora_resolution(@arg);

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