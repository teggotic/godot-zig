const std = @import("std");
const Vector3 = @import("vector3.zig").Vector3;

pub const AABB = struct {
    const Self = this;
    position: Vector3,
    size: Vector3,
};