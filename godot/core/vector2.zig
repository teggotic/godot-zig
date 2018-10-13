const std = @import("std");

pub const Vector2 = struct {
    const Self = @This();
    x: f32,
    y: f32,

    pub fn new(x: f32, y: f32) Self {
        return Self {
            .x = x,
            .y = y
        };
    }

    pub fn copy(self: *const Self) Self {
        return Self.new(self.x, self.y);
    }

    pub fn add(self: *const Self, other: *const Self) Self {
        return Self.new(self.x + other.x, self.y + other.y);
    }
    
    pub fn sub(self: *const Self, other: *const Self) Self {
        return Self.new(self.x - other.x, self.y - other.y);
    }

    pub fn mul(self: *const Self, scalar: f32) Self {
        return Self.new(self.x * scalar, self.y * scalar);
    }

    pub fn equal(self: *const Self, other: *const Self) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn normalize(self: *Self) void {
        var l: f32 = self.x * self.x + self.y * self.y;
        if (l != 0) {
            self.x /= l;
            self.y /= l;
        }
    }

    pub fn normalized(self: *const Self) Self {
        var result = self.copy();
        result.normalize();
        return result;
    }

    pub fn distanceTo(self: *const Self, other: *const Self) f32 {
        var lx = self.x - other.x;
        var ly = self.y - other.y;
        return std.math.sqrt(lx * lx + ly * ly);
    }

    pub fn distanceSquaredTo(self: *const Self, other: *const Self) f32 {
        var lx = self.x - other.x;
        var ly = self.y - other.y;
        return lx * lx + ly * ly;
    }

    pub fn angleTo(self: *const Self, other: *const Self) f32 {
        return std.math.atan2(f32, self.cross(other), self.dot(other));
    }

    pub fn angleToPoint(self: *const Self, other: *const Self) f32 {
        return std.math.atan2(f32, self.y - other.y, self.x - other.x);
    }

    pub fn dot(self: *const Self, other: *const Self) f32 {
        return self.x * other.x + self.y * other.y;
    }

    pub fn cross(self: *const Self, other: *const Self) f32 {
        return self.x * other.y - self.y * other.x;
    }
};
