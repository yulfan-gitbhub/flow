namespace eval cc_invs {
}

proc GG_fix_si_double_switch {} {
    setEcoMode -LEQCheck true -honorDontTouch false -honorDontUse false -honorFixedStatus false -updateTiming false -refinePlace false -batchMode true

    foreach one [glob ../../sta/run/PtTim*/reports/*si_double_switching.all_nets.rpt.gz] {
        foreach aa [split [exec zcat $one] \n]] {
            if { ! [regexp VIO $aa] } {
                continue
            }
            set net [lindex $aa 0]
            set vio [lindex $aa 4]
            if { ! [info exists ss($net)] } {
                set ss($net) $vio
            } else { 
                if { $ss($net) > $vio } {
                    set ss($net) $vio
                }
            }
        }
    }


    foreach net [array name ss] {
        Puts "#fix si double switch: $ss($net) $net"
        if { [dbGet [dbGetNetByName $net].isClock] || [dbGet [dbGetNetByName $net].isCTSClock] } {
            Puts "    # skip clock net fix $net"
            continue
        }
        set size_cell 0
        set move_cell 0
        set insert_buf 0
        set pins [get_pins -leaf -of $net]

        if { [sizeof_collection $pins] == 2 } {
            set drive_pin [get_pins -leaf -of $net -filter "direction==out"]
            set load_pin [get_pins -leaf -of $net -filter "direction==in"]

            set d_x [dbGet [dbGetObjByName [get_object_name $drive_pin]].pt_x]
            set d_y [dbGet [dbGetObjByName [get_object_name $drive_pin]].pt_y]

            set l_x [dbGet [dbGetObjByName [get_object_name $load_pin]].pt_x]
            set l_y [dbGet [dbGetObjByName [get_object_name $load_pin]].pt_y]

            set load_ref [get_property [get_cell -of $load_pin] ref_name]

            set net_length [expr abs($d_x-$l_x) +abs($d_y-$l_y)]
        
            
            if { [regexp BUF $load_ref] || [regexp INV $load_ref] } {
                set next_load [get_pins -leaf -of [get_net -of [get_pins -of [get_cell -of $load_pin] -filter "direction==out"]] -filter "direction==in"]
                if { [sizeof_collection $next_load] == 1 } {
                    set nl_x [dbGet [dbGetObjByName [get_object_name $next_load]].pt_x]
                    set nl_y [dbGet [dbGetObjByName [get_object_name $next_load]].pt_y]

                    set load_net_length  [expr abs($nl_x-$l_x) +abs($nl_y-$l_y)]
                    if { $load_net_length < 20 } {
                        set move_cell 1
                    } else {
                        if { $ss($net) > -0.01 } {
                            set size_cell 1
                        } else {
                            set insert_buf 1
                        }
                    }

                } else {
                    set insert_buf 1
                }
            } else {
                if { $ss($net) > -0.01 } {
                    set size_cell 1
                } else {
                    set insert_buf 1
                }
            }

            if { $size_cell } {
                set drive_ref [get_property [get_cell -of $drive_pin] ref_name]
                set drive_inst [get_object_name [get_cell -of $drive_pin]]
                set new_ref [regsub A9PP96CTL $drive_ref A9PP96CTUL]
                set new_ref [regsub A9PP96CTS $drive_ref A9PP96CTL]

                if { $drive_ref == $new_ref } {
                    set new_ref [regsub C18 $drive_ref C16]
                    set new_ref [regsub C20 $drive_ref C16]
                    set new_ref [regsub C24 $drive_ref C16]
                }
                if { $drive_ref == $new_ref } {
                    if { [regexp BUF $drive_ref] || [regexp INV $drive_ref] } {
                        if { [regexp {(.*_X)([0-9P]*)([A-Z].*)} $drive_ref all a size b] } {
                            set size [regsub P $size .] 
                            if { $size < 8 } {
                                set cells   [lsort -dict [dbGet head.libCells.name ${a}*${b}]]
                                set new_ref [lindex $cells [lsearch  $cells $drive_ref]+1]
                                if { $new_ref == "" } {
                                    set new_ref $drive_ref
                                }
                            }
                        }
                    } else {
                        set insert_buf 1
                    }
                }


                if { $drive_ref != $new_ref } {
                    Puts "ecoChange -inst $drive_inst -cell $new_ref"
                    ecoChange -inst $drive_inst -cell $new_ref
                }
            }
            if { $move_cell } {
                set load_inst [get_object_name [get_cell -of $load_pin]]
                set new_x [expr ($d_x + $nl_x)/2]
                set new_y [expr ($d_y + $nl_y)/2]
                puts "placeInstance $load_inst $new_x $new_y -placed"
                placeInstance $load_inst $new_x $new_y -placed
            } 
            if { $insert_buf } {
                set load_pin [get_object_name $load_pin]
                set buf BUFH_X6N_A9PP96CTL_C20
                Puts "ecoAddRepeater -cell $buf -term $load_pin -relativeDistToSink 0.5"
                ecoAddRepeater -cell $buf -term $load_pin -relativeDistToSink 0.5

            }

        } else {
            set drive_pin [get_pins -leaf -of $net -filter "direction==out"]

            set size_cell 1

            if { $size_cell } {
                set drive_ref [get_property [get_cell -of $drive_pin] ref_name]
                set drive_inst [get_object_name [get_cell -of $drive_pin]]
                set new_ref [regsub A9PP96CTL $drive_ref A9PP96CTUL]
                set new_ref [regsub A9PP96CTS $drive_ref A9PP96CTL]

                if { $drive_ref == $new_ref } {
                    set new_ref [regsub C18 $drive_ref C16]
                    set new_ref [regsub C20 $drive_ref C16]
                    set new_ref [regsub C24 $drive_ref C16]
                }
                if { $drive_ref == $new_ref } {
                    if { [regexp BUF $drive_ref] || [regexp INV $drive_ref] } {
                        if { [regexp {(.*_X)([0-9P]*)([A-Z].*)} $drive_ref all a size b] } {
                            set size [regsub P $size .] 
                            if { $size < 8 } {
                                set cells   [lsort -dict [dbGet head.libCells.name ${a}*${b}]]
                                set new_ref [lindex $cells [lsearch  $cells $drive_ref]+1]
                                if { $new_ref == "" } {
                                    set new_ref $drive_ref
                                }
                            }
                        }
                    } else {
                        set insert_buf 1
                    }
                }
                if { $drive_ref != $new_ref } {
                    Puts "ecoChange -inst $drive_inst -cell $new_ref"
                    ecoChange -inst $drive_inst -cell $new_ref
                }
            }
        }
    }

}

proc GG_fix_coupled_slew { {print 0} } {
    setEcoMode -LEQCheck true -honorDontTouch false -honorDontUse false -honorFixedStatus false -updateTiming false -refinePlace false -batchMode true

    foreach one [glob ../../sta/run/PtTim*/reports/*.max_transition.coupled_slew.rpt.gz] {
        foreach aa [split [exec zcat $one] \n]] {
            if { ! [regexp VIO $aa] } {
                continue
            }
            set pin [lindex $aa 0]
            set net [get_object_name [get_net -of $pin]]
            set vio [lindex $aa 3]
            if { ! [info exists ss($net)] } {
                set ss($net) $vio
            } else { 
                if { $ss($net) > $vio } {
                    set ss($net) $vio
                }
            }
        }
    }
    foreach net [array name ss] {
        Puts "# fix coupled slew: $ss($net) $net"
        if { [dbGet [dbGetNetByName $net].isClock] || [dbGet [dbGetNetByName $net].isCTSClock] } {
            Puts "    # skip clock net fix $net"
            continue
        }
        set size_cell 0
        set insert_buf 0
        set pins [get_pins -leaf -of $net]

        if { [sizeof_collection $pins] == 2 } {
            set drive_pin [get_pins -leaf -of $net -filter "direction==out"]
            set load_pin [get_pins -leaf -of $net -filter "direction==in"]

            set d_x [dbGet [dbGetObjByName [get_object_name $drive_pin]].pt_x]
            set d_y [dbGet [dbGetObjByName [get_object_name $drive_pin]].pt_y]

            set l_x [dbGet [dbGetObjByName [get_object_name $load_pin]].pt_x]
            set l_y [dbGet [dbGetObjByName [get_object_name $load_pin]].pt_y]

            set load_ref [get_property [get_cell -of $load_pin] ref_name]

            set net_length [expr abs($d_x-$l_x) +abs($d_y-$l_y)]
        
            set drive_ref [get_property [get_cell -of $drive_pin] ref_name]
            set drive_inst [get_object_name [get_cell -of $drive_pin]]            

            if { [regexp CTS $drive_ref] } {
                set size_cell 1
            } elseif { $ss($net) > -0.01 } {
                set size_cell 1
            } else {
                set insert_buf 1
            }

            if { $size_cell } {
                set new_ref [regsub A9PP96CTL $drive_ref A9PP96CTUL]
                set new_ref [regsub A9PP96CTS $drive_ref A9PP96CTL]

                if { $drive_ref == $new_ref } {
                    set new_ref [regsub C18 $drive_ref C16]
                    set new_ref [regsub C20 $drive_ref C16]
                    set new_ref [regsub C24 $drive_ref C16]
                }

                if { $drive_ref == $new_ref } {
                    if { [regexp BUF $drive_ref] || [regexp INV $drive_ref] } {
                        if { [regexp {(.*_X)([0-9P]*)([A-Z].*)} $drive_ref all a size b] } {
                            set size [regsub P $size .] 
                            if { $size < 8 } {
                                set cells   [lsort -dict [dbGet head.libCells.name ${a}*${b}]]
                                set new_ref [lindex $cells [lsearch  $cells $drive_ref]+1]
                                if { $new_ref == "" } {
                                    set new_ref $drive_ref
                                }
                            }
                        }
                    } else {
                        set insert_buf 1
                    }
                }

                if { $drive_ref != $new_ref } {
                    Puts "ecoChange -inst $drive_inst -cell $new_ref"
                     if { ! $print } {
                        ecoChange -inst $drive_inst -cell $new_ref
                    }
                }
            }
            
            if { $insert_buf } {
                set load_pin [get_object_name $load_pin]
                set buf BUFH_X5N_A9PP96CTL_C20
                Puts "ecoAddRepeater -cell $buf -term $load_pin -relativeDistToSink 0.5"
                if { ! $print } {
                    ecoAddRepeater -cell $buf -term $load_pin -relativeDistToSink 0.5
                }
            }
        } else {
            set drive_pin [get_pins -leaf -of $net -filter "direction==out"]
            set drive_ref [get_property [get_cell -of $drive_pin] ref_name]
            set drive_inst [get_object_name [get_cell -of $drive_pin]]   

            if { [regexp CTS $drive_ref] || [regexp CTL $drive_ref] } {
                set size_cell 1
            }

            if { $size_cell } {
                set new_ref [regsub A9PP96CTL $drive_ref A9PP96CTUL]
                set new_ref [regsub A9PP96CTS $drive_ref A9PP96CTL]

                if { $drive_ref == $new_ref } {
                    set new_ref [regsub C18 $drive_ref C16]
                    set new_ref [regsub C20 $drive_ref C16]
                    set new_ref [regsub C24 $drive_ref C16]
                }

                if { $drive_ref == $new_ref } {
                    if { [regexp BUF $drive_ref] || [regexp INV $drive_ref] } {
                        if { [regexp {(.*_X)([0-9P]*)([A-Z].*)} $drive_ref all a size b] } {
                            set size [regsub P $size .] 
                            if { $size < 8 } {
                                set cells   [lsort -dict [dbGet head.libCells.name ${a}*${b}]]
                                set new_ref [lindex $cells [lsearch  $cells $drive_ref]+1]
                                if { $new_ref == "" } {
                                    set new_ref $drive_ref
                                }
                            }
                        }
                    } else {
                        set insert_buf 1
                    }
                }

                if { $drive_ref != $new_ref } {
                    Puts "ecoChange -inst $drive_inst -cell $new_ref"
                    if { ! $print } {
                        ecoChange -inst $drive_inst -cell $new_ref
                    }
                }
            }
        }
    }
}

proc GG_gui_select_si_double_switch_net {} {
	global gui_select
	global gui_select_num
	if { [info exists gui_select] }     { unset gui_select}
	if { [info exists gui_select_num] } { unset gui_select_num}

    set gui_select_num -1

    foreach one [glob ../../sta/run/PtTim*/reports/*si_double_switching.all_nets.rpt.gz] {
        foreach aa [split [exec zcat $one] \n]] {
            if { ! [regexp VIO $aa] } {
                continue
            }
            set net [lindex $aa 0]
            set vio [lindex $aa 4]
            if { ! [info exists ss($net)] } {
                set ss($net) $vio
            } else { 
                if { $ss($net) > $vio } {
                    set ss($net) $vio
                }
            }
        }
    }

    foreach key [array name ss] {
        lappend gui_select "$ss($key) $key"
    }
    set gui_select [lsort -ascii -decreasing -index 0 $gui_select]

}

proc GG_gui_select_coupled_slew {} {
	global gui_select
	global gui_select_num
	if { [info exists gui_select] }     { unset gui_select}
	if { [info exists gui_select_num] } { unset gui_select_num}

    set gui_select_num -1

    foreach one [glob ../../sta/run/PtTim*/reports/*.max_transition.coupled_slew.rpt.gz] {
        foreach aa [split [exec zcat $one] \n]] {
            if { ! [regexp VIO $aa] } {
                continue
            }
            set net [lindex $aa 0]
            set vio [lindex $aa 3]
            if { ! [info exists ss($net)] } {
                set ss($net) $vio
            } else { 
                if { $ss($net) > $vio } {
                    set ss($net) $vio
                }
            }
        }
    }

    foreach key [array name ss] {
        lappend gui_select "$ss($key) $key"
    }
    set gui_select [lsort -ascii -decreasing -index 0 $gui_select]

}
proc GG_gui_select_uncoupled_slew {} {
	global gui_select
	global gui_select_num
	if { [info exists gui_select] }     { unset gui_select}
	if { [info exists gui_select_num] } { unset gui_select_num}

    set gui_select_num -1

    foreach one [glob ../../sta/run/PtTim*/reports/*.max_transition.uncoupled_slew.rpt.gz] {
        foreach aa [split [exec zcat $one] \n]] {
            if { ! [regexp VIO $aa] } {
                continue
            }
            set net [lindex $aa 0]
            set vio [lindex $aa 3]
            if { ! [info exists ss($net)] } {
                set ss($net) $vio
            } else { 
                if { $ss($net) > $vio } {
                    set ss($net) $vio
                }
            }
        }
    }

    foreach key [array name ss] {
        lappend gui_select "$ss($key) $key"
    }
    set gui_select [lsort -ascii -decreasing -index 0 $gui_select]

}

proc GG_gui_select_convert_net {} {
	global gui_select
	global gui_select_num
	if { [info exists gui_select_num] } { unset gui_select_num}

    set gui_select_num -1

    foreach key $gui_select {
        set net [get_object_name [get_net -of [lindex $key end]]]
        if { [info exists aa($net)] } {
        } else {
            set aa($net) ""
            lappend gui_select_conv \{$net\}
        }
    }

    set gui_select [lsort -ascii -decreasing -index 0 $gui_select_conv]
}

proc GG_object_info {obj} {
    if { [dbGetNetByName $obj] != "0x0" } {
        set ptr [dbGetNetByName $obj]
        set terms [dbGet $ptr.numTerms]
        set drive_inst [dbGet [dbGet $ptr.instTerms.isOutput 1 -p].inst.name]
        set drive_cell [dbGet [dbGet $ptr.instTerms.isOutput 1 -p].inst.cell.name]
        set net_length 0
        foreach wire [dbGet -e $ptr.wires] {
            set length [dbGet $wire.length]
            set net_length [expr $net_length + $length]
        }
        puts "   is_net; length = $net_length ; terms = $terms ; drive = $drive_cell $drive_inst ;"
    }

}


proc cc_invs::gui_select_befort {} {
    global gui_select
    global gui_select_num

    set total [llength $gui_select]

    incr gui_select_num -1

    set cur [lindex $gui_select $gui_select_num]
    deselectAll
    select_obj [lindex $cur end]
    zoomSelected
    if { $gui_select_num == 0 } {
        puts "###################################" 
        puts "# Select function"
        puts "# Bindkey:        Shift+n Shift+p"
        puts "# Control num:    gui_select_num"
        puts "# Select value:   gui_select"
        puts "#                 { {... select1} {... select2} {... select3} {... select4} ..}"   
        puts "###################################"
    }
    puts "$gui_select_num/$total: $cur"
    GG_object_info [lindex $cur end]

}

proc cc_invs::gui_select_after {} {
    global gui_select
    global gui_select_num

    set total [llength $gui_select]

    incr gui_select_num 

    set cur [lindex $gui_select $gui_select_num]
    deselectAll
    select_obj [lindex $cur end]
    zoomSelected
    if { $gui_select_num == 0 } {
        puts "###################################" 
        puts "# Select function"
        puts "# Bindkey:        Shift+n Shift+p"
        puts "# Control num:    gui_select_num"
        puts "# Select value:   gui_select"
        puts "#                 { {... select1} {... select2} {... select3} {... select4} ..}"   
        puts "###################################"
    }
    puts "$gui_select_num/$total: $cur"
    GG_object_info [lindex $cur end]
}



bindKey Shift+p cc_invs::gui_select_befort
bindKey Shift+n cc_invs::gui_select_after

if { [uiGet -quiet guiSelect ] == "" } {
    uiAdd guiSelect -newline true -in main -label "gui select" -type toolbar
    set ICON /ic/eda_tools/cadence/INNOVUS_19.12-s087/share/cdssetup/icons/24x24
    uiAdd selectPrevious -in guiSelect -label "Shift+p" -tooltip "select previous" -type toolbutton -icon [file join $ICON left.png] -command {cc_invs::gui_select_befort} -shortcut Shift+p
    uiAdd selectNext     -in guiSelect -label "Shift+n" -tooltip "select next"     -type toolbutton -icon [file join $ICON right.png] -command  {cc_invs::gui_select_after} -shortcut Shift+n
    uiSet guiSelect -tooltip "gui select" -visible true -disabled false
}

