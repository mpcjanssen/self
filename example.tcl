tcl::tm::path add .
package require self

# create a Point object.
Object clone Point

# add a to_s slot to display information of the object
Object to_s: {} {
    return "[self]"
}

# add x and y slots for the point, notice that these slots cannot be called for now.
Point x: {args} {error "abstract slot, override in clone"}
Point y: {args} {error "abstract slot, override in clone"} 

# extend default behavior from parent (Object)
Point to_s: {} {
    return "id: [next] ([self x],[self y])"
    # Here next will search for a slot named to_s in the parents of the implementor of the current method (Point)
    # finding the Object slot to_s and the execute it in the context of the receiver (which will be a clone of Point) 
}

# define a point factory
Point create: {name x y} {
    self clone $name
    $name x: $x
    $name y: $y
}

# clone a Point
Point clone p1

# to_s will fail because the x and y slots in Point are called
catch {p1 to_s} err
puts $err

# use the Point factory which will define x and y slots
Point create p1 0 0

# to_s will now work
puts [p1 to_s]


Object clone A
A test: args {return}

A clone a
a test

A clone debug
debug test: {args} {puts "called test with $args"; next}

a parents*: {debug}
a test 1 2 3