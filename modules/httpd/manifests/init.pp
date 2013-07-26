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
class httpd::task (
    $serverName = "gooddata",
    $documentRoot = '/var/www/task'
) {
    include httpd::monit

    package { 'perl-CGI':
        ensure  => installed,
    }

    file {"${documentRoot}":
        ensure  => directory,
        owner   => 'root',
        group   => 'apache',
        mode    => 0750,
    }

    file {"${documentRoot}/index.pl":
        ensure  => file,
        source  => 'puppet:///modules/httpd/index.pl',
        owner   => 'apache',
        group   => 'apache',
        mode    => 0750,
        require => Package['perl-CGI'],
    }
    
    file { '/etc/httpd/conf.d/task.conf':
        ensure  => file,
        content => template('httpd/task.conf.erb'),
        mode    => 0644,
        owner   => 'root',
        group   => 'root',
        notify  => Service['httpd'],
    }
}
