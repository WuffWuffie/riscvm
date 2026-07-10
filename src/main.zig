const std = @import("std");
const Io = std.Io;
const elf = std.elf;

const allocator = std.heap.page_allocator;

const emu = @import("emu.zig");

fn add(a: i32, b: i32) i32 {
    return a *% 69 +% b;
}

pub fn formatHex(value: i64, w: *Io.Writer) Io.Writer.Error!void {
    return w.print("{s}0x{X}", .{ if (value < 0) "-" else "", @abs(value) });
}

pub fn fmtHex(value: i64) std.fmt.Alt(i64, formatHex) {
    return .{ .data = value };
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    _ = &gpa;
    _ = &io;

    const cwd = Io.Dir.cwd();
    const file_bytes = try cwd.readFileAllocOptions(
        io,
        "zig-out/lib/libtst.so",
        gpa,
        .unlimited,
        .fromByteUnits(emu.page_size),
        null,
    );
    defer gpa.free(file_bytes);

    const eh: *const elf.Elf64.Ehdr = @ptrCast(file_bytes.ptr);
    if (@as(u32, @bitCast(eh.ident.magic)) != @as(u32, @bitCast(@as(*const [4]u8, elf.MAGIC).*))) return error.NotElfFile;
    if (eh.type != .DYN) return error.NotDynamicLibrary;

    const memory = try gpa.alignedAlloc(u8, .fromByteUnits(emu.page_size), 16 * 1024 * 1024);
    defer gpa.free(memory);

    const memory_base = 1024 * 1024;
    const stack_base = memory_base / 2;

    const phdr_ptr: [*]const elf.Elf64.Phdr = @ptrCast(@alignCast(file_bytes.ptr + eh.phoff));
    const phdrs = phdr_ptr[0..eh.phnum];

    for (phdrs) |phdr| {
        if (phdr.type == .LOAD and phdr.flags.X) {
            const exec_bytes = file_bytes[phdr.offset .. phdr.offset + phdr.filesz];
            const insts: []const u32 = @ptrCast(@alignCast(exec_bytes));
            for (insts) |raw| {
                const inst = emu.Inst{ .raw = raw };
                std.debug.print("    {f}\n", .{inst});
            }
        }

        if (phdr.type == .LOAD) {
            const target_vaddr = phdr.vaddr;

            const file_data = file_bytes[phdr.offset..][0..phdr.filesz];
            @memcpy(memory[memory_base + target_vaddr ..][0..file_data.len], file_data);
            @memset(memory[memory_base + target_vaddr + phdr.filesz ..][0 .. phdr.memsz - phdr.filesz], 0);
        }
    }

    const shdrs = @as([*]const elf.Elf64.Shdr, @ptrCast(@alignCast(file_bytes.ptr + eh.shoff)))[0..eh.shnum];

    var syms: []const elf.Elf64.Sym = &.{};
    var strtab: []const u8 = &.{};

    for (shdrs) |shdr| {
        if (shdr.type == .DYNSYM) {
            const syms_ptr = @as([*]const elf.Elf64.Sym, @ptrCast(@alignCast(file_bytes.ptr + shdr.offset)));
            const num_syms = shdr.size / @sizeOf(elf.Elf64.Sym);
            syms = syms_ptr[0..num_syms];

            const str_shdr = shdrs[shdr.link];
            strtab = file_bytes[str_shdr.offset .. str_shdr.offset + str_shdr.size];
            break;
        }
    }

    var sym_vaddr: usize = undefined;

    for (syms) |sym| {
        if (sym.name == 0) continue;

        var end: usize = sym.name;
        while (end < strtab.len and strtab[end] != 0) : (end += 1) {}
        const sym_name = strtab[sym.name..end];

        if (sym.info.type == .FUNC and std.mem.eql(u8, sym_name, "init")) {
            sym_vaddr = sym.value;
            break;
        }
    }

    var vm = emu.VM{ .memory = memory, .pc = 0, .base = memory_base };
    vm.set(u64, .sp, stack_base);
    try vm.run(memory_base + sym_vaddr);
}
