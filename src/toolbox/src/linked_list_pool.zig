const toolbox = @import("toolbox.zig");
pub fn LinkedListPool(comptime T: type, comptime N: usize) type {
    return struct {
        pool: [N]T = undefined,
        head: ?usize = null,
        tail: ?usize = null,
        next_free: usize = 0,
        next_pool_slot: usize = 1,
        len: usize = 0,

        const Self = @This();

        pub fn it(self: *Self) Iterator {
            return Iterator{ .index = self.head, .list = self };
        }
        pub fn it_reversed(self: *Self) ReverseIterator {
            return ReverseIterator{ .index = self.tail, .list = self };
        }

        pub const Iterator = struct {
            index: ?usize,
            list: *Self,
            pub fn next(self: *Iterator) ?usize {
                if (self.index) |index| {
                    const e = self.list.element(index);
                    self.index = e.next;
                    return index;
                }
                return null;
            }
        };
        pub const ReverseIterator = struct {
            index: ?usize,
            list: *Self,
            pub fn next(self: *ReverseIterator) ?usize {
                if (self.index) |index| {
                    const e = self.list.element(index);
                    self.index = e.prev;
                    return index;
                }
                return null;
            }
        };
        pub inline fn element(self: *Self, index: usize) *T {
            return &self.pool[index];
        }
        pub fn append(self: *Self, value: T) usize {
            const index: usize = self.next_free;
            if (index >= self.pool.len) {
                toolbox.panic("Reached max number of units: {}", .{self.pool.len});
            }
            const e = self.element(index);

            if (e.next) |next_free| {
                self.next_free = next_free;
            } else {
                self.next_free = self.next_pool_slot;
                self.next_pool_slot += 1;
            }

            e.* = value;

            e.next = null;
            e.prev = self.tail;
            if (self.tail) |tail| {
                self.pool[tail].next = index;
            }
            self.tail = index;

            if (self.head == null) {
                self.head = index;
            }

            self.len += 1;

            return index;
        }
        pub fn remove(self: *Self, to_remove_index: usize) void {
            const to_remove = self.element(to_remove_index);
            if (to_remove.prev) |prev| {
                self.pool[prev].next = to_remove.next;
            }
            if (to_remove.next) |next| {
                self.pool[next].prev = to_remove.prev;
            }

            const index = (@intFromPtr(to_remove) - @intFromPtr(&self.pool)) / @sizeOf(T);
            if (self.head.? == index) {
                self.head = to_remove.next;
            }
            if (self.tail.? == index) {
                self.tail = to_remove.prev;
            }
            to_remove.next = self.next_free;
            self.next_free = index;

            self.len -= 1;
        }
    };
}
