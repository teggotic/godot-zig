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

pub const Options = c.godot_gdnative_init_options;
pub const Handle = c_void;

const WrapperFn = extern fn(?&c.godot_object, ?&c_void, ?&c_void, c_int, ?&?&c.godot_variant) c.godot_variant;
const CreateFn = extern fn(?&c.godot_object, ?&c_void) ?&c_void;
const DestroyFn = extern fn(?&c.godot_object, ?&c_void, ?&c_void) void;
const FreeFn = extern fn (?&c_void) void;
const ConstructorFn = extern fn() ?&c.godot_object;

fn GodotWrapper(comptime T: type) type {
    return extern struct { 
        extern fn wrapped(obj: ?&c.godot_object, data: ?&c_void, userdata: ?&c_void, num: c_int, cargs: ?&?&c.godot_variant) c.godot_variant {
            var result: c.godot_variant = undefined;
            // TODO: Figure out how to turn array into varargs while casting each
            // argument into the proper type for the function call
            // Refer to how godot_cpp does this.
            const Info = @typeInfo(T);
            const Args = Info.Fn.args;
            var args = (??cargs)[0..usize(num)];
            var func = @ptrCast(T, data);
            switch (Args.len) {
                0 => {
                    _ = func();
                },
                1 => {
                    // TODO: godot_variant can't directly be casted
                    // If the variant is an object use godot_nativescript_get_userdata
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    _ = func(arg0);
                },
                2 => { 
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    _ = func(arg0, arg1);
                },
                3 => {
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    var arg2 = @ptrCast(Args[2].arg_type, @alignCast(@alignOf(Args[2].arg_type), args[2]));
                    _ = func(arg0, arg1, arg2);
                },
                4 => { 
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    var arg2 = @ptrCast(Args[2].arg_type, @alignCast(@alignOf(Args[2].arg_type), args[2]));
                    var arg3 = @ptrCast(Args[3].arg_type, @alignCast(@alignOf(Args[3].arg_type), args[3]));
                    _ = func(arg0, arg1, arg2, arg3);
                },
                5 => { 
                    var arg0 = @ptrCast(Args[0].arg_type, @alignCast(@alignOf(Args[0].arg_type), args[0]));
                    var arg1 = @ptrCast(Args[1].arg_type, @alignCast(@alignOf(Args[1].arg_type), args[1]));
                    var arg2 = @ptrCast(Args[2].arg_type, @alignCast(@alignOf(Args[2].arg_type), args[2]));
                    var arg3 = @ptrCast(Args[3].arg_type, @alignCast(@alignOf(Args[3].arg_type), args[3]));
                    var arg4 = @ptrCast(Args[4].arg_type, @alignCast(@alignOf(Args[4].arg_type), args[4]));
                    _ = func(arg0, arg1, arg2, arg3, arg4);
                },
                else => {}
            }
            return result;
        }
    };
}

fn GodotFns(comptime T: type) type {
    return extern struct {
        extern fn create(obj: ?&c.godot_object, data: ?&c_void) ?&c_void {
            var t: &T = std.heap.c_allocator.create(T) catch std.os.abort();
            t.base = @ptrCast(&T.Parent, @alignCast(@alignOf(T.Parent), ??obj));
            if (util.hasField(T, "init")) {
                t.init();
            }
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
    handle: ?&Handle,

    fn new() Self {
        return Self {
            .heap = std.heap.FixedBufferAllocator.init(memoryBuffer[0..]),
            .native = null,
            .core = null,
            .handle = null
        };
    }

    fn getBaseClassName(comptime T: type) []const u8 {
        if (util.getField(T, "Parent")) |field| {
            return @typeName(@typeOf(field));
        }
        return "";
    }

    fn getFns(comptime T: type) []FnInfo {
        comptime {
            const Info = @typeInfo(T);
            var num: usize = 0;
            // First get the number of functions so we can
            // define a const-sized array
            for (Info.Struct.defs) |def| {
                if (def.is_pub) {
                    switch (def.data) {
                        TypeInfo.Definition.Data.Fn => |fndef| {
                            if (fndef.is_export) {
                                num += 1;
                            }
                        },
                        else => {},
                    }
                }
            }
            
            var result: [num]FnInfo = []FnInfo{} ** num;
            var i: usize = 0;
            for (Info.Struct.defs) |def| {
                if (def.is_pub) {
                    switch (def.data) {
                        TypeInfo.Definition.Data.Fn => |fndef| {
                            if (fndef.is_export) {
                                result[i].t = @typeOf(@field(T, def.name));
                                result[i].ptr = @ptrToInt(@field(T, def.name));
                                result[i].name = def.name;
                                i += 1;
                            }
                        },
                        else => {}
                    }
                }
            }

            return result;
        } 
    }

    /// This needs to be called in `export godot_nativescript_init(handle: &c_void) void`
    pub fn initNative(self: &Self, handle: &Handle) void {
        self.handle = handle;
    }

    /// This needs to be called in `export godot_gdnative_init(options: &godot.Options) void`
    pub fn initCore(self: &Self, options: &Options) void {
        api.core = options.api_struct;
        var i = 0;
        while (i < api.core.num_extensions) {
            switch (api.core.extensions[i].type) {
                c.GDNATIVE_EXT_NATIVESCRIPT => {
                    var nativeApi = @ptrCast(&c.godot_gdnative_ext_nativescript_api_struct, api.extensions[i]);
                    api.native = nativeApi;
                },
                    else => {}
            }
            i += 1;
        }
    }

    pub fn getMethod(self: &Self, classname: &const u8, method: &const u8) ?&c.godot_method_bind {
        if (self.core) |core| {
            return (??(core).godot_method_bind_get_method)(classname, method);
        } else {
            std.debug.warn("Core API hasn't been initialized!\n");
        }
        return null;
    }

    pub fn getConstructor(self: &Self, classname: &const u8) ?ConstructorFn {
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

    pub fn registerClass(self: &Self, comptime T: type) void {
        const Name = @typeName(T);
        const BaseName = getBaseClassName(T);
        
        // TODO: Tell user that we ran into an error before aborting
        var name = std.cstr.addNullByte(&self.heap.allocator, Name) catch std.os.abort();
        defer self.heap.allocator.free(name);
        var base = std.cstr.addNullByte(&self.heap.allocator, BaseName) catch std.os.abort();
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

    pub fn registerMethod(self: &Self, comptime F: type, classname: &const u8, methodname: &const u8, func: F) void {
        var attributes = c.godot_method_attributes {
            // TODO: Support different method attributes
            .rpc_type = (c.godot_method_rpc_mode)(c.GODOT_METHOD_RPC_MODE_DISABLED)
        };
        
        // create a wrapper function
        const Wrapper = GodotWrapper(F);
        const wrapped: ?WrapperFn = Wrapper.wrapped;
    
        var mfn: ?&const c_void = @ptrCast(&const c_void, func);
        var data = c.godot_instance_method {
            .method = wrapped,
            .method_data = mfn, 
            .free_func = null,
        };

        if (self.native) |native| {
            (??(native).godot_nativescript_register_method)(self.handle, classname, methodname, attributes, data);
        } else {
            std.debug.warn("NativeScript API hasn't been initialized!\n");
        }
    }
};

pub var api: GodotApi = GodotApi.new();

test "register class" {
    const Test = struct {
        const Self = this;
        const Parent = godot.Node2D;
        base: &Parent,
        hi: i32,

        fn init(self: &Self) void {
        }

        fn derp() void {
        }
    };

    api.registerClass(Test);
    api.registerMethod(@typeOf(Test.init), c"Test", c"init", Test.init);
    api.registerMethod(@typeOf(Test.derp), c"Test", c"derp", Test.derp);
}
