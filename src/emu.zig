const std = @import("std");
const decode = @import("decode.zig");

pub const Reg = enum(u5) {
    x0,
    x1,
    x2,
    x3,
    x4,
    x5,
    x6,
    x7,
    x8,
    x9,
    x10,
    x11,
    x12,
    x13,
    x14,
    x15,
    x16,
    x17,
    x18,
    x19,
    x20,
    x21,
    x22,
    x23,
    x24,
    x25,
    x26,
    x27,
    x28,
    x29,
    x30,
    x31,

    pub const zero: Reg = .x0; // Hard-wired zero
    pub const ra: Reg = .x1; // Return address
    pub const sp: Reg = .x2; // Stack pointer
    pub const gp: Reg = .x3; // Global pointer
    pub const tp: Reg = .x4; // Thread pointer
    pub const fp: Reg = .x8; // Frame pointer (s0)

    // Return value / Argument
    pub const a0: Reg = .x10;
    pub const a1: Reg = .x11;
    // Argument
    pub const a2: Reg = .x12;
    pub const a3: Reg = .x13;
    pub const a4: Reg = .x14;
    pub const a5: Reg = .x15;
    pub const a6: Reg = .x16;
    pub const a7: Reg = .x17;

    // Saved register
    pub const s0: Reg = .x8;
    pub const s1: Reg = .x9;
    pub const s2: Reg = .x18;
    pub const s3: Reg = .x19;
    pub const s4: Reg = .x20;
    pub const s5: Reg = .x21;
    pub const s6: Reg = .x22;
    pub const s7: Reg = .x23;
    pub const s8: Reg = .x24;
    pub const s9: Reg = .x25;
    pub const s10: Reg = .x26;
    pub const s11: Reg = .x27;

    // Temporary
    pub const t0: Reg = .x5;
    pub const t1: Reg = .x6;
    pub const t2: Reg = .x7;
    pub const t3: Reg = .x28;
    pub const t4: Reg = .x29;
    pub const t5: Reg = .x30;
    pub const t6: Reg = .x31;

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

pub const BImm12Lo = packed struct(u5) { bit11: u1, bits1to4: u4 };

pub const BImm12Hi = packed struct(u7) { bits5to10: u6, bit12: u1 };

pub const JImm20 = packed struct(u20) { bits12to19: u8, bit11: u1, bits1to10: u10, bit20: u1 };

pub const RType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    func7: u7,

    pub fn format(self: RType, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("rd = {s}\trs1 = {s}\trs2 = {s}", .{ @tagName(self.rd), @tagName(self.rs1), @tagName(self.rs2) });
    }
};

pub const R4Type = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    func2: u2,
    rs3: Reg,

    pub fn format(self: RType, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("rd = {s}\trs1 = {s}\trs2 = {s}", .{ @tagName(self.rd), @tagName(self.rs1), @tagName(self.rs2) });
    }
};

pub const IType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    func3: u3,
    rs1: Reg,
    imm12: i12,

    pub fn format(self: IType, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("rd = {s}\trs1 = {s}\timm12 = {}", .{ @tagName(self.rd), @tagName(self.rs1), self.imm12 });
    }
};

pub const SType = packed struct(u32) {
    opcode: u7,
    imm12lo: u5,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    imm12hi: i7,

    pub fn format(self: SType, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const full = Inst{ .s_type = self };
        try writer.print("rs1 = {s}\trs2 = {s}\toffset = {}", .{ @tagName(self.rs1), @tagName(self.rs2), full.unpackStoreOffset() });
    }
};

pub const BType = packed struct(u32) {
    opcode: u7,
    bimm12lo: BImm12Lo,
    func3: u3,
    rs1: Reg,
    rs2: Reg,
    bimm12hi: BImm12Hi,

    pub fn format(self: BType, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const full = Inst{ .b_type = self };
        try writer.print("rs1 = {s}\trs2 = {s}\toffset = {}", .{ @tagName(self.rs1), @tagName(self.rs2), full.unpackBranchOffset() });
    }
};

pub const UType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    imm20: i20,

    pub fn format(self: UType, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("rd = {s}\timm20 = {}", .{ @tagName(self.rd), self.imm20 });
    }
};

pub const JType = packed struct(u32) {
    opcode: u7,
    rd: Reg,
    jimm20: JImm20,

    pub fn format(self: JType, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        const full = Inst{ .j_type = self };
        try writer.print("rd = {s}\toffset = {}", .{ @tagName(self.rd), full.unpackJumpOffset() });
    }
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
        return @as(i12, hi) << 5 | @as(i12, lo);
    }

    pub inline fn unpackBranchOffset(inst: Inst) i64 {
        const lo = inst.b.bimm12lo;
        const hi = inst.b.bimm12hi;
        return @as(i13, lo.bits1to4) << 1 |
            @as(i13, hi.bits5to10) << 5 |
            @as(i13, lo.bit11) << 11 |
            @as(i13, hi.bit12) << 12;
    }

    pub inline fn unpackJumpOffset(inst: Inst) i64 {
        const imm = inst.j.jimm20;
        return @as(i21, imm.bits1to10) << 1 |
            @as(i21, imm.bit11) << 11 |
            @as(i21, imm.bits12to19) << 12 |
            @as(i21, imm.bit20) << 20;
    }
};

const Flt = extern union {
    f32: f32,
    f64: f64,
};

pub const VM = struct {
    pc: i64,
    int_regs: [32]i64 = [_]i64{0} ** 32,
    flt_regs: [32]Flt = [_]Flt{.{ .f64 = 0.0 }} ** 32,
    memory: []align(@sizeOf(u64)) u8,

    pub inline fn setInt(self: *VM, reg: Reg, value: i64) void {
        // if (reg == .x13) std.debug.print("x13 set to 0x{X}\n", .{value});
        self.int_regs[@intFromEnum(reg)] = if (reg != .x0) value else 0;
    }

    pub inline fn getInt(self: *VM, reg: Reg) i64 {
        return self.int_regs[@intFromEnum(reg)];
    }

    pub inline fn setFloat(self: *VM, reg: Reg, value: f32) void {
        self.flt_regs[@intFromEnum(reg)].f32 = value;
    }

    pub inline fn getFloat(self: *VM, reg: Reg) f32 {
        return self.flt_regs[@intFromEnum(reg)].f32;
    }

    pub inline fn setDouble(self: *VM, reg: Reg, value: f64) void {
        self.flt_regs[@intFromEnum(reg)].f64 = value;
    }

    pub inline fn getDouble(self: *VM, reg: Reg) f64 {
        return self.flt_regs[@intFromEnum(reg)].f64;
    }

    pub inline fn store(self: *VM, addr: i64, value: anytype) !void {
        const T = @TypeOf(value);
        if (addr > self.memory.len -% @sizeOf(T)) {
            @branchHint(.cold);
            return error.SegFault;
        }
        @as(*T, @ptrCast(@alignCast(self.memory.ptr + @as(usize, @bitCast(addr))))).* = value;
        // self.dumpIntRegs();
        std.debug.print("wrote value 0x{X} with type {s} at addr 0x{X}\n", .{ value, @typeName(T), addr });
    }

    pub inline fn load(self: *VM, addr: i64, comptime T: type) !T {
        if (addr > self.memory.len -% @sizeOf(T)) {
            @branchHint(.cold);
            return error.SegFault;
        }
        const v = @as(*T, @ptrCast(@alignCast(self.memory.ptr + @as(usize, @bitCast(addr))))).*;
        // std.debug.print("read value 0x{X} at addr 0x{X}\n", .{ v, addr });
        return v;
    }

    pub fn eval(self: *VM) !void {
        var steps: usize = 0;
        while (self.pc > 0) {
            std.debug.print("{X}: ", .{@as(u64, @bitCast(self.pc))});
            const inst = try self.load(self.pc, u32);
            const inst_name = decode.disassemble(inst) orelse "unknown";
            std.debug.print("{s}\n", .{inst_name});
            try decode.exec(self, .{ .raw = inst });
            std.debug.print("{any}\n", .{self.int_regs});
            steps += 1;
        }
        std.debug.print("steps: {}\n", .{steps});
    }

    pub fn dumpIntRegs(self: *VM) void {
        for (self.int_regs, 0..) |reg, i| {
            if (i > 0) {
                std.debug.print(", ", .{});
            }
            std.debug.print("x{}: 0x{X}", .{ i, reg });
        }
        std.debug.print("\n", .{});
    }
};
