const Vector2 = @import("vector2.zig").Vector2;

pub const Rect2 = struct {
    const Self = this;
    pos: Vector2,
    size: Vector2,
};