#!/usr/bin/perl
my $red   ="\033[0;31m";
my $green ="\033[0;32m";
my $end   ="\033[0m";

if (!defined $ARGV[0]) {
    print "Usage : cwait <flagfile>       ;perform cmd\n";
    print "  E.g.: cwait sta/flag/my.flag ;make -j PtIce\n";
    print "  E.g.: cwait \"1.flag 2.flag\"  ;source ***\n";
    exit
}
$unit_time = "60s";
$i         = 0;
chop($date =`date`);
print "$red $i x $unit_time ${date}$end < $ARGV[0] >\n";
init:
foreach $file (split(/\s+/,$ARGV[0])) {
    unless (-f "$file") {
        $i++;
        sleep $unit_time;
        chop($date =`date`);
        print "$red $i x $unit_time ${date}$end < $ARGV[0] >\n";
        goto init;
    }
}

chop($date =`date`);
print "$green $date end of wait!\n$end";
