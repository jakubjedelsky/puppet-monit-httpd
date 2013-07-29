There are two puppet modules:

1.  module `monit`: setup monit as a service provider

    It needs to have installed puppet with monit as a service type provider. Check [this commit](https://github.com/jakubjedelsky/puppet/commit/9c49519266c7a3f9f761bc5f6041c66d42c80d1f) for more details. You can clone updated puppet from https://github.com/jakubjedelsky/puppet.

2.  module `httpd`: install and configure simple apache page. Apache is running as a service under monit.

# Test it
For test puppet modules on a local system clone this repo and run `puppet apply -e "include httpd:task"`:
```bash
git clone https://github.com/jakubjedelsky/puppet-monit-httpd.git
cd puppet-monit-httpd
puppet apply --modulepath=$(pwd)/modules -d -e "include monit" -e "include httpd::monit"
```

# Customize
For customize Monit service you can use variables:
- `$useWebServer` - boolean; if you want to enable build-in webserver for monitoring services.
- `$webServerIp` - ip address; IP where build-in webserver should listen
- `$webServerPort` - port number

For customize httpd you can use variables (only for test environment):
- `$serverName` - a server name of virtual host
- `$documentRoot` - a path where we store CGI script for testing
