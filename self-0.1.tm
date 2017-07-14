# slots contain either lambdas or values {slottype m and v respectively}
# slots with _ are used internally and should not be changed

namespace eval self {
# cache method lookups as {slotName obj cachedSlotValue}
  variable cachedLookup {}
  proc dispatch {obj state args} {
    set slotArgs [lassign $args slotName]
    if {$slotName eq "_state"} {
      return $state
    }
    if {$slotName eq "clone"} {
      if {[llength $slotArgs]!=1} {
        error "clone name"
      }

      newObject $slotArgs $obj
      return 
    }
    if {[string index $slotName end] eq ":"} {
      variable cachedLookup
      set slotName [string range $slotName 0 end-1]

      if {[llength $slotArgs]==1} {
      # Value slot
        set type v
      } elseif {[llength $slotArgs]==2} {
      # Method slot
        set type m
      } else {
        error "$slotName: value | $slotName: name args body"
      }

      # invalidate cache
      if {$slotName eq "parents*"} {
      # inheritance tree change invalidate cache
        set cachedLookup {}
      } else {
      # invalidate cache for this slot
        dict unset cachedLookup $slotName
      }


      dict set state slots $slotName [list $type  {*}$slotArgs]
      interp alias {} $obj {} self::dispatch $obj $state
      return
    }
    if {[dict exists $state slots $slotName]} {
      set slotValue [dict get $state slots $slotName]
    } elseif {[findCachedSlot $obj $slotName] ne {}} {
      set slotValue [findCachedSlot $obj $slotName]
    } elseif {[dict exists $state slots parents*]} {
      set parents	[evalSlot $obj [dict get $state slots parents*]]
      set slotValue [findInheritedSlot $obj $parents $slotName]
    } 
    if {$slotValue eq {}} {
      error "Slot $obj $slotName not found" 
    }
    return [evalSlot $obj $slotValue $slotArgs]	
  }

  proc evalSlot {obj slotValue {slotArgs {}}} {
  # puts "Executing slot $slotName -> $slotValue"
    set slotBody [lassign $slotValue slotType slotValOrArgs]
    if {$slotType eq "v"} {return $slotValOrArgs}
    if {$slotType eq "m"} {	    
      return [apply [list [list self {*}$slotValOrArgs] {*}$slotBody] $obj {*}$slotArgs]    
    }
    error "Unknown slot type $slotType" 
  }

  proc newObject {name parent} {
    interp alias {} $name {} self::dispatch $name [list slots [list parents* [list v $parent]]]
  }

  proc findCachedSlot {obj slotName} {
    variable cachedLookup
    if {[dict exists $cachedLookup $obj $slotName]} {
      return [dict get $cachedLookup $obj $slotName]
    }
  }

  proc findInheritedSlot {obj parents slotName} {
    variable cachedLookup
    if {$parents eq {}} {
      return
    }
    set visited {}
    set tovisit $parents
    while {[llength $tovisit] > 0} {
      set tovisit [lassign $tovisit current]
      if {[lsearch $visited $current] > -1} continue
      if {[dict exists [$current _state] slots $slotName]} {
        set slotValue [dict get [$current _state] slots $slotName]
        dict set cachedLookup $slotName $obj $slotValue
        return $slotValue
      }
      lappend visited $current
      lappend tovisit {*}[$obj parents*]
    }
    return {}
  }
}


self::newObject Object {}







