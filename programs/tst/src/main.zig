const std = @import("std");

inline fn syscall1(sys: usize, a: usize) void {
    asm volatile ("ecall"
        :
        : [number] "{x17}" (sys),
          [arg1] "{x10}" (a),
        : .{});
}

var buffer align(8) = [1]u8{0} ** 1024;

inline fn output() void {
    var i: usize = 0;
    while (true) {
        if (buffer[i] == '\x00') {
            break;
        }
        syscall1(1, buffer[i]);
        i += 1;
    }
}

export fn init() void {
    @memcpy(@as([*]u8, &buffer), "Hello!");
    // const msg = "Hello!";
    // for (0..msg.len) |i| {
    //     buffer[i] = msg[i];
    // }
    output();
}

// inline fn syscall2(sys: usize, a: usize, b: usize) void {
//     asm volatile ("ecall"
//         :
//         : [number] "{x17}" (sys),
//           [arg1] "{x10}" (a),
//           [arg2] "{x11}" (b),
//         : .{});
// }

// const stdout_writer = struct {
//     pub fn writeAll(bytes: []const u8) void {
//         syscall2(0, @intFromPtr(bytes.ptr), bytes.len);
//     }

//     fn drain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
//         // writeAll("Drain used\n");
//         // syscall1(1, w.end);
//         // syscall1(1, data.len);
//         // syscall1(1, splat);
//         _ = splat;
//         var consumed: usize = w.end;
//         if (w.end > 0) {
//             // syscall1(1, w.end);
//             syscall1(1, @intFromPtr(w.buffer.ptr));
//             writeAll(w.buffer[0..w.end]);
//             w.end = 0;
//         }
//         for (data) |slice| {
//             if (slice.len == 0) continue;
//             writeAll(slice);
//             consumed += slice.len;
//         }
//         return consumed;
//     }
// };

// var stdout_buffer: [1024]u8 = undefined;
// var stdout = std.Io.Writer{
//     .buffer = &stdout_buffer,
//     .vtable = &.{
//         .drain = stdout_writer.drain,
//     },
// };

// fn isPrime(n: u64) bool {
//     if (n < 2) return false;
//     if (n == 2) return true;
//     if (n % 2 == 0) return false;

//     var i: u8 = 3;
//     while (i * i <= n) : (i += 2) {
//         if (n % i == 0) return false;
//     }
//     return true;
// }

// var f: *const fn () callconv(.c) void = outputShit;

// export fn setFn(new: *const fn () callconv(.c) void) void {
//     f = new;
// }

// export fn getShit() [*]u8 {
//     return &buffer;
// }

// fn count() u64 {
//     var i: u64 = 0;
//     while (i < 1 << 32) {
//         i += 1;
//         std.mem.doNotOptimizeAway(i);
//     }
//     return i;
// }

// export fn init() u64 {
//     // return count();
// }
