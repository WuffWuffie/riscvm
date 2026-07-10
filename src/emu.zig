const std = @import("std");
const Io = std.Io;

const dis = @import("dis.zig");
const decode = @import("decode.zig");

const debug = false;

pub const Reg = enum(u5) {
    x0,
    ra,
    sp,
    gp,
    tp,
    t0,
    t1,
    t2,
    s0,
    s1,
    a0,
    a1,
    a2,
    a3,
    a4,
    a5,
    a6,
    a7,
    s2,
    s3,
    s4,
    s5,
    s6,
    s7,
    s8,
    s9,
    s10,
    s11,
    t3,
    t4,
    t5,
    t6,

    pub const zero: Reg = .x0; // Hard-wired zero
    pub const x1: Reg = .ra; // Return address
    pub const x2: Reg = .sp; // Stack pointer
    pub const x3: Reg = .gp; // Global pointer
    pub const x4: Reg = .tp; // Thread pointer
    pub const fp: Reg = .s0; // Frame pointer (s0)

    // Return value / Argument
    pub const x10: Reg = .a0;
    pub const x11: Reg = .a1;
    // Argument
    pub const x12: Reg = .a2;
    pub const x13: Reg = .a3;
    pub const x14: Reg = .a4;
    pub const x15: Reg = .a5;
    pub const x16: Reg = .a6;
    pub const x17: Reg = .a7;

    // Saved register
    pub const x8: Reg = .s0;
    pub const x9: Reg = .s1;
    pub const x18: Reg = .s2;
    pub const x19: Reg = .s3;
    pub const x20: Reg = .s4;
    pub const x21: Reg = .s5;
    pub const x22: Reg = .s6;
    pub const x23: Reg = .s7;
    pub const x24: Reg = .s8;
    pub const x25: Reg = .s9;
    pub const x26: Reg = .s10;
    pub const x27: Reg = .s11;

    // Temporary
    pub const x5: Reg = .t0;
    pub const x6: Reg = .t1;
    pub const x7: Reg = .t2;
    pub const x28: Reg = .t3;
    pub const x29: Reg = .t4;
    pub const x30: Reg = .t5;
    pub const x31: Reg = .t6;

    pub const f0: Reg = .x0;
    pub const f1: Reg = .x1;
    pub const f2: Reg = .x2;
    pub const f3: Reg = .x3;
    pub const f4: Reg = .x4;
    pub const f5: Reg = .x5;
    pub const f6: Reg = .x6;
    pub const f7: Reg = .x7;
    pub const f8: Reg = .x8;
    pub const f9: Reg = .x9;
    pub const f10: Reg = .x10;
    pub const f11: Reg = .x11;
    pub const f12: Reg = .x12;
    pub const f13: Reg = .x13;
    pub const f14: Reg = .x14;
    pub const f15: Reg = .x15;
    pub const @"f16": Reg = .x16;
    pub const f17: Reg = .x17;
    pub const f18: Reg = .x18;
    pub const f19: Reg = .x19;
    pub const f20: Reg = .x20;
    pub const f21: Reg = .x21;
    pub const f22: Reg = .x22;
    pub const f23: Reg = .x23;
    pub const f24: Reg = .x24;
    pub const f25: Reg = .x25;
    pub const f26: Reg = .x26;
    pub const f27: Reg = .x27;
    pub const f28: Reg = .x28;
    pub const f29: Reg = .x29;
    pub const f30: Reg = .x30;
    pub const f31: Reg = .x31;
};

pub const FltReg = enum(u5) {
    f0,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    f13,
    f14,
    f15,
    f16,
    f17,
    f18,
    f19,
    f20,
    f21,
    f22,
    f23,
    f24,
    f25,
    f26,
    f27,
    f28,
    f29,
    f30,
    f31,
};

pub const BImm12Lo = packed struct(u5) { bit11: u1, bits1to4: u4 };

pub const BImm12Hi = packed struct(u7) { bits5to10: u6, bit12: i1 };

pub const JImm20 = packed struct(u20) { bits12to19: u8, bit11: u1, bits1to10: u10, bit20: i1 };

pub const RType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    func7: u7,
};

pub const R4Type = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    func2: u2,
    rs3: Reg,
};

pub const IType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    func3: u3,
    rs1: Reg,
    imm12: i12,
};

pub const SType = packed struct(u32) {
    opcode: u7,
    imm12lo: u5,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    imm12hi: i7,
};

pub const BType = packed struct(u32) {
    opcode: u7,
    bimm12lo: BImm12Lo,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    bimm12hi: BImm12Hi,
};

pub const UType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    imm20: i20,
};

pub const JType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    jimm20: JImm20,
};

pub const Inst = packed union {
    raw: u32,
    r: RType,
    r4: R4Type,
    i: IType,
    s: SType,
    b: BType,
    u: UType,
    j: JType,

    pub inline fn unpackStoreOffset(inst: Inst) i64 {
        const lo = inst.s.imm12lo;
        const hi = inst.s.imm12hi;
        return @as(i64, hi) << 5 | @as(i64, lo);
    }

    pub inline fn unpackBranchOffset(inst: Inst) i64 {
        const lo = inst.b.bimm12lo;
        const hi = inst.b.bimm12hi;
        return @as(i64, lo.bits1to4) << 1 |
            @as(i64, hi.bits5to10) << 5 |
            @as(i64, lo.bit11) << 11 |
            @as(i64, hi.bit12) << 12;
    }

    pub inline fn unpackJumpOffset(inst: Inst) i64 {
        const imm = inst.j.jimm20;
        return @as(i64, imm.bits1to10) << 1 |
            @as(i64, imm.bit11) << 11 |
            @as(i64, imm.bits12to19) << 12 |
            @as(i64, imm.bit20) << 20;
    }

    pub fn format(self: @This(), writer: *Io.Writer) Io.Writer.Error!void {
        return dis.disassemble(writer, self);
    }
};

const Int = extern union {
    u8: u8,
    i8: i8,
    u16: u16,
    i16: i16,
    u32: u32,
    i32: i32,
    u64: u64,
    i64: i64,
};

const Flt = extern union {
    f32: f32,
    f64: f64,
};

pub const page_size: u64 = 4096;

pub const VM = struct {
    pc: u64,
    base: u64,
    int_regs: [32]Int = @splat(.{ .i64 = 0 }),
    flt_regs: [32]Flt = @splat(.{ .f64 = 0.0 }),
    memory: []align(@sizeOf(u64)) u8,

    pub inline fn goto(self: *VM, address: u64) void {
        if (debug) std.debug.print("jump to: {X}\n", .{address});
        self.pc = address;
    }

    pub inline fn get(self: *VM, comptime T: type, reg: Reg) T {
        return switch (T) {
            i8, u8, i16, u16, i32, u32, i64, u64 => {
                const val = self.int_regs[@intFromEnum(reg)];
                if (debug and reg != .x0) std.debug.print("{t} is {f}\n", .{ reg, dis.fmtHex(val.i64) });
                return @field(val, @typeName(T));
            },
            f32, f64 => {
                const val = @field(self.flt_regs[@intFromEnum(reg)], @typeName(T));
                if (debug) std.debug.print("{t} is {}\n", .{ reg, val });
                return val;
            },
            else => @compileError("unsupported type: " ++ @typeName(T)),
        };
    }

    pub inline fn set(self: *VM, comptime T: type, reg: Reg, value: T) void {
        switch (T) {
            i64, u64 => {
                if (debug and reg != .x0) std.debug.print("{t} = {f}\n", .{ reg, dis.fmtHex(@bitCast(value)) });
                @field(self.int_regs[@intFromEnum(reg)], @typeName(T)) = if (reg != .x0) value else 0;
            },
            f32, f64 => {
                if (debug) std.debug.print("{t} = {}\n", .{ @as(FltReg, @enumFromInt(@intFromEnum(reg))), value });
                @field(self.flt_regs[@intFromEnum(reg)], @typeName(T)) = value;
            },
            else => @compileError("unsupported type: " ++ @typeName(T)),
        }
    }

    pub inline fn store(self: *VM, comptime T: type, addr: u64, value: T) !void {
        if (addr > self.memory.len -% @sizeOf(T)) {
            @branchHint(.cold);
            return error.SegFault;
        }
        @as(*align(1) T, @ptrCast(self.memory.ptr + @as(usize, @bitCast(addr)))).* = value;
        if (debug) std.debug.print("wrote {s} of {X} at addr 0x{X}\n", .{ @typeName(T), value, addr });
    }

    pub inline fn load(self: *VM, comptime T: type, addr: u64) !T {
        if (addr > self.memory.len -% @sizeOf(T)) {
            @branchHint(.cold);
            return error.SegFault;
        }
        const v = @as(*align(1) T, @ptrCast(self.memory.ptr + @as(usize, @bitCast(addr)))).*;
        if (debug) std.debug.print("read {s} of {X} at addr 0x{X}\n", .{ @typeName(T), v, addr });
        return v;
    }

    pub fn run(self: *VM, addr: u64) !void {
        self.goto(addr);
        self.set(u64, .ra, ~@as(u64, 0));
        var steps: usize = 0;
        while (@as(i64, @bitCast(self.pc)) >= 0) {
            const inst = Inst{ .raw = try self.load(u32, self.pc) };
            if (debug) std.debug.print("{f}\n", .{inst});
            try decode.exec(self, inst);
            if (debug) std.debug.print("\n", .{});
            steps += 1;
        }
        if (debug) {
            std.debug.print("steps: {}\n", .{steps});
        }
    }

    pub fn dumpIntRegs(self: *VM) void {
        for (self.int_regs, 0..) |reg, i| {
            if (i > 0) std.debug.print(", ", .{});
            std.debug.print("{t} = {f}", .{ @as(Reg, @enumFromInt(i)), dis.fmtHex(reg.i64) });
        }
        std.debug.print("\n", .{});
    }
};
