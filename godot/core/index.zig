pub use @import("vector2.zig");
pub use @import("rid.zig");
pub use @import("transform_2d.zig");
pub use @import("string.zig");

const TypeInfo = @import("builtin").TypeInfo;
const util = @import("util.zig");
const c = @import("c.zig");
const std = @import("std");
const godot = @import("../index.zig");

var memoryBuffer: [3000]u8 = undefined;

const CreateFn = extern fn(?&c.godot_object, ?&c_void) ?&c_void;
const DestroyFn = extern fn(?&c.godot_object, ?&c_void, ?&c_void) void;
const FreeFn = extern fn (?&c_void) void;
const ConstructorFn = extern fn() ?&c.godot_object;

pub fn GodotFns(comptime T: type) type {
    return extern struct {
        extern fn create(obj: ?&c.godot_object, data: ?&c_void) ?&c_void {
            var t: &T = std.heap.c_allocator.create(T) catch std.os.abort();
            t.base = @ptrCast(&T.Parent, @alignCast(@alignOf(T.Parent), ??obj));
            t.init();
            return @ptrCast(&c_void, t);
        }

        extern fn destroy(obj: ?&c.godot_object, method_data: ?&c_void, data: ?&c_void) void {
            std.heap.c_allocator.destroy(@ptrCast(&T, @alignCast(@alignOf(T), ??data)));
        }
    };
}

pub const GodotApi = struct {
    const Self = this;
    const NativeApi = c.godot_gdnative_ext_nativescript_api_struct;
    const CoreApi = c.godot_gdnative_core_api_struct;
    heap: std.heap.FixedBufferAllocator,
    native: ?&NativeApi,
    core: ?&CoreApi, 
    handle: ?&c_void,

    fn new() Self {
        return Self {
            .heap = std.heap.FixedBufferAllocator.init(memoryBuffer[0..]),
            .native = null,
            .core = null,
            .handle = null
        };
    }

    fn getBaseClassName(comptime T: type) []const u8 {
        if (util.hasField(T, "Parent")) |field| {
            return @typeName(@typeOf(field));
        }
        return "";
    }

    pub fn initNative(self: &Self, handle: &c_void) void {
        self.handle = handle;
    }

    pub fn get_method(self: &Self, classname: &const u8, method: &const u8) ?&c.godot_method_bind {
        if (self.core) |core| {
            return (??(core).godot_method_bind_get_method)(classname, method);
        } else {
            std.debug.warn("Core API hasn't been initialized!\n");
        }
        return null;
    }

    pub fn get_constructor(self: &Self, classname: &const u8) ?ConstructorFn {
        if (self.core) |core| {
            var result = (??(core).godot_get_class_constructor)(classname);
            return @ptrCast(ConstructorFn, result);
        } else {
            std.debug.warn("Core API hasn't been initialized!\n");
        }
        return null;
    }

    pub fn newObj(self: &Self, comptime T: type, constructor: ConstructorFn) &T {
        return @ptrCast(&T, @alignCast(@alignOf(&T), constructor()));
    }

    pub fn registerClass(self: &Self, comptime T: type) !void {
        const Name = @typeName(T);
        const BaseName = getBaseClassName(T);

        var name = try std.cstr.addNullByte(&self.heap.allocator, Name);
        defer self.heap.allocator.free(name);
        var base = try std.cstr.addNullByte(&self.heap.allocator, BaseName);
        defer self.heap.allocator.free(base);
        
        const Fns = GodotFns(T);
        const cfn: ?CreateFn = Fns.create;
        var createFunc = c.godot_instance_create_func { 
            .create_func = cfn, 
            .method_data = null, 
            .free_func = null
        };
        const dfn: ?DestroyFn = Fns.destroy;
        var destroyFunc = c.godot_instance_destroy_func {
            .destroy_func = dfn,
            .method_data = null,
            .free_func = null,
        };

        var cname: ?&const u8 = &name[0];
        var cbase: ?&const u8 = &base[0];
        if (self.native) |native| {
            (??(native).godot_nativescript_register_class)(self.handle, cname, cbase, createFunc, destroyFunc);
        } else {
            std.debug.warn("NativeScript API hasn't been initialized!\n");
        }
        // TODO: Register every function that is `pub` to Godot
        // TODO: Look at T.Inspector const and register all fields with Godot Inspector
    }

    pub fn registerMethod(self: &Self, comptime T: type, name: &const u8) void {
        // TODO: Test if method name is godot built-in
        // ready, init, process, physicsProcess, etc.
        // Turn method name into godot built-in version
        // ready -> _ready
        // init -> _init
        // process -> process
        // physicsProcess -> _physics_process
    }
};

pub var api: GodotApi = GodotApi.new();

extern fn godot_gdnative_init(options: &c.godot_gdnative_init_options) void {
    var api = options.api_struct;
    var i = 0;
    while (i < api.num_extensions) {
        switch (api.extensions[i].type) {
            c.GDNATIVE_EXT_NATIVESCRIPT => {
                var nativeApi = @ptrCast(&c.godot_gdnative_ext_nativescript_api_struct, api.extensions[i]);
                api.native = nativeApi;
            },
            else => {}
        }
        i += 1;
    }
}

extern fn godot_nativescript_init(handle: &c_void) void {
    api.handle = handle;
}

const Derp = struct {
    const Parent = godot.Node2D;
    base: &Parent,
    tmp: u8,
};

test "register class" {
    const Obj = struct {
        b: i32,
    };

    const Test = struct {
        const Self = this;
        const Parent = godot.Node2D;
        base: &Parent,
        hi: i32,

        fn init(self: &Self) void {
        }
    };

    var r: ?Derp = null;
    var v: &c_void = @ptrCast(&c_void, &r);
    var r2 = @ptrCast(&Derp, @alignCast(@alignOf(&Derp), v)).*;

    var resource: &godot.Resource = godot.Resource.new();
    //_ = godot.Resource.getPath(resource);

    try api.registerClass(Test);
}