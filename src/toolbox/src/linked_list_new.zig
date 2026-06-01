const toolbox = @import("toolbox.zig");
pub fn LinkedListPool(comptime T: type, comptime next_node_field_name: []const u8) type {
    return struct {
        head: ?*LinkedListNode = null,
        tail: ?*LinkedListNode = null,
        free_list: ?*LinkedListNode = null,

        arena: *toolbox.Arena,

        const Self = @This();

        pub fn add(self: *Self) *T {}

        pub fn remove(self: *Self, to_remove: *T) void {}

        pub fn iterator() Iterator {}

        pub const Iterator = struct {
            pub fn next(self: *Iterator) ?*T {}
        };
    };
}

pub const LinkedListNode = struct {
    next: ?*LinkedListNode = null,
};
