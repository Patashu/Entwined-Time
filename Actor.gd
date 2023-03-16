extends Sprite
class_name Actor

var actorname = ""
var pos = Vector2.ZERO
var state = {}
var broken = false
var powered = false
# -1 for grounded, 0 for falling, 1+ for turns of coyote time left
var airborne_state = -1
var strength = 0
var heaviness = 0
var durability = 0
