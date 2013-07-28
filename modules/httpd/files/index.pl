#!/usr/bin/perl

use strict;
use warnings;
use CGI;

# retruns a hash with year, day, etc. as key
# eg. { DAY => 52, HOUR => 16, MIN => 6, SEC => 56}
sub uptime()
{
    if (open(UPTIME, '/proc/uptime')) {
        my $uptime = <UPTIME>;
        close(UPTIME);
        my $secs =  (split /\s+/,$uptime)[0];

        my %retval = (
            "DAY"   => int($secs/(24*60*60)),
            "HOUR"  => ($secs/(60*60))%24,
            "MIN"   => ($secs/60)%60,
            "SEC"   => $secs%60
        );
    
        return %retval;
    }
}

# get_dist returns a string with running distribution (read from /etc/system-release)
sub get_dist()
{
    if (open(INFO, '/etc/system-release')) {
        my $distribution = <INFO>;
        close(INFO);

        $distribution =~ s/\R//g;
        return $distribution;
    }
}

# load() returns load of server
sub load()
{
    if (open(LOAD, '/proc/loadavg')) {
        my $loadavg = <LOAD>;
        close(LOAD);
        $loadavg =~ s/^((\d+\.\d+\s){3}).*\n$/$1/;
        return $loadavg;
    }
}

# cpu_info() returns a hash with info about CPU:
# { "CPUS" => <number of cpus>, "CORES" = <cores per cpu> }
sub cpu_info
{

    my $NUM = 0;
    my %PHYS;

    open(CPU, '/proc/cpuinfo');
    while (<CPU>) {
        chomp;
        if (/^processor\s*:.*$/) {
            $NUM +=1;
        } elsif (/^physical id\s*: (.*)$/) {
            $PHYS{$1} = undef;
        }
    }
    close CPU;
    
    my $cpus = scalar(keys %PHYS);
    if ( $cpus == 0 ) {
        $cpus = 1;
    }
    my $cores = int($NUM/$cpus);

    my %retval = (
        "CPUS" => $cpus,
        "CORES" => $cores,
    );

    return %retval;
}

# num_processes() returns a number of running processes
sub num_processes()
{
    my @list = `/bin/ps -ef`;
    return scalar(@list) - 1;
}

# num_files() returns a number of opened files on a system
sub num_files()
{
    my @list = `/usr/sbin/lsof`;
    return scalar(@list) - 1;
}

# logged_users() returns simple info about logged in users
sub logged_users()
{

    my @retval;

    my @output = `/usr/bin/who -u`;
    foreach my $line (@output) {
        my ($name,$term,$date,$time) = split /\s+/, $line;
        push(@retval, {
            "name" => $name,
            "term" => $term,
            "date" => $date,
            "time" => $time,
        });
    }
    return @retval;
}

# memory() returns a hash with info about system memory
# keys: MEMTOTAL, MEMINFO
sub memory()
{
    my $MEMTOTAL;
    my $MEMFREE;
    my %retval;

    open(MEM, '/proc/meminfo');
    while (<MEM>) {
        chomp;
        if (/^MemTotal:\s+(\d+)/) {
            $MEMTOTAL = sprintf("%.0f", $1/1024);
        } elsif (/^MemFree:\s+(\d+)/) {
            $MEMFREE = sprintf("%.0f", $1/1024);
        } elsif (/^Buffers:\s+(\d+)/) {
            $MEMFREE += sprintf("%.0f", $1/1024);
        } elsif (/^Cached:\s+(\d+)/) {
            $MEMFREE += sprintf("%.0f", $1/1024);
        } 
    }

    %retval = (
        "MEMTOTAL"  => $MEMTOTAL,
        "MEMFREE"   => $MEMFREE,
    );
    return %retval;
}

# let's create a web page
my $q = CGI->new();
$ENV{'LANG'} = 'en_US.utf8';

my %uptime = uptime();
my %cpuinfo = cpu_info();
my %memory = memory();
my @users = logged_users();

print   $q->header(-charset=>'utf-8'),
        $q->start_html({-title=>'sysinfo', -style=>{-src=>['bootstrap.min.css'], -media=>'all'}}),
        $q->start_div({-class=>"container"}),

        $q->h1("System info"),

        $q->start_dl({-class=>"dl-horizontal"}),
            $q->dt("Distribution"),
                $q->dd(get_dist()),
            $q->dt("CPUs"),
                $q->dd($cpuinfo{'CPUS'}),
            $q->dt("Cores per CPU"),
                $q->dd($cpuinfo{"CORES"}),
            $q->dt("Memory"),
                $q->dd("Total: $memory{'MEMTOTAL'}, Free: $memory{'MEMFREE'}"),
            $q->dt("Load"),
                $q->dd(load()),
            $q->dt("Uptime"),
                $q->dd("$uptime{'DAY'} days, $uptime{'HOUR'} hours, $uptime{'MIN'} minutes and $uptime{'SEC'} seconds"),
            $q->dt("No. of open files"),
                $q->dd(num_files()),
            $q->dt("No. of processes"),
                $q->dd(num_processes()),
        $q->end_dl();
        

print   $q->start_table({-class=>"table"}),
            $q->start_Tr,
                $q->th("Name"),
                $q->th("Term"),
                $q->th("Date"),
                $q->th("Time"),
            $q->end_Tr;
            foreach (@users) {
                print $q->start_Tr,
                    $q->td($_->{name}),
                    $q->td($_->{term}),
                    $q->td($_->{date}),
                    $q->td($_->{time}),
                $q->end_Tr;
            };
print   $q->end_table(),

        $q->end_div(),
        $q->end_html();
