if {[info exists synopsys_program_name] && $synopsys_program_name != ""} {
    alias list_router "get_cells -hier -filter \"ref_name =~ quad_npcr*\""
    alias cs          "change_selection"
    alias gs          "get_selection"
    alias gc          "get_cells"
    alias gp          "get_pins"
    alias all_data_inputs "remove_from_collection \[all_inputs\] \[get_attribute \[get_clocks -filter \"defined(sources)\"\] sources\]"
    alias rpt         "report_timing -nosplit -include_hierarchical_pins -transition"
    alias rptc        "report_timing -nosplit -include_hier -path_type full_clock_expanded -transition -input -cap"
}


if {[info exists synopsys_program_name] && $synopsys_program_name == "icc2_shell"} {
   
}

# (c) 2018 Synopsys, Inc.  All rights reserved.
#
# This script is proprietary and confidential information of
# Synopsys, Inc. and may be used and disclosed only as authorized per
# your agreement with Synopsys, Inc. controlling such use and disclosure.


#C# Category       supported
#D# Description    reports 3 stages of timing
#D#                using -highlight, these 3 stages will be highlighted in GUI.
#D#                command takes switches of get_timing_paths
#U# Usage          report_stage_timing -scenario [current_scenario]
#K# Keywords       report timing stage pipeline highlight gui
#L# Language       tcl 
#T# Tools          dcrt icc2 pt

proc report_stage_timing {args} {

	parse_proc_arguments -args $args results
	global synopsys_program_name

	set DEBUG 0
	set cmd "get_timing_paths"

	set highlight 0
	if {[info exists results(-highlight)]} {
		if {[get_app_var in_gui_session]} {
			set highlight 1
			gui_set_setting -window [gui_get_current_window -types Layout -mru] -setting showIgnoreHighlightColor -value false
		}
	}
		
	set verbose 0
	if {[info exists results(-verbose)]} {
		set verbose 1
	}

	if {[info exists results(-modes)]} {
		set modes_arg " -modes $results(-modes)"
	} else {
		set modes_arg ""
	}
	if {[info exists results(-corners)]} {
		set corners_arg " -corners $results(-corners)"
	} else {
		set corners_arg ""
	}
	set provide_scenario 0
	if {[info exists results(-scenarios)]} {
		set provide_scenario 1
		set act_scn [get_object_name [get_scenarios -filter active]]
		foreach_in_collection scn [get_scenarios $results(-scenarios)] {
			if {[llength [lsearch -all -inline -exact $act_scn [get_object_name $scn]]] == 0} {
				puts "Error: Scenario [get_object_name $scn] is not active"
				return
			}
		}
		set scenarios_arg " -scenarios $results(-scenarios)"
		if {[info exists results(-group)]} {
			set cur_scn [current_scenario]
			foreach_in_collection scn [get_scenarios $results(-scenarios)] {
				current_scenario $scn
				if {[sizeof_collection [get_path_group -quiet $results(-group)]] == 0} {
					puts "Error: Path Group $results(-group) doesn't exist in Scenario [get_object_name $scn]"
					current_scenario $cur_scn
					return
				}
			}
			current_scenario $cur_scn
		}
	} else {
		set scenarios_arg ""
	}
	if {[info exists results(-group)]} {
		set group_arg " -group $results(-group)"
	} else {
		set group_arg ""
	}
	if {[info exists results(-nworst)]} {
		set nworst_arg " -nworst $results(-nworst)"
	} else {
		set nworst_arg ""
	}
	if {[info exists results(-max_paths)]} {
		set max_paths_arg " -max_paths $results(-max_paths)"
	} else {
		set max_paths_arg ""
	}
	if {[info exists results(-delay_type)]} {
		set delay_type_arg " -delay_type $results(-delay_type)"
		if {$provide_scenario} {
			if {[lsearch $delay_type_arg max*] < 0} {
				redirect /dev/null {set active_scn [get_scenarios $scenarios_arg -filter active&&hold]}
				if {[sizeof_collection $active_scn] == 0} {
					puts "Error: scenario and delay_type mismatch"
					return
				}
			} else {
				redirect /dev/null {set active_scn [get_scenarios $scenarios_arg -filter active&&setup]}
				if {[sizeof_collection $active_scn] == 0} {
					puts "Error: scenario and delay_type mismatch"
					return
				}
			}
		}
	} else {
		set delay_type_arg ""
	}
	if {[info exists results(-slack_lesser_than)]} {
		set slack_lesser_than_arg " -slack_lesser_than $results(-slack_lesser_than)"
	} else {
		set slack_lesser_than_arg ""
	}
	if {[info exists results(-from)]} {
		set from_arg " -from $results(-from)"
	} else {
		set from_arg ""
	}
	if {[info exists results(-to)]} {
		set to_arg " -to $results(-to)"
	} else {
		set to_arg ""
	}
	if {[info exists results(-through)]} {
		set through_arg " -through $results(-through)"
	} else {
		set through_arg ""
	}
	if {[info exists results(-pba)]} {
		if {$synopsys_program_name eq "pt_shell"} {
#			set pba_arg " -pba $results(-pba)"
			set pba_arg " -pba exhaustive"
		} else {
			set pba_arg ""
		}
	} else {
		set pba_arg ""
	}

	if {$synopsys_program_name eq "icc2_shell"} {
		set significant [get_app_option_value -name shell.common.report_default_significant_digits]
		set cpu_memory [get_app_option_value -name shell.common.monitor_cpu_memory]
		set_app_options -as_user_default -list "shell.common.monitor_cpu_memory false"
	} else {
		set significant [get_app_var report_default_significant_digits]
	}
	if {$DEBUG} {
		puts "$cmd$modes_arg$corners_arg$scenarios_arg$group_arg$nworst_arg$max_paths_arg$delay_type_arg$slack_lesser_than_arg$from_arg$to_arg$through_arg$pba_arg"
	}
	redirect /dev/null {set paths [eval $cmd$modes_arg$corners_arg$scenarios_arg$group_arg$nworst_arg$max_paths_arg$delay_type_arg$slack_lesser_than_arg$from_arg$to_arg$through_arg$pba_arg]}
	if {[sizeof_collection $paths] == 0} {
		puts "Error: no path found"
		return
	}

	if {$highlight} {
		if {[sizeof_collection $paths] > 1} {
			set highlight 0
		}
	}
	
	set index 0
	set scenario_name_length 0
	set endpoint_name_length 0
	foreach_in_collection path $paths {
		set endpoint [get_attribute $path endpoint]
		set startpoint [get_attribute $path startpoint]
		set endpoint_class [get_attribute $endpoint object_class]
		set startpoint_class [get_attribute $startpoint object_class]
		if {$synopsys_program_name eq "pt_shell"} {
			set endpoint_name [get_object_name [get_attribute $path endpoint]]
			set startpoint_name [get_object_name [get_attribute $path startpoint]]
		} else {
			set endpoint_name [get_attribute $path endpoint_name]
			set startpoint_name [get_attribute $path startpoint_name]
		}
		set slack [get_attribute $path slack]
		set depth [expr [sizeof_collection [get_pins [get_attribute  [get_attribute $path points] object] -filter "direction==out&&!is_hierarchical" -quiet]] -1]
		if {$synopsys_program_name eq "pt_shell"} {
			set scenario_name  "CURRENT_SCENARIO"
			set startpoint_clock_latency [get_attribute $path startpoint_clock_latency]
			set endpoint_clock_latency [get_attribute $path endpoint_clock_latency]
		} else {
			set scenario_name  [get_attribute $path scenario_name]
			set startpoint_clock_open_edge_arrival [get_attribute $path startpoint_clock_open_edge_arrival]
			set startpoint_clock_open_edge_value [get_attribute $path startpoint_clock_open_edge_value]
			set startpoint_clock_latency [expr $startpoint_clock_open_edge_arrival - $startpoint_clock_open_edge_value]
			set endpoint_clock_close_edge_arrival [get_attribute $path endpoint_clock_close_edge_arrival]
			set endpoint_clock_close_edge_value [get_attribute $path endpoint_clock_close_edge_value]
			set endpoint_clock_latency [expr $endpoint_clock_close_edge_arrival - $endpoint_clock_close_edge_value]
		}
		set skew [expr $startpoint_clock_latency - $endpoint_clock_latency]
		if {$DEBUG} {
			puts "$startpoint_name $endpoint_name $slack $endpoint_class $startpoint_class $skew"
		}

		set start_path_unconstraint 0
		if {$startpoint_class eq "port"} {
			set start_is_port 1
		} else {
			set start_is_port 0
			set startpoint_cell [get_cells -of_objects $startpoint]
			set startcmd "get_timing_path -to $startpoint_cell"
			if {$synopsys_program_name ne "pt_shell"} {
				set scenarios_arg " -scenarios $scenario_name"
			}
			redirect /dev/null {set start_path [eval $startcmd$modes_arg$corners_arg$scenarios_arg$delay_type_arg$pba_arg]}
			if {[sizeof_collection $start_path] == 0} {
				set start_path_unconstraint 1
			} else {
				set start_slack [get_attribute $start_path slack]
				set start_depth [expr [sizeof_collection [get_pins [get_attribute  [get_attribute $start_path points] object] -filter "direction==out&&!is_hierarchical" -quiet]] -1]
				set start_startpoint [get_attribute $start_path startpoint]
				if {$synopsys_program_name eq "pt_shell"} {
					set start_startpoint_name [get_object_name [get_attribute $start_path startpoint]]
					set start_endpoint_name [get_object_name [get_attribute $start_path endpoint]]
					set startpoint_clock_latency [get_attribute $start_path startpoint_clock_latency]
					set endpoint_clock_latency [get_attribute $start_path endpoint_clock_latency]
				} else {
					set start_startpoint_name [get_attribute $start_path startpoint_name]
					set start_endpoint_name [get_attribute $start_path endpoint_name]
					set start_startpoint_clock_open_edge_arrival [get_attribute $start_path startpoint_clock_open_edge_arrival]
					set start_startpoint_clock_open_edge_value [get_attribute $start_path startpoint_clock_open_edge_value]
					set start_startpoint_clock_latency [expr $startpoint_clock_open_edge_arrival - $startpoint_clock_open_edge_value]
					set start_endpoint_clock_close_edge_arrival [get_attribute $start_path endpoint_clock_close_edge_arrival]
					set start_endpoint_clock_close_edge_value [get_attribute $start_path endpoint_clock_close_edge_value]
					set start_endpoint_clock_latency [expr $endpoint_clock_close_edge_arrival - $endpoint_clock_close_edge_value]
				}
				set start_skew [expr $startpoint_clock_latency - $endpoint_clock_latency]
				if {$DEBUG} {
					puts "START: $start_startpoint_name $start_endpoint_name $start_slack $start_depth $start_skew"
				}
			}
		}

		set end_path_unconstraint 0
		if {$endpoint_class eq "port"} {
			set end_is_port 1
		} else {
			set end_is_port 0
			set end_path_unconstraint 0
			set endpoint_cell [get_cells -of_objects $endpoint]
			set endcmd "get_timing_path -from $endpoint_cell"
			if {$synopsys_program_name ne "pt_shell"} {
				set scenarios_arg " -scenarios $scenario_name"
			}
			redirect /dev/null {set end_path [eval $endcmd$modes_arg$corners_arg$scenarios_arg$delay_type_arg$pba_arg]}
			if {[sizeof_collection $end_path] == 0} {
				set end_path_unconstraint 1
			} else {
				set end_slack [get_attribute $end_path slack]
				set end_depth [expr [sizeof_collection [get_pins [get_attribute  [get_attribute $end_path points] object] -filter "direction==out&&!is_hierarchical" -quiet]] -1]
				set end_endpoint [get_attribute $end_path endpoint]
				if {$synopsys_program_name eq "pt_shell"} {
					set start_startpoint_name [get_object_name [get_attribute $end_path startpoint]]
					set start_endpoint_name [get_object_name [get_attribute $end_path endpoint]]
					set startpoint_clock_latency [get_attribute $end_path startpoint_clock_latency]
					set endpoint_clock_latency [get_attribute $end_path endpoint_clock_latency]
				} else {
					set end_startpoint_name [get_attribute $end_path startpoint_name]
					set end_endpoint_name [get_attribute $end_path endpoint_name]
					set end_startpoint_clock_open_edge_arrival [get_attribute $end_path startpoint_clock_open_edge_arrival]
					set end_startpoint_clock_open_edge_value [get_attribute $end_path startpoint_clock_open_edge_value]
					set end_startpoint_clock_latency [expr $startpoint_clock_open_edge_arrival - $startpoint_clock_open_edge_value]
					set end_endpoint_clock_close_edge_arrival [get_attribute $end_path endpoint_clock_close_edge_arrival]
					set end_endpoint_clock_close_edge_value [get_attribute $end_path endpoint_clock_close_edge_value]
					set end_endpoint_clock_latency [expr $endpoint_clock_close_edge_arrival - $endpoint_clock_close_edge_value]
				}
				set end_skew [expr $startpoint_clock_latency - $endpoint_clock_latency]
				if {$DEBUG} {
					puts "END: $end_startpoint_name $end_endpoint_name $end_slack $end_depth $end_skew"
				}
			}
		}
	

		set outputflag $start_is_port$end_is_port$start_path_unconstraint$end_path_unconstraint
		switch $outputflag {
			0000 {
				set START_SLACK($index) "[format "%15.${significant}f (%2s)" $start_slack $start_depth]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15.${significant}f (%2s)" $end_slack $end_depth]"
			}
			0001 {
				set START_SLACK($index) "[format "%15.${significant}f (%2s)" $start_slack $start_depth]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15s (%2s)" "Unconstrained" "0"]"
			}
			0010 {
				set START_SLACK($index) "[format "%15s (%2s)" "Unconstrained" "0"]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15.${significant}f (%2s)" $end_slack $end_depth]"
			}
			0011 {
				set START_SLACK($index) "[format "%15s (%2s)" "Unconstrained" "0"]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15s (%2s)" "Unconstrained" "0"]"
			}
			0100 {
				set START_SLACK($index) "[format "%15.${significant}f (%2s)" $start_slack $start_depth]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15s (%2s)" "OutputPort" "0"]"
			}
			0110 {
				set START_SLACK($index) "[format "%15s (%2s)" "Unconstrained" "0"]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15s (%2s)" "OutputPort" "0"]"
			}

			1000 {
				set START_SLACK($index) "[format "%15s (%2s)" "InputPort" "0"]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15.${significant}f (%2s)" $end_slack $end_depth]"
			}
			1001 {
				set START_SLACK($index) "[format "%15s (%2s)" "InputPort" "0"]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15s (%2s)" "Unconstrained" "0"]"
			}
			1100 {
				set START_SLACK($index) "[format "%15s (%2s)" "InputPort" "0"]"
				set SLACK($index) "[format "%15.${significant}f (%2s)" $slack $depth]"
				set END_SLACK($index) "[format "%15s (%2s)" "OutputPort" "0"]"
			}
		}
		set SCENARIO($index) $scenario_name
		set ENDPOINT($index) $endpoint_name
		if {$DEBUG} {
			puts "$START_SLACK($index) $SLACK($index) $END_SLACK($index) $SCENARIO($index) $ENDPOINT($index)"
		}

		if {$verbose} {
			if {[info exists start_startpoint] > 0} {
				if {[get_attribute $start_startpoint object_class] eq "cell"} {
					set START_STARTPOINT_CEL($index) [get_object_name [get_cells -of_objects $start_startpoint]]
				} else {
					set START_STARTPOINT_CEL($index) [get_object_name $start_startpoint]
				}
			} else {
				set START_STARTPOINT_CEL($index) Unknown
			}
			if {[get_attribute $startpoint object_class] eq "cell"} {
				set STARTPOINT_CEL($index) [get_object_name [get_cells -of_objects $startpoint]]
			} else {
				set STARTPOINT_CEL($index) [get_object_name $startpoint]
			}
			if {[get_attribute $endpoint object_class] eq "cell"} {
				set ENDPOINT_CEL($index) [get_object_name [get_cells -of_objects $endpoint]]
			} else {
				set ENDPOINT_CEL($index) [get_object_name $endpoint]
			}
			if {[info exists end_endpoint] > 0} {
				if {[get_attribute $end_endpoint object_class] eq "cell"} {
					set END_ENDPOINT_CEL($index) [get_object_name [get_cells -of_objects $end_endpoint]]
				} else {
					set END_ENDPOINT_CEL($index) [get_object_name $end_endpoint]
				}
		
			} else {
				set END_ENDPOINT_CEL($index) Unknown
			}

		}

		incr index

	}

	if {$highlight} {
		gui_change_highlight -remove -all_colors
		gui_change_highlight -color red -collection $paths
		gui_change_highlight -color blue -collection $start_path
		gui_change_highlight -color green -collection $end_path
	}

	set scenario_name_length 0
	set endpoint_name_length 0

	foreach {k v} [array get SCENARIO] {
		if {[string length $v] > $scenario_name_length} {
			set scenario_name_length [expr [string length $v] + 5]
		}
	}

	foreach {k v} [array get ENDPOINT] {
		if {[string length $v] > $endpoint_name_length} {
			set endpoint_name_length [expr [string length $v] + 5]
		}
	}

	puts ""
	puts "[format "%20s %20s %20s %2s %-${scenario_name_length}s %2s %-${endpoint_name_length}s" "PreStageSlack(Lvl)" "CurStageSlack(Lvl)" "PostStageSlack(Lvl)" "" "Scenario" "" "Endpoint"]"
	puts "[string repeat "=" [expr 70 + ${scenario_name_length} + ${endpoint_name_length}]]"
	for {set i 0} {$i < [sizeof_collection $paths]} {incr i} {
		if {$verbose} {
			puts "START_STARTPOINT: $START_STARTPOINT_CEL($i)"
			puts "      STARTPOINT: $STARTPOINT_CEL($i)"
			puts "        ENDPOINT: $ENDPOINT_CEL($i)"
			puts "    END_ENDPOINT: $END_ENDPOINT_CEL($i)"
		}
		puts "[format "%15s %15s %15s %2s %-${scenario_name_length}s %2s %-${endpoint_name_length}s" $START_SLACK($i) $SLACK($i) $END_SLACK($i) "" $SCENARIO($i) "" $ENDPOINT($i)]"
		if {$verbose} {
			puts "[string repeat "-" [expr 70 + ${scenario_name_length} + ${endpoint_name_length}]]"
		}
	}
	
	if {$synopsys_program_name eq "icc2_shell"} {
		redirect /dev/null {set_app_options -as_user_default -list "shell.common.monitor_cpu_memory $cpu_memory"}
	}
	puts ""
}

define_proc_attributes report_stage_timing \
	-info "Analyzing pre/post stage slack of timing path" \
	-define_args {
		{-modes "use scenarios of these modes (default is all modes)" mode_list string optional}
		{-corners "use scenarios of these corners (default is all corners)" corner_list string optional}
		{-scenarios "use scenarios of these corners (default is all corners)" scenario_list string optional}
		{-group "List of path group names to report (default is all path group)" group_list string optional}
		{-nworst "Number of paths per endpoint: \n\t\t\t\tValue >= 1" nworst int optional}
		{-max_paths "Maximum total paths to find: \n\t\t\t\tValue >= 1" max_paths int optional}
		{-delay_type "Delay type: \n\t\t\t\tValues: max, max_fall, max_rise, min,\n\t\t\t\tmin_fall, min_rise" delay_type string optional}
		{-slack_lesser_than "Filter by slack" lesser_slack_limit float optional}
		{-from "List of path startpoints or clocks" from_list string optional}
		{-to "List of path endpoints or clocks" to_list string optional}
		{-through "List of path endpoints or clocks" through_list string optional}
		{-pba "Exhaustive path-based analysis mode" "" boolean optional}
		{-highlight "Highlight stage: blue - red - green" "" boolean optional}
		{-verbose "Print startpoint and endpoint" "" boolean optional}
	}


#source ~luojianping/scr/primetime/proc/pt_lib.tcl

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
proc sns_get_clock_structure {} {
    if {[file writable ./]} {
        exec mkdir -p ./clock_structure
    } else {
        puts "Error: fail to mkdir under current path, terminate..."
        return
    }
    
    puts "\n++ Start to generate clock structure ... \n"

    set total_clocks [get_clocks -filter {defined(sources)}]
    set total_cnt [sizeof_collection $total_clocks]
    set cur_clks ""

    # master clocks
    set done_cnt 0
    foreach_in_collection c [get_clocks -filter {is_generated == false && defined(sources)}] {
        set cn [get_object_name $c]
        exec mkdir -p clock_structure/$cn

        lappend cur_clks $cn
        set arr_path($cn) "./clock_structure/$cn"
        
        set paths [filter_collection [get_timing_path -from $c -slack_lesser_than 0.000 -max_paths 1000 -include_hierarchical_pins] {slack != "INFINITY"}]
        redirect $arr_path($cn)/report_timing_from__${cn}.rpt {report_timing $paths -nosplit -include_hierarchical_pins}
        
        set paths [filter_collection [get_timing_path -to $c -slack_lesser_than 0.000 -max_paths 1000 -include_hierarchical_pins] {slack != "INFINITY"}]
        redirect $arr_path($cn)/report_timing_to__${cn}.rpt {report_timing $paths -nosplit -include_hierarchical_pins}

        incr done_cnt
    }
    puts "\[${done_cnt} \/ ${total_cnt}\]"
    
    # generate clocks
    set search_cnt 1
    while {1} {
        set up_clks $cur_clks
        set cur_clks ""
        foreach_in_collection c [get_clocks -filter {is_generated == true && defined(sources)}] {
            set cn [get_object_name $c]
            set mcn [get_object_name [get_attribute $c master_clock]]
            if {[lsearch $up_clks $mcn] > -1} {
                set up_clk [lsearch -inline $up_clks $mcn]
                exec mkdir -p $arr_path($up_clk)/$cn
                set arr_path($cn) "$arr_path($up_clk)/$cn"

                set paths [filter_collection [get_timing_path -from $c -slack_lesser_than 0.000 -max_paths 1000 -include_hierarchical_pins] {slack != "INFINITY"}]
                redirect $arr_path($cn)/report_timing_from__${cn}.rpt {report_timing $paths -nosplit -include_hierarchical_pins}

                set paths [filter_collection [get_timing_path -to $c -slack_lesser_than 0.000 -max_paths 1000 -include_hierarchical_pins] {slack != "INFINITY"}]
                redirect $arr_path($cn)/report_timing_to__${cn}.rpt {report_timing $paths -nosplit -include_hierarchical_pins}

                lappend cur_clks $cn
            } else {
                continue
            }
        }
        incr search_cnt
        
        set cnt [llength $cur_clks]
        if {$search_cnt > 100 && $cnt > 0} {
            puts "Error: search deep exceed 100, terminated ..."
            break
        } elseif {$cnt == 0} {
            puts "Build clock structure done, max search depth $search_cnt !"
            break
        } else {
            set done_cnt [expr $done_cnt + $cnt]
            puts "\[${done_cnt} \/ ${total_cnt}\]"
        }
    }
}
# ====================================================================
# Proc to check duty cycle in Primetime
# Usage
#       report_dcd -all
#       report_dcd -clock CLKM1_XXX -rpt_dir "./dcd_reports"
# Author: Jianping Luo
# History: 
#       v1.0 : initial version - March 9th 2018
# ====================================================================
puts "proc report_dcd <-all/-clock> <-rpt_dir>"
proc report_dcd {args} {
    global RUN

    set results(-all) 0
    set results(-rpt_dir) "./"
    parse_proc_arguments -args $args results
    
    set start_time [clock seconds]
    if {$results(-all)} {
        puts "\[report_dcd\]: report_dcd for all clocks in current design. Long run time is expected depending on number and size of all clocks"
        puts "\[report_dcd\]: report_dcd start at [date]..."
        set allclk  [get_clocks * -filter "propagated_clock == true"]
        set clks    [get_object_name $allclk]
    } elseif {[llength $results(-clock)] > 0} {
        puts "\[report_dcd\]: report_dcd for clocks assigned by user: $results(-clock)"
        puts "\[report_dcd\]: report_dcd start at [date]..."
        set clks $results(-clock)
    } else {
        puts "\[report_dcd\]: Error, at least one of -all and -clock should be defined ! Terminated ..."
        return 0
    }
    
    set clks_succ ""
    set clks_fail ""
    foreach clk $clks {
        if {[get_clock -quiet $clk] == ""} {
            puts "Error: clock $clk cannot be found !"
            lappend clks_fail $clk
            continue
        }
        
        set ofh [open $results(-rpt_dir)/${RUN}.dcd.${clk}.rpt "w"]
        redirect $results(-rpt_dir)/${RUN}.mpw.${clk}.full.rpt {report_min_pulse_width -nosplit -significant_digits 4 -path_type full_clock_expanded [all_registers -clock $clk -clock_pins]}
        puts "\n\[report_dcd\]: report_dcd for $clk start at [date] ..."

        if {[file exists $results(-rpt_dir)/${RUN}.mpw.${clk}.full.rpt]} {
            set ifh [open $results(-rpt_dir)/${RUN}.mpw.${clk}.full.rpt r]
            set Edge 0
            set EdgeClk ""
            set start_open  0
            set start_close 0
            set open_cell_list  ""
            set close_cell_list ""
            set start 0
            set valid 0

            #puts $ofh "#ClkPin Clk HiLo Period Uncertainty ActualPulse ActualPulseAdj ClkIsNotConv DutyCycle"
            puts $ofh [format "# %-10s %-10s %-10s %-10s %-10s %-15s %-15s %-15s %-15s %-40s" DtRatio  DutyCyc HiLo Clk Period Uncertainty ActualPulse ActPulseAdj ClkIsNotConv ClkPin]
            while {[gets $ifh line] >= 0} {
                set splitline [regexp -inline -all -- {\S+} $line]
                if {[regexp {  Pin:} $line]} {
                    set pin [lindex $splitline 1]
                    set start 1
                    set hl ""
                }
                if {[regexp {Related clock:} $line] && $start == 1} {
                    set Clk [lindex $splitline 2]
                    if {[string match $clk $Clk]} {
                        set start_open 1
                        set valid 1
                    } else {
                        set valid 0
                    }
                }

                # check clock reconvergent path
                if {[regexp { edge\)} $line] && $start == 1 && $valid == 1} {
                    set prd0 [lindex $line 4]
                    lappend EdgeClk $prd0
                }
                if {[regexp {open edge clock latency} $line] && $valid == 1 && [llength $line] == 2} {
                    set start_open  0
                    set start_close 1
                }
                if {[regexp {close edge clock latency} $line] && $valid == 1 && [llength $line] == 2} {
                    set start_close 0
                }

                if {$start == 1 && $start_open == 1} {
                    if {[string eq [lindex $splitline [expr [llength $splitline] -1]] "r"] || [string eq [lindex $splitline [expr [llength $splitline] - 1]] "f"]} {
                        set open_cell [lindex $splitline 1]
                        lappend open_cell_list $open_cell
                    }
                }

                if {$start == 1 && $start_close == 1} {
                    if {[string eq [lindex $splitline [expr [llength $splitline] -1]] "r"] || [string eq [lindex $splitline [expr [llength $splitline] - 1]] "f"]} {
                        set close_cell [lindex $splitline 1]
                        lappend close_cell_list $close_cell
                    }
                }

                if {[regexp {clock uncertainty} $line] && $start == 1 && $valid == 1} {
                    set unc [lindex $splitline end-1]
                    set $Edge 0
                }
                if {[regexp {required pulse width} $line] && $start == 1 && $valid == 1} {
                    set hl [regsub -all {\(|\)} [lindex $splitline 3] ""]
                }
                if {[info exists hl] && $hl != "" && [regexp {actual pulse width} $line] && $start == 1} {
                    if {[string eq $clk $Clk]} {
                        set actual_pulse [lindex $splitline 3]
                        set prd [expr ([lindex $EdgeClk 1] - [lindex $EdgeClk 0])*2]
                        set actual_pulse_adj [expr $actual_pulse - $unc]
                        set duty_cycle [format "%.4f" [expr ${actual_pulse_adj}/${prd}]]
                        set duty_cycle_dratio [expr abs($duty_cycle - 0.5)] 
                        set actual_pulse_adj [format "%.4f" $actual_pulse_adj]
                        if {[string eq $open_cell_list $close_cell_list]} {
                            set ClkIsNotConv true
                        } else {
                            set ClkIsNotConv false
                        }

                        if {[regexp {high} $hl]} {
                            #puts $ofh "$pin $Clk $hl $prd $unc $actual_pulse $actual_pulse_adj $ClkIsNotConv $duty_cycle"
                            #puts $ofh [format "%-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-40s" $duty_cycle_dratio $duty_cycle $hl $Clk $prd $unc $actual_pulse $actual_pulse_adj $ClkIsNotConv $pin]
                            set arr_dc($pin)  $duty_cycle
                            set arr_dcd($pin) $duty_cycle_dratio
                            set arr_hl($pin)  $hl
                            set arr_clk($pin) $Clk
                            set arr_prd($pin) $prd
                            set arr_unc($pin) $unc
                            set arr_ap($pin)  $actual_pulse
                            set arr_apa($pin) $actual_pulse_adj
                            set arr_cic($pin) $ClkIsNotConv
                            
                            if {[info exists arr_dpp($duty_cycle_dratio)]} {
                                lappend arr_dpp($duty_cycle_dratio) $pin
                            } else {
                                set arr_dpp($duty_cycle_dratio) $pin
                            }
                        }

                        set EdgeClk ""
                        set start 0
                        set open_cell_list ""
                        set close_cell_list ""
                        set start_open 0
                        set start_close 0
                        set valid 0
                    } else {
                        set EdgeClk ""
                        set start 0
                        set open_cell_list ""
                        set close_cell_list ""
                        set start_open ""
                        set start_close ""
                        set valid ""
                    }
                }
            }
            
            foreach v [lsort -real -decreasing [array name arr_dpp]] {
                foreach pin $arr_dpp($v) {
                    set duty_cycle        $arr_dc($pin)
                    set duty_cycle_dratio $arr_dcd($pin)
                    set hl                $arr_hl($pin)
                    set Clk               $arr_clk($pin)
                    set prd               $arr_prd($pin)
                    set unc               $arr_unc($pin)
                    set actual_pulse      $arr_ap($pin)
                    set actual_pulse_adj  $arr_apa($pin)
                    set ClkIsNotConv      $arr_cic($pin)
                    
                    if {$duty_cycle_dratio > 0.05} {
                        puts $ofh [format "x %-10s %-10s %-10s %-10s %-10s %-15s %-15s %-15s %-15s %-40s" $duty_cycle_dratio $duty_cycle $hl $Clk $prd $unc $actual_pulse $actual_pulse_adj $ClkIsNotConv $pin]
                        if {[info exists arr_vio($Clk)]} {
                            incr arr_vio($Clk)
                        } else {
                            set arr_vio($Clk) 1
                        }
                    } else {
                        puts $ofh [format "  %-10s %-10s %-10s %-10s %-10s %-15s %-15s %-15s %-15s %-40s" $duty_cycle_dratio $duty_cycle $hl $Clk $prd $unc $actual_pulse $actual_pulse_adj $ClkIsNotConv $pin]
                        if {![info exists arr_vio($Clk)]} {set arr_vio($Clk) 0}
                    }
                }
            }

            close $ifh
        } else {
            puts "\[report_dcd\]: fail to find MPW report: $results(-rpt_dir)/${RUN}.mpw.${clk}.full.rpt"
        }

        close $ofh
        puts "\[report_dcd\]: create dcd report : $results(-rpt_dir)/${RUN}.dcd.${clk}.rpt "
        puts "\[report_dcd\]: report_dcd for $clk end at [date]"
    }
    
    puts "\n\[report_dcd\]: summary "
        foreach clk [array name arr_vio] {
        puts [format "         FEP: %-10s %-20s" $arr_vio($clk) $clk]
    }
    set end_time [clock seconds]
    set run_time [format "%.1f" [expr ($end_time - $start_time)/60]]
    puts "\[report_dcd\]: report_dcd ends at [date]"
    puts "\[report_dcd\]: report_dcd run time is: $run_time min"
}

define_proc_attributes report_dcd \
    -info "report dcd on clock pins" \
    -define_args {
        {-all "optional: report_DCD for all the clocks in the design, exclude virtual clocks and clocks without sinks" {} boolean optional}
        {-clock "optional: report DCD for specified clock(s) in the design" clock_list list optional}
        {-rpt_dir "optional: specify report directory path, default is current directory" output_dir string optional}
    }

#echo "SCRIPT-Info: Start: [info script]"
# ? 2014 Synopsys, Inc. All rights reserved. 
# # This script is proprietary and confidential information of 
# Synopsys, Inc. and may be used and disclosed only as authorized 
# per your agreement with Synopsys, Inc. controlling such use and disclosure.
# proc_histogram proc_qor and proc_compare_qor scripts

#################################################
#Author Narendra Akilla
#Applications Consultant
#Company Synopsys Inc.
#Not for Distribution without Consent of Synopsys
#proc to reformat report_qor output into a table 
#################################################

proc proc_histogram {args} {

set version 1.11
set ::timing_save_pin_arrival_and_slack true
#fixed -define_args
#add tns/-paths support
#dont take the below echo, used by proc_compare_qor
echo "\nStarting  Histogram (proc_histogram) $version\n"

parse_proc_arguments -args $args results

set s_flag  [info exists results(-slack_lesser_than)]
set gs_flag [info exists results(-slack_greater_than)]
set path_flag [info exists results(-paths)]
set h_flag [info exists results(-hold)]
set pba_mode "none"

if {[info exists results(-number_of_bins)]} { set numbins $results(-number_of_bins) } else { set numbins 10 }
if {[info exists results(-slack_lesser_than)]} { set slack $results(-slack_lesser_than) } else { set slack 0.0 }
if {[info exists results(-slack_greater_than)]} { set gslack $results(-slack_greater_than) }
if {[info exists results(-hold)]} { set attr "min_slack" } else { set attr "max_slack" }
if {[info exists results(-number_of_critical_hierarchies)]} { set number $results(-number_of_critical_hierarchies) } else { set number 10 }

if {[info exists results(-pba_mode)]} {
  if {$::synopsys_program_name!="pt_shell"} { echo "Error!! -pba_mode supported only in pt_shell" ; return }
  set pba_mode $results(-pba_mode)
}

if {$gs_flag&&!$s_flag} { echo "Error!! -slack_greater_than can only be used with -slack_lesser_than ....Exiting\n" ; return }
if {$gs_flag&&$gslack>$slack} { echo "Error!! -slack_greater_than should be more than -slack_lesser_than ....Exiting\n" ; return }

if {[info exists results(-clock)]} {
  set clock [get_clocks -quiet $results(-clock)]
  if {[sizeof $clock]!=1} { echo "Error!! provided -clock value did not results in 1 clock" ; return }
  set clock_arg "-clock [get_object_name $clock]"
  set clock_per [get_attr $clock period]
} else {
  set clock_arg ""
}

foreach_in_collection clock [all_clocks] { if {[get_attribute -quiet $clock sources] != "" } { append_to_collection -unique real_clocks $clock } }
set min_period [lindex [lsort -real [get_attr -quiet $real_clocks period]] 0]

catch {redirect -var y {report_units}}
if {[regexp {(\S+)\s+Second} $y match unit]} {
  if {[regexp {e-12} $unit]} { set unit 1000000 } else { set unit 1000 }
} elseif {[regexp {ns} $y]} { set unit 1000
} elseif {[regexp {ps} $y]} { set unit 1000000 }

#if unit cannot be determined make it ns
if {![info exists unit]} { set unit 1000 }

if {[info exists clock_per]} { set min_period $clock_per }
if {$min_period<=0} { echo "Error!! Failed to calculate min_period of real clocks .... Exiting\n" ; return }

if {$path_flag} {

  set paths $results(-paths)
  if {[sizeof $paths]<2} { echo "Error! Not enough -paths [sizeof $paths] given for histogram" ; return }

  set paths [filter_coll $paths "slack!=INFINITY"]
  if {[sizeof $paths]<2} { echo "Error! Not enough -paths [sizeof $paths] with real slack given for histogram" ; return }

  set path_type [lsort -unique [get_attr -quiet $paths path_type]]
  if {[llength $path_type]!=1} { echo "Error! please provide only max paths or min paths - not both" ; return }
  if {$path_type=="min"} { set attr "min_slack" ; set h_flag 1 } else { set attr "max_slack" ; set h_flag 0 }

  echo "Analayzing given [sizeof $paths] path collection - ignores REGOUT\n"
  set coll $paths 
  set endpoint_coll [get_pins -quiet [get_attr -quiet $paths endpoint]]
  if {[sizeof $endpoint_coll]<2} { echo "\nNo Violations or Not enough Violations Found" ; return }
  set check_attr "slack"
}

if {!$path_flag} {

  if {$pba_mode =="none"} 		{ set type "GBA"
  } elseif {$pba_mode =="path"} 		{ set type "PBA Path"
  } elseif {$pba_mode =="exhaustive"} 	{ set type "PBA Exhaustive"
  }

  if {$gs_flag} {
    echo -n "Acquiring $type Endpoints ($gslack > Slack < $slack) - ignores REGOUT ... "
  } else {
    echo -n "Acquiring $type Endpoints (Slack < $slack) - ignores REGOUT ... "
  }

  set coll   [sort_coll [filter_coll [eval all_registers -data_pins $clock_arg] "$attr<$slack"] $attr]
  if {$gs_flag} { set coll [sort_coll [filter_coll $coll "$attr>$gslack"] $attr] }

  if {[sizeof $coll]<2} { echo "\nNo Violations or Not enough Violations Found" ; return }
  set endpoint_coll $coll

  if {$pba_mode!="none"} {
    set check_attr "slack"
    if {$gs_flag} {
      redirect /dev/null {set coll [get_timing_path -to $coll -pba_mode $pba_mode -max_paths [sizeof $coll] -slack_lesser $slack -slack_greater $gslack] }
      set endpoint_coll [get_attr -quiet $coll endpoint]
    } else {
      redirect /dev/null {set coll [get_timing_path -to $coll -pba_mode $pba_mode -max_paths [sizeof $coll] -slack_lesser $slack] }
      set endpoint_coll [get_attr -quiet $coll endpoint]
    }
  } else {
    set check_attr $attr
  }

  echo "Done\n"
}

if {[sizeof $coll]<2} { echo "\nNo Violations or Not enough Violations Found" ; return }

echo -n "Initializing Histogram ... "
set values [lsort -real [get_attr -quiet $coll $check_attr]]
set min    [lindex $values 0]
set max    [lindex $values [expr {[llength $values]-1}]]
set new_max    [expr $max+0.1] ; # to avoid rounding errors
set range  [expr {$max-$min}]
set width  [expr {$range/$numbins}]

for {set i 1} {$i<=$numbins} {incr i} { 
  set compare($i) [expr {$min+$i*$width}] 
  set histogram($i) 0
  set tns_histogram($i) 0
}
set compare($i) $new_max

echo -n "Populating Bins ... "
foreach v $values {
  for {set i 1} {$i<=$numbins} {incr i} {
    if {$v<=$compare($i)} {
      incr histogram($i)
      if {$v<0} { set tns_histogram($i) [expr {$tns_histogram($i)+$v}] }
      break
    }
  }
}
echo "Done - TNS can be slightly off\n"

set tot_tns 0
for {set i 1} {$i<=$numbins} {incr i} { set tot_tns [expr $tot_tns+$tns_histogram($i)] }

echo "========================================================================="
echo "          WNS RANGE        -          Endpoints                       TNS"
echo "========================================================================="
if {[llength $values]>1} {
  for {set i $numbins} {$i>=1} {incr i -1} {
    set low [expr {$min+$i*$width}]
    set high [expr {$min+($i-1)*$width}]
    set f_low [format %.3f $low]
    set f_high [format %.3f $high]
    set pct [expr {100.0*$histogram($i)/[llength $values]}]
    echo -n "[format "% 10s" $f_low] to [format "% 10s" $f_high]   -  [format %9i $histogram($i)] ([format %4.1f $pct]%)"
    if {$attr=="max_slack"} {
      if {[expr {($min_period-$high)*$unit}]>0} { set freq [expr {(1.0/($min_period-$high))*$unit}] } else { set freq 0.0 }
      echo -n " - [format %4.0f ${freq}]Mhz"
    }
    if {$h_flag} { echo " [format "% 25.1f" $tns_histogram($i)]" } else { echo " [format "% 15.1f" $tns_histogram($i)]" }
  }
}
echo "========================================================================="
echo "Total Endpoints            - [format %10i [llength $values]] [format "% 33.1f" $tot_tns]"
if {$attr=="max_slack"} { echo "Clock Frequency            - [format %10.0f [expr (1.0/$min_period)*$unit]]Mhz (estimated)" }
echo "========================================================================="
echo ""

if {$::synopsys_program_name=="icc2_shell"||$::synopsys_program_name=="pt_shell"} {
  set allicgs [get_cells -quiet -hi -f "is_hierarchical==false&&is_integrated_clock_gating_cell==true"]
} else {
  set allicgs [get_cells -quiet -hi -f "is_hierarchical==false&&clock_gating_integrated_cell=~*"]
}
set slkff [remove_from_coll [get_cells -quiet -of $endpoint_coll] $allicgs]

foreach c [get_attr -quiet $slkff full_name] {
  set cell $c
  for {set i 1} {$i<20} {incr i} {
    set parent [file dir $cell]
    if {$parent=="."} { break }
    set parent_coll [get_cells -quiet $parent -f "is_hierarchical==true"]
    if {[sizeof $parent_coll]<1} { set cell $parent ; continue }
    if {[info exists hier_repeat($parent)]} { incr hier_repeat($parent) } else { set hier_repeat($parent) 1 }
    set cell $parent
  }
}

echo "========================================================================="
echo " Viol.   $number Critical"
echo " Count - Hierarchies - ignores ICGs"
echo "========================================================================="

if {![array exists hier_repeat]} { echo "No Critial Hierarchies found" ; return }

foreach {a b} [array get hier_repeat] { lappend repeat_list [list $a $b] }

set cnt 0
foreach i [lsort -real -decreasing -index 1 $repeat_list] { 
  echo "[format %6i [lindex $i 1]] - [lindex $i 0]" 
  incr cnt
  if {$cnt==$number} { break }
}
echo "========================================================================="
echo ""

}

define_proc_attributes proc_histogram -info "USER_PROC: Prints histogram of setup or hold slack endpoints" \
  -define_args { \
  {-number_of_bins      "Optional - number of bins for histgram, default 10"			"<int>"               int  optional}
  {-slack_lesser_than   "Optional - histogram for endpoints with slack less than, default 0" 	"<float>"               float  optional}
  {-slack_greater_than  "Optional - histogram for endpoints with slack greater than, can only be used with -slack_greater_than, default wns" 	"<float>"               float  optional}
  {-hold		"Optional - Generates histogram for hold slack, default is setup"	""                      boolean  optional}
  {-number_of_critical_hierarchies      "Optional - number of critical hierarchies to display viol. count, default 10" "<int>" int  optional}
  {-clock      		"Optional - Generates histogram only for the specified clock endpoints, default all clocks" "<clock>" string  optional}
  {-pba_mode 		"Optional - PBA mode supported in PrimeTime only" "<path or exhaustive>" one_of_string {optional value_help {values {path exhaustive}}}}
  {-paths 		"Optional - Generates histogram for given user path collection" "<path coll>" string optional}
}
 

#################################################
#Author Narendra Akilla
#Applications Consultant
#Company Synopsys Inc.
#Not for Distribution without Consent of Synopsys
#################################################

#Version 2.05
#added pt report_qor support
#minor fix for icc2 total drc count - will compute if not present in report_qor
#errors out as unsupported format for report_qor files from PT
#bug fix for -skew in pt
#-tee support
#icc2 support
#complete makeover with hashes for flexibility

proc proc_qor {args} {

  set version 2.05
  proc proc_mysort_hash {args} {

    parse_proc_arguments -args ${args} opt

    upvar $opt(hash) myarr

    set given    "[info exists opt(-values)][info exists opt(-dict)][info exists opt(-reverse)]"

    set key_list  [array names myarr]

    switch $given {
      000 { return [lsort -real $key_list] }
      001 { return [lsort -real -decreasing $key_list] }
      010 { return [lsort -dictionary $key_list] }
      011 { return [lsort -dictionary -decreasing $key_list] }
    }
  
    foreach {a b} [array get myarr] { lappend full_list [list $a $b] }

    switch $given {
      100 { set sfull_list [lsort -real -index 1 $full_list] }
      101 { set sfull_list [lsort -real -index 1 -decreasing $full_list] }
      110 { set sfull_list [lsort -index 1 -dictionary $full_list] }
      111 { set sfull_list [lsort -index 1 -dictionary -decreasing $full_list] }

    }

    foreach i $sfull_list { lappend sorted_key_list [lindex $i 0] }
    return $sorted_key_list
  }

  define_proc_attributes proc_mysort_hash -info "USER PROC:sorts a hash based on options and returns sorted keys list\nUSAGE: set sorted_keys \[proc_mysort_hash hash_name_without_dollar\]" \
        -define_args { \
                    { -reverse 	"reverse sort"      			""              	boolean optional }
                    { -dict 	"dictionary sort, default numerical"	""              	boolean optional }
                    { -values 	"sort values, default keys"      	""              	boolean optional }
                    { hash   	"hash"         				"hash"            	list    required }
                    }

  echo "\nVersion $version\n"
  parse_proc_arguments -args $args results
  set skew_flag [info exists results(-skew)]
  set scenario_flag [info exists results(-scenarios)]
  set pba_flag  [info exists results(-pba_mode)]
  set file_flag [info exists results(-existing_qor_file)]
  set no_hist_flag [info exists results(-no_histogram)]
  set unit_flag [info exists results(-units)]
  set no_pg_flag   [info exists results(-no_pathgroup_info)]
  set sort_by_tns_flag   [info exists results(-sort_by_tns)]
  set uncert_flag [info exists results(-signoff_uncertainty_adjustment)]
  if {[info exists results(-tee)]} {set tee "-tee -var" } else { set tee "-var" }
  if {[info exists results(-csv_file)]} {set csv_file $results(-csv_file)} else { set csv_file "qor.csv" }
  if {$file_flag&&$skew_flag} { echo "Error!! -skew cannot be used with -existing_qor_file" ; return }
  if {$file_flag&&$no_hist_flag} { echo "Warning!! -no_histogram flag is ignored when -existing_qor_file is used" }
  if {$file_flag} { 
    if {[file exists $results(-existing_qor_file)]} { 
      set qor_file  $results(-existing_qor_file) 
    } else { 
      echo "Error!! Cannot find given -existing_qor_file $results(-existing_qor_file)" 
      return
    }
  }
  if {[info exists results(-units)]} {set unit $results(-units)}
  if {[info exists results(-pba_mode)]} {
    if {$::synopsys_program_name!="pt_shell"} { echo "Error!! -pba_mode supported only in pt_shell" ; return}
  }
  if {[info exists results(-pba_mode)]} {set pba_mode $results(-pba_mode)} else { set pba_mode "none" }
  if {[info exists results(-pba_mode)]&&$file_flag} { echo "-pba_mode ignored when -existing_qor_file is used" }


  #character to print for no value
  set nil "~"

  #set ::collection_deletion_effort low

  if {$uncert_flag} {
    echo "-signoff_uncertainty_adjustment only changes Frequency Column, report still sorted by WNS"
    set signoff_uncert $results(-signoff_uncertainty_adjustment)
  }

  if {$file_flag} {
    set tmp [open $qor_file "r"]
    set x [read $tmp]
    close $tmp
    if {[regexp {\(max_delay/setup|\(min_delay/hold} $x]} { set pt_file 1 } else { set pt_file 0 }
  } else {
    if {$::synopsys_program_name == "pt_shell"} {
          if {$::pt_shell_mode=="primetime_master"} {echo "Error!! proc_qor not supported in DMSA Master" ; return }
          set pt_file 1
          set orig_uncons $::timing_report_unconstrained_paths
          if {[info exists ::timing_report_union_tns]} { set orig_union  $::timing_report_union_tns } else { set orig_union true }
          set ::timing_report_union_tns true
          if {[regsub -all {[A-Z\-\.]} $::sh_product_version {}]>=201506} {
            echo -n "Running report_qor -pba_mode $pba_mode ; report_qor -pba_mode $pba_mode -summary ... "
            redirect {*}$tee x { report_qor -pba_mode $pba_mode ; report_qor -pba_mode $pba_mode -summary }
          } else {
            echo -n "Running report_qor ; report_qor -summary ... "
            redirect {*}$tee x { report_qor ; report_qor -summary }
          }
          echo "Done"
      } else {
	#not in pt
        set pt_file 0
        if {$scenario_flag} {
          if {$::synopsys_program_name == "icc2_shell"} {
            echo -n "Running report_qor -nosplit -scenarios $results(-scenarios) ; report_qor -nosplit -summary ... "
            redirect {*}$tee x { report_qor -nosplit -scenarios $results(-scenarios) ; report_qor -nosplit -summary }
          } else {
            echo -n "Running report_qor -nosplit -scenarios $results(-scenarios) ... "
            redirect {*}$tee x { report_qor -nosplit -scenarios $results(-scenarios) }
          }
          echo "Done"
        } else {
          if {$::synopsys_program_name == "icc2_shell"} {
            echo -n "Running report_qor -nosplit ; report_qor -nosplit -summary ... "
            redirect {*}$tee x { report_qor -nosplit ; report_qor -nosplit -summary }
          } else {
            echo -n "Running report_qor -nosplit ... "
            redirect {*}$tee x { report_qor -nosplit }
          }
          echo "Done"
        }
    }
  }
  
  if {$unit_flag} {
    if {[string match $unit "ps"]} { set unit 1000000 } else { set unit 1000 }
  } else {
    catch {redirect -var y {report_units}}
    if {[regexp {(\S+)\s+Second} $y match unit]} {
      if {[regexp {e-12} $unit]} { set unit 1000000 } else { set unit 1000 }
    } elseif {[regexp {ns} $y]} { set unit 1000
    } elseif {[regexp {ps} $y]} { set unit 1000000 }
  }

  #if units cannot be determined make it ns
  if {![info exists unit]} { set unit 1000 }
  
  set drc 0
  set cella 0
  set buf 0
  set leaf 0
  set tnets 0
  set cbuf 0
  set seqc 0
  set tran 0
  set cap 0
  set fan 0
  set combc 0
  set macroc 0
  set comba 0
  set seqa 0
  set desa 0
  set neta 0
  set netl 0
  set netx 0
  set nety 0
  set hierc 0
  if {![file writable [file dir $csv_file]]} {
    echo "$csv_file not writable, Writing to /dev/null instead"
    set csv_file "/dev/null"
  }
  set csv [open $csv_file "w"]

  #process non pt report_qor file
  if {!$pt_file} {
  set i 0
  set group_just_set 0
  foreach line [split $x "\n"] {
  
    incr i
    #echo "Processing $i : $line"

    if {[regexp {^\s*Scenario\s+\'(\S+)\'} $line match scenario]} {
    } elseif {[regexp {^\s*Timing Path Group\s+\'(\S+)\'} $line match group]} {
      if {[info exists scenario]} { set group ${group}($scenario) }
      set GROUPS($group) 1
      set group_just_set 1
      unset -nocomplain ll cpl wns cp tns nvp wnsh tnsh nvph fr
    } elseif {[regexp {^\s*------\s*$} $line]} {
      if {$group_just_set} {
        continue 
      } else {
        set group_just_set 0
        unset -nocomplain group scenario
      }
    } elseif {[regexp {^\s*Levels of Logic\s*:\s*(\S+)\s*$} $line match ll]} {
      set GROUP_LL($group) $ll
    } elseif {[regexp {^\s*Critical Path Length\s*:\s*(\S+)\s*$} $line match cpl]} {
      set GROUP_CPL($group) $cpl
    } elseif {[regexp {^\s*Critical Path Slack\s*:\s*(\S+)\s*$} $line match wns]} { 
      if {![string is double $wns]} { set wns 0.0 }
      set GROUP_WNS($group) $wns 
    } elseif {[regexp {^\s*Critical Path Clk Period\s*:\s*(\S+)\s*$} $line match cp]} { 
      if {![string is double $cp]} { set cp 0.0 }
      set GROUP_CP($group) $cp
    } elseif {[regexp {^\s*Total Negative Slack\s*:\s*(\S+)\s*$} $line match tns]} {
      set GROUP_TNS($group) $tns
    } elseif {[regexp {^\s*No\. of Violating Paths\s*:\s*(\S+)\s*$} $line match nvp]} {
      set GROUP_NVP($group) $nvp
    } elseif {[regexp {^\s*Worst Hold Violation\s*:\s*(\S+)\s*$} $line match wnsh]} {
      if {![string is double $wnsh]} { set wnsh 0.0 }
      set GROUP_WNSH($group) $wnsh
    } elseif {[regexp {^\s*Total Hold Violation\s*:\s*(\S+)\s*$} $line match tnsh]} {
      set GROUP_TNSH($group) $tnsh
    } elseif {[regexp {^\s*No\. of Hold Violations\s*:\s*(\S+)\s*$} $line match nvph]} {
      set GROUP_NVPH($group) $nvph

    } elseif {[regexp {^\s*Hierarchical Cell Count\s*:\s*(\S+)\s*$} $line match hierc]} {
    } elseif {[regexp {^\s*Hierarchical Port Count\s*:\s*(\S+)\s*$} $line match hierp]} {
    } elseif {[regexp {^\s*Leaf Cell Count\s*:\s*(\S+)\s*$} $line match leaf]} {
      set leaf [expr {$leaf/1000}]
    } elseif {[regexp {^\s*Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match buf]} {
      set buf [expr {$buf/1000}]
    } elseif {[regexp {^\s*CT Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match cbuf]} {
    } elseif {[regexp {^\s*Combinational Cell Count\s*:\s*(\S+)\s*$} $line match combc]} {
      set combc [expr $combc/1000]
    } elseif {[regexp {^\s*Sequential Cell Count\s*:\s*(\S+)\s*$} $line match seqc]} {
    } elseif {[regexp {^\s*Macro Count\s*:\s*(\S+)\s*$} $line match macroc]} {
 
    } elseif {[regexp {^\s*Combinational Area\s*:\s*(\S+)\s*$} $line match comba]} {
      set comba [expr {int($comba)}]
    } elseif {[regexp {^\s*Noncombinational Area\s*:\s*(\S+)\s*$} $line match seqa]} {
      set seqa [expr {int($seqa)}]
    } elseif {[regexp {^\s*Net Area\s*:\s*(\S+)\s*$} $line match neta]} {
      set neta [expr {int($neta)}]
    } elseif {[regexp {^\s*Net XLength\s*:\s*(\S+)\s*$} $line match netx]} {
    } elseif {[regexp {^\s*Net YLength\s*:\s*(\S+)\s*$} $line match nety]} {
    } elseif {[regexp {^\s*Cell Area\s*.*:\s*(\S+)\s*$} $line match cella]} {
      set cella [expr {int($cella)}]
    } elseif {[regexp {^\s*Design Area\s*:\s*(\S+)\s*$} $line match desa]} {
      set desa [expr {int($desa)}]
    } elseif {[regexp {^\s*Net Length\s*:\s*(\S+)\s*$} $line match netl]} {
      set netl [expr {int($netl)}]

    } elseif {[regexp {^\s*Total Number of Nets\s*:\s*(\S+)\s*$} $line match tnets]} {
      set tnets [expr {$tnets/1000}]
    } elseif {[regexp {^\s*Nets With Violations\s*:\s*(\S+)\s*$} $line match drc]} {
    } elseif {[regexp {^\s*Max Trans Violations\s*:\s*(\S+)\s*$} $line match tran]} {
    } elseif {[regexp {^\s*Max Cap Violations\s*:\s*(\S+)\s*$} $line match cap]} {
    } elseif {[regexp {^\s*Max Fanout Violations\s*:\s*(\S+)\s*$} $line match fan]} {


    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set SETUP_SCENARIOS($scenario) 1
      set SETUP_SCENARIO_WNS($scenario) $wns
      set SETUP_SCENARIO_TNS($scenario) $tns
      set SETUP_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\(Hold\)\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set HOLD_SCENARIOS($scenario) 1
      set HOLD_SCENARIO_WNS($scenario) $wns
      set HOLD_SCENARIO_TNS($scenario) $tns
      set HOLD_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Design\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match setup_wns setup_tns setup_nvp]} {
      if {![string is double $setup_wns]} { set setup_wns 0.0 }
      if {![string is double $setup_tns]} { set setup_tns 0.0 }
      if {![string is double $setup_nvp]} { set setup_nvp 0 }
    } elseif {[regexp {^\s*Design\s+\(Hold\)\s*WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match hold_wns hold_tns hold_nvp]} {
      if {![string is double $hold_wns]} { set hold_wns 0.0 }
      if {![string is double $hold_tns]} { set hold_tns 0.0 }
      if {![string is double $hold_nvp]} { set hold_nvp 0 }
    #for icc2
    } elseif {[regexp {^\s*Design\s+\(Setup\)\s+(\S+)\s+(\S+)\s+(\d+)\s*$} $line match setup_wns setup_tns setup_nvp]} {
      if {![string is double $setup_wns]} { set setup_wns 0.0 }
      if {![string is double $setup_tns]} { set setup_tns 0.0 }
      if {![string is double $setup_nvp]} { set setup_nvp 0 }
    } elseif {[regexp {^\s*Design\s+\(Hold\)\s+(\S+)\s+(\S+)\s+(\d+)\s*$} $line match hold_wns hold_tns hold_nvp]} {
      if {![string is double $hold_wns]} { set hold_wns 0.0 }
      if {![string is double $hold_tns]} { set hold_tns 0.0 }
      if {![string is double $hold_nvp]} { set hold_nvp 0 }
    } elseif {[regexp {^\s*Error\:} $line]} {
      echo "Error: found in report_qor. Exiting ..."
      return
    }

  }
  if {$drc==0} { set drc [expr $tran+$cap+$fan] }
  #all lines of non pt qor file read
  }

  #process pt report_qor file
  if {$pt_file} {
  #in pt, process qor file lines
  set i 0
  set group_just_set 0
  foreach line [split $x "\n"] {
  
    incr i
    #echo "Processing $i : $line"

    if {[regexp {^\s*Scenario\s+\'(\S+)\'} $line match scenario]} {
    } elseif {[regexp {^\s*Timing Path Group\s+\'(\S+)\'\s*\(max_delay} $line match group]} {
      if {[info exists scenario]} { set group ${group}($scenario) }
      set GROUPS($group) 1
      set group_just_set 1
      set group_is_setup 1
      unset -nocomplain ll cpl wns cp tns nvp wnsh tnsh nvph fr
    } elseif {[regexp {^\s*Timing Path Group\s+\'(\S+)\'\s*\(min_delay} $line match group]} {
      if {[info exists scenario]} { set group ${group}($scenario) }
      set GROUPS($group) 1
      set group_just_set 1
      set group_is_setup 0
      unset -nocomplain ll cpl wns cp tns nvp wnsh tnsh nvph fr
    } elseif {[regexp {^\s*------\s*$} $line]} {
      if {$group_just_set} {
        continue 
      } else {
        set group_just_set 0
        unset -nocomplain group scenario
      }
    } elseif {[regexp {^\s*Levels of Logic\s*:\s*(\S+)\s*$} $line match ll]} {
      set GROUP_LL($group) $ll
    } elseif {[regexp {^\s*Critical Path Length\s*:\s*(\S+)\s*$} $line match cpl]} {
      set GROUP_CPL($group) $cpl
    } elseif {[regexp {^\s*Critical Path Slack\s*:\s*(\S+)\s*$} $line match wns]} {
      if {![string is double $wns]} { set wns 0.0 } 
      if {$group_is_setup} { set GROUP_WNS($group) $wns } else { set GROUP_WNSH($group) $wns }
    } elseif {[regexp {^\s*Critical Path Clk Period\s*:\s*(\S+)\s*$} $line match cp]} {
      if {![string is double $cp]} { set cp 0.0 }
      set GROUP_CP($group) $cp
    } elseif {[regexp {^\s*Total Negative Slack\s*:\s*(\S+)\s*$} $line match tns]} {
      if {$group_is_setup} { set GROUP_TNS($group) $tns } else { set GROUP_TNSH($group) $tns }
    } elseif {[regexp {^\s*No\. of Violating Paths\s*:\s*(\S+)\s*$} $line match nvp]} {
      if {$group_is_setup} { set GROUP_NVP($group) $nvp } else { set GROUP_NVPH($group) $nvp }

    } elseif {[regexp {^\s*Hierarchical Cell Count\s*:\s*(\S+)\s*$} $line match hierc]} {
    } elseif {[regexp {^\s*Hierarchical Port Count\s*:\s*(\S+)\s*$} $line match hierp]} {
    } elseif {[regexp {^\s*Leaf Cell Count\s*:\s*(\S+)\s*$} $line match leaf]} {
      set leaf [expr {$leaf/1000}]
    } elseif {[regexp {^\s*Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match buf]} {
      set buf [expr {$buf/1000}]
    } elseif {[regexp {^\s*CT Buf/Inv Cell Count\s*:\s*(\S+)\s*$} $line match cbuf]} {
    } elseif {[regexp {^\s*Combinational Cell Count\s*:\s*(\S+)\s*$} $line match combc]} {
      set combc [expr $combc/1000]
    } elseif {[regexp {^\s*Sequential Cell Count\s*:\s*(\S+)\s*$} $line match seqc]} {
    } elseif {[regexp {^\s*Macro Count\s*:\s*(\S+)\s*$} $line match macroc]} {
 
    } elseif {[regexp {^\s*Combinational Area\s*:\s*(\S+)\s*$} $line match comba]} {
      set comba [expr {int($comba)}]
    } elseif {[regexp {^\s*Noncombinational Area\s*:\s*(\S+)\s*$} $line match seqa]} {
      set seqa [expr {int($seqa)}]
    } elseif {[regexp {^\s*Net Interconnect area\s*:\s*(\S+)\s*$} $line match neta]} {
      set neta [expr {int($neta)}]
    } elseif {[regexp {^\s*Net XLength\s*:\s*(\S+)\s*$} $line match netx]} {
    } elseif {[regexp {^\s*Net YLength\s*:\s*(\S+)\s*$} $line match nety]} {
    } elseif {[regexp {^\s*Total cell area\s*.*:\s*(\S+)\s*$} $line match cella]} {
      set cella [expr {int($cella)}]
    } elseif {[regexp {^\s*Design Area\s*:\s*(\S+)\s*$} $line match desa]} {
      set desa [expr {int($desa)}]
    } elseif {[regexp {^\s*Net Length\s*:\s*(\S+)\s*$} $line match netl]} {
      set netl [expr {int($netl)}]

    } elseif {[regexp {^\s*Total Number of Nets\s*:\s*(\S+)\s*$} $line match tnets]} {
      set tnets [expr {$tnets/1000}]
    } elseif {[regexp {^\s*Nets With Violations\s*:\s*(\S+)\s*$} $line match drc]} {
    } elseif {[regexp {^\s*max_transition Count\s*:\s*(\S+)\s*$} $line match tran]} {
    } elseif {[regexp {^\s*max_capacitance Count\s*:\s*(\S+)\s*$} $line match cap]} {
    } elseif {[regexp {^\s*max_fanout Count\s*:\s*(\S+)\s*$} $line match fan]} {


    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set SETUP_SCENARIOS($scenario) 1
      set SETUP_SCENARIO_WNS($scenario) $wns
      set SETUP_SCENARIO_TNS($scenario) $tns
      set SETUP_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Scenario:\s*(\S+)\s+\(Hold\)\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match scenario wns tns nvp]} {
      set HOLD_SCENARIOS($scenario) 1
      set HOLD_SCENARIO_WNS($scenario) $wns
      set HOLD_SCENARIO_TNS($scenario) $tns
      set HOLD_SCENARIO_NVP($scenario) $nvp
    } elseif {[regexp {^\s*Setup\s+WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match setup_wns setup_tns setup_nvp]} {
      if {![string is double $setup_wns]} { set setup_wns 0.0 }
      if {![string is double $setup_tns]} { set setup_tns 0.0 }
      if {![string is double $setup_nvp]} { set setup_nvp 0 }
    } elseif {[regexp {^\s*Hold\s*WNS:\s*(\S+)\s*TNS:\s*(\S+).*Paths:\s*(\S+)} $line match hold_wns hold_tns hold_nvp]} {
      if {![string is double $hold_wns]} { set hold_wns 0.0 }
      if {![string is double $hold_tns]} { set hold_tns 0.0 }
      if {![string is double $hold_nvp]} { set hold_nvp 0 }
    } elseif {[regexp {^\s*Error\:} $line]} {
      echo "Error: found in report_qor. Exiting ..."
      return
    }

  }
  if {$drc==0} { set drc [expr $tran+$cap+$fan] }
  #all lines of pt qor file read
  }

  if {![info exists GROUPS]} {
    echo "Error!! no QoR data found to reformat"
    return
  }

  if {$skew_flag} {
    #skew computation begins

    if {$::synopsys_program_name=="icc2_shell"} {
      if {![get_app_option -name timer.remove_clock_reconvergence_pessimism]} { echo "WARNING!! crpr is not turned on, skew values reported could be pessimistic" }
    } else {
      if {$::timing_remove_clock_reconvergence_pessimism=="false"} { echo "WARNING!! crpr is not turned on, skew values reported could be pessimistic" }
    }
    echo "Skews numbers reported include any ocv derates, crpr value is close, but may not match report_timing UITE-468"
    echo "Getting setup timing paths for skew analysis"
    if {$::synopsys_program_name != "pt_shell"} {
      redirect /dev/null {set paths [get_timing_paths -slack_less 0 -max_paths 100000] } 
    } else { 
      redirect /dev/null {set paths [get_timing_paths -slack_less 0 -max_paths 100000 -pba_mode $pba_mode] } 
    }

    foreach_in_collection p $paths {

      set g [get_attribute [get_attribute -quiet $p path_group] full_name]
      set scenario [get_attribute -quiet $p scenario]
      if {[regexp {^_sel\d+$} $scenario]} { set scenario [get_object_name $scenario] }
      if {$scenario !=""} { set g ${g}($scenario) }
      if {$::synopsys_program_name=="icc2_shell"} {
        set e_arr [get_attribute -quiet $p endpoint_clock_close_edge_arrival]
        set e_val [get_attribute -quiet $p endpoint_clock_close_edge_value]
        if {$e_arr!=""&&$e_val!=""} { set e [expr {$e_arr-$e_val}] ; if {$e<0} { set e 0.0 } }
        set s_arr [get_attribute -quiet $p startpoint_clock_open_edge_arrival]
        set s_val [get_attribute -quiet $p startpoint_clock_open_edge_value]
        if {$s_arr!=""&&$s_val!=""} { set s [expr {$s_arr-$s_val}] ; if {$s<0} { set s 0.0 } }
      } else {
        set e [get_attribute -quiet $p endpoint_clock_latency]
        set s [get_attribute -quiet $p startpoint_clock_latency]
      }

      if {$::synopsys_program_name == "pt_shell"||$::synopsys_program_name=="icc2_shell"} { 
        set crpr [get_attribute -quiet $p common_path_pessimism]
      } else {
        set crpr [get_attribute -quiet $p crpr_value]
      }
      if {$crpr==""} { set crpr 0 }

      if {$e!=""&&$s!=""} { set skew [expr {$e-$s}] } else { set skew 0 }

      if {$skew<0}       { set skew [expr {$skew+$crpr}]
      } elseif {$skew>0} { set skew [expr {$skew-$crpr}]
      } elseif {$skew==0} {}

      if {![info exists SKEW_WNS($g)]} { set SKEW_WNS($g) $skew }
      if {![info exists SKEW_TNS($g)]} { set SKEW_TNS($g) $skew } else { set SKEW_TNS($g) [expr {$SKEW_TNS($g)+$skew}] }
    }

    echo "Getting hold  timing paths for skew analysis"
    if {$::synopsys_program_name != "pt_shell"} {
      redirect /dev/null { set paths [get_timing_paths -slack_less 0 -max_paths 100000 -delay min] }
    } else { 
      redirect /dev/null { set paths [get_timing_paths -pba_mode $pba_mode -slack_less 0 -max_paths 100000 -delay min] }
    }

    foreach_in_collection p $paths {

      set g [get_attribute [get_attribute -quiet $p path_group] full_name]
      set scenario [get_attribute -quiet $p scenario]
      if {[regexp {^_sel\d+$} $scenario]} { set scenario [get_object_name $scenario] }
      if {$scenario !=""} { set g ${g}($scenario) }
      if {$::synopsys_program_name=="icc2_shell"} { 
        set e_arr [get_attribute -quiet $p endpoint_clock_close_edge_arrival]
        set e_val [get_attribute -quiet $p endpoint_clock_close_edge_value]
        if {$e_arr!=""&&$e_val!=""} { set e [expr {$e_arr-$e_val}] ; if {$e<0} { set e 0.0 } }
        set s_arr [get_attribute -quiet $p startpoint_clock_open_edge_arrival]
        set s_val [get_attribute -quiet $p startpoint_clock_open_edge_value]
        if {$s_arr!=""&&$s_val!=""} { set s [expr {$s_arr-$s_val}] ; if {$s<0} { set s 0.0 } }
      } else {
        set e [get_attribute -quiet $p endpoint_clock_latency]
        set s [get_attribute -quiet $p startpoint_clock_latency]
      }

      if {$::synopsys_program_name == "pt_shell"||$::synopsys_program_name=="icc2_shell"} { 
        set crpr [get_attribute -quiet $p common_path_pessimism]
      } else {
        set crpr [get_attribute -quiet $p crpr_value]
      }
      if {$crpr==""} { set crpr 0 }

      if {$e!=""&&$s!=""} { set skew [expr {$e-$s}] } else { set skew 0 }

      if {$skew<0}       { set skew [expr {$skew+$crpr}]
      } elseif {$skew>0} { set skew [expr {$skew-$crpr}]
      } elseif {$skew==0} {}

      if {![info exists SKEW_WNSH($g)]} { set SKEW_WNSH($g) $skew }
      if {![info exists SKEW_TNSH($g)]} { set SKEW_TNSH($g) $skew } else { set SKEW_TNSH($g) [expr {$SKEW_TNSH($g)+$skew}] }
    }

    #now compute avgskew and worst skew for setup and hold
    foreach g [array names GROUPS] {

      if {![info exists SKEW_WNS($g)]} { 
        set SKEW_WNS($g) 0.0
        set SKEW_TNS($g) 0.0
      } else {
        set SKEW_TNS($g) [expr {$SKEW_TNS($g)/$GROUP_NVP($g)}]
        if {![info exists maxskew]} { set maxskew $SKEW_WNS($g) }
        if {![info exists maxavg]} { set maxavg $SKEW_TNS($g) }
        if {$maxskew>$SKEW_WNS($g)} { set maxskew $SKEW_WNS($g) }
        if {$maxavg>$SKEW_TNS($g)} { set maxavg $SKEW_TNS($g) }
      }

      if {![info exists SKEW_WNSH($g)]} {
        set SKEW_WNSH($g) 0.0
        set SKEW_TNSH($g) 0.0
      } else {
        set SKEW_TNSH($g) [expr {$SKEW_TNSH($g)/$GROUP_NVPH($g)}]
        if {![info exists maxskewh]} { set maxskewh $SKEW_WNSH($g) }
        if {![info exists maxavgh]} { set maxavgh $SKEW_TNSH($g) }
        if {$maxskewh<$SKEW_WNSH($g)} { set maxskewh $SKEW_WNSH($g) }
        if {$maxavgh<$SKEW_TNSH($g)} { set maxavgh $SKEW_TNSH($g) }
      }

    }

    #populate 0 if worst skew is not found
    if {![info exists maxskew]} { set maxskew 0.0 }
    if {![info exists maxavg]} { set maxavg 0.0 }
    if {![info exists maxskewh]} { set maxskewh 0.0 }
    if {![info exists maxavgh]} { set maxavgh 0.0 }

    set maxskew  [format "%10.3f" $maxskew]
    set maxavg   [format "%10.3f" $maxavg]
    set maxskewh [format "%10.3f" $maxskewh]
    set maxavgh  [format "%10.3f" $maxavgh]

    #skew computation complete
  }

  #sometimes in PT if report_qor is passed with only hold path groups
  if {[info exists GROUP_WNS]} {
    #compute freq. for all setup groups
    foreach g [proc_mysort_hash -values GROUP_WNS] {
  
      set wns  [expr {double($GROUP_WNS($g))}]
      #if in pt and -existing_qor is not used try to get the clock period
      if {$pt_file&&!$file_flag} {
        #if clock period does not exist - as pt report_qor does not have it
        if {![info exists GROUP_CP($g)]} { 
          redirect /dev/null { set cp [get_attr -quiet [get_timing_path -group $g -pba_mode $pba_mode] endpoint_clock.period] }
          if {$cp!=""} { set GROUP_CP($g) $cp }
        }
      }
      #0 out any missing cp
      if {![info exists GROUP_CP($g)]} { continue }
      set per  [expr {double($GROUP_CP($g))}]
      if {$wns >= $per} { set freq 0.0
      } else {
        if {$uncert_flag} {
          set freq [expr {1.0/($per-$wns-$signoff_uncert)*$unit}]
        } else {
          set freq [expr {1.0/($per-$wns)*$unit}] 
        }
      }
      #save worst freq
      if {![info exists wfreq]} { set wfreq [format "% 7.0fMHz" $freq] }
      set GROUP_FREQ($g) $freq

    }
  }

  #if no worst freq reset it
  if {![info exists wfreq]} { set wfreq [format "% 7.0fMhz" 0.0] }

  #populate and format all values, compute total tns,nvp,tnsh,nvph
  set ttns  0.0
  set tnvp  0
  set ttnsh 0.0
  set tnvph 0

  foreach g [array names GROUPS] {

    #compute total tns nvp tnsh and nvph
    if {[info exists GROUP_TNS($g)]}  { set ttns  [expr {$ttns+$GROUP_TNS($g)}] }
    if {[info exists GROUP_NVP($g)]}  { set tnvp  [expr {$tnvp+$GROUP_NVP($g)}] }
    if {[info exists GROUP_TNSH($g)]} { set ttnsh [expr {$ttnsh+$GROUP_TNSH($g)}] }
    if {[info exists GROUP_NVPH($g)]} { set tnvph [expr {$tnvph+$GROUP_NVPH($g)}] }

    #format and populate values, create new hash of formatted values for printing
    if {[info exists GROUP_WNS($g)]}  { set GROUP_WNS_F($g)  [format "% 10.3f" $GROUP_WNS($g)] }  else { set GROUP_WNS_F($g)  [format "% 10s" $nil] }
    if {[info exists GROUP_TNS($g)]}  { set GROUP_TNS_F($g)  [format "% 10.1f" $GROUP_TNS($g)] }  else { set GROUP_TNS_F($g)  [format "% 10s" $nil] }
    if {[info exists GROUP_NVP($g)]}  { set GROUP_NVP_F($g)  [format "% 7.0f"  $GROUP_NVP($g)] }  else { set GROUP_NVP_F($g)  [format "% 7s" $nil] }
    if {[info exists GROUP_WNSH($g)]} { set GROUP_WNSH_F($g) [format "% 10.3f" $GROUP_WNSH($g)] } else { set GROUP_WNSH_F($g) [format "% 10s" $nil] }
    if {[info exists GROUP_TNSH($g)]} { set GROUP_TNSH_F($g) [format "% 10.1f" $GROUP_TNSH($g)] } else { set GROUP_TNSH_F($g) [format "% 10s" $nil] }
    if {[info exists GROUP_NVPH($g)]} { set GROUP_NVPH_F($g) [format "% 7.0f"  $GROUP_NVPH($g)] } else { set GROUP_NVPH_F($g) [format "% 7s" $nil] }
    if {[info exists GROUP_FREQ($g)]} { set GROUP_FREQ_F($g) [format "% 7.0fMHz"  $GROUP_FREQ($g)] } else { set GROUP_FREQ_F($g) [format "% 10s" $nil] }

    #populate skew with NA even if not asked, lazy to put an if skew_flag around this
    if {[info exists SKEW_WNS($g)]}  { set SKEW_WNS_F($g)  [format "% 10.3f"  $SKEW_WNS($g)] }  else { set SKEW_WNS_F($g)  [format "% 10s" $nil] }
    if {[info exists SKEW_TNS($g)]}  { set SKEW_TNS_F($g)  [format "% 10.3f"  $SKEW_TNS($g)] }  else { set SKEW_TNS_F($g)  [format "% 10s" $nil] }
    if {[info exists SKEW_WNSH($g)]} { set SKEW_WNSH_F($g) [format "% 10.3f"  $SKEW_WNSH($g)] } else { set SKEW_WNSH_F($g) [format "% 10s" $nil] }
    if {[info exists SKEW_TNSH($g)]} { set SKEW_TNSH_F($g) [format "% 10.3f"  $SKEW_TNSH($g)] } else { set SKEW_TNSH_F($g) [format "% 10s" $nil] }
  }

  #if total tns/nvp read from report_qor then use them
  if {[info exists setup_tns]} { set ttns $setup_tns }
  if {[info exists setup_nvp]} { set tnvp $setup_nvp }
  if {[info exists hold_tns]} { set ttnsh $hold_tns }
  if {[info exists hold_nvp]} { set tnvph $hold_nvp }
  set ttns [format "% 10.1f" $ttns]
  set tnvp [format "% 7.0f" $tnvp]
  set ttnsh [format "% 10.1f" $ttnsh]
  set tnvph [format "% 7.0f" $tnvph]

  #find the string length of path groups
  set maxl 0
  foreach g [array names GROUPS] {
    set l [string length $g]
    if {$maxl < $l} { set maxl $l }
  }
  set maxl [expr {$maxl+2}]
  if {$maxl < 20} { set maxl 20 }
  set drccol [expr {$maxl-13}]

  for {set i 0} {$i<$maxl} {incr i} { append bar - }
  if {$skew_flag} { 
    set bar "${bar}-------------------------------------------------------------------------------------------------------------------" 
  } else {
    set bar "${bar}-----------------------------------------------------------------------"
  }

  #now start printing the table with setup hash
  if {$skew_flag} {

    echo ""
    echo "SKEW      - Skew on WNS Path"
    echo "AVGSKW    - Average Skew on TNS Paths"
    echo "NVP       - No. of Violating Paths"
    echo "FREQ      - Estimated Frequency, not accurate in some cases, multi/half-cycle, etc"
    echo "WNS(H)    - Hold WNS"
    echo "SKEW(H)   - Skew on Hold WNS Path"
    echo "TNS(H)    - Hold TNS"
    echo "AVGSKW(H) - Average Skew on Hold TNS Paths"
    echo "NVP(H)    - Hold NVP"
    echo ""

    puts $csv "Path Group, WNS, SKEW, TNS, AVGSKW, NVP, FREQ, WNS(H), SKEW(H), TNS(H), AVGSKW(H), NVP(H)"
    echo [format "%-${maxl}s % 10s % 10s % 10s % 10s % 7s % 9s    % 8s % 10s % 10s % 10s % 7s" \
    "Path Group" "WNS" "SKEW" "TNS" "AVGSKW" "NVP" "FREQ" "WNS(H)" "SKEW(H)" "TNS(H)" "AVGSKW(H)" "NVP(H)"]
    echo "$bar"

  } else {

    echo ""
    echo "NVP    - No. of Violating Paths"
    echo "FREQ   - Estimated Frequency, not accurate in some cases, multi/half-cycle, etc"
    echo "WNS(H) - Hold WNS"
    echo "TNS(H) - Hold TNS"
    echo "NVP(H) - Hold NVP"
    echo ""

    puts $csv "Path Group, WNS, TNS, NVP, FREQ, WNS(H), TNS(H), NVP(H)"
    echo [format "%-${maxl}s % 10s % 10s % 7s % 9s    % 8s % 10s % 7s" \
    "Path Group" "WNS" "TNS" "NVP" "FREQ" "WNS(H)" "TNS(H)" "NVP(H)"]
    echo "$bar"

  }

  #figure out worst wns and wnsh
  unset -nocomplain wwns wwnsh
  if {[info exists setup_wns]} {
    #read from report_qor file
    set wwns [format "%10.3f" $setup_wns]
    #else get it from the worst group below, make sure there are setup groups
    #copy wwns only once, the first will be the worst
  } else { if {[info exists GROUP_WNS]} { foreach g [proc_mysort_hash -values GROUP_WNS] { if {![info exists wwns]} { set wwns $GROUP_WNS_F($g) } } } }
  #populate nil if not found
  if {![info exists wwns]} { set wwns [format "% 10s" $nil] }

  if {[info exists hold_wns]} { 
    #read from report_qor file
    set wwnsh [format "%10.3f" $hold_wns]
    #else get it from the worst group below, make sure there are hold groups
    #copy wwnsh only once, the first will be the worst
  } else { if {[info exists GROUP_WNSH]} { foreach g [proc_mysort_hash -values GROUP_WNSH] { if {![info exists wwnsh]} { set wwnsh $GROUP_WNSH_F($g) } } } }
  #populate nil if not found
  if {![info exists wwnsh]} { set wwnsh [format "% 10s" $nil] }

  if {$sort_by_tns_flag} {
    set setup_sort_group GROUP_TNS
    set hold_sort_group  GROUP_TNSH
  } else {
    set setup_sort_group GROUP_WNS
    set hold_sort_group  GROUP_WNSH
  }

  #print setup groups
  if {[info exists GROUP_WNS]} {
    foreach g [proc_mysort_hash -values $setup_sort_group] {

      if {$skew_flag} {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $SKEW_WNS_F($g), $GROUP_TNS_F($g), $SKEW_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $SKEW_WNSH_F($g), $GROUP_TNSH_F($g), $SKEW_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      } else {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $GROUP_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $GROUP_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      }

      if {!$no_pg_flag} {
        if {$skew_flag} {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $SKEW_WNS_F($g) $GROUP_TNS_F($g) $SKEW_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $SKEW_WNSH_F($g) $GROUP_TNSH_F($g) $SKEW_TNSH_F($g) $GROUP_NVPH_F($g)"
        } else {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $GROUP_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $GROUP_TNSH_F($g) $GROUP_NVPH_F($g)"
        }
      }
      set PRINTED($g) 1

    }
  }

  #now start printing the table with hold hash
  if {[info exists GROUP_WNSH]} {
    foreach g [proc_mysort_hash -values $hold_sort_group] {

      #continue if group is already printed
      if {[info exists PRINTED($g)]} { continue }

      if {$skew_flag} {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $SKEW_WNS_F($g), $GROUP_TNS_F($g), $SKEW_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $SKEW_WNSH_F($g), $GROUP_TNSH_F($g), $SKEW_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      } else {
        puts $csv "[format "%-${maxl}s" $g], $GROUP_WNS_F($g), $GROUP_TNS_F($g), $GROUP_NVP_F($g), $GROUP_FREQ_F($g), $GROUP_WNSH_F($g), $GROUP_TNSH_F($g), $GROUP_NVPH_F($g)\n"
      }

      if {!$no_pg_flag} {
        if {$skew_flag} {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $SKEW_WNS_F($g) $GROUP_TNS_F($g) $SKEW_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $SKEW_WNSH_F($g) $GROUP_TNSH_F($g) $SKEW_TNSH_F($g) $GROUP_NVPH_F($g)"
        } else {
          echo      "[format "%-${maxl}s" $g] $GROUP_WNS_F($g) $GROUP_TNS_F($g) $GROUP_NVP_F($g) $GROUP_FREQ_F($g) $GROUP_WNSH_F($g) $GROUP_TNSH_F($g) $GROUP_NVPH_F($g)"
        }
      }
      set PRINTED($g) 1
    }
  }

  if {!$no_pg_flag} {
    echo "$bar"
  }

  if {$skew_flag} {
    puts $csv "Summary, $wwns, $maxskew, $ttns, $maxavg, $tnvp, $wfreq, $wwnsh, $maxskewh, $ttnsh, $maxavgh, $tnvph"
  } else {
    puts $csv "Summary, $wwns, $ttns, $tnvp, $wfreq, $wwnsh, $ttnsh, $tnvph"
  }

  if {$skew_flag} {
    echo "[format "%-${maxl}s" "Summary"] $wwns $maxskew $ttns $maxavg $tnvp $wfreq $wwnsh $maxskewh $ttnsh $maxavgh $tnvph"
  } else {
    echo "[format "%-${maxl}s" "Summary"] $wwns $ttns $tnvp $wfreq $wwnsh $ttnsh $tnvph"
  }
  echo "$bar"

  puts $csv "CAP, FANOUT, TRAN, TDRC, CELLA, BUFS, LEAFS, TNETS, CTBUF, REGS"

  if {$skew_flag} {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 10s % 10s % 7s % 10s % 10s" \
     "CAP" "FANOUT" "TRAN" "TDRC" "CELLA" "BUFS" "LEAFS" "TNETS" "CTBUF" "REGS"]
  } else {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 7s % 9s % 11s % 10s % 7s" \
    "CAP" "FANOUT" "TRAN" "TDRC" "CELLA" "BUFS" "LEAFS" "TNETS" "CTBUF" "REGS"]
  }
  echo "$bar"

  if {$buf==0}   { set buf   $nil }
  if {$tnets==0} { set tnets $nil }
  if {$cbuf==0}  { set cbuf  $nil }
  if {$seqc==0}  { set seqc  $nil }

  puts $csv "$cap, $fan, $tran, $drc, $cella, ${buf}K, ${leaf}K, ${tnets}K, $cbuf, $seqc"

  if {$skew_flag} {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 9sK % 9sK % 6sK % 10s % 10s" \
    $cap $fan $tran $drc $cella $buf $leaf $tnets $cbuf $seqc]
  } else {
    echo [format "% 7s % 7s % 7s % ${drccol}s % 10s % 6sK % 8sK % 10sK % 10s % 7s" \
    $cap $fan $tran $drc $cella $buf $leaf $tnets $cbuf $seqc]
  }
  echo "$bar"


  if {![info exists setup_tns]} { echo "#Union TNS/NVP not found in report_qor, Summary line will report pessimistic summation TNS/NVP" }

  close $csv
  if {$::synopsys_program_name == "pt_shell"&&!$file_flag} {
          set ::timing_report_unconstrained_paths $orig_uncons
          set ::timing_report_union_tns $orig_union
  }
  echo "Written $csv_file"

  if {!$file_flag&&!$no_hist_flag} { 
    if {$pba_mode=="none"} {
      proc_histogram
    } else {
      proc_histogram -pba_mode $pba_mode
    }
  }
  rename proc_mysort_hash ""

}

define_proc_attributes proc_qor -info "USER PROC: reformats report_qor" \
          -define_args {
          {-tee     "Optional - displays the output of under-the-hood report_qor command" "" boolean optional}
          {-no_histogram "Optional - Skips printing text histogram for setup corner" "" boolean optional}
          {-existing_qor_file "Optional - Existing report_qor file to reformat" "<report_qor file>" string optional}
          {-scenarios "Optional - report qor on specified set of scenarios, skip on inactive scenarios" "{ scenario_name1 scenario_name2 ... }" string optional}
          {-no_pathgroup_info "Optional - to suppress individual pathgroup info" "" boolean optional}
          {-sort_by_tns "Optional - to sort by tns instead of wns" "" boolean optional}
          {-skew     "Optional - reports skew and avg skew on failing path groups" "" boolean optional}
          {-csv_file "Optional - Output csv file name, default is qor.csv" "<output csv file>" string optional}
          {-units    "Optional - override the automatic units calculation" "<ps or ns>" one_of_string {optional value_help {values {ps ns}}}}
          {-pba_mode "Optional - pba mode when in PrimeTime" "<path or exhaustive>" one_of_string {optional value_help {values {path exhaustive}}}}
          {-signoff_uncertainty_adjustment "Optional - adjusts ONLY the frequency column with signoff uncertainty, default 0." "" float optional}
          }

#################################################
#Author Narendra Akilla
#Applications Consultant
#Company Synopsys Inc.
#Not for Distribution without Consent of Synopsys
#################################################

#Version 1.2

proc proc_compare_qor {args} {

#######################
#SUB PROC
#######################

proc proc_myformat {file} {

  set tmp [open $file "r"]
  set x [read $tmp]
  close $tmp
  set start_flag 0

  foreach line [split $x "\n"] {
 
    #skip lines until the table
    if {!$start_flag} { if {![regexp {^\s*Path Group\s+WNS\s+} $line match]} { continue } }
    if {[regexp {^\s*Starting\s+Histogram} $line]} { break}

    if {[regexp {^\s*Path Group\s+WNS\s+} $line match]} {
      set start_flag 1
    } elseif {[regexp {^\s*CAP\s+FANOUT\s+TRAN\s+} $line match]} {
    } elseif {[regexp {^\s*Summary\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $line match wwns ttns tnvp wfreq wwnsh ttnsh tnvph]} {
      set summary [list total $wwns $ttns $tnvp $wfreq $wwnsh $ttnsh $tnvph]
    } elseif {[regexp {^\#} $line]} {
    } elseif {[regexp {^\s*\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $line match drc cella buf leaf tnets cbuf seqc]} {
      set stat [list $drc $cella $buf $leaf $cbuf $seqc $tnets]
    } elseif {[regexp {^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $line match group wns tns nvp freq wnsh tnsh nvph]} {
      lappend all_group_data [list $group $wns $tns $nvp $freq $wnsh $tnsh $nvph]
    }

  }

  if {![info exists all_group_data]} { echo "Error!! Unsupported QoR file $file, provide report_qor from DC/ICC/ICC2 or proc_qor outputs only. No csv or other PT report_qor formats. Exiting" ; return 0 }

  return [list $all_group_data $summary $stat]

}

proc proc_myskewformat {file} {

  set tmp [open $file "r"]
  set x [read $tmp]
  close $tmp
  set start_flag 0

  foreach line [split $x "\n"] {

    #skip lines until the table
    if {!$start_flag} { if {![regexp {^\s*Path Group\s+WNS\s+} $line match]} { continue } }
    if {[regexp {^\s*Starting\s+Histogram} $line]} { break}

    if {[regexp {^\s*Path Group\s+WNS\s+} $line match]} {
      set start_flag 1
    } elseif {[regexp {^\s*CAP\s+FANOUT\s+TRAN\s+} $line match]} {
    } elseif {[regexp {^\s*Summary\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $line match wwns maxskew ttns maxavgskew tnvp wfreq wwnsh maxskewh ttnsh maxavgskewh tnvph]} {
      set summary [list total $wwns $maxskew $ttns $maxavgskew $tnvp $wfreq $wwnsh $maxskewh $ttnsh $maxavgskewh $tnvph]
    } elseif {[regexp {^\#} $line]} {
    } elseif {[regexp {^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $line match group wns skew tns avgskew nvp freq wnsh skewh tnsh avgskewh nvph]} {
      lappend all_group_data [list $group $wns $skew $tns $avgskew $nvp $freq $wnsh $skewh $tnsh $avgskewh $nvph]
    } elseif {[regexp {^\s*\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)} $line match drc cella buf leaf tnets cbuf seqc]} {
      set stat [list $drc $cella $buf $leaf $cbuf $seqc $tnets]
    }

  }

  if {![info exists all_group_data]} { echo "Error!! QoR data not found in given files, provide only report_qor or proc_qor outputs. Exiting" ; return 0 }

  return [list $all_group_data $summary $stat]

}

#######################
#END OF SUB PROC
#######################

parse_proc_arguments -args $args results

#character to print for no value
set nil "~"

set unit_flag [info exists results(-units)]
if {[info exists results(-units)]} {set unit $results(-units)}
if {[info exists results(-csv_file)]} {set csv_file $results(-csv_file)} else { set csv_file "compare_qor.csv" }

if {$unit_flag} {
  if {[string match $unit "ps"]} { set unit ps } else { set unit ns }
} else {
  catch {redirect -var y {report_units}}
  if {[regexp {(\S+)\s+Second} $y match unit]} {
    if {[regexp {e-12} $unit]} { set unit ps } else { set unit ns }
  } elseif {[regexp {ns} $y]} { set unit ns
  } elseif {[regexp {ps} $y]} { set unit ps }
}     

#if units cannot be determined make it ns
if {![info exists unit]} { set unit ns }

set file_list $results(-qor_file_list)
if {[info exists results(-tag_list)]} { 
  set tag_list  $results(-tag_list) 
} else {
  set i 0 
  foreach file $file_list { lappend tag_list "qor_$i" ; incr i }
}

if {[llength $file_list] != [llength $tag_list]} { echo "Error!! -tag_list and -qor_file_list should have same number of elements" ; return }

if {[llength $file_list] <2} { echo "Error!! Need atleast 2 files" ; return}
if {[llength $file_list] >6} { echo "Error!! Supports only upto 6 files" ; return }

foreach file $file_list { if {![file exists $file]} { echo "Error!! Given file $file does not exist" ; return } }


set i 0
set skew_flag 0
foreach file $file_list {

  if {![catch {exec grep "Path Group.*AVGSKW" [file normalize $file]}]} {
    set skew_flag 1
    set qor_data($i) [proc_myskewformat $file]
  } elseif {![catch {exec grep "Path Group.*WNS" [file normalize $file]}]} {
    set qor_data($i) [proc_myformat $file]
  } else {
    proc_qor -existing_qor_file $file -units $unit > .junk
    set qor_data($i) [proc_myformat .junk]
    file delete .junk
    file delete qor.csv
  }
  if {[llength $qor_data($i)] !=3} { echo "Error!! Unable to process $file. Aborting ...." ; return }
  incr i

}

if {![file writable [file dir $csv_file]]} {
  echo "$csv_file not writable, Writing to /dev/null instead"
  set csv_file "/dev/null"
}
set csv [open $csv_file "w"]

foreach ref_grps [lindex $qor_data(0) 0] {
  foreach e [list $ref_grps] { lappend ref_grp_list [lindex $e 0] }
}

foreach f [lsort -integer [array names qor_data]] {
  foreach grps_of_f [lindex $qor_data($f) 0] {
    foreach grp [list $grps_of_f]  {
      lappend all_grp_list [lindex $grp 0]
      set entry ${f}_[lindex $grp 0]
      if {$skew_flag} {
        if {[llength $grp]==8} {
          set all_data($entry) "[lindex $grp 1] 0.0 [lindex $grp 2] 0.0 [lindex $grp 3] [lindex $grp 4] [lindex $grp 5] 0.0 [lindex $grp 6] 0.0 [lindex $grp 7]"
        } else {
          set all_data($entry) "[lindex $grp 1] [lindex $grp 2] [lindex $grp 3] [lindex $grp 4] [lindex $grp 5] [lindex $grp 6] [lindex $grp 7] [lindex $grp 8] [lindex $grp 9] [lindex $grp 10] [lindex $grp 11]"
        }
      } else {
        set all_data($entry) "[lindex $grp 1] [lindex $grp 2] [lindex $grp 3] [lindex $grp 4] [lindex $grp 5] [lindex $grp 6] [lindex $grp 7]"
      }
    }
  }
}

set extra_grp_list [lminus [lsort -unique $all_grp_list] $ref_grp_list]

foreach extra $extra_grp_list { lappend ref_grp_list $extra }

set maxl 0
foreach g $ref_grp_list {
  set l [string length [lindex $g 0]]
  if {$maxl < $l} { set maxl $l }
}
set maxl [expr {$maxl+2}]
if {$maxl < 20} { set maxl 20 }
set drccol [expr {$maxl-13}]
for {set i 0} {$i<$maxl} {incr i} { append bar - }

puts -nonewline $csv ","
echo -n [format "%-${maxl}s " ""]

foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }

if {$skew_flag} {
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }
} 

foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 12s " "$tag"] }

if {$skew_flag} {
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }
}

foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 7s " "$tag"] }

foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 7s " "$tag"] }

foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }

if {$skew_flag} {
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }
}

foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 12s " "$tag"] }

if {$skew_flag} {
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }
}

foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 7s " "$tag"] }
puts $csv ""
echo ""

puts -nonewline $csv "Path Group,"

echo -n [format "%-${maxl}s " "Path Group"]
append line "$bar"

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "WNS,"
  echo -n [format "% 8s " "WNS"]
  append line "---------"
}

if {$skew_flag} {
  foreach f [lsort -integer [array names qor_data]] {
    puts -nonewline $csv "SKEW,"
    echo -n [format "% 8s " "SKEW"]
    append line "---------"
  }
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "TNS,"
  echo -n [format "% 12s " "TNS"]
  append line "-------------"
}

if {$skew_flag} {
  foreach f [lsort -integer [array names qor_data]] {
    puts -nonewline $csv "AVGSKEW,"
    echo -n [format "% 8s " "AVGSKEW"]
    append line "---------"
  }
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "NVP,"
  echo -n [format "% 7s " "NVP"]
  append line "--------"
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "FREQ,"
  echo -n [format "% 7s " "FREQ"]
  append line "--------"
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "WNSH,"
  echo -n [format "% 8s " "WNSH"]
  append line "---------"
}

if {$skew_flag} {
  foreach f [lsort -integer [array names qor_data]] {
    puts -nonewline $csv "SKEWH,"
    echo -n [format "% 8s " "SKEWH"]
    append line "---------"
  }
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "TNSH,"
  echo -n [format "% 12s " "TNSH"]
  append line "-------------"
}

if {$skew_flag} {
  foreach f [lsort -integer [array names qor_data]] {
    puts -nonewline $csv "AVGSKEWH,"
    echo -n [format "% 8s " "AVGSKEWH"]
    append line "---------"
  }
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "NVPH,"
  echo -n [format "% 7s " "NVPH"]
  append line "--------"
}

#unindented if
if {$skew_flag} {

puts -nonewline $csv "\n"
echo -n "\n$line"

foreach ref_grp $ref_grp_list {

  #name
  puts -nonewline $csv "\n$ref_grp,"
  echo -n [format "\n%-${maxl}s " $ref_grp]

  #wns
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 0]] } else { set value [format "% 8s " $nil] ] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #skew 
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 1]] } else { set value [format "% 8s " $nil] }
    puts -nonewline $csv "$value," 
    echo -n $value
  }

  #tns
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 12s " [lindex $all_data($entry) 2]] } else { set value [format "% 12s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #avgskew
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 3]] } else { set value [format "% 8s " $nil] }
    puts -nonewline $csv "$value," 
    echo -n $value
  } 

  #nvp
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 7s " [lindex $all_data($entry) 4]] } else { set value [format "% 7s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #freq
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 7s " [lindex $all_data($entry) 5]] } else { set value [format "% 7s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #wnsh
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 6]] } else { set value [format "% 8s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #skewh
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 7]] } else { set value [format "% 8s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #tnsh
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 12s " [lindex $all_data($entry) 8]] } else { set value [format "% 12s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #avgskewh
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 9]] } else { set value [format "% 8s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #nvph
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 7s " [lindex $all_data($entry) 10]] } else { set value [format "% 7s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

}
puts $csv ""
echo "\n$line" 
puts -nonewline $csv "Summary,"
echo -n [format "%-${maxl}s " "Summary"]

foreach f [lsort -integer [array names qor_data]] {
    set qor_total($f) [lindex $qor_data($f) 1]
  if {[llength $qor_total($f)]<12} {
    set qor_total($f) "[lindex $qor_total($f) 0] [lindex $qor_total($f) 1] 0.0 [lindex $qor_total($f) 2] 0.0 [lindex $qor_total($f) 3] [lindex $qor_total($f) 4] [lindex $qor_total($f) 5] 0.0 [lindex $qor_total($f) 6] 0.0 [lindex $qor_total($f) 7]"
  }
}

#twns
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_total($f) 1]] ; puts -nonewline $csv "[lindex $qor_total($f) 1]," }

#maxskew
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_total($f) 2]] ; puts -nonewline $csv "[lindex $qor_total($f) 2]," }

#ttns
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 12s " [lindex $qor_total($f) 3]] ; puts -nonewline $csv "[lindex $qor_total($f) 3]," }

#maxavgskew
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_total($f) 4]] ; puts -nonewline $csv "[lindex $qor_total($f) 4]," }

#tnvp
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_total($f) 5]] ; puts -nonewline $csv "[lindex $qor_total($f) 5]," }

#tfreq
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_total($f) 6]] ; puts -nonewline $csv "[lindex $qor_total($f) 6]," }

#twnsh
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_total($f) 7]] ; puts -nonewline $csv "[lindex $qor_total($f) 7]," }

#maxskewh
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_total($f) 8]] ; puts -nonewline $csv "[lindex $qor_total($f) 8]," }

#ttnsh
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 12s " [lindex $qor_total($f) 9]] ; puts -nonewline $csv "[lindex $qor_total($f) 9]," }

#maxavgskewh
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s" [lindex $qor_total($f) 10]] ; puts -nonewline $csv "[lindex $qor_total($f) 10]," }

#tnvph
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_total($f) 11]] ; puts -nonewline $csv "[lindex $qor_total($f) 11]," }

puts $csv ""
echo "\n$line"

#unindented else
} else {
#if no skew flag

puts -nonewline $csv "\n"
echo -n "\n$line"

foreach ref_grp $ref_grp_list {

  #name
  puts -nonewline $csv "\n$ref_grp,"
  echo -n [format "\n%-${maxl}s " $ref_grp]

  #wns
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 0]] } else { set value [format "% 8s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #tns
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 12s " [lindex $all_data($entry) 1]] } else { set value [format "% 12s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #nvp
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 7s " [lindex $all_data($entry) 2]] } else { set value [format "% 7s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #freq
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 7s " [lindex $all_data($entry) 3]] } else { set value [format "% 7s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #wnsh
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 8s " [lindex $all_data($entry) 4]] } else { set value [format "% 8s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #tnsh
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 12s " [lindex $all_data($entry) 5]] } else { set value [format "% 12s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

  #nvph
  foreach f [lsort -integer [array names qor_data]] {
    set entry ${f}_$ref_grp
    if {[info exists all_data($entry)]} { set value [format "% 7s " [lindex $all_data($entry) 6]] } else { set value [format "% 7s " $nil] }
    puts -nonewline $csv "$value,"
    echo -n $value
  }

}
puts $csv ""
echo "\n$line" 
puts -nonewline $csv "Summary,"
echo -n [format "%-${maxl}s " "Summary"]

foreach f [lsort -integer [array names qor_data]] {
  set qor_total($f) [lindex $qor_data($f) 1]
}

#twns
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_total($f) 1]] ; puts -nonewline $csv "[lindex $qor_total($f) 1]," }

#ttns
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 12s " [lindex $qor_total($f) 2]] ; puts -nonewline $csv "[lindex $qor_total($f) 2],"}

#tnvp
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_total($f) 3]] ; puts -nonewline $csv "[lindex $qor_total($f) 3]," }

#tfreq
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_total($f) 4]] ; puts -nonewline $csv "[lindex $qor_total($f) 4]," }

#twnsh
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_total($f) 5]] ; puts -nonewline $csv "[lindex $qor_total($f) 5]," }

#ttnsh
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 12s " [lindex $qor_total($f) 6]] ; puts -nonewline $csv "[lindex $qor_total($f) 6]," }

#tnvph
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_total($f) 7]] ; puts -nonewline $csv "[lindex $qor_total($f) 7]," }

puts $csv ""
echo "\n$line"

}
#end unindented no skew flag

puts -nonewline $csv " ,"
echo -n [format "%-${maxl}s " " "]
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 12s " "$tag"] }
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 7s " "$tag"] }
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 7s " "$tag"] }
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 8s " "$tag"] }
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 12s " "$tag"] }
foreach tag $tag_list { puts -nonewline $csv "$tag,";  echo -n [format "% 7s " "$tag"] }
puts $csv ""
echo ""

puts -nonewline $csv " ,"
echo -n [format "%-${maxl}s " " "]

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "DRC,"
  echo -n [format "% 8s " "DRC"]
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "CELLA,"
  echo -n [format "% 12s " "CELLA"]
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "BUF,"
  echo -n [format "% 7s " "BUF"]
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "LEAF,"
  echo -n [format "% 7s " "LEAF"]
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "CBUFS,"
  echo -n [format "% 8s " "CBUFS"]
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "REGS,"
  echo -n [format "% 12s " "REGS"]
}

foreach f [lsort -integer [array names qor_data]] {
  puts -nonewline $csv "NETS,"
  echo -n [format "% 7s " "NETS"]
}

puts $csv ""
echo "\n$line" 

puts -nonewline $csv ","
echo -n [format "%-${maxl}s " " "]

foreach f [lsort -integer [array names qor_data]] {
  set qor_stat($f) [lindex $qor_data($f) 2]
}

#drc
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_stat($f) 0]] ; puts -nonewline $csv " [lindex $qor_stat($f) 0]," }

#cella
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 12s " [lindex $qor_stat($f) 1]] ; puts -nonewline $csv " [lindex $qor_stat($f) 1]," }

#buf
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_stat($f) 2]] ; puts -nonewline $csv " [lindex $qor_stat($f) 2]," }

#leaf
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_stat($f) 3]] ; puts -nonewline $csv " [lindex $qor_stat($f) 3]," }

#cbuf
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 8s " [lindex $qor_stat($f) 4]] ; puts -nonewline $csv " [lindex $qor_stat($f) 4]," }

#seqc
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 12s " [lindex $qor_stat($f) 5]] ; puts -nonewline $csv " [lindex $qor_stat($f) 5]," }

#tnets
foreach f [lsort -integer [array names qor_data]] { echo -n [format "% 7s " [lindex $qor_stat($f) 6]] ; puts -nonewline $csv " [lindex $qor_stat($f) 6]," }

puts $csv ""
echo "\n$line"

close $csv
echo "Written $csv_file\n"
rename proc_myformat ""
rename proc_myskewformat ""
}

define_proc_attributes proc_compare_qor -info "USER PROC: Compares upto 6 report_qor reports" \
	-define_args {
        {-qor_file_list "Required - List of report_qor files to compare" "<report_qor file list>" string required} 
        {-tag_list "Optional - Tag each QoR report with a name" "<qor file tag list>" string optional} 
        {-csv_file "Optional - Output csv file name, default is compare_qor.csv" "<output csv file>" string optional}
        {-units    "Optional - specify ps to override the default, default uses report_unit or ns" "<ps or ns>" one_of_string {optional value_help {values {ps ns}}}}
        }

echo "\tproc_qor"
echo "\tproc_compare_qor"
echo "\tproc_histogram"

#echo "SCRIPT-Info: End: [info script]"



#source ~luojianping/scr/primetime/proc/write_path_summary.tcl
# write_path_summary.tcl
#  writes customizable summary table for a collection of paths
#
# v1.0 chrispy 04/02/2004
#  initial release
# v1.1 chrispy 05/12/2004
#  added startpoint/endpoint clock latency, clock skew, CRPR
#  (thanks to John S. for article feedback!)
# v1.2 chrispy 06/15/2004
#  changed net/cell delay code to work in 2003.03
#  (thanks John Schritz @ Tektronix for feedback on this!)
# v1.3 chrispy 08/31/2004
#  fixed append_to_collection bug (again, thanks to John Schritz @ Tektronix!)
# v1.4 chrispy 03/26/2006
#  fixed handling of unconstrained paths
# v1.5 chrispy 09/01/2006
#  fixed slowest_cell reporting (thanks Pradeep @ OpenSilicon!)
# v1.6 chrispy 11/17/2010
#  fix harmless warning when a path has no cells (ie, feedthrough)
#  fix harmless warning when a path has no startpoint or endpoint clock
# v1.7 chrispy 01/31/2012
#  rename total_xtalk as total_xtalk_data
#  add total_xtalk_clock, total_xtalk (clock+data)


namespace eval path_summary {
    set finfo(index) {int {index number of path in original path collection (0, 1, 2...)} {{index} {#}}}
    set finfo(startpoint) {string {name of path startpoint} {{startpoint} {name}}}
    set finfo(endpoint) {string {name of path endpoint} {{endpoint} {name}}}
    set finfo(start_clk) {string {name of startpoint launching clock} {{startpoint} {clock}}}
    set finfo(end_clk) {string {name of endpoint capturing clock} {{endpoint} {clock}}}
    set finfo(launch_latency) {real {launching clock latency} {{launch} {latency}}}
    set finfo(capture_latency) {real {capturing clock latency} {{capture} {latency}}}
    set finfo(skew) {real {skew between launch/capture clock (negative is tighter)} {{clock} {skew}}}
    set finfo(crpr) {real {clock reconvergence pessimism removal amount} {{CRPR} {amount}}}
    set finfo(path_group) {string {path group name} {{path} {group}}}
    set finfo(slack) {real {path slack} {{path} {slack}}}
    set finfo(duration) {real {combinational path delay between startpoint and endpoint} {{path} {duration}}}
    set finfo(levels) {real {levels of combinational logic} {{levels} {of logic}}}
    set finfo(hier_pins) {int {number of hierarchy pins in path} {{# hier} {pins}}}
    set finfo(num_segments) {int {number of segments in path} {{#} {segments}}}
    set finfo(num_unique_segments) {int {number of unique segments in path} {{# unique} {segments}}}
    set finfo(num_segment_crossings) {int {number of segment crossings in path} {{# segment} {crossings}}}
    set finfo(average_cell_delay) {real {average combinational cell delay (duration / levels)} {{average} {cell delay}}}
    set finfo(slowest_cell) {string {name of slowest cell in path} {{slowest} {cell}}}
    set finfo(slowest_cell_delay) {real {cell delay of slowest cell in path} {{slowest} {cell delay}}}
    set finfo(slowest_net) {string {name of slowest net in path} {{slowest} {net}}}
    set finfo(slowest_net_delay) {real {net delay of slowest net in path} {{slowest} {net delay}}}
    set finfo(slowest_net_R) {real {resistance of slowest net in path} {{slowest} {net R}}}
    set finfo(slowest_net_C) {real {capacitance of slowest net in path} {{slowest} {net C}}}
    set finfo(total_net_delay) {real {summation of all net delays in path} {{total} {net delay}}}
    set finfo(max_trans) {real {slowest pin transition in path} {{max} {transition}}}
    set finfo(total_xtalk_data) {real {summation of all crosstalk deltas in data path} {{data} {xtalk}}}
    set finfo(total_xtalk_clock) {real {summation of all crosstalk deltas in clock path} {{clock} {xtalk}}}
    set finfo(total_xtalk) {real {summation of all crosstalk deltas in clock/data path} {{total} {xtalk}}}
    set finfo(xtalk_ratio) {real {percentage ratio of 'total_xtalk_data' versus 'duration'} {{xtalk} {ratio}}}
    set known_fields {index startpoint endpoint start_clk end_clk launch_latency capture_latency skew crpr path_group slack duration levels hier_pins num_segments num_unique_segments num_segment_crossings average_cell_delay slowest_cell slowest_cell_delay slowest_net slowest_net_delay slowest_net_R slowest_net_C total_net_delay max_trans total_xtalk_data total_xtalk_clock total_xtalk xtalk_ratio}

    proc max {a b} {
        return [expr $a > $b ? $a : $b]
    }

    proc min {a b} {
        return [expr $a < $b ? $a : $b]
    }
}

proc process_paths {args} {
    set results(-ungrouped) {}
    parse_proc_arguments -args $args results

    if {[set paths [filter_collection $results(paths) {object_class == timing_path}]] == ""} {
        echo "Error: no timing paths provided"
        return 0
    }

    set ungrouped_cells {}
    if {[set cells [get_cells -quiet $results(-ungrouped) -filter "is_hierarchical == true"]] != ""} {
        echo "Assuming the following instances have been ungrouped and flattened for segment processing:"
        foreach_in_collection cell $cells {
        echo " [get_object_name $cell]"
        }
        echo ""

        # now build a list of all ungrouped hierarchical cells
        while {$cells != ""} {
            set cell [index_collection $cells 0]
            set hier_cells [get_cells -quiet "[get_object_name $cell]/*" -filter "is_hierarchical == true"]
            set cells [remove_from_collection $cells $cell]
            set cells [append_to_collection -unique cells $hier_cells]
            set ungrouped_cells [append_to_collection -unique ungrouped_cells $cell]
        }
    }

    # come up with a list of index numbers where we want to print progress
    if {[set num_paths [sizeof $paths]] >= 25} {
        set index_notice_point 0
        set index_notice_messages {"\n(0%.."}
        set index_notice_points {}
        for {set i 10} {$i <= 90} {incr i 10} {
            lappend index_notice_points [expr {int($i * ($num_paths - 1) / 100)}]
            lappend index_notice_messages "${i}%.."
        }
        lappend index_notice_points [expr {$num_paths - 1}]
        lappend index_notice_messages "100%)\n"
    } else {
        set index_notice_point 25
    }

    # store path data in this namespace
    set path_summary::data_list {}

    # we start at an index number of 0
    set index 0

    foreach_in_collection path $paths {
        # print progress message if needed
        if {$index == $index_notice_point} {
            echo -n "[lindex $index_notice_messages 0]"
            set index_notice_point [lindex $index_notice_points 0]
            set index_notice_messages [lrange $index_notice_messages 1 [expr [llength $index_notice_messages]-1]]
            set index_notice_points [lrange $index_notice_points 1 [expr [llength $index_notice_points]-1]]
        }

        set hier_pins 0
        set combo_cell_pins 0
        set last_cell_port {}
        set slowest_cell {}
        set slowest_cell_delay "-INFINITY"
        set slowest_net_delay "-INFINITY"
        set total_net_delay 0
        set max_trans 0
        set total_xtalk_data 0.0
        set total_xtalk_clock 0.0
        set hier_cell_paths {}
        set last_cell_or_port {}
        set change_in_hier 1
        set last_cell_or_port {}
        set cell_delay {}
        set input_pin_arrival {}
        foreach_in_collection point [set points [get_attribute $path points]] {
            set object [get_attribute $point object]
            set port [get_ports -quiet $object]
            set pin [get_pins -quiet $object]
            set cell [get_cells -quiet -of $pin]
            set is_hier [get_attribute -quiet $cell is_hierarchical]
            set annotated_delta_transition [get_attribute -quiet $point annotated_delta_transition]

            if {$is_hier == "true"} {
                # if the pin is hierarchical, increment (these are always in pairs)
                incr hier_pins
                if {[remove_from_collection $cell $ungrouped_cells] != ""} {
                    set change_in_hier 1
                }
                continue
            }

            # if we are looking at a new cell just after a change in hierarchy,
            # add this to our list
            if {$change_in_hier} {
                if {$cell != ""} {
                # add cell path to list
                    set basename [get_attribute $cell base_name]
                    set fullname [get_attribute $cell full_name]
                    lappend hier_cell_paths [string range $fullname 0 [expr [string last $basename $fullname]-2]]
                } else {
                    # port, which is base level
                    lappend hier_cell_paths {}
                }
            }

            # we've handled any change in hierarchy
            set change_in_hier 0

            # use the fact that a true expression evaluates to 1, count combinational pins
            incr combo_cell_pins [expr {[get_attribute -quiet $cell is_sequential] == "false"}]

            if {[set annotated_delay_delta [get_attribute -quiet $point annotated_delay_delta]] != ""} {
                set total_xtalk_data [expr $total_xtalk_data + $annotated_delay_delta]
            }

            set max_trans [path_summary::max $max_trans [get_attribute $point transition]]

            # at this point, we have either a leaf pin or a port
            # net delay - delay from previous point to current point with annotated_delay_delta
            # cell delay - delay from previous point with annotated_delay_delta to current point
            set this_arrival [get_attribute $point arrival]
            set this_cell_or_port [add_to_collection $port $cell]

            if {[compare_collection $this_cell_or_port $last_cell_or_port]} {
                if {$last_cell_or_port != ""} {
                    if {[set net_delay [expr $this_arrival-$last_arrival]] > $slowest_net_delay} {
                        set slowest_net_delay $net_delay
                        set slowest_net [get_nets -quiet -segments -top_net_of_hierarchical_group [all_connected $object]]
                    }
                    set total_net_delay [expr $total_net_delay + $net_delay]
                }
                if {$input_pin_arrival != ""} {
                    set cell_delay [expr {$last_arrival - $input_pin_arrival}]
                    if {$cell_delay > $slowest_cell_delay} {
                        set slowest_cell_delay $cell_delay
                        set slowest_cell $last_cell_or_port
                    }
                }
                if {$cell != ""} {
                    set input_pin_arrival $this_arrival
                }
                set last_cell_or_port $this_cell_or_port
            }
            set last_arrival $this_arrival
        }

        # get first data arrival time, but skip any clock-as-data pins
        set i 0
        while {1} {
            set startpoint_arrival [get_attribute [set point [index_collection $points $i]] arrival]
            if {[get_attribute -quiet [get_attribute $point object] is_clock_pin] != "true"} {
                break
            }
            incr i
        }

        # get clock crosstalk
        # 1. pins may appear twice at gclock boundaries, but the delta only appears once
        # and is not double-counted
        # 2. capture clock deltas are subtracted to account for inverted sign
        foreach_in_collection point [get_attribute -quiet [get_attribute -quiet $path launch_clock_paths] points] {
            if {[set annotated_delay_delta [get_attribute -quiet $point annotated_delay_delta]] != ""} {
                set total_xtalk_clock [expr $total_xtalk_clock + $annotated_delay_delta]
            }
        }
        foreach_in_collection point [get_attribute -quiet [get_attribute -quiet $path capture_clock_paths] points] {
            if {[set annotated_delay_delta [get_attribute -quiet $point annotated_delay_delta]] != ""} {
                set total_xtalk_clock [expr $total_xtalk_clock - $annotated_delay_delta]
            }
        }

        set data(startpoint) [get_object_name [get_attribute -quiet $path startpoint]]
        set data(endpoint) [get_object_name [get_attribute -quiet $path endpoint]]
        set data(start_clk) [get_attribute -quiet [get_attribute -quiet $path startpoint_clock] full_name]
        set data(end_clk) [get_attribute -quiet [get_attribute -quiet $path endpoint_clock] full_name]
        if {[set data(launch_latency) [get_attribute -quiet $path startpoint_clock_latency]] == {}} {set data(launch_latency) 0.0}
        if {[set data(capture_latency) [get_attribute -quiet $path endpoint_clock_latency]] == {}} {set data(capture_latency) 0.0}
        set data(skew) [expr {($data(capture_latency)-$data(launch_latency))*([get_attribute -quiet $path path_type]=="max" ? 1 : -1)}]
        if {[set data(crpr) [get_attribute -quiet $path common_path_pessimism]] == ""} {set data(crpr) 0}
        set data(path_group) [get_object_name [get_attribute -quiet $path path_group]]
        set data(duration) [format "%.8f" [expr {[get_attribute $path arrival]-$data(launch_latency)-$startpoint_arrival}]]
        set data(slack) [get_attribute -quiet $path slack]
        set data(hier_pins) [expr $hier_pins / 2]
        set data(num_segments) [llength $hier_cell_paths]
        set data(num_segment_crossings) [expr $data(num_segments) - 1]
        set data(num_unique_segments) [llength [lsort -unique $hier_cell_paths]]
        set data(levels) [expr {$combo_cell_pins / 2.0}]
        set data(average_cell_delay) [expr {$data(levels) == 0 ? 0.0 : [format "%.7f" [expr {($data(duration) / $data(levels))}]]}]
        set data(slowest_cell) [get_attribute -quiet $slowest_cell full_name]
        set data(slowest_cell_delay) $slowest_cell_delay
        set data(total_net_delay) $total_net_delay
        set data(slowest_net) [get_object_name $slowest_net]
        set data(slowest_net_delay) $slowest_net_delay
        set data(slowest_net_R) [get_attribute -quiet $slowest_net net_resistance_max]
        set data(slowest_net_C) [get_attribute -quiet $slowest_net total_capacitance_max]
        set data(index) $index
        set data(max_trans) $max_trans
        set data(total_xtalk_data) $total_xtalk_data
        set data(total_xtalk_clock) $total_xtalk_clock
        set data(total_xtalk) [expr {$total_xtalk_data + $total_xtalk_clock}]
        set data(xtalk_ratio) [expr {$data(duration) == 0.0 ? 0 : (100.0 * $total_xtalk_data / $data(duration))}]
        incr index

        set list_entry {}
        foreach field $path_summary::known_fields {
            lappend list_entry $data($field)
        }
        lappend path_summary::data_list $list_entry
    }
    echo "Path information stored."
    echo ""
}

define_proc_attributes process_paths \
 -info "Extract information from paths for write_path_summary" \
 -define_args {\
  {paths "Timing paths from get_timing_paths" "timing_paths" string required}
  {-ungrouped "Assume these instances have been ungrouped" ungrouped list optional}
 }




proc write_path_summary {args} {
 # if user asks for help, remind him of what info is available
 if {[lsearch -exact $args {-longhelp}] != -1} {
  echo "Available data fields:"
  foreach field $path_summary::known_fields {
   echo " $field - [lindex $path_summary::finfo($field) 1]"
  }
  echo ""
  return
 }

 # process arguments
 set results(-fields) {startpoint endpoint levels slack}
 set results(-csv) 0
 set results(-descending) 0
 parse_proc_arguments -args $args results
 set num_fields [llength $results(-fields)]

 # did the user ask for any fields we don't understand?
 set leftovers [lminus $results(-fields) $path_summary::known_fields]
 if {$leftovers != ""} {
  echo "Error: unknown fields $leftovers"
  echo " (Possible values: $path_summary::known_fields)"
  return 0
 }

 # get sort type and direction, if specified
 if {[info exists results(-sort)]} {
  if {[set sort_field [lsearch -exact $path_summary::known_fields $results(-sort)]] == -1} {
   echo "Error: unknown sort field $results(-sort)"
   echo " (Possible values: $path_summary::known_fields)"
   return 0
  }
  set sort_type [lindex $path_summary::finfo($results(-sort)) 0]
  set sort_dir [expr {$results(-descending) ? "-decreasing" : "-increasing"}]
 }

 # obtain saved data from namespace, apply -sort and -max_paths
 set data_list $path_summary::data_list
 if {[info exists sort_field]} {
  set data_list [lsort $sort_dir -$sort_type -index $sort_field $data_list]
 }

 set data_list_length [llength $data_list]
 if {[info exists results(-max_paths)] && $data_list_length > $results(-max_paths)} {
  set data_list [lrange $data_list 0 [expr $results(-max_paths)-1]]
 }

 # generate a list of field index numbers relating to our known fields
 set field_indices {}
 foreach field $results(-fields) {
  lappend field_indices [lsearch $path_summary::known_fields $field]
 }

 # generate report
 if {$results(-csv)} {
  # join multi-line headers together
  set headers {}
  foreach index $field_indices {
   lappend headers [join [lindex $path_summary::finfo([lindex $path_summary::known_fields $index]) 2] { }]
  }

  # print headers
  echo [join $headers {,}]

  # print data
  foreach item $data_list {
   set print_list {}
   foreach index $field_indices {
    lappend print_list [lindex $item $index]
   }
   echo [join $print_list {,}]
  }
 } else {
  # determine maximum column widths
  echo ""
  echo "Legend:"
  foreach index $field_indices {
   set this_field [lindex $path_summary::known_fields $index]
   set this_finfo $path_summary::finfo($this_field)

   set this_max_length 0

   # check widths of each line of header
   foreach header [lindex $this_finfo 2] {
    set this_max_length [path_summary::max $this_max_length [string length $header]]
   }

   # check widths of data

   switch [lindex $this_finfo 0] {
    real {
     set max_pre 0
     set max_post 0
     foreach item $data_list {
      if {[set this_item [lindex $item $index]] == {INFINITY} || $this_item == {-INFINITY}} {
       set max_pre 3
       set max_post 0
      } else {
       regexp {([-0-9]*\.?)(.*)} [expr $this_item] dummy pre post
       set max_pre [path_summary::max $max_pre [string length $pre]]
       set max_post [path_summary::max $max_post [string length $post]]
      }
     }

     if {[info exists results(-significant_digits)]} {
      set max_post $results(-significant_digits)
     } else {
      set max_post [path_summary::min $max_post 7]
     }

     set this_max_length [path_summary::max $this_max_length [expr $max_pre + $max_post]]
    }
    default {
     foreach item $data_list {
      set this_max_length [path_summary::max $this_max_length [string length [lindex $item $index]]]
     }
    }
   }

   set max_length($index) $this_max_length

   switch [lindex $this_finfo 0] {
    int {
     set formatting($index) "%${this_max_length}d"
    }
    real {
     set formatting($index) "%${this_max_length}.${max_post}f"
    }
    string {
     set formatting($index) "%-${this_max_length}s"
    }
   }

   echo "$this_field - [lindex $this_finfo 1]"
  }

  # now print header
  echo ""
  for {set i 0} {$i <= 1} {incr i} {
   set print_list {}
   foreach index $field_indices {
    set this_field [lindex $path_summary::known_fields $index]
    set this_finfo $path_summary::finfo($this_field)
    lappend print_list [format "%-$max_length($index)s" [lindex [lindex $this_finfo 2] $i]]
   }
   echo [join $print_list { }]
  }

  set print_list {}
  foreach index $field_indices {
   lappend print_list [string repeat {-} $max_length($index)]
  }
  echo [join $print_list {+}]

  # print all data
  foreach item $data_list {
   set print_list {}
   foreach index $field_indices {
    lappend print_list [format $formatting($index) [lindex $item $index]]
   }
   echo [join $print_list { }]
  }
  echo ""
 }
}

define_proc_attributes write_path_summary \
 -info "Generate a summary report for given timing paths" \
 -define_args {\
  {-longhelp "Show description of available data fields" "" boolean optional}
  {-max_paths "Limit report to this many paths" "num_paths" int optional}
  {-fields "Information fields of interest" "fields" list optional}
  {-sort "Sort by this field" "field" string optional}
  {-descending "Sort in descending order" "" boolean optional}
  {-csv "Generate CSV report for spreadsheet" "" boolean optional}
  {-significant_digits "Number of digits to display" digits int optional}
 }


#source ~luojianping/scr/icc/report_timing_summary.tcl
# proc to generate timing summary report with startpoint and endpoint format
puts "#\tproc report_timing_summary <option_same_with_get_timing_path>"
proc report_timing_summary {args} {
    global synopsys_program_name

    if {[regsub {\-trace_timing} $args {} args]} {set trace_timing 1} else {set trace_timing 0}

    set cmd " set paths \[get_timing_path $args\]"
    eval $cmd
    
    puts "#-------------------------------------------------------------------------------------------------------------------------"
    if {$trace_timing} {
        puts [format "# %-4s | %-10s | %-5s | %-14s > %-14s | (%-5s) %-30s > (%-5s) %-30s" Num Slk Depth SClk EClk EarSlk Startpoint LatSlk Endpoint ]
    } else {
        puts [format "# %-4s | %-10s | %-5s | %-14s > %-14s | (%-5s) %-30s > (%-5s) %-30s" Num Slk Depth SClk EClk FEP Startpoint FEP Endpoint ]
    }
    puts "#-------------------------------------------------------------------------------------------------------------------------"
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

        if {[info exists synopsys_program_name] && [regexp {dc} $synopsys_program_name]} {
            set depth [get_attribute $path logic_depth]
        } else {
            set depth UNK
        }
        set lat_sclk [get_attribute -quiet $path startpoint_clock_latency]
        set lat_eclk [get_attribute -quiet $path endpoint_clock_latency]
        
        if {$lat_sclk == ""} {set lat_sclk 0}
        if {$lat_eclk == ""} {set lat_eclk 0}
        
        if {$trace_timing} {
            set sc     [get_cells -quiet -of $sp -filter "is_sequential == true"]
            set ec     [get_cells -quiet -of $ep -filter "is_sequential == true"]
            
            if {$sc != ""} {
                set dp_sc  [get_pins -of $sc -filter "is_data_pin == true && direction == in"]
                set slk_sc [lindex [lsort -r [get_attribute [get_timing_path -to $dp_sc] slack]] 0]
            } else {
                set slk_sc "UNK"
            }
            
            if {$ec != ""} {
                set ck_ec  [get_pins -of $ec -filter "is_clock_pin == true && direction == in"]
                set slk_ec [lindex [lsort -r [get_attribute [get_timing_path -from $ck_ec] slack]] 0]
            } else {
                set slk_ec "UNK"
            }
        }
        #if {![info exists fep_num($epn)]} {
        #    set fep_ep [llength [lsort -u [get_object_name [get_attribute [get_timing_path -to $ep -slack_lesser_than -0.005 -max 10000 -nworst 10000] startpoint]]]]
        #    set fep_num($epn) $fep_ep
        #}
        #
        #if {![info exists fep_num($spn)]} {
        #    set fep_sp [llength [lsort -u [get_object_name [get_attribute [get_timing_path -from $sp -slack_lesser_than -0.005 -max 10000 -nworst 10000] endpoint]]]]
        #    set fep_num($spn) $fep_sp
        #}
        
        
            set fep_num($spn) UNK
            set fep_num($epn) UNK

        if {$slk != ""} {
            if {![regexp -nocase {inf} $slk]} { set slk [format "%.4f" $slk] }
        } else {
            set slk "-"
        }
        #puts [format "  %-3s | %-7s | %-5s | %-7s > %-7s | (%-5s) %-30s > (%-5s) %-30s" $cnt $slk $depth $sclkn $eclkn $fep_num($spn) $spn $fep_num($epn) $epn]
        if {$trace_timing} {
            puts [format "   %-3s | %-10s | %-5s | %-7s(%-5.2f) > %-7s(%-5.2f) | (%-5s) %-30s > (%-5s) %-30s" $cnt $slk $depth $sclkn $lat_sclk $eclkn $lat_eclk $slk_sc $spn $slk_ec $epn]
        } else {
            puts [format "   %-3s | %-10s | %-5s | %-7s(%-5.2f) > %-7s(%-5.2f) | (%-5s) %-30s > (%-5s) %-30s" $cnt $slk $depth $sclkn $lat_sclk $eclkn $lat_eclk $fep_num($spn) $spn $fep_num($epn) $epn]
        }
        #puts [format "  %-3s | %-7s | %-5s | %7s(%-5.2f) > %-7s(%-5.2f) | %-30s > %-30s" $cnt $slk $depth $sclkn $lat_sclk $eclkn $lat_eclk $spn $epn]
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
    if {[info exists results(-from)]}          {set pps_from $results(-from)}
    if {[info exists results(-through)]}       {set pps_thr $results(-through)}
    if {[info exists results(-to)]}            {set pps_to $results(-to)}
    if {[info exists results(-other_options)]} {set oth_opt $results(-other_options)}
    
    set paths ""
    if {[info exists pps_from]} {
        foreach_in_collection p $pps_from {
            set cmd "set pths \[get_timing_path -from $p $oth_opt\]"
            eval $cmd
            append_to_collection paths $pths
        }
    }
    if {[info exists pps_thr]} {foreach_in_collection p $pps_thr {append_to_collection paths [get_timing_path -through $p $oth_opt]}}
    if {[info exists pps_to]} {foreach_in_collection p $pps_to {append_to_collection paths [get_timing_path -to $p $oth_opt]}}

    report_paths_summary $paths   
}
define_proc_attributes report_timing_by_points -info "list path summary from each points listed" \
    -define_args {
        {-from "specified the collection of startpoints" Astring string optional}
        {-through "specified the collection of through points" Astring string optional}
        {-to "specified the collection of endpoints" Astring string optional}
        {-other_options "specified other options to filter timing paht" Alist list optional}
    }


#source ~luojianping/scr/icc/sub_categories.tcl
proc get_app_option_sub_categories {args} {
    parse_proc_arguments -args $args results
    set match 1
    set app_options [get_app_options]
    set sub_c [list]
    set main_c [list]
    foreach app $app_options {
        set temp [split $app .]
        set category [lindex $temp 0]
        lappend main_c $category
        if {$results(-category_name) eq $category} {
            set match 0
            if {[llength $temp] == 3} {
                set sub_category [lindex $temp 1]
                set option [lindex $temp 2]
                lappend sub_c $sub_category
            }
        }
    }
    if {$match} {
        echo "Error: \"$results(-category_name)\" is not a valid category for app options." ;
        set unique_mainc_list [lsort -unique $main_c]
        set i 1
        echo "Please choose from any of the below mentioned valid categories of app-options :-"
        foreach valm $unique_mainc_list {
            echo $i. $valm;
            incr i;
        }
    } elseif {[llength $sub_c] > 0} {
        set unique_subc_list [lsort -unique $sub_c]
        set j 1
        echo "The sub-categories available for \"$results(-category_name)\" category of app options are shown below :-"
        foreach vals $unique_subc_list {
            echo $j. $vals;
            incr j;
        }
    } else {
        echo "There are no sub-categories available for \"$results(-category_name)\" category of app options." ;
    }
}
define_proc_attributes get_app_option_sub_categories -info "Script to report all the sub-categories for a specific category of app option" \
    -define_args {
    {-category_name "Category name of app options" category_name string required}
}


#source /ic/project/Yokneam/pd/wa/luojianping/scr_team/summary_design/report_vt.tcl
puts "proc sns_report_vt_ratio <-tech N7|N16|A7|A16|M16>"
proc sns_report_vt_ratio {args} {
    global tech synopsys_program_name
    parse_proc_arguments -args $args results
    
    if {[regexp {dc} $synopsys_program_name]} {
        set cs_all [get_cells -hier -filter {is_hierarchical != true && ref_name !~ *\*\*logic_* && is_physical_only == "false" && is_black_box != "true"}]
    } elseif {[regexp {pt} $synopsys_program_name]} {
        set cs_all [get_cells -hier -filter {is_hierarchical != true && ref_name !~ *\*\*logic_* && is_black_box != "true"}]
    } else {
        set cs_all [get_cells -hier -filter {is_hierarchical != true && ref_name !~ *\*\*logic_* && is_physical_only == "false" && is_hard_macro == "false"}]
    }
    set num_all [sizeof_collection $cs_all]
    set area_all 1.0
    foreach_in_collection c $cs_all {
        set a [get_attribute $c area]
        set area_all [expr $area_all + $a] 
    }

    if {[info exists results(-tech)]} {set tech_proc $results(-tech)}
    if {![info exists tech] && ![info exists tech_proc]} {
        puts "Error: unknown tech for the lib, please define with -tech option. terminate ..."
        return 0
    }
    
    if {[info exists tech_proc]} {set tech_ff $tech_proc} else {set tech_ff $tech}
    
    if {$tech_ff == "N7"} {
        set arr_vt(lvt)      [filter_collection $cs_all "ref_name =~ *PDLVT"]
        set cs_left          [remove_from_collection $cs_all $arr_vt(lvt)]
        set arr_vt(ulvt)     [filter_collection $cs_left "ref_name =~ *PDULVT"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt)]
        set arr_vt(svt)      [filter_collection $cs_left "ref_name =~ *PDSVT"]
    } elseif {$tech_ff == "A7"} {
        set arr_vt(lvt)      [filter_collection $cs_all "ref_name =~ *TL_C*"]
        set cs_left          [remove_from_collection $cs_all $arr_vt(lvt)]
        set arr_vt(ulvt)     [filter_collection $cs_left "ref_name =~ *TUL_C*"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt)]
        set arr_vt(svt)      [filter_collection $cs_left "ref_name =~ *TS_C*"]   
    } elseif {$tech_ff == "A16"} {
        set arr_vt(lvt,c16)  [filter_collection $cs_all "ref_name =~ *CTL_C16"]
        set cs_left          [remove_from_collection $cs_all $arr_vt(lvt,c16)]
        set arr_vt(lvt,c18)  [filter_collection $cs_left "ref_name =~ *CTL_C18"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(lvt,c18)]
        set arr_vt(lvt,c20)  [filter_collection $cs_left "ref_name =~ *CTL_C20"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(lvt,c20)]
        set arr_vt(lvt,c24)  [filter_collection $cs_left "ref_name =~ *CTL_C24"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(lvt,c24)]

        set arr_vt(ulvt,c16) [filter_collection $cs_left "ref_name =~ *CTUL_C16"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c16)]
        set arr_vt(ulvt,c18) [filter_collection $cs_left "ref_name =~ *CTUL_C18"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c18)]
        set arr_vt(ulvt,c20) [filter_collection $cs_left "ref_name =~ *CTUL_C20"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c20)]
        set arr_vt(ulvt,c24) [filter_collection $cs_left "ref_name =~ *CTUL_C24"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c24)]

        set arr_vt(svt,c16)  [filter_collection $cs_left "ref_name =~ *CTS_C16"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c16)]
        set arr_vt(svt,c18)  [filter_collection $cs_left "ref_name =~ *CTS_C18"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c18)]
        set arr_vt(svt,c20)  [filter_collection $cs_left "ref_name =~ *CTS_C20"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c20)]
        set arr_vt(svt,c24)  [filter_collection $cs_left "ref_name =~ *CTS_C24"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c24)]
        
        set arr_vt(zz_other)    $cs_left
    } elseif {$tech_ff == "N16"} {
        set arr_vt(lvt,c16)  [filter_collection $cs_all "ref_name =~  *BWP16*CPDLVT"]
        set cs_left          [remove_from_collection $cs_all $arr_vt(lvt,c16)]
        set arr_vt(lvt,c20)  [filter_collection $cs_left "ref_name =~ *BWP20*CPDLVT"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(lvt,c20)]

        set arr_vt(ulvt,c16) [filter_collection $cs_left "ref_name =~ *BWP16*CPDULVT"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c16)]
        set arr_vt(ulvt,c20) [filter_collection $cs_left "ref_name =~ *BWP20*CPDULVT"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c20)]

        set arr_vt(svt,c16)  [filter_collection $cs_left "ref_name =~ *BWP16*CPD"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c16)]
        set arr_vt(svt,c20)  [filter_collection $cs_left "ref_name =~ *BWP20*CPD"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c20)]
        
        set arr_vt(zz_other)    $cs_left
    } elseif {$tech_ff == "M16"} {
        set arr_vt(lvt,c16)  [filter_collection $cs_all "ref_name =~  *AL12"]
        set cs_left          [remove_from_collection $cs_all $arr_vt(lvt,c16)]
        set arr_vt(lvt,c18)  [filter_collection $cs_left "ref_name =~ *BL12"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(lvt,c18)]

        set arr_vt(ulvt,c16) [filter_collection $cs_left "ref_name =~ *AV12"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c16)]
        set arr_vt(ulvt,c18) [filter_collection $cs_left "ref_name =~ *BV12"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(ulvt,c18)]

        set arr_vt(svt,c16)  [filter_collection $cs_left "ref_name =~ *AS12"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c16)]
        set arr_vt(svt,c18)  [filter_collection $cs_left "ref_name =~ *BS12"]
        set cs_left          [remove_from_collection $cs_left $arr_vt(svt,c18)]

        set arr_vt(zz_other)    $cs_left
    } else {
        puts "Error: unknown techonoly or project, terminated ..."
        return 0
    }

    set num_tot_ff 0
    set num_tot_comb 0
    set area_tot_ff 0.0
    set area_tot_comb 0.0
    puts "\n===================================================================================================================="
    puts [format "|  %-10s |  %-10s %-10s |  %-10s %-10s |  %-10s %-10s | %10s | %10s |" VT num_ff area_ff num_comb area_comb num_tot area_tot num_ratio area_ratio]
    puts "--------------------------------------------------------------------------------------------------------------------"
    foreach vt [lsort -dict [array name arr_vt]] {
        set num_tot   [sizeof_collection $arr_vt($vt)]
        set area_tot  0.0
        set num_ff    0
        set area_ff   0.0
        set num_comb  0
        set area_comb 0.0
        
        foreach_in_collection c $arr_vt($vt) {
            set a [get_attribute $c area]
            set area_tot [expr $area_tot + $a]
            if {[get_attribute -quiet $c is_sequential] == "true"} {
                incr num_ff
                set area_ff [expr $area_ff + $a] 
            } else {
                incr num_comb
                set area_comb [expr $area_comb + $a]
            }
        }
        set num_tot_ff     [expr $num_tot_ff + $num_ff]
        set num_tot_comb   [expr $num_tot_comb + $num_comb]
        set area_tot_ff    [expr $area_tot_ff + $area_ff]
        set area_tot_comb  [expr $area_tot_comb + $area_comb]
        
        set ratio_num      [expr (${num_tot}*1.0/${num_all})*100.0]
        set ratio_area     [expr (($area_ff + $area_comb)/${area_all})*100.0]
        puts [format "|  %-10s |  %-10s %-10.2f |  %-10s %-10.2f |  %-10s %-10.2f | %9.1f%1s | %9.1f%1s |" $vt $num_ff $area_ff $num_comb $area_comb $num_tot $area_tot $ratio_num % $ratio_area %]
    }
    puts "====================================================================================================================="
    puts [format "|  %-10s |  %-10s %-10.2f |  %-10s %-10.2f |  %-10s %-10.2f | %10s | %10s |" Total $num_tot_ff $area_tot_ff $num_tot_comb $area_tot_comb $num_all $area_all - -]
    puts "=====================================================================================================================\n"
}
define_proc_attributes sns_report_vt_ratio -info "print vt ratio reports" \
    -define_args {
        {-tech "the technology for libs, such N7/A7/N16/A16/M16, M16 means M31 Libs@N16 tech" Astring one_of_string {optional value_help {values {N7 A7 N16 A16 M16}}}}
    }


# proc summary design instance num
puts "proc sns_report_design_physical_info"
proc sns_report_design_physical_info {} {
    global arr_hier
    set de_l1 [get_object_name [get_cells -filter "is_hierarchical == true"]]
    
    foreach d $de_l1 {
        set de_l2 [get_object_name [get_cells ${d}/* -filter "is_hierarchical == true"]]
        set arr_hier($d) "$de_l2"

        foreach d $de_l2 {
            set de_l3 [get_object_name [get_cells ${d}/* -filter "is_hierarchical == true"]]
            set arr_hier($d) "$de_l3"
            foreach dd $de_l3 {
                set arr_hier($dd) ""
            }
        }
    }

    foreach d [array name arr_hier] {
        puts "=> Calc $d ..."
        set aa 0.0
        set cs [get_cells -hier -filter "full_name =~ ${d}/* && is_hierarchical == false"]
        set regs [filter_collection $cs "is_sequential == true"]
        foreach a [get_attribute -quiet $cs area] {
            if {$a != ""} { set aa [expr $aa + $a] }
        }

        set arr_inst_num($d) [sizeof_collection $cs]
        set arr_reg
