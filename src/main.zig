const std = @import("std");
const posix = std.posix;
const elf = std.elf;

const emu = @import("emu.zig");
const VM = emu.VM;

const allocator = std.heap.page_allocator;

pub fn main() !void {
    const page_size: u64 = 4096;
    const stack_size: u64 = page_size * 16;
    const base_addr: u64 = stack_size;

    const file = try std.fs.cwd().openFile("programs/tst/zig-out/lib/libtst.so", .{});
    defer file.close();

    const stat = try file.stat();
    const file_size = std.math.cast(usize, stat.size) orelse return error.FileTooBig;

    const file_bytes = try posix.mmap(
        null,
        (file_size + page_size - 1) & -%page_size,
        posix.PROT.READ,
        .{ .TYPE = .PRIVATE },
        file.handle,
        0,
    );
    defer posix.munmap(file_bytes);

    const eh = @as(*elf.Elf64_Ehdr, @ptrCast(file_bytes.ptr));
    if (!std.mem.eql(u8, eh.e_ident[0..4], elf.MAGIC)) return error.NotElfFile;
    if (eh.e_type != elf.ET.DYN) return error.NotDynamicLibrary;

    // Iterate over the program header entries to find out the
    // dynamic vector as well as the total size of the virtual memory.
    var memory_end: usize = 0;

    {
        var i: usize = 0;
        var ph_addr: [*]u8 = file_bytes.ptr + eh.e_phoff;
        while (i < eh.e_phnum) : ({
            i += 1;
            ph_addr += eh.e_phentsize;
        }) {
            const ph: *elf.Elf64_Phdr = @ptrCast(@alignCast(ph_addr));
            switch (ph.p_type) {
                elf.PT_LOAD => memory_end = @max(memory_end, ph.p_paddr + ph.p_memsz),
                else => {},
            }
        }
    }

    memory_end = (memory_end + page_size - 1) & -%page_size;
    memory_end += base_addr;

    const memory = try posix.mmap(
        null,
        memory_end,
        posix.PROT.READ | posix.PROT.WRITE,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );

    @memset(memory, 0);

    const binary = memory[base_addr..];
    var maybe_dynv: ?[*]usize = null;

    {
        var i: usize = 0;
        var ph_addr: [*]u8 = file_bytes.ptr + eh.e_phoff;
        while (i < eh.e_phnum) : ({
            i += 1;
            ph_addr += eh.e_phentsize;
        }) {
            const ph: *elf.Elf64_Phdr = @ptrCast(@alignCast(ph_addr));
            switch (ph.p_type) {
                elf.PT_LOAD => @memcpy(binary[ph.p_paddr..][0..ph.p_filesz], file_bytes[ph.p_offset..][0..ph.p_filesz]),
                elf.PT_DYNAMIC => maybe_dynv = @ptrCast(@alignCast(binary.ptr + ph.p_paddr)),
                else => {},
            }
        }
    }

    const dynv = maybe_dynv orelse return error.MissingDynamicLinkingInformation;

    var maybe_strings: ?[*:0]u8 = null;
    var maybe_syms: ?[*]elf.Elf64_Sym = null;

    {
        var i: usize = 0;
        while (dynv[i] != 0) : (i += 2) {
            const p = binary.ptr + dynv[i + 1];
            switch (dynv[i]) {
                elf.DT_STRTAB => maybe_strings = @ptrCast(p),
                elf.DT_SYMTAB => maybe_syms = @ptrCast(@alignCast(p)),
                else => {},
            }
        }
    }

    const strings = maybe_strings orelse return error.ElfStringSectionNotFound;
    const syms = maybe_syms orelse return error.ElfSymSectionNotFound;

    const sym_table_size = @intFromPtr(strings) - @intFromPtr(syms);
    const sym_count = sym_table_size / @sizeOf(elf.Elf64_Sym);

    var function_map: std.StringHashMapUnmanaged(u64) = .empty;
    for (syms[0..sym_count]) |sym| {
        if (sym.st_type() == elf.STT_FUNC) {
            const name = std.mem.sliceTo(strings[sym.st_name..], 0);
            const func_addr = base_addr + sym.st_value;
            try function_map.put(allocator, name, func_addr);
        }
    }

    var vm = VM{ .memory = memory, .pc = 0 };

    const func_addr = function_map.get("init") orelse return error.FunctionNotFound;

    vm.pc = @bitCast(func_addr);

    vm.setInt(.sp, base_addr);

    var timer = try std.time.Timer.start();
    try vm.eval();
    const elapsed = timer.read();
    std.debug.print("elapsed: {D}\n", .{elapsed});
}
