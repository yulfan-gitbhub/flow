#!/usr/bin/perl
# OUTLINE START ########################################################
# Author       : Guoqiang Wang
# Keywords     : TIMING
# Description  : analyze timing report by innovus  
# Usage        : anaRptByInnovus.pl xxx.rpt [ |wns|tns|weight|num]
# Version      :
#                2015/11/10   v0.2    fix MET bug                   guoqiang.wang
#                             v0.1    initial version               guoqiang.wang
# OUTLINE END ##########################################################
if ($ARGV[0]=~/^-h/ || $ARGV[0]=~/^$/) {
	print "
Usage:
	anaRptByInnovus.pl xxx.rpt [ |wns|tns|weight|num]\n";

	exit;
}


$include_startreg=0;

if ( $ARGV[0] =~/\.gz$/ ) {
    open rfile, "/bin/zcat $ARGV[0] |" or die "Cannot read $ARGV[0]";
} else {
    open rfile, "< $ARGV[0]" or die "Cannot read $ARGV[0]";
}

@_=split(/\//,$ARGV[0]);
$file=$_[$#_];

open clock, "> $file\_clock.rpt" or die "Cannot create";
open wfsp, "> $file\_startpoint.rpt" or die "Cannot create";
open wfspt, "> $file\_startpoint.table" or die "Cannot create";
open wfep, "> $file\_endpoint.rpt" or die "Cannot create";
open wfept, "> $file\_endpoint.table" or die "Cannot create";
open wbot, "> $file\_bottleneck.rpt" or die "Cannot create";


$num=0;
$mark=0;
$total_slack=0;


while (<rfile>) {
	chomp;

	if (/^Path\s+\d+:\s+MET/) {last;}
	if (/^Path\s+(\d+):/) {
		$mark=1;
		$num++;
		$line = $_;
		$launch=0;
		$capture=0;
		$logic_level=0;
		next;
	}
	if (/^Endpoint:/) {
		push @aa,$line;
		$line = $_;
		next;
	}
	if (/^Beginpoint:/) {
		split(/\'/,$line);
		$endclock=$_[1];
		push @aa,$line;
		split(/\s+/,$line);
		$endpoint=$endpoint_cell=$_[1];
		$endpoint_cell=~s#/[^/]*$##;
		$line = $_;
		next;
	}
	if (/Path Groups:/) {
		split(/\'/,$line);
		$startclock=$_[1];
		push @aa,$line;
		split(/\s+/,$line);
		$startpoint=$startpoint_cell=$_[1];
		$startpoint_cell =~ s#/[^/]*$##;
		$mark=0;
		next;
	}
	if (/Slack Time\s+(\S+)/) {
		$data_begin=0;
		$capture=0;
		$slack=$1;
		if ( $startclock eq $endclock) {
			print clock "Slack: $slack\t\t$startclock\t\t$endclock\n";
		} else {
			print clock "Slack: $slack\t\t$startclock\t\t$endclock\t\tcross\n";
		}
		$start_endlist{$startpoint}.=" $endpoint";
		$end_startlist{$endpoint}.=" $startpoint";
		
		$total_slack=$total_slack+$slack;

		if ( $WNS{$startpoint} >= $slack) {
			$WNS{$startpoint} = $slack;
		}
		if ( $WNS{$endpoint} >= $slack) {
			$WNS{$endpoint} = $slack;
		}
		$TNS{$startpoint}=$TNS{$startpoint}+$slack;
		$TNS{$endpoint}=$TNS{$endpoint}+$slack;
		next;
	}

	if ($mark) {
		$line.="$_";
	}

	if (/\|\s+Instance\s+\|/) {
		$ins="";
		$launch=1;
		$launch_data=0;
	}

	if ($_=~/ \| / && $_!~/ Instance / && $launch) {
		$_=~s/\s+//g;
		@tmp=split(/\|/,$_);

		if ( $tmp[1] !~ /\w+/ ) {next;}

		if ( $tmp[2]=~/\w+/ && $tmp[3]=~/\w+/) {
			$stop_mark=0;
			if ($launch_data) {
				$bot->{$ins}->{cnt}++;
				$bot->{$ins}->{cell}=$cell;
				if ($bot->{$ins}->{slew}<$slew) {$bot->{$ins}->{slew}=$slew;}
				if ($bot->{$ins}->{load}<$load) {$bot->{$ins}->{load}=$load;}
				if ($bot->{$ins}->{delay}<$delay) {$bot->{$ins}->{delay}=$delay;}
				if ($bot->{$ins}->{wns}>=$slack) {$bot->{$ins}->{wns}=$slack;}
				$bot->{$ins}->{tns}=$bot->{$ins}->{tns}+$slack;
				$logic_level=$logic_level+1;
			} else {
				if ($ins =~ m#$startpoint_cell# ) {
					if ( $include_startreg ) {
						$bot->{$ins}->{cnt}++;
						$bot->{$ins}->{cell}=$cell;
						if ($bot->{$ins}->{slew}<$slew) {$bot->{$ins}->{slew}=$slew;}
						if ($bot->{$ins}->{load}<$load) {$bot->{$ins}->{load}=$load;}
						if ($bot->{$ins}->{delay}<$delay) {$bot->{$ins}->{delay}=$delay;}
						if ($bot->{$ins}->{wns}>=$slack) {$bot->{$ins}->{wns}=$slack;}
						$bot->{$ins}->{tns}=$bot->{$ins}->{tns}+$slack;

					}
					$launch_data=1;
					$logic_level=1;
				}
			}
			$ins=$tmp[1];
			$cell=$tmp[3];
			$slew=$tmp[4];
			$load=$tmp[5];
			$delay=$tmp[7];
		} elsif ( $tmp[2]!~/\w+/ && $tmp[3]!~/\w+/ && $stop_mark==0) {
			$ins.="$tmp[1]";
		} elsif ( $tmp[2]!~/\w+/ && $tmp[3]=~/\w+/) {
			$stop_mark=1;
		}
	}

	if (/Other End Path:/) {
		if ( $ins!~m#$startpoint_cell#) {
			$bot->{$ins}->{cnt}++;
			$bot->{$ins}->{cell}=$cell;
			if ($bot->{$ins}->{slew}<$slew) {$bot->{$ins}->{slew}=$slew;}
			if ($bot->{$ins}->{load}<$load) {$bot->{$ins}->{load}=$load;}
			if ($bot->{$ins}->{delay}<$delay) {$bot->{$ins}->{delay}=$delay;}
			if ($bot->{$ins}->{wns}>=$slack) {$bot->{$ins}->{wns}=$slack;}
			$bot->{$ins}->{tns}=$bot->{$ins}->{tns}+$slack;
		}
		$level->{$startpoint}->{$endpoint}=$logic_level;
		if ( $level->{$startpoint}->{value} < $logic_level ) {
			$level->{$startpoint}->{value}=$logic_level;
		}
		if ( $level->{$endpoint}->{value} < $logic_level ) {
			$level->{$endpoint}->{value}=$logic_level;
		}
		if ( $level->{$startpoint}->{$endpoint_cell} < $logic_level ) {
			$level->{$startpoint}->{$endpoint_cell}=$logic_level;
		}
		$ins= ""; $launth=0; $capture=1; next;

	}
}
close rfile;


	
#print wfsp "#$ARGV[0]       TNS:$total_slack    num:$num\n";
#printf wfsp "#%-180s%-10s%-10s%-8s%s\n",STARTPOINT,WNS,TNS,WEIGHT,NUM;
foreach $point (sort keys %start_endlist) {
	@a=split(/\s+/,$start_endlist{$point});

	$weight=sprintf "%.1f%",$TNS{$point}/$total_slack*100;
	#printf wfsp "%-180s%-10s%-10s%-8s%s\n",$point,$WNS{$point},$TNS{$point},$weight,$#a;
    $TNS{$point}=sprintf "%.4f",$TNS{$point};
	printf wfsp "%-10s%-10s%-10s%-10s%s\n",$WNS{$point},$TNS{$point},$weight,$#a,$point;
	print wfspt "$point: $#a\n";
	foreach $one (@a) {
		if ($one=~/^$/) {next;}
		print wfspt "   $WNS{$one} L$level->{$point}->{$one} $one\n"
	}
}

#print wfep "#$ARGV[0]       TNS:$total_slack    num:$num\n";
#printf wfep "#%-180s%-10s%-10s%-8s%s\n",ENDPOINT,WNS,TNS,WEIGHT,NUM;
foreach $point (sort keys %end_startlist) {
	@a=split(/\s+/,$end_startlist{$point});

	$weight=sprintf "%.1f%",$TNS{$point}/$total_slack*100;
    $TNS{$point}=sprintf "%.4f",$TNS{$point};
	#printf wfep "%-180s%-10s%-10s%-8s%s\n",$point,$WNS{$point},$TNS{$point},$weight,$#a;
	printf wfep "%-10s%-10s%-10s%-10s%s\n",$WNS{$point},$TNS{$point},$weight,$#a,$point;
	print wfept "$point: $#a\n";
	foreach $one (@a) {
		if ($one=~/^$/) {next;}
		print wfept "   $WNS{$one} L$level->{$one}->{$point} $one\n"
	}
}

foreach $point (sort keys %$bot) {
	printf wbot "%-10s%-5s%-10s%-35s%s\n",$bot->{$point}->{wns},$bot->{$point}->{cnt},$bot->{$point}->{delay},$bot->{$point}->{cell},$point;
}


close $clock;
close $wfsp;
close $wfspt;
close $wfep;
close $wfept;
close $wbot;

##############################
##  sort <file>_startpoint.rpt
##############################
system("echo \"$ARGV[0]         TNS:$total_slack   num:$num\" > startpoint.rpttmp");
system('echo "STARTPOINT WNS TNS WEIGHT NUM" | awk \'{printf "%-10s%-10s%-10s%-10s%s\n",$2,$3,$4,$5,$1}\' >> startpoint.rpttmp');
if ( $ARGV[1] eq "tns" ) {
	system("sort -nk2 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
} elsif ( $ARGV[1] eq "weight" ) {
	system("sort -nrk3 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
} elsif ( $ARGV[1] eq "num" ) {
	system("sort -nrk4 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
} else {
	system("sort -nk1 $file\_startpoint.rpt >> startpoint.rpttmp; cp -f startpoint.rpttmp $file\_startpoint.rpt; rm -f startpoint.rpttmp");
}
#############################
##  sort <file>_endpoint.rpt
#############################
system("echo \"$ARGV[0]         TNS:$total_slack   num:$num\" > endpoint.rpttmp");
system('echo "ENDPOINT WNS TNS WEIGHT NUM" | awk \'{printf "%-10s%-10s%-10s%-10s%s\n",$2,$3,$4,$5,$1}\' >> endpoint.rpttmp');
if ( $ARGV[1] eq "tns" ) {
	system("sort -nk2 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
} elsif ( $ARGV[1] eq "weight" ) {
	system("sort -nrk3 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
} elsif ( $ARGV[1] eq "num" ) {
	system("sort -nrk4 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
} else {
	system("sort -nk1 $file\_endpoint.rpt >> endpoint.rpttmp; cp -f endpoint.rpttmp $file\_endpoint.rpt; rm -f endpoint.rpttmp");
}


system('echo "#WNS NUM DELAY CELL INSTANCE" | awk \'{printf "%-10s%-5s%-10s%-35s%s\n",$1,$2,$3,$4,$5}\' > bottleneck.rpttmp');
system("sort -rnk2 $file\_bottleneck.rpt >> bottleneck.rpttmp; cp -f bottleneck.rpttmp $file\_bottleneck.rpt; rm -f bottleneck.rpttmp");


unless ( $ARGV[1] eq "wns" || $ARGV[1] eq "tns" || $ARGV[1] eq "weight" || $ARGV[1] eq "num" ) {
	$ARGV[1]="wns";
}

print "Done, sort by $ARGV[1], pls check reports ...\n\t$file\_clock.rpt\n\t$file\_startpoint.rpt\n\t$file\_startpoint.table\n\t$file\_endpoint.rpt\n\t$file\_endpoint.table\n\t$file\_bottleneck.rpt\n";







