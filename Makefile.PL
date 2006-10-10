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
                           Alvis::TermTagger => 0,
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
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Alvis/NLPPlatform.pm', # retrieve abstract from module
       AUTHOR         => 'Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr> and Julien Deriviere <julien.deriviere@lipn.univ-paris13.fr>') : ()),
    EXE_FILES    => [ 'bin/client.pl', 'bin/server.pl', 'bin/go.pl' ],
#     UNINSTALL => '$(PERLRUN) -MExtUtils::Install -e \'uninstall({@ARGV});\'',
    
);

sub MY::postamble {
    return <<'MAKE_FRAG';
# config :: config_$(INSTALLDIRS)

# lib/Lingua/YaTeA/Config.pm.orig : 
# 	  cp lib/Lingua/YaTeA/Config.pm lib/Lingua/YaTeA/Config.pm.orig 

# config_site :: lib/Lingua/YaTeA/Config.pm.orig
# 	ABSPWD_PREFIX=`$(PERLRUN) -M"Cwd 'abs_path'" -e 'print abs_path('\''$(SITEPREFIX)'\'');'` ; \
# 	cat lib/Lingua/YaTeA/Config.pm.orig | sed "s|@ROOT@|$$ABSPWD_PREFIX|" > lib/Lingua/YaTeA/Config.pm

# config_perl :: lib/Lingua/YaTeA/Config.pm.orig
# 	ABSPWD_PREFIX=`$(PERLRUN) -M"Cwd 'abs_path'" -e 'print abs_path('\''$(PERLPREFIX)'\'');'` ; \
# 	cat lib/Lingua/YaTeA/Config.pm.orig | sed "s|@ROOT@|$$ABSPWD_PREFIX|" > lib/Lingua/YaTeA/Config.pm

# config_vendor :: 
# 	ABSPWD_PREFIX=`$(PERLRUN) -M"Cwd 'abs_path'" -e 'print abs_path('\''$(VENDORPREFIX)'\'');'` ; \
# 	cat lib/Lingua/YaTeA/Config.pm.orig | sed "s|@ROOT@|$$ABSPWD_PREFIX|" > lib/Lingua/YaTeA/Config.pm

install :: 
	if [ -z $(DESTDIR) ] ; then \
	    $(CP) -a etc $(PREFIX) ; \
	else \
	    $(CP) -a etc $(DESTDIR) ; \
	fi

# clean ::
# 	-$(MV) lib/Lingua/YaTeA/Config.pm.orig lib/Lingua/YaTeA/Config.pm $(DEV_NULL)

MAKE_FRAG
}


