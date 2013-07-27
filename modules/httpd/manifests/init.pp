class httpd {

    package {'httpd':
    	ensure	=> installed,
    }

}

class httpd::monit {
    include ::monit
    
    file {'/etc/monit.d/httpd':
    	ensure	=> file,
    	mode	=> 0640,
    	source	=> 'puppet:///modules/httpd/httpd',
        notify  => Service['monit'],
    }
    
    service {'httpd':
	    provider      => "monit",
        enable     => true,
    	ensure	       => running,
    	hasstatus     => true,
        hasrestart => true,
        require    => File['/etc/monit.d/httpd'],
    }
}

class httpd::task (
    $serverName = "testserver",
    $documentRoot = '/var/www/task'
) {
    include httpd
    include httpd::monit

    package { 'perl-CGI':
        ensure  => installed,
    }
    package { 'lsof':
        ensure => installed,
    }

    user {"cgi":
        ensure  => present,
        shell   => '/bin/bash',
        home    => "${documentRoot}",
    }

    file {"${documentRoot}":
        ensure  => directory,
        owner   => 'cgi',
        group   => 'cgi',
        mode    => 0755,
        require => User['cgi'],
    }

    file {"${documentRoot}/index.pl":
        ensure  => file,
        source  => 'puppet:///modules/httpd/index.pl',
        owner   => 'cgi',
        group   => 'cgi',
        mode    => 0750,
        require => Package['perl-CGI'],
    }

    file {"${documentRoot}/bootstrap.min.css":
        ensure => file,
        source => 'puppet:///modules/httpd/bootstrap.min.css',
        owner  => 'cgi',
        group  => 'cgi',
        mode   => 0644,
    }
    
    file { '/etc/httpd/conf.d/task.conf':
        ensure  => file,
        mode    => 0644,
        owner   => 'root',
        group   => 'root',
        require => Package['httpd'],
        notify  => Service['httpd'],
        content => template('httpd/task.conf.erb'),
    }
}
