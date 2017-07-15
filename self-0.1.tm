# slots contain either lambdas or values {slottype m and v respectively}
# slots with _ are used internally and should not be changed

namespace eval self {
  variable cachedLookup {}
  proc dispatch {obj state args} {
    variable cachedLookup
    set slotArgs [lassign $args slotName]
    if {$slotName eq "_state"} {
      return $state
    }
    if {$slotName eq "clone"} {
      if {[llength $slotArgs]!=1} {
        error "clone name"
      }
      newClone $slotArgs $obj
      return 
    }
    if {$slotName eq "copy"} {
      if {[llength $slotArgs]!=1} {
        error "copy name"
      }
      newCopy $slotArgs $obj
      return 
    }
    if {[string index $slotName end] eq ":"} {
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
      set implementor $obj 
      set slotValue [dict get $state slots $slotName]
    } elseif {[dict exists $state slots parents*]} {
      lassign [findInheritedSlot $obj $slotName] implementor slotValue
    } 
    if {$slotValue eq {}} {
      error "Slot $obj $slotName not found" 
    }
    return [evalSlot $obj $implementor $slotValue $slotArgs]	
  }

  proc dispatchNext {self implementor slotName args} {
    lassign [findInheritedSlot $implementor $slotName] implementor slotValue 
    if {$slotValue eq {}} {
      error "Slot $slotName not found in parents of $implementor"
    }
    return [evalSlot $self $implementor $slotValue $args]
  }

  proc evalSlot {obj implementor slotValue {slotArgs {}}} {
  # puts "Executing slot $slotName -> $slotValue"
    set slotBody [lassign $slotValue slotType slotValOrArgs]
    if {$slotType eq "v"} {return $slotValOrArgs}
    if {$slotType eq "m"} {	    
      set currentNext [interp alias {} next]
      interp alias {} next {} self::dispatchNext $obj $implementor
      set result [apply [list [list self {*}$slotValOrArgs] {*}$slotBody] $obj {*}$slotArgs]    
      interp alias {} next {} $currentNext
      return $result
    }
    error "Unknown slot type $slotType" 
  }

  proc newClone {name parent} {
    interp alias {} $name {} self::dispatch $name [list slots [list parents* [list v $parent]]]
  }

  proc newCopy {name parent} {
    interp alias {} $name {} self::dispatch $name [$parent _state]
  }

  proc findInheritedSlot {startObj slotName} {
    variable cachedLookup
    if {[dict exists $cachedLookup $slotName $startObj]} {
       return [dict get $cachedLookup $slotName $startObj]
    }

    set state [$startObj _state]
    if {[dict exists $state slots parents*]} {
      set parents	[evalSlot $startObj $startObj [dict get $state slots parents*]]
    } else {
      return [list {} {}]
    }
    set visited {}
    set tovisit $parents
    while {[llength $tovisit] > 0} {
      set tovisit [lassign $tovisit current]
      if {[lsearch $visited $current] > -1} continue
      if {[dict exists [$current _state] slots $slotName]} {
        set slotValue [dict get [$current _state] slots $slotName]
        dict set cachedLookup $slotName $startObj [list $current $slotValue]
        return [list $current $slotValue]
      }
      lappend visited $current
      lappend tovisit {*}[$current parents*]
    }
    return [list {} {}]
  }
}

interp alias {} next {} error "Not in method scope"
self::newClone Object {}







