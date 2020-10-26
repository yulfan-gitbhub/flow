#!/usr/bin/perl
#
#use lib qw!/home/1680039/bin/tools/perl5/lib/perl5 /home/1680039/bin/tools/perl5/lib/perl5/x86_64-linux-thread-multi!;

if ( $ARGV[0] =~/\.gz/ ) {
    open rfile, "gunzip -c $ARGV[0] |" or die "Can not read $ARGV[0]";
} else {
    open rfile, "< $ARGV[0]" or die "Can not read $ARGV[0]";
}

@_=split(/\//,$ARGV[0]);
$file=$_[$#_];


open clock, "> $file\_clock.rpt" or die "Can not create";
open wfsp, "> $file\_startpoint.rpt" or die "Can not create";
open wfspt, "> $file\_startpoint.table" or die "Can not create";
open wfep, "> $file\_endpoint.rpt" or die "Can not create";
open wfept, "> $file\_endpoint.table" or die "Can not create";
open wbot, "> $file\_bottleneck.rpt" or die "Can not create";

$num=0;
$mark=0;
$total_slack=0;
$record=0;

while (<rfile>) {
	chomp;
	if (/Startpoint:/) {
		split(/\s+/,$_);
		$startpoint_cell=@_[2];
        $startpoint_cell=~s#\[#zuofangkuohao#g;
        $startpoint_cell=~s#\]#youfangkuohao#g;
		$startmark=1;
#next;
	}
	if ($startmark) {
		if (/ clocked by (.*)\)/) {
			$startclock=$1;
			$startmark=0;
		}
	}
	if (/Endpoint:/) {
		split(/\s+/,$_);
		$endpoint_cell=@_[2];
        $endpoint_cell=~s#\[#zuofangkuohao#g;
        $endpoint_cell=~s#\]#youfangkuohao#g;
		$endmark=1;
#	next;
	}
	if ($endmark) {
		if (/ clocked by (.*)\)/) {
			$endclock=$1;
			$endmark=0;
		}
	}

	if (/Point/) {
		$launch=1;
		$launch_data=0;
		undef @depot;
		
	}
	if ($launch) {
		split(/\s+/,$_);
        
        $_[1]=~s#\[#zuofangkuohao#g;
        $_[1]=~s#\]#youfangkuohao#g;		
		if ($_[1]=~m#$startpoint_cell\b#) {
			$record=1;
		}
		if ($_[1]=~m#$endpoint_cell\b#) {
            $_[1]=~s#zuofangkuohao#\[#;
            $_[1]=~s#youfangkuohao#\]#;
			$endpoint=$_[1];
			$record=0;
			$launch=0;
		}
		if (!$record) { next; }
		if ($_[1]=~m#$startpoint_cell\b#) {
            $_[1]=~s#zuofangkuohao#\[#;
            $_[1]=~s#youfangkuohao#\]#;
			$startpoint=$_[1];	
		}


		if ($#_ == 9) {
			$mark=1;
#print "$_\n";
			next;
		}
		if ($mark) {
			$_[1]=~s#/[^/]+$##;
			$_[2]=~s#\(##; $_[2]=~s#\)##;
			$ins=$_[1];
			$cell=$_[2];
			$delay=$_[4];
#print "$ins $cell $delay\n";
			$mark=0;

			$bot->{$ins}->{cnt}++;
			$bot->{$ins}->{cell}=$cell;
		
			if ($bot->{$ins}->{delay}<$delay) {$bot->{$ins}->{delay}=$delay;}
			push @depot,$ins;
#	if ($bot->{$ins}->{wns}<$slack) {$bot->{$ins}->{wns}=$slack;}
#			$bot->{$ins}->{tns}=$bot->{$ins}->{tns}+$slack;
		}


	}

	if (/VIOLATED[^0-9.-]*([0-9.-]+)/) {
		$slack=$1;
		$total_slack= $slack + $total_slack;
		$num++;

		$start_endlist{$startpoint}.=" $endpoint";
		$end_startlist{$endpoint}.=" $startpoint";
		if ( $WNS{$startpoint} >= $slack ) {
			$WNS{$startpoint}=$slack;
		}
		if ( $WNS{$endpoint} >= $slack ) {
			$WNS{$endpoint}=$slack;
		}
		$TNS{$startpoint}=sprintf "%.3f",$TNS{$startpoint}+$slack;
		$TNS{$endpoint}=sprintf "%.3f",$TNS{$endpoint}+$slack;
		foreach $ins (@depot) {
#		if ( $ins == "") { next;}
			if ($bot->{$ins}->{wns}>=$slack) { $bot->{$ins}->{wns}=$slack;}
			$bot->{$ins}->{tns}=$bot->{$ins}->{tns}+$slack;
#print "$bot->{$ins}->{wns} $bot->{$ins}->{tns}\n";
		}

		if ( $startclock eq $endclock ) {
			print clock "Slack: $slack\t\t$startclock\t\t$endclock\n";
		} else {
			print clock "Slack: $slack\t\t$startclock\t\t$endclock\t\tcross\n";

		}
	}

}

#print wfsp "#$ARGV[0]       TNS:$total_slack    num:$num\n";
#printf wfsp "#%-180s%-10s%-10s%-8s%s\n",STARTPOINT,WNS,TNS,WEIGHT,NUM;
foreach $point (sort keys %start_endlist) {
	@a=split(/\s+/,$start_endlist{$point});

	$weight=sprintf "%.1f%",$TNS{$point}/$total_slack*100;
	printf wfsp  "%-180s%-10s%-10s%-8s%s\n",$point,$WNS{$point},$TNS{$point},$weight,$#a;
	print wfspt "$point: $#a";
	foreach $one (@a) {
		print wfspt "    $one\n"
	}
}

#print wfep "#$ARGV[0]       TNS:$total_slack    num:$num\n";
#printf wfep "#%-180s%-10s%-10s%-8s%s\n",ENDPOINT,WNS,TNS,WEIGHT,NUM;
foreach $point (sort keys %end_startlist) {
	@a=split(/\s+/,$end_startlist{$point});

	$weight=sprintf "%.1f%",$TNS{$point}/$total_slack*100;
	printf wfep "%-180s%-10s%-10s%-8s%s\n",$point,$WNS{$point},$TNS{$point},$weight,$#a;

	print wfept "$point: $#a";
	foreach $one (@a) {
		print wfept "    $one\n"
	}
}

foreach $point (sort keys %$bot) {
	printf wbot "%-10s%-5s%-10s%-25s%s\n",$bot->{$point}->{wns},$bot->{$point}->{cnt},$bot->{$point}->{delay},$bot->{$point}->{cell},$point;
}


close $clock;
close $wfsp;
close $wfspt;
close $wfep;
close $wfept;
close $wbot;

##############################
##  sort <file>_startprint.rpt
##############################
system("echo \"$ARGV[0]         TNS:$total_slack   num:$num\" > startpoint.rpttmp");
system('echo "STARTPOINT WNS TNS WEIGHT NUM" | awk \'{printf "%-180s%-10s%-10s%-8s%s\n",$1,$2,$3,$4,$5}\' >> startpoint.rpttmp');
if ( $ARGV[1] eq "tns" ) {
	system("sort -nk3 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
} elsif ( $ARGV[1] eq "weight" ) {
	system("sort -nrk4 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
} elsif ( $ARGV[1] eq "num" ) {
	system("sort -nrk5 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
} else {
	system("sort -nk2 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
}
#############################
##  sort <file>_endprint.rpt
#############################
system("echo \"$ARGV[0]         TNS:$total_slack   num:$num\" > endpoint.rpttmp");
system('echo "STARTPOINT WNS TNS WEIGHT NUM" | awk \'{printf "%-180s%-10s%-10s%-8s%s\n",$1,$2,$3,$4,$5}\' >> endpoint.rpttmp');
if ( $ARGV[1] eq "tns" ) {
	system("sort -nk3 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
} elsif ( $ARGV[1] eq "weight" ) {
	system("sort -nrk4 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
} elsif ( $ARGV[1] eq "num" ) {
	system("sort -nrk5 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
} else {
	system("sort -nk2 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
}


system('echo "#WNS NUM DELAY CELL INSTANCE" | awk \'{printf "%-10s%-5s%-10s%-25s%s\n",$1,$2,$3,$4,$5}\' > bottleneck.rpttmp');
system("sort -rnk2 $file\_bottleneck.rpt >> bottleneck.rpttmp; cp -f bottleneck.rpttmp $file\_bottleneck.rpt; rm -f bottleneck.rpttmp");


unless ( $ARGV[1] eq "wns" || $ARGV[1] eq "tns" || $ARGV[1] eq "weight" || $ARGV[1] eq "num" ) {
	$ARGV[1]="wns";
}

print "Done, sort by $ARGV[1], pls check reports ...\n\t$file\_clock.rpt\n\t$file\_startpoint.rpt\n\t$file\_startpoint.table\n\t$file\_endpoint.rpt\n\t$file\_endpoint.table\n\t$file\_bottleneck.rpt\n";

