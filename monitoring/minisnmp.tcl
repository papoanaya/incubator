#!/opt/bin/tclsh
#sysDescr.0 = STRING: 
#sysObjectID.0 = OID: enterprises
#sysUpTimeInstance = Timeticks: (195646) 0:32:36.46
#sysContact.0 = STRING: 
#sysName.0 = STRING: Chubby
#sysLocation.0 = STRING: 
#ifNumber.0 = INTEGER: 1
#ifIndex.1 = INTEGER: 1
#ifDescr.1 = STRING: wlan0
#ifOperStatus.1 = INTEGER: up(1)
#ifInOctets.1 = Counter32: 1521964
#ifInUcastPkts.1 = Counter32: 6215
#ifInDiscards.1 = Counter32: 0
#ifInErrors.1 = Counter32: 0
#ifOutOctets.1 = Counter32: 715578
#ifOutUcastPkts.1 = Counter32: 4066
#ifOutDiscards.1 = Counter32: 0
#ifOutErrors.1 = Counter32: 0
#hrSystemUptime.0 = Timeticks: (201139) 0:33:31.39

# Test Constants

set GREEN green
set YELLOW yellow
set RED red

set HOSTTAG "minisnmp"
set COLUMN "minisnmp"

set hl_fp  [open "|$env(XYMONHOME)/bin/xymongrep $HOSTTAG"]

# BB Global Variablesn
set pref_run_log  "$env(BBTMP)/$env(MACHINE).minisnmp.data"
set bbtest  "minisnmp"
set color  $GREEN
##set status  "$bbtest OK"

set hl_string [gets $hl_fp]

while {![eof $hl_fp]} {
    set status  "$bbtest OK"
    set DATA  ""
    set hl_list [split $hl_string " "]
    set address [string trim [lindex $hl_list 0]]
 
    set machine [string trim [lindex $hl_list 1]]
    set walk_fp [open "|/opt/bin/snmpwalk -Os -c public -v1 $address"]

    while { ![eof $walk_fp] } {
        set line [gets $walk_fp]
        set valuelist [split $line "="]
 
    #compare the key
    ##puts [format ":%s:%s:" [lindex $valuelist 0] [lindex $valuelist 1]]
    
        if {[string equal "ifDescr.1 " [lindex $valuelist 0]]} {
	    set dummy [split [lindex $valuelist 1] ":" ]
            set ifaceDescr [string trim [lindex $dummy 1]]
        } elseif {[string equal "ifOperStatus.1 " [lindex $valuelist 0]]} {
	    if {[llength [regexp "up" [lindex $valuelist 1]]]} {
	        set color $GREEN
	        set status "$bbtest OK"
	    } else {
	        set color $RED
	        set status "$bbtest NOK"
	    }
        } elseif {[string equal "ifInOctets.1 " [lindex $valuelist 0]]} {
	    set ifIn [string trim [lindex [split [lindex $valuelist 1] ":" ] 1 ]]
        } elseif {[string equal "ifOutOctets.1 " [lindex $valuelist 0]]} {
	    set ifOut [string trim [lindex [split [lindex $valuelist 1] ":" ] 1]]
        }
    }
	
    set DATA [format "Interface: %s\nInBytes: %d\nOutBytes: %d\n"  $ifaceDescr $ifIn $ifOut]

    close $walk_fp       

#send to hobbit
    set report_fp  [open "|/bin/date"]

    set report_date [gets $report_fp]

    close $report_fp

####puts "$env(BB) $env(BBDISP) \'status $env(MACHINE).$bbtest $color $report_date\n\n$DATA\'\n"
##set result_fp  [open "|$env(BB) $env(BBDISP) \'status $env(MACHINE).$bbtest $color $report_date\n\n$DATA\' \n"]

    set result_fp  [open "|$env(BB) $env(BBDISP) \"status\ $machine.$bbtest\ $color\ $report_date\n\n$DATA\"\n"]
    close $result_fp
    set hl_string [gets $hl_fp]
}

exit 0
