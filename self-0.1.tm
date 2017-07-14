# slots contain lambdas with an implicit self

namespace eval self {
	proc dispatch {obj state args} {
		set args [lassign $args slotName]
		if {$slotName eq "_state"} {
		     return $state
		}
                if {$slotName eq "clone"} {
			if {[llength $args]!=1} {
				error "clone name"
			}
			interp alias {} $args {} self::dispatch $args [list parents* [list v $obj]]
			return 
                }
		set slot [dict get $state $slotName]
		set slotBody [lassign $slot slotType]
		if {$slotType eq "v"} {return $slotBody}
		error "Unknown slot type $slotType" 
		

		
        }
	proc getSlot {obj state slot} {
		return [dict get $state slots $slot]
	}
}

interp alias {} Object {} self::dispatch Object [list parents* {v {}}]




