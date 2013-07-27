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
    my @list = `ps -ef`;
    return scalar(@list) - 1;
}

# num_files() returns a number of opened files on a system
sub num_files()
{
    my @list = `lsof`;
    return scalar(@list) - 1;
}

# logged_users() returns simple info about logged in users
sub logged_users()
{

    my @retval;

    my @output = `who`;
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

my %uptime = uptime();
my %cpuinfo = cpu_info();
my @users = logged_users();

print   $q->header(-charset=>'utf-8'),
        $q->start_html('sysinfo'),
        $q->p("Distribution: ", get_dist()),
        $q->p("Load: ", load()),
        $q->p("Uptime: ",$uptime{"DAY"} ,"days,",$uptime{"HOUR"},"hours,", $uptime{"MIN"} ,"minutes and", $uptime{"SEC"} ,"seconds"),
        $q->p("CPUs: ", $cpuinfo{"CPUS"}, "cores per cpu: ", $cpuinfo{"CORES"}),
        $q->start_table(-border=>0);
        foreach (@users) {
            print $q->start_Tr,
                $q->start_td, $_->{name},$q->end_td,
                $q->start_td, $_->{term},$q->end_td,
                $q->start_td, $_->{date},$q->end_td,
                $q->start_td, $_->{time},$q->end_td,
            $q->end_Tr;
        };
print   $q->end_html();
