# $Id: Makefile.PL,v 1.2 2007/03/09 17:27:26 drhyde Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
		NAME	=> 'Net::Random',
		VERSION_FROM => 'lib/Net/Random.pm',
		PREREQ_PM => {
		    'LWP::UserAgent'  => 0,
		    'Test::More'      => 0.64,
		    'Test::Mock::LWP' => 0.04
		}
	     );
