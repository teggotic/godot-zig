const TypeId = @import("builtin").TypeId;
const TypeInfo = @import("builtin").TypeInfo;
const std = @import("std");

pub fn Array(comptime T: type, comptime size: usize) type {
    return [size]T;
}

pub fn hasField(comptime T: type, comptime name: []const u8) bool {
    comptime {
        if (getField(T, name)) |field| {
            return true;
        }
        return false;
    }
}

pub fn getField(comptime T: type, comptime name: []const u8) ?T {
    comptime { 
        if (@typeId(T) != TypeId.Struct) return null;
        for (@typeInfo(T).Struct.fields) |field| {
            if (std.mem.eql(u8, name, field.name)) {
                return @field(T, name);
            }
        }
        return null;
    }
}

pub fn getDef(comptime T: type, comptime name: []const u8) bool {
    comptime {
        if (@typeId(T) != TypeId.Struct) @compileError("T must be struct");
        for (@typeInfo(T).Struct.defs) |def| {
            if (std.mem.eql(u8, name, def.name)) {
                return true;
            }
        }
        return false;
    }
}

pub fn as(comptime T: type, t: var) ?*T {
    comptime {
        var current = @typeOf(t);
        if (current == T) {
            return t;
        }
        const Id = @typeId(current);
        if (Id == TypeId.Pointer) {
            const Info = @typeInfo(current);
            if (Info.Pointer.child == T) {
                return t;
           }
        }
        while (true) {
            var currentId: TypeId = @typeId(current);
            if (currentId == TypeId.Pointer) {
                const Info = @typeInfo(current);
                if (Info.Pointer.child.Parent == T) {
                    return &t.base;
                }
                break;
            } else {
                if (current.Parent == T) {
                    return &t.base;
                }
                break;
            }
        }
        @compileError("Does not inherit type T");
    }
}

pub fn callFn(comptime R: type, obj: var, name: []const u8, args: ...) R {
    return @noInlineCall(@field(obj, name), args);
}
