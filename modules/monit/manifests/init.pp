class monit(
    $useWebServer = true,
    $webServerIp = "127.0.0.1",
    $webServerPort = "2812"
) {

	package { "monit":
        ensure  => present,
    }

    file { "/etc/monit.conf":
        ensure  => file,
        content => template("monit/monit.conf.erb"),
        mode    => 0600,
        owner   => 'root',
        group   => 'root',
        require => Package['monit'];

        "/etc/monit.d":
        ensure  => directory,
        mode    => 0750,
        owner   => 'root',
        group   => 'root',
    }

    service { "monit":
        ensure  => running,
        hasstatus => true,
        hasrestart => true,
    }
}
