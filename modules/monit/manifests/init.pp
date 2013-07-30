class monit(
    $useWebServer = true,
    $webServerIp = "127.0.0.1",
    $webServerPort = "2812"
) {

	package { "monit":
        ensure  => present,
    }

    service { "monit":
        ensure  => running,
        enable  => true,
        hasstatus => true,
        hasrestart => true,
        require => Package['monit'],
    }

    file { "/etc/monit.conf":
        ensure  => file,
        content => template("monit/monit.conf.erb"),
        mode    => 0600,
        owner   => 'root',
        group   => 'root',
        notify  => Service['monit'],
    }

    file { "/etc/monit.d":
        ensure  => directory,
        mode    => 0750,
        owner   => 'root',
        group   => 'root',
    }
}
