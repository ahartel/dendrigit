# © 2014 Synopsys, Inc. All rights reserved. 
# # This script is proprietary and confidential information of 
# Synopsys, Inc. and may be used and disclosed only as authorized 
# per your agreement with Synopsys, Inc. controlling such use and disclosure.

##################################################################################
# proc_time - Calculates elapsed wall clock time
##################################################################################


proc proc_time {args} {

    #tracks available mem and swp
    #prints machine information
    #Version 2.2

    set ::sh_new_variable_message false
    parse_proc_arguments -args ${args} opt

    if {[info exists opt(prompt)]} { set prompt $opt(prompt) } else { set prompt "" }
    if {[info exists opt(-include_cputime)]} { set show_cpu 1 } else { set show_cpu 0 }
    if {[info exists opt(-reset)]} {
      unset -nocomplain ::_naren_cpulast ::_naren_wfirst ::_naren_wallast
    }

    set cpu [expr {int([cputime])}]
    set ctime [proc_naren_convert $cpu]
    set wall [clock seconds]

    #get machine load
    regexp {average:\s+(\S+),} [exec uptime] match load
    if {![info exists load]} { set load 0.0 }
    set cores [exec grep -c "processor" /proc/cpuinfo]
    if {$cores==0} { set cores 1 }
    set load [expr {($load*100.0)/$cores}]
    set load "Load - [format %3.0f ${load}]%"

    #get free mem/swp of machine
    set freecmd [exec free -m]
    regexp {Mem:\s+(\d+)\s+(\d+)\s+(\d+)} $freecmd match memt memu memf
    regexp {Swap:\s+(\d+)\s+(\d+)\s+(\d+)} $freecmd match swpt swpu swpf

    set memf "(Free RAM : [format %6.1f [expr {${memf}/1024.0}]]GB)"
    set swp "Swp : [format %6.1f [expr {${swpu}/1024.0}]]GB)"

    set mem "Mem : [format %6.1f [expr {[mem]/1048576.0}]]GB $memf $swp"
    set prompt "[format %-15s [string range $prompt 0 14]]"

    if { ![info exists ::_naren_cpulast] } {
        if {$show_cpu} {
          echo "Starting Timer for the First Time ...."
          proc_machine_info
          echo "TimeStamp - $prompt - Incr (cpu) - 00h:00m:00s (00h:00m:00s) Total (cpu) - 00h:00m:00s (00h:00m:00s) - $mem - $load - [date]"
        } else {
          echo "Starting Timer for the First Time ...."
          proc_machine_info
          echo "TimeStamp - $prompt - Incr - 00h:00m:00s Total - 00h:00m:00s - $mem - $load - [date]"
        }
        set ::_naren_wfirst $wall
    } else {
        set cdiff [expr $cpu - $::_naren_cpulast]
        set cincr [proc_naren_convert $cdiff]
        set wdiff [expr $wall - $::_naren_wallast]
        set wincr [proc_naren_convert $wdiff]
        set wtot  [expr $wall - $::_naren_wfirst]
        set wtime [proc_naren_convert $wtot]

        if {$show_cpu} {
          echo "TimeStamp - $prompt - Incr (cpu) - $wincr ($cincr) Total (cpu) - $wtime ($ctime) - $mem - $load - [date]"
        } else {
          echo "TimeStamp - $prompt - Incr - $wincr Total - $wtime - $mem - $load - [date]"
        }
    }
    set ::_naren_cpulast $cpu
    set ::_naren_wallast $wall
    set ::sh_new_variable_message true
    return ""
}

define_proc_attributes proc_time \
    -info "USER PROC: returns memory, incremental and total time, machine loading since the last call" \
    -define_args {
        {-include_cputime "Optional - Reports cputime also, not correct for multicore jobs" "" boolean optional}
        {-reset "Optional - Resets all timers, in case procedure was called earlier" "" boolean optional}
        { prompt "Optional message to be printed" "message string" string optional}
    }

proc proc_naren_convert {seconds} {

  set min [expr $seconds/60]
  set sec [expr $seconds%60]
  set hrs [expr $min/60]
  set rmin [expr $min%60]
  set tot [format "%02ih:%02im:%02is" $hrs $rmin $sec]
  return $tot

}

proc proc_machine_info {} {

  set naren_tmpdir /tmp
  redirect -var naren_dsk { exec df -kh $naren_tmpdir }
  set naren_ttmp [lindex [lindex [split $naren_dsk "\n"] 1] 1]
  set naren_avail [lindex [lindex [split $naren_dsk "\n"] 1] 3]
  set naren_pctav [lindex [lindex [split $naren_dsk "\n"] 1] 4]
  set naren_pctav [string trim ${naren_pctav} "%"]

  set naren_model "[exec grep -m 1 "model name" /proc/cpuinfo | sed s/.*:\s*//]"
  set naren_cores "[exec grep -c "processor" /proc/cpuinfo]"
  set naren_sockets "[exec grep "physical id" /proc/cpuinfo | sort -u | wc -l]"
  set naren_cache "[exec grep -m 1 "cache size" /proc/cpuinfo | sed s/.*:\s*//]"
  set naren_mhz   "[exec grep -m 1 "cpu MHz" /proc/cpuinfo | sed s/.*:\s*//]"
  if {[string is double -strict $naren_mhz]} {
    set naren_mhz "[format %.2f [expr {$naren_mhz/1000.0}]]Ghz"
  } else {
    set naren_mhz "${naren_mhz}Mhz"
  }

  #get free mem/swp of machine
  set naren_freecmd [exec free -g]
  regexp {Mem:\s+(\d+)\s+(\d+)\s+(\d+)} $naren_freecmd naren_match naren_mem naren_memu naren_memf
  regexp {Swap:\s+(\d+)\s+(\d+)\s+(\d+)} $naren_freecmd naren_match naren_swp naren_swpu naren_swpf
  
  echo "\n########################## MACHINE INFORMATION ##############################"
  echo "User:       [exec whoami]"
  echo "Host:       [info hostname]"
  echo "Date:       [date]"
  echo "OS:         [exec uname -srm]"
  echo "CPU:        Cores = $naren_cores : Sockets = $naren_sockets : Cache Size = $naren_cache : Freq = $naren_mhz : Model Name = $naren_model"
  echo "Memory:     Ram:  [format %5s "${naren_mem}GB"]\t(Free [format %5s "${naren_memf}GB"])"
  echo "\t    Swap: [format %5s "${naren_swp}GB"]\t(Free [format %5s "${naren_swpf}GB"])"
  echo "\t    ${naren_tmpdir}: [format %5s "${naren_ttmp}B"]\t(Free [format %5s "${naren_avail}B"])"
  echo "Dir:        [pwd]"
  echo "Version:    $::sh_product_version"
  if {${naren_pctav}>=90} { echo "WARNING: temp disk space (${naren_tmpdir}) is near FULL ${naren_pctav}% ..." }
  echo "##################### END MACHINE INFORMATION ###############################\n"
}

echo "\tproc_machine_info"
echo "\tproc_time"
