proc Inn_prepareEco {} {
    setEcoMode -honorDontTouch false -honorDontUse false -honorFixedStatus false -refinePlace false -updateTiming false
}
define_proc_arguments get_flat_cells -info "proc to map get_flat_cells of synopsys" \
    -define_args {
        {-quiet "" "" boolean optional}
        {_name_or_pattern "leaf cell name or name pattern to search" "Astring" string optional}
    }

proc remove_path_group {args} {
    parse_proc_arguments -args $args results
    if {[info exists results(-all)]} {
        return [reset_path_group -all]
    }
    if {[info exists results(path_group_names)]} {
        foreach pg $results(path_group_names) {
            set cmd "reset_path_group -name $pg"
            eval $cmd
        }
    }
}
define_proc_arguments remove_path_group -info "proc to map synopsys command remove_path_group with inn comand reset_path_group" \
    -define_args {
        {path_group_names "" "" list optional }
        {-all   "" "" boolean optional}
    }

# proc for innovus to support sdc tcl generated by cms

puts "=> Create or re-define the following proc: "
puts "  proc: set_clock_sense_inn"
proc set_clock_sense_inn {args} {
    parse_proc_arguments -args $args results
    
    if {[info exists results(-clocks)]} {
        set clocks [get_object_name [get_clocks $results(-clocks)]]
    }
    if {[info exists results(-stop_propagation)]} {
        set stop 1
    } else {
        set stop 0
    }
    if {[info exists results(objects)]} {
        set objects [get_object_name [get_pins $results(objects)]]
    }
    
    set cmd "set_clock_sense"
    if {[info exists stop] && $stop} {
        append cmd " -stop"
    }
    if {[info exists clocks]} {
        append cmd " -clocks \"$clocks\""
    }
    append cmd " \"$objects\""
    
    eval $cmd
}
define_proc_arguments set_clock_sense_inn -info "Commands to override inner command \"set_clock_sense\"" \
    -define_args {
        {-clocks "" "" string optional }
        {-stop_propagation   "" "" boolean optional}
        {objects "" "" list  required  }
    }


puts "  proc: set_sense"
proc set_sense {args} {
    parse_proc_arguments -args $args results
    set type  ""
    set clock ""
    set stop  "0"
    set negative "0"
    set positive "0"
    set objects $results(_objects)
    

    if {[info exists results(-type)]} {set type $results(-type)}
    if {[info exists results(-stop_propagation)]} {set stop $results(-stop_propagation)}
    if {[info exists results(-clock)]} {set clock $results(-clock)}
    if {[info exists results(-negative)]} {set negative $results(-negative)}
    if {[info exists results(-positive)]} {set positive $results(-positive)}

    if {$type == "data"} { puts "Error: un-support stop data logic propagation !" }
    
    set cmd "set_clock_sense"
    if {$stop} { append cmd " -stop_propagation" }
    if {$negative} { append cmd " -negative" }
    if {$positive} { append cmd " -positive" }
    if {$clock != ""} { 
        set clkn [get_object_name [get_clocks $clock]]
        append cmd " -clock \[get_clocks \"$clock\"\]" 
    }

    if {$objects != ""} { 
        set set_sense_tmp_pps $objects
        #append cmd " \[get_pins \"\$objects\"\] "
        append cmd " \"\$objects\" "
    }
    eval $cmd
    puts $cmd
}

define_proc_arguments set_sense \
-info "proc created by user, to support set_sense command of synopsys" \
-define_args {
    {-type "data or clock" "" string optional}
    {-stop_propagation "" "" boolean optional}
    {-clock "the clock to stop" "" string optional}
    {-negative "" "" boolean optional}
    {-positive "" "" boolean optional}
    {_objects "port or pins" "" string required}
}

#proc set_max_transition {options} {
#    if {[regexp {set_max_transition\s+(.*)\s+\[get_designs\s*\**\s*\]} $options match value]} {
#        set cmd "set_max_transtion $value \[current_design\]"
#    } else {
#        set cmd $options
#    }
#}


puts "\n=> Load command map tcl is done.\n"


# proc timer is used to calulate run time in the flow
# usage: run_timer place_opt_1st
echo "proc run_timer <marker>"
proc run_timer {{marker "default"}} {
    set cmd "global run_timer_marker.${marker}.start"
    eval $cmd
    
    set cmd "info exists run_timer_marker.${marker}.start"
    if {[eval $cmd]} {
        set zz_stt_time  "[set run_timer_marker.${marker}.start]"
        set zz_cur_time  "[clock seconds]"
        set zz_dur_time  "[expr $zz_cur_time - $zz_stt_time]"
        set zz_run_hour  "[expr ${zz_dur_time}/3600]hour"
        set zz_run_min   "[expr (${zz_dur_time}%3600)/60]min"
        set zz_run_sec   "[expr (${zz_dur_time}%3600)%60]second"
        set zz_mem       "[expr [mem]/1000.0] Mb"
        puts "\n\[Process $marker\]: totally took time: ${zz_run_hour}_${zz_run_min}_${zz_run_sec} ; mem: $zz_mem\n"
        
        set cmd "unset run_timer_marker.${marker}.start"
        eval $cmd

    } else {
       set cmd "set run_timer_marker.${marker}.start \[clock seconds\]"
       eval $cmd
    }
}

echo "proc flow_source <file_to_source>"
proc flow_source {args} {
    parse_proc_arguments -args $args results
    set file_name $results(tcl_file)
    set echo_print 0 ; set error_exit 0 ; set quiet 0 ;
    if {[info exists results(-echo)]} {set echo_print 1}
    if {[info exists results(-quiet)]} {set quiet 1}
    if {[info exists results(-error_and_exit)]} {set error_exit 1}

    if {[file exists $file_name]} {
        if {!$quiet} { puts "\nINFO: start source file $file_name ...\n" }
        if {$echo_print} {
            puts ""
            eval { uplevel 1 "source -verbose -echo $file_name" }
            puts ""
        } elseif {$quiet} {
            eval { redirect /dev/null {uplevel 1 "source $file_name"} }
        } else {
            eval { uplevel 1 "source $file_name" }
        }
        if {!$quiet} { puts "INFO: finish source $file_name .\n" }
    } else {
        if {$error_exit} {
            puts "\nError: fail to find file $file_name to source ! Terminated ...\n"
            exit 0
        } else {
            puts "\nError: fail to find file $file_name to source !\n"
        }
    }
}

define_proc_attributes flow_source \
    -info "proc to source tcl" \
    -define_args {
        {tcl_file "the tcl file to source" "file_name" string required }
        {-echo "echo source tcl content" "" boolean optional}
        {-error_and_exit "exit once meet error" "" boolean optional}
        {-quiet "no return any info" "" boolean optional}
    }



# proc sns_pl
proc sns_pl {args} {
    parse_proc_arguments -args $args results
    set l $results(_list)
    if {[info exists results(-sort)]} {
        set sort 1
    } else {
        set sort 0
    }
    
    if {[info exists results(-uniqfy)]} {
        set uniq 1
    } else {
        set uniq 0
    }

    if {[info exists results(-merge_bus)]} {
        set merge_bus 1
    } else {
        set merge_bus 0
    }
    puts ""
    if {[info exists results(-attribute)]} {
        if {$merge_bus} {
            puts "Error: cannot use -merge_bus and attribute options together, terminate ..."
            return 0
        }
        set attribute $results(-attribute)
    } else {
        set attribute ""
    }

    redirect /dev/null {set a [sizeof_collection $l]}
    if {$a == ""} {
        set tot_num [llength $l]
    } else {
        set tot_num $a
    }
    if {$a != ""} {
        set ll [get_object_name $l]
        if {$attribute != ""} {
            foreach_in_collection o $l {
                set on [get_object_name $o]
                set atts ""
                foreach a $attribute {
                    lappend atts [get_attribute -quiet $o $a]
                }
                if {[as_collection -check $atts]} {set atts [get_object_name $atts]}
                set arr_att($on) $atts
            }
        }
    } else {
        set ll $l
        if {$attribute != ""} {
            puts "Error: the specified objects should be collection if you use -attribute option, terminate ..."
            return 0
        }
    }

    if {$uniq} {set ll [lsort -u -dict $ll]}
    if {$sort} {set ll [lsort -dict $ll]}

    # merge bus format
    if {$merge_bus} {
        set ll_new ""
        foreach o $ll {
            set oo [regsub {\[[0-9]+\]} $o "==="]
            set oo [regsub {_[0-9]+$} $oo "==="]
            lappend ll_new $oo
        }
        
        set ll_last ""
        foreach o [lsort -u $ll_new] {
            if {[regexp {\=\=\=} $o]} {
                set n [llength [lsearch -all $ll_new $o]] 
                append o "$n"
            }
            set oo $o
            lappend ll_last $oo
        }
        
        set ll $ll_last
    }
    
    puts "----------------------------------------------------"
    if {$attribute == ""} {
        foreach n $ll { puts $n }
    } else {
        foreach n $ll {
            set line [format "%-30s $arr_att($n)" $n]
            puts $line
        }
    }
    puts "----------------------------------------------------"
    puts "Total Num: $tot_num \n"
}
define_proc_attributes sns_pl -info "print list/collection" \
    -define_args {
        {_list "list/collection to print" Astring string required}
        {-sort "sort list/collection before print" "" boolean optional}
        {-uniqfy "uniqfy list/collection before print" "" boolean optional}
        {-merge_bus "merge bus format opjects" "" boolean optional}
        {-attribute "list attribute of collection" Astring string optional}
    }

if {[info command max] == ""} {
    proc max {ll} {
       return [lindex [lsort -real $ll] end]
    }
}

if {[info command min] == ""} {
    proc min {ll} {
        return [lindex [lsort -real $ll] 0]
    }
}

proc lremove {listVariable value} {
    upvar 1 $listVariable var 
    set idx [lsearch -exact $var $value]
    set var [lreplace $var $idx $idx]
}


proc print_histogram_for_list {vlist high_range pct_step} {
  set step [expr $high_range / $pct_step]
  set low_range $high_range
 
  set current_end $high_range
  set current_start [expr $current_end - $step]
 
  set current_pct_end 100
  set current_pct_start [expr $current_pct_end - $pct_step]
  while { $current_pct_start >= 0 } {
 
    set ltmp ""
    foreach v $vlist {
        if {($v <= $current_end) && ($v > $current_start)} {
            lappend ltmp $v
        }
    }
    set print_format [format "%-7s : < %.6f \: %d" \
              [format "%d-%d%%" \
                   $current_pct_start $current_pct_end] \
              $current_end [llength $ltmp]]
    echo $print_format
                                                                                                                                                                                                                                                                                                                          
    set current_end $current_start
    set current_start [expr $current_end - $step]
 
    set current_pct_end $current_pct_start
    set current_pct_start [expr $current_pct_end - $pct_step]
  }
}

# proc to generate timing summary report with startpoint and endpoint format
puts "#\tproc report_timing_summary <option_same_with_get_timing_path>"
proc report_timing_summary {args} {
    global synopsys_program_name
    set cmd " set paths \[report_timing -collection $args\]"
    eval $cmd
    
    puts "#-----------------------------------------------------------------------------------------------------------------------"
    puts [format "# %-3s | %-7s | %-5s | %-15s > %-15s | (%-5s) %-30s > (%-5s) %-30s" Num Slk Depth SClk EClk FEP Startpoint FEP Endpoint ]
    puts "#-----------------------------------------------------------------------------------------------------------------------"
    set cnt 1
    foreach_in_collection path $paths {
        set slk   [get_attribute $path slack]
        set sp    [get_attribute $path startpoint]
        set spn   [get_object_name $sp]
        set ep    [get_attribute $path endpoint]
        set epn   [get_object_name $ep]
        set sclk  [get_attribute -quiet $path startpoint_clock]
        if {$sclk != ""} {
            set sclkn [get_object_name $sclk]
        } else {
            set sclkn "-"
        }
        set eclk  [get_attribute -quiet $path endpoint_clock]
        if {$eclk != ""} {
            set eclkn [get_object_name $eclk]
        } else {
            set eclkn "-"
        }

        set depth UNK
        set lat_sclk [get_attribute -quiet $path startpoint_clock_latency]
        set lat_eclk [get_attribute -quiet $path endpoint_clock_latency]
        
        if {$lat_sclk == ""} {set lat_sclk 0}
        if {$lat_eclk == ""} {set lat_eclk 0}

        set fep_num($spn) UNK
        set fep_num($epn) UNK

        if {$slk != ""} {
            if {![regexp -nocase {inf} $slk]} { set slk [format "%.4f" $slk] }
        } else {
            set slk "-"
        }
        puts [format "  %-3s | %-7s | %-5s | %15s > %-15s | (%-5s) %-30s > (%-5s) %-30s" $cnt $slk $depth "$sclkn\($lat_sclk\)" "$eclkn\($lat_eclk\)" $fep_num($spn) $spn $fep_num($epn) $epn]
        incr cnt
    }
}


puts "#\tproc report_paths_summary <timing_path_collection>"
proc report_paths_summary {paths} {
    global synopsys_program_name
    if {[sizeof_collection $paths] < 0} {
        puts "Error: paths collection should be specified !"
        return 0
    }

    puts "#-----------------------------------------------------------------------------------------------------------------------"
    puts [format "# %-3s | %-7s | %-5s | %-7s > %-7s | %-30s > %-30s" Num Slk Depth SClk EClk Startpoint Endpoint ]
    puts "#-----------------------------------------------------------------------------------------------------------------------"
    
    set cnt 1
    foreach_in_collection path $paths {
        set slk   [get_attribute $path slack]
        set sp    [get_attribute $path startpoint]
        set spn   [get_object_name $sp]
        set ep    [get_attribute $path endpoint]
        set epn   [get_object_name $ep]
        set sclk  [get_attribute $path startpoint_clock]
        set sclkn [get_object_name $sclk]
        set eclk  [get_attribute $path endpoint_clock]
        set eclkn [get_object_name $eclk]
        if {[info exists synopsys_program_name] && [regexp {dc} $synopsys_program_name]} {
            set depth [get_attribute $path logic_depth]
        } else {
            set depth UNK
        }
        set lat_sclk [get_attribute $path startpoint_clock_latency]
        set lat_eclk [get_attribute $path endpoint_clock_latency]

        if {$slk != ""} {
            if {![regexp -nocase {inf} $slk]} { set slk [format "%.4f" $slk] }
        } else {
            set slk "-"
        }
        puts [format "  %-3s | %-7s | %-5s | %7s(%-5.2f) > %-7s(%-5.2f) | %-30s > %-30s" $cnt $slk $depth $sclkn $lat_sclk $eclkn $lat_eclk $spn $epn]
        incr cnt
    }
}

proc get_vio_endpoint_of {startpoint} {
    set sp $startpoint
    set eps [all_fanout -from $sp -flat -endpoints_only]

    set eps_vio ""
    foreach_in_collection ep $eps {
        set slk [get_attribute -quiet [get_timing_path -from $sp -to $ep] slack]
        if {$slk == "" || [regexp -nocase {INF} $slk]} {continue}
        if {$slk < 0} {append_to_collection eps_vio $eps}
    }
    return $eps_vio
}

puts "#\tproc report_bottleneck_points <paths_collection> <-startpoint> <-endpoint>"
proc report_bottleneck_points {args} {
    parse_proc_arguments -args $args results
    if {[info exists results(-startpoint)]} {set check_sp 1} else {set check_sp 0}
    if {[info exists results(-endpoint)]} {set check_ep 1} else {set check_ep 0}
    set paths $results(_paths)
    set clk   $results(-clock)

    set sps [get_attribute $paths startpoint]
    set eps [get_attribute $paths endpoint]
    
    if {$check_sp} {
        foreach_in_collection sp [add_to_collection -unique $sps $sps] {
            set spn [get_object_name $sp]
            set eps_t [all_fanout -from $sp -flat -endpoints_only]
            
            set eps_tns 0.0
            set eps_t_vio ""
            foreach_in_collection ep_t $eps_t {
                set slk [get_attribute -quiet [filter_collection [get_timing_path -from $sp -to $ep_t] "endpoint_clock.name == $clk"] slack]
                if {$slk == "" || [regexp -nocase {INF} $slk]} {continue}
                if {$slk < -0.030} {append_to_collection eps_t_vio $ep_t ; set eps_tns [expr $eps_tns + $slk]}
            }
            
            set arr_tns($spn) $eps_tns
            set arr_vio($spn) $eps_t_vio
            puts [format "%-10.2f %10s/%-10s %-30s" $arr_tns($spn) [sizeof_collection $arr_vio($spn)] [sizeof_collection $eps_t] $spn]
        }
    }

    if {$check_ep} {
        foreach_in_collection ep [add_to_collection -unique $eps $eps] {
            set epn [get_object_name $ep]
            set sps_t [all_fanin -to $ep -flat -startpoints_only]
            
            set sps_tns 0.0
            set sps_t_vio ""
            foreach_in_collection sp_t $sps_t {
                set slk [get_attribute -quiet [filter_collection [get_timing_path -from $sp_t -to $ep] "startpoint_clock.name == $clk"] slack]
                if {$slk == "" || [regexp -nocase {INF} $slk]} {continue}
                if {$slk < -0.030} {append_to_collection sps_t_vio $sp_t ; set sps_tns [expr $sps_tns + $slk]}
            }
            
            set arr_tns($epn) $sps_tns
            set arr_vio($epn) $sps_t_vio
            puts [format "%-10.2f %10s/%-10s %-30s" $arr_tns($epn) [sizeof_collection $arr_vio($epn)] [sizeof_collection $sps_t] $epn]           
        }
    }
}

define_proc_attributes report_bottleneck_points -info "print vio num or tns cuased by start/endpoint of paths specified" \
    -define_args {
        {_paths "specify paths collection" Astring string required}
        {-startpoint "check startpoints of paths" "" boolean optional}
        {-endpoint "check endpoints of paths" "" boolean optional}
        {-clock "define the clock to check timing" Astring string required}
    }

puts "#       proc report_timing_by_points <-from|-through|-to>"
proc report_timing_by_points {args} {
    parse_proc_arguments -args $args results
    if {[info exists results(-from)]}    {set pps_from $results(-from)}
    if {[info exists results(-through)]} {set pps_thr $results(-through)}
    if {[info exists results(-to)]}      {set pps_to $results(-to)}
    
    set paths ""
    if {[info exists pps_from]} {foreach_in_collection p $pps_from {append_to_collection paths [get_timing_path -from $p]}}
    if {[info exists pps_thr]} {foreach_in_collection p $pps_thr {append_to_collection paths [get_timing_path -through $p]}}
    if {[info exists pps_to]} {foreach_in_collection p $pps_to {append_to_collection paths [get_timing_path -to $p]}}

    report_paths_summary $paths   
}
define_proc_attributes report_timing_by_points -info "list path summary from each points listed" \
    -define_args {
        {-from "specified the collection of startpoints" Astring string optional}
        {-through "specified the collection of through points" Astring string optional}
        {-to "specified the collection of endpoints" Astring string optional}
    }

# proc query_cell
# print info of cells inputed
proc query_cells {cs} {
    set ccs [get_cells $cs]
    foreach_in_collection c $ccs {
        set cn  [get_object_name $c]
        set ref [get_property $c ref_name]
        set loc [dbGet [dbGetInstByName $cn].pt]
        
        puts [format "%-20s $loc %-30s" $ref $cn]
    }
}

# proc hili_path "options of report_timing"
proc hili_path {args} {
    set lastFile "~/_tmp_[clock seconds]_mtarpt"
    if {[file exists $lastFile]} {exec rm $lastFile}
    #touch $lastFile
    if {[regexp {\-incr} $args]} {set incr 1; set args [regsub {\-incr[a-z]*} $args {}]} else {set incr 0}
    
    set report_timing_cmd [concat "report_timing -machine_readable " $args " >> $lastFile"]
    eval $report_timing_cmd
    load_timing_debug_report $lastFile -name hilite
    
    if {$incr} {
        highlight_timing_report -file $lastFile -all -append
    } else {
        highlight_timing_report -file $lastFile -all
    }
    #if {[file exists $lastFile]} {exec rm $lastFile}
}


proc get_selection {} {
    foreach obj [dbGet selected] {
        set type [dbGet ${obj}.objType]
        set name [dbGet ${obj}.name]

        switch -glob $type {
            "inst"     {set cmd get_cells}
            "net"      {set cmd get_nets}
            "instTerm" {set cmd get_pins}
            "term"     {set cmd get_ports}
            default    {puts "Error: unspoort object type ($type)"; return }
        }
        if {[info exists results]} {
            append_to_collection results [eval "$cmd $name"]
        } else {
            set results [eval "$cmd $name"]
        }
    }

    return $results
}


proc proc_qor {args} {
    parse_proc_arguments -args $args results
    
    set sort_type wns
    if {[info exists results(-sort_by_tns)]} {set sort_type tns}
    if {[info exists results(-sort_by_path_group_name)]} {set sort_type name}

    redirect /dev/null {set tmp_postfix [exec date +%Y%m%d%s]}
    set tmp_file "~/.tmp_proc_qor_${tmp_postfix}"
    report_analysis_summary -csv $tmp_file
    
    set ifh [open $tmp_file r]
    set line_cnt 0
    set views    ""
    set chks     ""
    set pgs      ""
    while {[gets $ifh line] != -1} {
        if {[regexp {^\s*#} $line] || [regexp {^\s*$} $line]} {continue}
        set line [split $line {,}]
        if {$line_cnt == 0} {
            set ll [split $line {,}]
            set wns_loc  [lsearch $line {allwns}]
            set tns_loc  [lsearch $line {alltns}]
            set vp_loc   [lsearch $line {allvp}]
            set view_loc [lsearch $line {view}]
            set pg_loc   [lsearch $line {grouptype}]
            set chk_loc  [lsearch $line {setupOrhold}]
            incr line_cnt
            continue
        }
        
        set view [lindex $line $view_loc]
        set pg   [lindex $line $pg_loc]
        set chk  [lindex $line $chk_loc]
        set wns  [lindex $line $wns_loc]
        set tns  [lindex $line $tns_loc]
        set vps  [lindex $line $vp_loc]
        
        lappend views $view
        lappend chks  $chk
        lappend pgs   $pg
        set arr_pgs($view) $pg
        set arr_view($view,$pg,$chk) "$wns $tns $vps"
        set arr_wns($view,$pg,$chk) $wns
        set arr_tns($view,$pg,$chk) $tns

        incr line_cnt
    }
    close $ifh
    file delete $tmp_file
    
    foreach view $views {
        foreach pg $pgs {
            if {![info exists arr_wns($view,$pg,Setup)]} {set arr_wns($view,$pg,Setup) 0}
            if {![info exists arr_wns($view,$pg,Hold)]} {set arr_wns($view,$pg,Hold) 0}
            if {![info exists arr_tns($view,$pg,Setup)]} {set arr_tns($view,$pg,Setup) 0}
            if {![info exists arr_tns($view,$pg,Hold)]} {set arr_tns($view,$pg,Hold) 0}
            if {![info exists arr_view($view,$pg,Setup)]} {set arr_view($view,$pg,Setup) "0 0 0"}
            if {![info exists arr_view($view,$pg,Hold)]} {set arr_view($view,$pg,Hold) "0 0 0"}
        }
    }

    foreach view [lsort -u $views] {
        set slks_wns ""
        set slks_tns ""
        if {[info exists arr_slk_wns]} {unset arr_slk_wns}
        foreach pg [lsort -u $pgs] {
            if {![info exists arr_slk_wns($arr_wns($view,$pg,Setup))]} {
                set arr_slk_wns($arr_wns($view,$pg,Setup)) $pg
            } else {
                set arr_slk_wns($arr_wns($view,$pg,Setup)) [lsort -u [concat $arr_slk_wns($arr_wns($view,$pg,Setup)) $pg]]
            }
            if {![info exists arr_slk_tns($arr_tns($view,$pg,Setup))]} {
                set arr_slk_tns($arr_tns($view,$pg,Setup)) $pg
            } else {
                set arr_slk_tns($arr_tns($view,$pg,Setup)) [lsort -u [concat $arr_slk_tns($arr_tns($view,$pg,Setup)) $pg]]
            }
            lappend slks_wns $arr_wns($view,$pg,Setup)
            lappend slks_tns $arr_tns($view,$pg,Setup)
        }
        
        set slks_wns [lsort -u -real $slks_wns]
        set slks_tns [lsort -u -real $slks_tns]
        
        set arr_pg_sorted_wns($view,Setup) ""
        foreach slk $slks_wns {
            set arr_pg_sorted_wns($view,Setup) [concat $arr_pg_sorted_wns($view,Setup) $arr_slk_wns($slk)]
        }

        set arr_pg_sorted_tns($view,Setup) ""
        foreach slk $slks_tns {
            set arr_pg_sorted_tns($view,Setup) [concat $arr_pg_sorted_tns($view,Setup) $arr_slk_tns($slk)]
        }
    }

    switch -glob $sort_type {
        name    {set ppgs [lsort -u -dict $pgs]}
        tns     {set ppgs $arr_pg_sorted_tns($view,Setup)}
        wns     {set ppgs $arr_pg_sorted_wns($view,Setup)}
        default {set ppgs $arr_pg_sorted_wns($view,Setup); puts "Error: \[proc proc_qor\] fail to match sort type ($sort_type)"}
    }
    
    suppressMessage TA-201
    set line ""
    #set wns_setup_tot 999
    #set tns_setup_tot 0
    #set wns_hold_tot  999
    #set tns_hold_tot  0
    #set nvp_setup_tot 0
    #set nvp_hold_tot  0
    foreach view [lsort -u $views] {
        set wns_setup_tot 999
        set tns_setup_tot 0
        set wns_hold_tot  999
        set tns_hold_tot  0
        set nvp_setup_tot 0
        set nvp_hold_tot  0
        puts "\n------------------------------------------------------------------------------------------------------------------------------------"
        put [format "%-40s %-10s %-15s %-15s %-10s %-10s %-15s %-15s" $view WNS TNS NVP FREQ WNS(H) TNS(H) NVP(H)]
        puts "------------------------------------------------------------------------------------------------------------------------------------"
        foreach pg $ppgs {
            set pth [report_timing -quiet -collection -path_group $pg]

            if {$pth != ""} {
                set pod [get_property [get_property $pth capturing_clock] period]
            } else {
                set pod "0.1"
            }

            if {[info exists arr_view($view,$pg,Setup)]} {
                set wns_setup [lindex $arr_view($view,$pg,Setup) 0]
                #puts "-> $view $pg $wns_setup"
                set fmax [expr int(1000.0/($pod-$wns_setup))]
            } else {
                set arr_view($view,$pg,Setup) "\- \- \-"
                set fmax "\-"
            }
 
            if {![info exists arr_view($view,$pg,Hold)]} {
                set arr_view($view,$pg,Hold) "\- \- \-"
            }                  

            set line [concat [concat [concat $pg $arr_view($view,$pg,Setup)] $fmax] $arr_view($view,$pg,Hold)] 
            set cmd "put \[format \"%-40s %-10s %-15s %-15s %-10s %-10s %-15s %-15s\" $line\]"
            eval $cmd

            set wns_setup [lindex $line 1]
            set wns_hold  [lindex $line 5]
            set tns_setup [lindex $line 2]
            set tns_hold  [lindex $line 6]
            set nvp_setup [lindex $line 3]
            set nvp_hold  [lindex $line 7]
            
            if {$wns_setup != "-" && $wns_setup < $wns_setup_tot} {set wns_setup_tot $wns_setup}
            if {$tns_setup != "-"} {set tns_setup_tot [expr $tns_setup_tot + $tns_setup]}
            if {$nvp_setup != "-"} {set nvp_setup_tot [expr $nvp_setup_tot + $nvp_setup]}
            if {$wns_hold != "-" && $wns_hold < $wns_hold_tot} {set wns_hold_tot $wns_hold}
            if {$tns_hold != "-"} {set tns_hold_tot [expr $tns_hold_tot + $tns_hold]}
            if {$nvp_hold != "-"} {set nvp_hold_tot [expr $nvp_hold_tot + $nvp_hold]}

            if {$wns_setup_tot == "999"} {set wns_setup_tot "-"}
            if {$wns_hold_tot  == "999"} {set wns_hold_tot  "-"}
        }
        
        puts "------------------------------------------------------------------------------------------------------------------------------------"
        set cmd "put \[format \"%-40s %-10s %-15s %-15s %-10s %-10s %-15s %-15s\" Total $wns_setup_tot $tns_setup_tot $nvp_setup_tot - $wns_hold_tot $tns_hold_tot $nvp_hold_tot\]"
        eval $cmd
        puts "------------------------------------------------------------------------------------------------------------------------------------"
    } 
    unsuppressMessage TA-201
    
    puts "\n"
}
define_proc_attributes proc_qor -info "report qor, default report by wns of each path group" \
    -define_args {
        {-sort_by_tns "sort pg groups in report by tns" "" boolean optional}
        {-sort_by_path_group_name "sort pg groups in report by name" "" boolean optional}
    }


proc inn_get_attribute {object_collection attribute_pattern} {
    set obj $object_collection
    set att $attribute_pattern
        
    redirect /dev/null {set obj_cnt [sizeof_collection $obj]}
    if {$obj_cnt == 0 || $obj_cnt == ""} {
        puts "\nError: please input collection"
        puts "       correct usage should be :"
        puts "          sns_get_attribute <collection> <attribute_pattern> \n"
        return 0
    }   
        
    set class [get_attribute -quiet $obj object_class]

    redirect -var tmp_rpt {list_property -type $class}
    set start 0
    set atts  ""  
    foreach line [split $tmp_rpt "\n"] {
        if {[regexp {^property } $line]} {
            set start 1
            continue
        }   

        if {[llength $line] == 3} {
            lappend atts [lindex $line 0]
        }   
    }   

    set cmd "set atts_hit \[lsearch -inline -all \$atts \"$att\"\]"
    eval $cmd
        
    puts "\n-----------------------------------------------------------------------------"
    foreach att $atts_hit {
        set objn [get_object_name $obj]
        set val  [get_attribute -quiet $obj $att]
        if {$val == ""} {set val "-"}
        puts [format "%-35s %-30s" $att $val]
    }   
    puts "-----------------------------------------------------------------------------\n"
}

proc inn_tracSink2Root {sink clk} {
    global trace_pps 
    set drv_inst_pt [dbGet [dbGet -p [dbGet -p top.insts.instTerms.name $sink].net.instTerms.isOutput 1].inst]
    set drv_port_pt [dbGet -p [dbGet -p top.insts.instTerms.name $sink].net.terms.isInput 1]

    if {![regexp 0x0 $drv_inst_pt] && ![regexp 0x0 $drv_port_pt]} {
        puts "Error: found multi-driver for input pin : $sink"
        return 0
    }

    if {![regexp 0x0 $drv_inst_pt]} {
        set net_pt [dbGet [dbGetTermByInstTermName $sink].net]
        select_obj $drv_inst_pt
        select_obj $net_pt
        foreach x [dbGet [dbGet -p $drv_inst_pt.instTerms.isInput 1].name] {
            set a {}
            if {[sizeof_collection [get_property [get_pins $x] clocks]]>0} {
                foreach y [lsort -u [get_object_name [get_property [get_pins $x] clocks]]] {
                    lappend a $y
                    if {[get_object_name [get_property -quiet [get_clocks $y] master_clock]] != ""} {
                        lappend a [get_object_name [get_property [get_clocks $y] master_clock]]
                    }
                }
            }
            if {[lsearch $a $clk] >= 0} {
                set drv_pins $x
                puts "+--> $drv_pins : [dbGet $drv_inst_pt.cell.name]"
                lappend trace_pps $x
                inn_tracSink2Root  $drv_pins $clk
            }
        }
    }
   
    if {![regexp 0x0 $drv_port_pt]} {
        puts "|--> [dbGet $drv_port_pt.name]"
        lappend trace_pps "[dbGet $drv_port_pt.name]"
    }
    puts "\n\n"
}

proc inn_list_inports_load {in_ports} {
    set ips [get_ports -quiet $in_ports]
    foreach_in_collection ip $ips {                                                    
        puts "|--> [get_object_name $ip]"
        sns_pl [all_fanout -from $ip -endpoints_only]
    } 
}

proc inn_list_outports_driver {out_ports} {
    set ops [get_ports -quiet $out_ports]
    foreach_in_collection op $ops {                                                    
        puts "|<-- [get_object_name $op]"
        sns_pl [all_fanin -to $op -startpoints_only]
    } 
}

proc Inn_sum_list {lst} {
    set re 0
    set n 0
    foreach cur $lst {
        set re [expr $re + [lindex $lst $n]]
        incr n
    }
    return $re
}

proc Inn_summary_timing {view} {
    puts [format "%-30s %10s %10s %10s" Group WNS TNS NVP]
    puts "---------------------------------------------------------------"
    set TTNS 0
    set TNVP 0
    set TWNS 0
    foreach_in_collection cur [get_path_groups] {
        set grp [get_object_name $cur]
        set path [report_timing -quiet -collection -path_group $grp -view $view]
        set WNS [get_property $path slack]
        if {$WNS != "" && $WNS < $TWNS} {
            set TWNS $WNS
        }
        set slack_lst [get_property [report_timing -quiet -path_group $grp  -max_paths 10000 -collection -max_slack -0.005 -view $view] slack]
        set NVP [llength $slack_lst]
        set TNS [Inn_sum_list $slack_lst]
        set TTNS [expr $TTNS + $TNS]
        set TNVP [expr $TNVP + $NVP]
        puts [format "%-30s %10s %10s %10s" $grp $WNS $TNS $NVP]
    }
    puts "---------------------------------------------------------------"
    puts [format "%-30s %10s %10s %10s" Summary $TWNS $TTNS $TNVP]
}

proc Inn_get_group_eps {group} {
    set eps [get_property [report_timing -quiet -path_group $group -max_paths 10000 -collection -max_slack -0.005] endpoint]
    foreach_in_collection cur $eps {
        set slack [get_property [report_timing -quiet -collection -to [get_object_name $cur]] slack]
        puts "[get_object_name $cur] $slack"
    }
}

proc Inn_list_procs {} {
    puts "Inn procs:"
    set n 1
    foreach cur_proc [concat [info proc Inn_*] [info proc inn_*]] {
        puts "[format "%-3s %-20s" $n. $cur_proc]"
        incr n
    }
}
Inn_list_procs