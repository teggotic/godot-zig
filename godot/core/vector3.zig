const std = @import("std");

pub const Vector3 = struct {
    const Self = @This();
    x: f32,
    y: f32,
    z: f32,

    pub fn new(x: f32, y: f32, z: f32) Self {
        return Self {
            .x = x,
            .y = y,
            .z = z
        };
    }

    pub fn copy(self: *const Self) Self {
        return Self.new(self.x, self.y, self.z);
    }

    pub fn add(self: *const Self, other: *const Self) Self {
        return Self.new(self.x + other.x, self.y + other.y, self.z + other.z);
    }

    pub fn sub(self: *const Self, other: *const Self) Self {
        return Self.new(self.x - other.x, self.y - other.y, self.z - other.z);
    }

    pub fn mul(self: *const Self, scalar: f32) Self {
        return Self.new(self.x * scalar, self.y * scalar, self.z * scalar);
    }

    pub fn equal(self: *const Self, other: *const Self) bool {
        return self.x == other.x and self.y == other.y and self.z == other.z;
    }

    pub fn abs(self: *const Self) Self {
        return Self.new(std.math.fabs(self.x), std.math.fabs(self.y), std.math.fabs(self.z));
    }

    pub fn cross(self: *const Self, other: *const Self) Self {
        return Self.new(
            (self.y * other.z) - (self.z * other.y),
            (self.z * other.x) - (self.x * other.z),
            (self.x * other.y) - (self.y * other.x)
        );
    }

    pub fn length(self: *const Self) f32 {
        var x2 = self.x * self.x;
        var y2 = self.y * self.y;
        var z2 = self.z * self.z;
        return std.math.sqrt(x2 + y2 + z2);
    }

    pub fn lengthSquared(self: *const Self) f32 {
        var x2 = self.x * self.x;
        var y2 = self.y * self.y;
        var z2 = self.z * self.z;
        return x2 + y2 + z2;
    }

    pub fn distanceSquaredTo(self: *const Self, other: *const Self) f32 {
        return other.sub(self).length();
    }

    pub fn distanceTo(self: *const Self, other: *const Self) f32 {
        return other.sub(self).lengthSquared();
    }

    pub fn normalize(self: *Self) void {
        var l = self.length();
        if (l == 0) {
            self.x = 0;
            self.y = 0;
            self.z = 0;
        } else {
            self.x /= l;
            self.y /= l;
            self.z /= l;
        }
    }

    pub fn normalized(self: *const Self) Self {
        var result = self.copy();
        result.normalize();
        return result;
    }
};
