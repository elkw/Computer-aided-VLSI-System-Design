if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name lib_max\
   -timing\
    [list ${::IMEX::libVar}/mmmc/slow.lib\
    ${::IMEX::libVar}/mmmc/sram_256x8_slow_syn.lib\
    ${::IMEX::libVar}/mmmc/sram_512x8_slow_syn.lib\
    ${::IMEX::libVar}/mmmc/sram_4096x8_slow_syn.lib]\
   -si\
    [list ${::IMEX::libVar}/mmmc/slow.cdB]
create_rc_corner -name RC_corner\
   -cap_table ${::IMEX::libVar}/mmmc/tsmc013.capTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -qx_tech_file ${::IMEX::libVar}/mmmc/RC_corner/icecaps_8lm.tch
create_delay_corner -name Delay_Corner_max\
   -library_set lib_max\
   -rc_corner RC_corner
create_constraint_mode -name func_mode\
   -sdc_files\
    [list ${::IMEX::dataVar}/mmmc/modes/func_mode/func_mode.sdc]
create_analysis_view -name av_func_mode_max -constraint_mode func_mode -delay_corner Delay_Corner_max -latency_file ${::IMEX::dataVar}/mmmc/views/av_func_mode_max/latency.sdc
set_analysis_view -setup [list av_func_mode_max] -hold [list av_func_mode_max]
