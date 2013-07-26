class httpd {

    package {'httpd':
    	ensure	=> installed,
    }

}

class httpd::monit {
    require ::monit
    include httpd
    
    file {'/etc/monit.d/httpd':
    	ensure	=> file,
    	mode	=> 0640,
    	source	=> 'puppet:///modules/httpd/httpd',
        notify  => Service['httpd'],
    }
    
    service {'httpd':
	    provider => "monit",
        enable  => true,
    	ensure	=> running,
    	hasstatus => true,
        hasrestart => true,
    }
}
# TODO
class httpd::cgi {

}
# TODO
class httpd::info {

}
