# $Id: Makefile.PL,v 1.3 2007/03/16 15:34:34 drhyde Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
		NAME	=> 'Net::Random',
		VERSION_FROM => 'lib/Net/Random.pm',
		PREREQ_PM => {
		    'LWP::UserAgent'   => 0,
		    'Test::More'       => 0.64,
		    'Test::MockObject' => 1.07
		}
	     );
