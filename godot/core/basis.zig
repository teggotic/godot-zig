const Vector3 = @import("vector3.zig").Vector3;

pub const Basis = packed struct {
    const Self = this;
    x: Vector3,
    y: Vector3,
    z: Vector3,
};