test "register class" {
    const core = @import("index.zig");
    const godot = @import("../index.zig");
    const Test = struct {
        const Self = @This();
        const Parent = godot.Node2D;
        base: *Parent,
        hi: i32,

        fn init(self: *Self) void {
        }

        fn derp() void {
        }
    };

    core.api.registerClass(Test);
    core.api.registerMethod(@typeOf(Test.init), c"Test", c"init", Test.init);
    core.api.registerMethod(@typeOf(Test.derp), c"Test", c"derp", Test.derp);
}
