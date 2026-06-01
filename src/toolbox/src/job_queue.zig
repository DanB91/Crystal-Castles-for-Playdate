const toolbox = @import("toolbox.zig");
const std = @import("std");
pub fn JobQueue(comptime T: type) type {
    const QUEUE_SIZE = 4096;
    return struct {
        head: usize = 0,
        tail: usize = 0,
        queue: [QUEUE_SIZE]*T = undefined,
        mutex: Mutex = .{},

        entry_pool: [QUEUE_SIZE]T = undefined,
        next_free_entry: usize = 0,

        const Self = @This();
        pub fn make_queue_entry(self: *Self) *T {
            const result = self.entry_pool[self.next_free_entry];
            self.next_free_entry += 1;
            self.next_free_entry %= QUEUE_SIZE;
            return result;
        }

        pub fn enqueue(self: *Self, entry: *T) void {}
    };
}

pub const WaitQueueObject = struct {
    notify_handle: c_int = 0,
    wait_handle: c_int = 0,
};
pub const WaitQueueObject = c_int;
fn make_wait_queue_object_macos() WaitQueueObject {
    var fds = [2]std.c.fd_t{ 0, 0 };
    std.c.pipe(&fds);
}
