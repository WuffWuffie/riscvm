const std = @import("std");

fn syscall2(number: u64, arg1: u64, arg2: u64) u64 {
    return asm volatile ("ecall"
        : [ret] "={x10}" (-> u64),
        : [number] "{x17}" (number),
          [arg1] "{x10}" (arg1),
          [arg2] "{x11}" (arg2),
        : .{ .memory = true });
}

fn debugWrite(msg: []const u8) void {
    _ = syscall2(0, @intFromPtr(msg.ptr), msg.len);
}

fn isPrime(n: u64) bool {
    if (n <= 1) return false;
    if (n <= 3) return true;
    if (n % 2 == 0 or n % 3 == 0) return false;

    var i: u64 = 5;
    while (i * i <= n) : (i += 6) {
        if (n % i == 0 or n % (i + 2) == 0) return false;
    }

    return true;
}

pub export fn init() void {
    for (0..1024) |i| {
        if (!isPrime(i)) continue;
        var buf: [4096]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "prime: {}\n", .{i}) catch @trap();
        debugWrite(msg);
    }
}

export fn add(a: i64, b: i64) i64 {
    return a +% b;
}

export fn mul(a: i64, b: i64) i64 {
    return a *% b;
}
