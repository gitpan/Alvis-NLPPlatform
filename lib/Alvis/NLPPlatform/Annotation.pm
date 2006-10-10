#!/usr/bin/perl -w


###
### Package Annotation
###
### Last updated:
### Thursday, August 31st, 2006
### Julien DERIVIERE, Thierry Hamon
### e-mail: julien.deriviere@lipn.univ-paris13.fr, thierry.hamon@lipn.univ-paris13.fr

package Alvis::NLPPlatform::Annotation;


=head1 NAME

Alvis::NLPPlatform::Annotation - Perl extension for managing XML
annotation of documents in the Alvis format

=head1 SYNOPSIS

use Alvis::NLPPlatform::Annotation;

Alvis::NLPPlatform::Annotation::load_xml($doc_xml);

Alvis::NLPPlatform::Annotation::render_xml($doc_xml, \*STDOUT);

=head1 DESCRIPTION

This module provides two main methods (C<load_xml> and C<render_xml>)
for loading and dumping XML annotated documents conformed to the Alvis
DTD (see http://www.alvis/info ).

Documents are read on the standard input and load in a has
table. Annotated documents are written on a file thanks to the
descriptor given as parameter. Note that the input documents can be
annoted or not, even partially annotated.

=head1 METHODS


=cut

use Alvis::NLPPlatform::MyReceiver;
use Time::HiRes qw(gettimeofday tv_interval);

our $document_record_id;
our $canonicalDocument;
our $acquisitionData;
our $originalDocument;
our $metaData;
our $links;
our $analysis;
our $relevance;
our $documenturl;
our $ALVISLANGUAGE;
our $nb_max_tokens;

my $is_in_canonical;
my $is_in_acquisition;
my $is_in_original;
my $is_in_meta;
my $is_in_links;
my $is_in_analysis;
my $is_in_relevance;


my $header="";

my $end_layer;

# Only for sorting xml id


=head2 read_key_id()

    read_key_id($element_id);

this method returns the number in the id (C<$element_id>) of the token
or word XML element (10 in the element id 'token10').

=cut

sub read_key_id{
    my $id=$_[0];
    $id=~m/^(token|word)([0-9]+)/;
    return $2;
}

=head2 sort_keys()

    sort_keys($element_id1, $element_id2);

This method sorts two xml element ids (C<$element_id1> and
C<$element_id2>) after removing string refering to the type of the xml
element ("token", "word", etc.).

=cut

sub sort_keys {

    my $key1;
    my $key2;
    $a=~m/^(token|word|sentence|semantic_unit|log_processing)([0-9]+)/;
    $key1=$2;
    $b=~m/^(token|word|sentence|semantic_unit|log_processing)([0-9]+)/;
    $key2=$2;
    return -1 if ($key1 < $key2);
    return 0 if ($key1 == $key2);
    return 1 if ($key1 > $key2);

}

=head2 sort()

    sort($ref_hashtable)

This method sorts elements of the hash table (C<$ref_hashtable>)
according to the number in the id (C<$element_id>) of the XML elements
(10 in the element id 'token10').

=cut

sub sort{
    my ($ref_hashtable) = @_;


    return(sort sort_keys keys %$ref_hashtable);


}

sub sort_keys_lex{
    return $a cmp $b;
}

=head2 render()

    render($doc_hash, $descriptor);

Write the XML document annotation in the specified decriptor
(C<$descriptor>). The document is passed as a hashtable (C<$doc_hash>)
loaded by the method load_xml. This hashtable can be modified by NLP
Wrappers (C<Alvis::NLPPlatform::NLPWrappers>).

The method return 0 in case of success.

=cut

sub render{
    my $annot=$_[0];
    my $descriptor = $_[1];


    my $markup_name = "";
    my $key = "";
    my $content = "";
    my $tmp = "";
    my $element = "";
    my $was_list_tab = "";
    my $was_list_hash = "";
    my $list_of = "";
    my $index = "";

    my $layer_tokens=0;
    my $layer_words=0;
    my $layer_sentences=0;
    my $layer_tag=0;
    my $layer_lemma=0;
    my $layer_semantic=0;
    my $layer_phrase=0;
    my $layer_log=0;
    my $layer_parsing=0;

    my  $indent="    "; # for indent


    # Hash table scaning
    foreach $key(sort sort_keys_lex keys %$annot){

	my $hash_key = $annot->{"$key"};

	# Get the key content (it is a reference)
	$content=$annot->{$key};

	if(ref($content) eq "HASH"){
	    # It's a reference to a hash table
	    $markup_name=$content->{"datatype"};


	    # Print in the descriptor the information related to the level
 	    if(($markup_name=~/^token/) && ($layer_tokens==0)){
		if($end_layer ne ""){
		    print $descriptor "$indent$end_layer";
		}
		$layer_tokens=1;
		$end_layer="</token_level>\n";
 		print $descriptor "\n";
 		print $descriptor "$indent<!--*************-->\n";
 		print $descriptor "$indent<!-- TOKEN LAYER -->\n";
 		print $descriptor "$indent<!--*************-->\n";
 		print $descriptor "\n";
		print $descriptor "$indent<token_level>\n";
 	    }

 	    if(($markup_name=~/^word/) && ($layer_words==0)){
		if($end_layer ne ""){
		    print $descriptor "$indent$end_layer";
		}
		$layer_words=1;
		$end_layer="</word_level>\n";
 		print $descriptor "\n";
 		print $descriptor "$indent<!--************-->\n";
 		print $descriptor "$indent<!-- WORD LAYER -->\n";
 		print $descriptor "$indent<!--************-->\n";
 		print $descriptor "\n";
		print $descriptor "$indent<word_level>\n";
 	    }

 	    if(($markup_name=~/^sentence/) && ($layer_sentences==0)){
		if($end_layer ne ""){
		    print $descriptor "$indent$end_layer";
		}
		$layer_sentences=1;
		$end_layer="</sentence_level>\n";
 		print $descriptor  "\n";
 		print $descriptor  "$indent<!--****************-->\n";
 		print $descriptor  "$indent<!-- SENTENCE LAYER -->\n";
 		print $descriptor  "$indent<!--****************-->\n";
 		print $descriptor  "\n";
		print $descriptor  "$indent<sentence_level>\n";
 	    }

 	    if(($markup_name=~/^morphosyntactic/) && ($layer_tag==0)){
		if($end_layer ne ""){
		    print $descriptor  "$indent$end_layer";
		}
		$layer_tag=1;
		$end_layer="</morphosyntactic_features_level>\n";
 		print $descriptor  "\n";
 		print $descriptor  "$indent<!--***********************-->\n";
 		print $descriptor  "$indent<!-- MORPHOSYNTACTIC LAYER -->\n";
 		print $descriptor  "$indent<!--***********************-->\n";
 		print $descriptor  "\n";
		print $descriptor  "$indent<morphosyntactic_features_level>\n";
 	    }

	    if(($markup_name=~/^syntactic/) && ($layer_parsing==0)){
		if($end_layer ne ""){
		    print $descriptor  "$indent$end_layer";
		}
		$layer_parsing=1;
		$end_layer="</syntactic_relation_level>\n";
		print $descriptor  "\n";
		print $descriptor  "$indent<!--**************************-->\n";
		print $descriptor  "$indent<!-- SYNTACTIC RELATION LAYER -->\n";
		print $descriptor  "$indent<!--**************************-->\n";
		print $descriptor  "\n";
		print $descriptor  "$indent<syntactic_relation_level>\n";
	    }

 	    if(($markup_name=~/^lemma/) && ($layer_lemma==0)){
		if($end_layer ne ""){
		    print $descriptor  "$indent$end_layer";
		}
		$layer_lemma=1;
		$end_layer="</lemma_level>\n";
 		print $descriptor  "\n";
 		print $descriptor  "$indent<!--****************-->\n";
 		print $descriptor  "$indent<!--   LEMMA LAYER  -->\n";
 		print $descriptor  "$indent<!--****************-->\n";
 		print $descriptor  "\n";
		print $descriptor  "$indent<lemma_level>\n";
 	    }

 	    if(($markup_name=~/^semantic/) && ($layer_semantic==0)){
		if($end_layer ne ""){
		    print $descriptor  "$indent$end_layer";
		}
		$layer_semantic=1;
		$end_layer="</semantic_unit_level>\n";
 		print $descriptor  "\n";
 		print $descriptor  "$indent<!--*************************-->\n";
 		print $descriptor  "$indent<!--   SEMANTIC UNIT LAYER   -->\n";
 		print $descriptor  "$indent<!--*************************-->\n";
 		print $descriptor  "\n";
		print $descriptor  "$indent<semantic_unit_level>\n";
 	    }

 	    if(($markup_name=~/^phrase/) && ($layer_phrase==0)){
		if($end_layer ne ""){
		    print $descriptor  "$indent$end_layer";
		}
		$layer_phrase=1;
		$end_layer="</phrase_level>\n";
 		print $descriptor  "\n";
 		print $descriptor  "$indent<!--***********************-->\n";
 		print $descriptor  "$indent<!--   PHRASE UNIT LAYER   -->\n";
 		print $descriptor  "$indent<!--***********************-->\n";
 		print $descriptor  "\n";
		print $descriptor  "$indent<phrase_level>\n";
 	    }

 	    if(($markup_name=~/^log/) && ($layer_log==0)){
		if($end_layer ne ""){
		    print $descriptor "$indent$end_layer";
		}
		$layer_log=1;
		$end_layer="</log_level>\n";
 		print $descriptor "\n";
 		print $descriptor "$indent<!--*************-->\n";
 		print $descriptor "$indent<!--  LOG  LAYER -->\n";
 		print $descriptor "$indent<!--*************-->\n";
 		print $descriptor "\n";
		print $descriptor "$indent<log_level>\n";
 	    }

	    # Recursively scan the the mark
	    print $descriptor  "$indent<$markup_name>\n";
	    $tmp=$indent;
	    $indent=$indent."  ";
	    render($content, $descriptor);
	    $indent=$tmp;
	    print $descriptor  "$indent</$markup_name>\n";
	}
	if(ref($content) eq "ARRAY"){
	    # It's a reference to an array
	    print $descriptor  "$indent<$key>";
	    $was_list_tab=0;
	    $was_list_hash=0;
	    $index=0;

	    # Scan the elements of the array
	    foreach $element (@$content){
		$index++;

		if(ref($element) eq "HASH"){
		    # the array contains has table references

		    # Add a carriage return but ignore rendondante ones
		    if(!$was_list_hash){
			print $descriptor  "\n";
		    }
		    # list mark
		    if(($key=~/^list\-(.+) *\n?/)){
			if(!$was_list_hash){
			    $list_of=$1;
			    print $descriptor  "$indent  <$list_of>\n";
			    $was_list_hash=1;
			}else{
			    print $descriptor  "$indent  </$list_of>\n";
			    print $descriptor  "$indent  <$list_of>\n";
			}
		    }

		    # Recursive call since it is a hash table reference
		    $tmp=$indent;
		    $indent=$indent."    ";
		    render($element, $descriptor);
		    $indent=$tmp;
		}

		# Process the element of the list
		if(!ref($element)){

		    if($key=~/^list\-(.+) *\n?/){
			# mark "list-"
			print $descriptor  "\n$indent  <$1>$element</$1>";
			$was_list_tab=1;
		    }else{
			# mark which is not of the type "list-"
			print $descriptor  $element;
			if($index<scalar @$content){
			    print $descriptor  "</$key>\n$indent<$key>"; 
			}
		    }
		}
	    }

	    if($was_list_tab){
		print $descriptor  "\n$indent";
	    }
	    if(($key=~/^list\-(.+) *\n?/) && ($was_list_hash)){
		print $descriptor  "$indent  </$list_of>\n$indent";
	    }
	    print $descriptor  "</$key>\n";
	}

	if(!ref($content)){
	    # Don't print the datatype field
	    # as it's only an internal use
	    # for generate mark name
	    if($key ne "datatype"){
		Alvis::NLPPlatform::XMLEntities::encode($content);
		print $descriptor  "$indent<$key>$content</$key>\n";
	    }
	}
    }
    return(0);
}

=head2 render_xml()


    render($doc_hash, $descriptor);


Main method used for generating XML document
annotations. C<$descriptor> is the decriptor of the file where the
document will be stored. C<$doc_hash> is tha hashtable containing the
annotated document.

The method return 0 in case of success.

=cut

sub render_xml{
    my $doc_xml_hash = $_[0];
    my $descriptor = $_[1];

    my  $indent="    "; # for indent
    $end_layer="";

    print $descriptor "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print $descriptor "<documentCollection xmlns=\"http://alvis.info/enriched/\" version=\"1.1\">\n";
    print $descriptor "<documentRecord id=\"$Alvis::NLPPlatform::Annotation::document_record_id\">\n";
    print $descriptor  "  <acquisition>\n";
    print $descriptor $Alvis::NLPPlatform::Annotation::acquisitionData;
    print $descriptor $Alvis::NLPPlatform::Annotation::originalDocument;
    print $descriptor $Alvis::NLPPlatform::Annotation::canonicalDocument;
    print $descriptor $Alvis::NLPPlatform::Annotation::metaData;
    print $descriptor $Alvis::NLPPlatform::Annotation::links;
    print $descriptor $Alvis::NLPPlatform::Annotation::analysis;
    print $descriptor "  </acquisition>\n";
    print $descriptor "  <linguisticAnalysis>\n";

    # call to the recursive function dunmping annotations
    render($doc_xml_hash, $descriptor); 
    

    if($end_layer ne ""){
	print $descriptor "$indent$end_layer";
	$end_layer="";
    }

    print $descriptor "  </linguisticAnalysis>\n";
    print $descriptor $Alvis::NLPPlatform::Annotation::relevance;
    print $descriptor "</documentRecord>\n";
    print $descriptor "</documentCollection>\n";

    return(0);
}

=head2 load_xml()

    load_xml($doc_xml);

Read a input XML annotated document (C<$doc_xml>) on STDIN. The loaded
annotations are stored in a hashtable. This hashtable can be modified
by NLP Wrappers (C<Alvis::NLPPlatform::NLPWrappers>).

The method return 0 in case of success.

=cut

sub load_xml
{
    my $doc_xml_in = $_[0];
    my @doc_xml;
    @doc_xml = split /\n/, $doc_xml_in;
    my $i;


    my $myreceiver = Alvis::NLPPlatform::MyReceiver->new();
    my $parser = XML::Parser::PerlSAX->new(Handler => $myreceiver);

    my $line;
    $canonicalDocument=""; $is_in_canonical=0;
    $acquisitionData=""; $is_in_acquisition=0;
    $originalDocument=""; $is_in_original=0;
    $metaData=""; $is_in_meta=0;
    $links=""; $is_in_links=0;
    $analysis=""; $is_in_analysis=0;
    $relevance=""; $is_in_relevance=0;

    my $enter="";
    my $n_line;
    $n_line=1;

    $i=0;
    $ALVISLANGUAGE="EN"; # default language is English
    while ($i < scalar(@doc_xml)) {
	$line=$doc_xml[$i];
 	$line .= "\n";
	$i++;
	$n_line++;
	$enter .= $line;
	# <property name="language"></property>
	if($line=~/<property name="language">([^<]+)<\/property>/i)
	{
	    $ALVISLANGUAGE=uc($1);
	}
        # Get the document id
	if($line=~/<documentRecord[ \s]+id[ \s]*=[ \s]*"(.+)">/){
	    $document_record_id=$1;
	}
	# canonicalDocument
	if($line=~/<canonicalDocument[^>]*>/i){$is_in_canonical=1;}
	if($is_in_canonical==1){$canonicalDocument.=$line;}
	if($line=~/<\/canonicalDocument>/i){$is_in_canonical=0;}
	# acquisitionData
	if($line=~/<acquisitionData[^>]*>/i){$is_in_acquisition=1;}
	if($is_in_acquisition==1){$acquisitionData.=$line;}
	if($line=~/<\/acquisitionData>/i){$is_in_acquisition=0;}
	# originalDocument
	if($line=~/<originalDocument[^>]*>/i){$is_in_original=1;}
	if($is_in_original==1){$originalDocument.=$line;}
	if($line=~/<\/originalDocument>/i){$is_in_original=0;}
	# metaData
	if($line=~/<metaData[^>]*>/i){$is_in_meta=1;}
	if($is_in_meta==1){$metaData.=$line;}
	if($line=~/<\/metaData>/i){$is_in_meta=0;}
	# links
	if($line=~/<links[^>]*>/i){$is_in_links=1;}
	if($is_in_links==1){$links.=$line;}
	if($line=~/<\/links>/i){$is_in_links=0;}
	# analysis
	if($line=~/<analysis[^>]*>/i){$is_in_analysis=1;}
	if($is_in_analysis==1){$analysis.=$line;}
	if($line=~/<\/analysis>/i){$is_in_analysis=0;}
	# relevance
	if($line=~/<relevance[^>]*>/i){$is_in_relevance=1;}
	if($is_in_relevance==1){$relevance.=$line;}
	if($line=~/<\/relevance>/i){$is_in_relevance=0;}
	
	# Stop analysis when the first Go out "</documentRecord>" is  encountered
	if($line=~/<\/documentRecord>/i){
	    if (defined $doc_xml[$i]) {
		$enter .= $doc_xml[$i];
	    }
	    last;
	}
    }

#      print STDERR "$enter\n";

    $enter=~s/ encoding *= *\"([^\"]*)\"/ encoding=\"UTF-8\"/;
    if($enter=~/(<\?xml version="[0-9\.]+")(.*?)([ \s\t]*<documentRecord)/sgo){
	$header=$1.$2;
    }else{
	$enter=$header.$enter;
    }
    $acquisitionData=~/<url>([^<]+)<\/url>/g;
    $documenturl=$1;

    $parser->parse(Source=>{String=>$enter});
    my $string_parse =  $myreceiver->{"tab_object"};
    return($string_parse);
}

# =head1 ENVIRONMENT

=head1 SEE ALSO

C<Alvis::NLPPlatform>

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
