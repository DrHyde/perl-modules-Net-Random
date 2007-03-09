use ExtUtils::MakeMaker;
WriteMakefile(
		NAME	=> 'Net::Random',
		VERSION => '1.4',
		PREREQ_PM => {
		    'LWP::UserAgent' => 0,
		}
	     );
