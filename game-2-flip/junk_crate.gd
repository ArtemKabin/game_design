extends CharacterBody2D

# The wall of space junk in Level 1 (group "pushable"), one long crate from the top wall
# to the bottom wall. The heavy cart shoves it along; it only slides to the left, towards
# the airlock, and stops at whatever is in the way (the wall, the player). On foot it is
# a solid block. See docs/decisions/0018.

# Called by the cart every physics frame while it drives into the crate.
# Returns false when the crate could not move the whole way: the cart has to stop.
func push(motion: Vector2) -> bool:
	if motion.x >= 0.0:
		return false  # junk goes left only
	var collision: KinematicCollision2D = move_and_collide(Vector2(motion.x, 0.0))
	return collision == null
