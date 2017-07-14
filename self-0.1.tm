# slots contain either lambdas or values {slottype m and v respectively)
# slots with _ are used internally and should not be changed

namespace eval self {
    proc dispatch {obj state args} {
	set slotArgs [lassign $args slotName]
	if {$slotName eq "_state"} {
	    return $state
	}
	if {$slotName eq "clone"} {
	    if {[llength $slotArgs]!=1} {
		error "clone name"
	    }
	    interp alias {} $args {} self::dispatch $args [list parents* [list v $obj]]
	    return 
	}
	if {$slotName eq "slot"} {
	    if {[llength $slotArgs]==2} {
		# Value slot
		set type v
	    } elseif {[llength $slotArgs]==3} {
		# Method slot
		set type m
	    } else {
		error "slot name value | slot name args body"
	    }
	    set rest [lassign $slotArgs newSlotName]
	    dict set state $newSlotName [list $type  {*}$rest]
	    interp alias {} $obj {} self::dispatch $obj $state
	    return
	}
	set slot [dict get $state $slotName]
	set slotBody [lassign $slot slotType slotValOrArgs]
	if {$slotType eq "v"} {return $slotValOrArgs}
	if {$slotType eq "m"} {
  
	    return [apply [list [list self {*}$slotValOrArgs] {*}$slotBody] $obj {*}$slotArgs] 
	    
	}
	error "Unknown slot type $slotType" 
	
    }
    proc getSlot {obj state slot} {
	return [dict get $state slots $slot]
    }
}

interp alias {} Object {} self::dispatch Object [list parents* {v {}}]




