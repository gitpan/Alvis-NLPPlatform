use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Alvis::NLPPlatform',
     dist_version_from => 'lib/Alvis/NLPPlatform.pm',
     license => 'gpl',
     requires => {'perl' => '5.005',
		  Time::HiRes => 0,
		  IO::Socket => 0,
		  XML::Parser::PerlSAX => 0,
		  Data::Dumper => 0,
		  Alvis::TermTagger => 0.3,
		  Alvis::Pipeline => 0,
		  XML::LibXML => 0,
		  IO::File => 0,
		  IO::Socket::INET => 0,
		  Getopt::Long => 0,
		  Pod::Usage => 0,
		  Config::General => 2.30,
		  Sys::Hostname => 0,
		  Fcntl => 0,
		  utf8 => 0,
	      },
     installdirs => 'core',
     etc_files => {
	 'etc/alvis-nlpplatform/nlpplatform-test.rc' => 'etc/alvis-nlpplatform/nlpplatform-test.rc',
	     'etc/alvis-nlpplatform/nlpplatform.rc' => 'etc/alvis-nlpplatform/nlpplatform.rc',
	     'etc/alvis-nlpplatform/xsd/enriched-document.xsd' => 'etc/alvis-nlpplatform/xsd/enriched-document.xsd',
	     'etc/alvis-nlpplatform/dtd/enriched-document.dtd' => 'etc/alvis-nlpplatform/dtd/enriched-document.dtd',
	     'etc/alvis-nlpplatform/xsl/Default.xsl' => 'etc/alvis-nlpplatform/xsl/Default.xsl',
	     'etc/alvis-nlpplatform/mime/magic.TeX' => 'etc/alvis-nlpplatform/mime/magic.TeX',
	 },
     );


$build->install_base_relpaths( etc => 'etc' );
$build->prefix_relpaths('site', etc => 'etc' );
$build->prefix_relpaths('core', etc => 'etc' );
$build->prefix_relpaths('vendor', etc => 'etc' );
$build->add_build_element('etc');

$build->create_build_script;
