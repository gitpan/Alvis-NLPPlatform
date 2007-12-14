use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Debian dependencies :  libalvis-termtagger-perl, libconfig-general-perl, libalvis-pipeline-perl, libxml-perl

WriteMakefile(
    NAME              => Alvis::NLPPlatform,
    VERSION_FROM      => 'lib/Alvis/NLPPlatform.pm', # finds $VERSION
    PREREQ_PM         => { Time::HiRes => 0,
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
                           Encode => 2.23,
                           Fcntl => 0,
                           File::MMagic => 1.27,
                         }, # e.g., Module::Name => 1.1
    LICENSE           => "gpl",
    INSTALLDIRS     => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Alvis/NLPPlatform.pm', # retrieve abstract from module
       AUTHOR         => 'Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr> and Julien Deriviere <julien.deriviere@lipn.univ-paris13.fr>') : ()),
    EXE_FILES    => [ 'bin/alvis-nlp-client', 'bin/alvis-nlp-server', 'bin/alvis-nlp-standalone', 'bin/ogmios-nlp-client', 'bin/ogmios-nlp-server', 'bin/ogmios-nlp-standalone' ],
#     UNINSTALL => '$(PERLRUN) -MExtUtils::Install -e \'uninstall({@ARGV});\'',
    
);

sub MY::postamble {
    return <<'MAKE_FRAG';
install :: 
	$(NOECHO) if [ -z "$(DESTDIR)" ] ; then \
	    if [ "$(PREFIX)" == "/usr" -o "$(PREFIX)" == "/usr/local" ] ; then \
	        $(ECHO) "Coping etc/alvis-nlpplatform in /etc" ;\
		$(CP) -a etc/alvis-nlpplatform /etc ; \
	    else \
	        $(ECHO) "Coping etc/alvis-nlpplatform in $(PREFIX)/etc" ;\
		$(CP) -a etc/alvis-nlpplatform $(PREFIX)/etc ; \
	    fi \
	else \
	    $(ECHO) "Coping etc/alvis-nlpplatform in $(DESTDIR)/etc" ;\
	    $(CP) -a etc/alvis-nlpplatform $(DESTDIR)/etc ; \
	fi

MAKE_FRAG
}


