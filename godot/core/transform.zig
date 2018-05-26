const Vector3 = @import("vector3.zig").Vector3;

pub const Transform = struct {
    const Self = this;
    basis: Basis,
    origin: Vector3,
};