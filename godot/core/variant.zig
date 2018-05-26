const c = @import("c.zig");

pub const Variant = struct {
    const Self = this;
    variant: c.godot_variant,
};