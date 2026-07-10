const std = @import("std");
const emu = @import("emu.zig");
const Inst = emu.Inst;
const Reg = emu.Reg;
const VM = emu.VM;

inline fn floatClass(x: anytype) u10 {
    const F = @TypeOf(x);
    const U = @Int(.unsigned, @bitSizeOf(F));
    const man_bits = std.math.floatMantissaBits(F);
    const exp_bits = std.math.floatExponentBits(F);
    const man_mask = (1 << man_bits) - 1;
    const exp_mask = ((1 << exp_bits) - 1) << man_bits;
    const sign_bit = 1 << (@bitSizeOf(F) - 1);
    const top_man_bit = 1 << (man_bits - 1);

    const bits: U = @bitCast(x);
    const man = bits & man_mask;
    const exp = bits & exp_mask;

    return switch (exp) {
        exp_mask => switch (man) {
            0 => switch (bits & sign_bit) {
                0 => 1 << 7, // +Inf
                else => 1 << 0, // -Inf
            },
            else => switch (bits & top_man_bit) {
                0 => 1 << 8, // sNaN
                else => 1 << 9, // qNaN
            },
        },
        0 => switch (man) {
            0 => switch (bits & sign_bit) {
                0 => 1 << 4, // +0.0
                else => 1 << 3, // -0.0
            },
            else => switch (bits & sign_bit) {
                0 => 1 << 5, // +Subnormal
                else => 1 << 2, // -Subnormal
            },
        },
        else => switch (bits & sign_bit) {
            0 => 1 << 6, // +Normal
            else => 1 << 1, // -Normal
        },
    };
}

// Instruction implementation

pub fn lb(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, try vm.load(i8, @bitCast(rs1 +% imm12)));
}

pub fn lh(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, try vm.load(i16, @bitCast(rs1 +% imm12)));
}

pub fn lw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, try vm.load(i32, @bitCast(rs1 +% imm12)));
}

pub fn ld(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, try vm.load(i64, @bitCast(rs1 +% imm12)));
}

pub fn lbu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(u64, rd, try vm.load(u8, @bitCast(rs1 +% imm12)));
}

pub fn lhu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(u64, rd, try vm.load(u16, @bitCast(rs1 +% imm12)));
}

pub fn lwu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(u64, rd, try vm.load(u32, @bitCast(rs1 +% imm12)));
}

pub fn flw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(f32, rd, try vm.load(f32, @bitCast(rs1 +% imm12)));
}

pub fn fld(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(f64, rd, try vm.load(f64, @bitCast(rs1 +% imm12)));
}

pub fn fence(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const succ: u4 = @truncate(@as(u12, @bitCast(imm12)));
    const pred: u4 = @truncate(@as(u12, @bitCast(imm12)) >> 4);
    const fm: u4 = @truncate(@as(u12, @bitCast(imm12)) >> 8);
    _ = rd;
    _ = rs1;
    _ = succ;
    _ = pred;
    _ = fm;
}

pub fn addi(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, rs1 +% imm12);
}

pub fn slli(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const shamt: u12 = @bitCast(inst.i.imm12);
    vm.set(i64, rd, rs1 << @truncate(shamt));
}

pub fn slti(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, @intFromBool(rs1 < imm12));
}

pub fn sltiu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(u64, inst.i.rs1);
    const imm12: u64 = @bitCast(@as(i64, inst.i.imm12));
    vm.set(i64, rd, @intFromBool(rs1 < imm12));
}

pub fn xori(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, rs1 ^ imm12);
}

pub fn srli(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(u64, inst.i.rs1);
    const shamt: u12 = @bitCast(inst.i.imm12);
    vm.set(u64, rd, rs1 >> @truncate(shamt));
}

pub fn srai(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const shamt: u12 = @bitCast(inst.i.imm12);
    vm.set(i64, rd, rs1 >> @truncate(shamt));
}

pub fn ori(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, rs1 | imm12);
}

pub fn andi(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i64, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, rs1 & imm12);
}

pub fn auipc(vm: *VM, inst: Inst) !void {
    const rd = inst.u.rd;
    const imm20: u64 = @bitCast(@as(i64, inst.u.imm20));
    vm.set(u64, rd, vm.pc +% (imm20 << 12));
    vm.pc +%= 4;
}

pub fn addiw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i32, inst.i.rs1);
    const imm12 = inst.i.imm12;
    vm.set(i64, rd, rs1 +% imm12);
}

pub fn slliw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i32, inst.i.rs1);
    const shamt: u12 = @bitCast(inst.i.imm12);
    vm.set(i64, rd, rs1 << @truncate(shamt));
}

pub fn srliw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(u32, inst.i.rs1);
    const shamt: u12 = @bitCast(inst.i.imm12);
    vm.set(i64, rd, @as(i32, @bitCast(rs1 >> @truncate(shamt))));
}

pub fn sraiw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = vm.get(i32, inst.i.rs1);
    const shamt: u12 = @bitCast(inst.i.imm12);
    vm.set(i64, rd, rs1 >> @truncate(shamt));
}

pub fn sb(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = vm.get(i64, inst.s.rs1);
    const rs2 = vm.get(i8, inst.s.rs2);
    const offset = inst.unpackStoreOffset();
    try vm.store(i8, @bitCast(rs1 +% offset), rs2);
}

pub fn sh(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = vm.get(i64, inst.s.rs1);
    const rs2 = vm.get(i16, inst.s.rs2);
    const offset = inst.unpackStoreOffset();
    try vm.store(i16, @bitCast(rs1 +% offset), rs2);
}

pub fn sw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = vm.get(i64, inst.s.rs1);
    const rs2 = vm.get(i32, inst.s.rs2);
    const offset = inst.unpackStoreOffset();
    try vm.store(i32, @bitCast(rs1 +% offset), rs2);
}

pub fn sd(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = vm.get(i64, inst.s.rs1);
    const rs2 = vm.get(i64, inst.s.rs2);
    const offset = inst.unpackStoreOffset();
    try vm.store(i64, @bitCast(rs1 +% offset), rs2);
}

pub fn fsw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = vm.get(i64, inst.s.rs1);
    const rs2 = vm.get(f32, inst.s.rs2);
    const offset = inst.unpackStoreOffset();
    try vm.store(f32, @bitCast(rs1 +% offset), rs2);
}

pub fn fsd(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = vm.get(i64, inst.s.rs1);
    const rs2 = vm.get(f64, inst.s.rs2);
    const offset = inst.unpackStoreOffset();
    try vm.store(f64, @bitCast(rs1 +% offset), rs2);
}

pub fn add(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, rs1 +% rs2);
}

pub fn sll(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(u8, inst.r.rs2);
    vm.set(i64, rd, rs1 << @truncate(rs2));
}

pub fn slt(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 < rs2));
}

pub fn sltu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u64, inst.r.rs1);
    const rs2 = vm.get(u64, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 < rs2));
}

pub fn xor(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, rs1 ^ rs2);
}

pub fn srl(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u64, inst.r.rs1);
    const rs2 = vm.get(u8, inst.r.rs2);
    vm.set(u64, rd, rs1 >> @truncate(rs2));
}

pub fn @"or"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, rs1 | rs2);
}

pub fn @"and"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, rs1 & rs2);
}

pub fn mul(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, rs1 *% rs2);
}

pub fn mulh(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: i128 = vm.get(i64, inst.r.rs1);
    const rs2: i128 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, @truncate((rs1 * rs2) >> 64));
}

pub fn mulhsu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: i128 = vm.get(i64, inst.r.rs1);
    const rs2: i128 = vm.get(u64, inst.r.rs2);
    vm.set(i64, rd, @truncate((rs1 * rs2) >> 64));
}

pub fn mulhu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: u128 = vm.get(u64, inst.r.rs1);
    const rs2: u128 = vm.get(u64, inst.r.rs2);
    vm.set(u64, rd, @truncate((rs1 * rs2) >> 64));
}

pub fn div(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, if (rs2 == 0) ~@as(i64, 0) else if (rs1 == std.math.minInt(i64) and rs2 == -1) rs1 else @divTrunc(rs1, rs2));
}

pub fn divu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u64, inst.r.rs1);
    const rs2 = vm.get(u64, inst.r.rs2);
    vm.set(u64, rd, if (rs2 == 0) ~@as(u64, 0) else @divTrunc(rs1, rs2));
}

pub fn rem(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, if (rs1 == std.math.minInt(i64) and rs2 == -1) 0 else if (rs2 == 0) rs1 else @rem(rs1, rs2));
}

pub fn remu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u64, inst.r.rs1);
    const rs2 = vm.get(u64, inst.r.rs2);
    vm.set(u64, rd, if (rs2 == 0) rs1 else @rem(rs1, rs2));
}

pub fn sub(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(i64, inst.r.rs2);
    vm.set(i64, rd, rs1 -% rs2);
}

pub fn sra(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    const rs2 = vm.get(u8, inst.r.rs2);
    vm.set(i64, rd, rs1 >> @truncate(rs2));
}

pub fn lui(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.u.rd;
    const imm20: i64 = inst.u.imm20;
    vm.set(i64, rd, imm20 << 12);
}

pub fn addw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    const rs2 = vm.get(i32, inst.r.rs2);
    vm.set(i64, rd, rs1 +% rs2);
}

pub fn sllw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    const rs2 = vm.get(u8, inst.r.rs2);
    vm.set(i64, rd, rs1 << @truncate(rs2));
}

pub fn srlw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u32, inst.r.rs1);
    const rs2 = vm.get(u8, inst.r.rs2);
    vm.set(i64, rd, @as(i32, @bitCast(rs1 >> @truncate(rs2))));
}

pub fn mulw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    const rs2 = vm.get(i32, inst.r.rs2);
    vm.set(i64, rd, rs1 *% rs2);
}

pub fn divw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    const rs2 = vm.get(i32, inst.r.rs2);
    vm.set(i64, rd, if (rs2 == 0) ~@as(i32, 0) else if (rs1 == std.math.minInt(i32) and rs2 == -1) rs1 else @divTrunc(rs1, rs2));
}

pub fn divuw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u32, inst.r.rs1);
    const rs2 = vm.get(u32, inst.r.rs2);
    vm.set(i64, rd, @as(i32, @bitCast(if (rs2 == 0) ~@as(u32, 0) else @divTrunc(rs1, rs2))));
}

pub fn remw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    const rs2 = vm.get(i32, inst.r.rs2);
    vm.set(i64, rd, if (rs1 == std.math.minInt(i32) and rs2 == -1) 0 else if (rs2 == 0) rs1 else @rem(rs1, rs2));
}

pub fn remuw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u32, inst.r.rs1);
    const rs2 = vm.get(u32, inst.r.rs2);
    vm.set(i64, rd, @as(i32, @bitCast(if (rs2 == 0) rs1 else @rem(rs1, rs2))));
}

pub fn subw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    const rs2 = vm.get(i32, inst.r.rs2);
    vm.set(i64, rd, rs1 -% rs2);
}

pub fn sraw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    const rs2 = vm.get(u8, inst.r.rs2);
    vm.set(i64, rd, rs1 >> @truncate(rs2));
}

pub fn @"fmadd.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f32, inst.r4.rs1);
    const rs2 = vm.get(f32, inst.r4.rs2);
    const rs3 = vm.get(f32, inst.r4.rs3);
    vm.set(f32, rd, @mulAdd(f32, rs1, rs2, rs3));
}

pub fn @"fmadd.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f64, inst.r4.rs1);
    const rs2 = vm.get(f64, inst.r4.rs2);
    const rs3 = vm.get(f64, inst.r4.rs3);
    vm.set(f64, rd, @mulAdd(f64, rs1, rs2, rs3));
}

pub fn @"fmsub.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f32, inst.r4.rs1);
    const rs2 = vm.get(f32, inst.r4.rs2);
    const rs3 = vm.get(f32, inst.r4.rs3);
    vm.set(f32, rd, @mulAdd(f32, rs1, rs2, -rs3));
}

pub fn @"fmsub.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f64, inst.r4.rs1);
    const rs2 = vm.get(f64, inst.r4.rs2);
    const rs3 = vm.get(f64, inst.r4.rs3);
    vm.set(f64, rd, @mulAdd(f64, rs1, rs2, -rs3));
}

pub fn @"fnmsub.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f32, inst.r4.rs1);
    const rs2 = vm.get(f32, inst.r4.rs2);
    const rs3 = vm.get(f32, inst.r4.rs3);
    vm.set(f32, rd, @mulAdd(f32, -rs1, rs2, -rs3));
}

pub fn @"fnmsub.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f64, inst.r4.rs1);
    const rs2 = vm.get(f64, inst.r4.rs2);
    const rs3 = vm.get(f64, inst.r4.rs3);
    vm.set(f64, rd, @mulAdd(f64, -rs1, rs2, -rs3));
}

pub fn @"fnmadd.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f32, inst.r4.rs1);
    const rs2 = vm.get(f32, inst.r4.rs2);
    const rs3 = vm.get(f32, inst.r4.rs3);
    vm.set(f32, rd, @mulAdd(f32, -rs1, rs2, rs3));
}

pub fn @"fnmadd.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = vm.get(f64, inst.r4.rs1);
    const rs2 = vm.get(f64, inst.r4.rs2);
    const rs3 = vm.get(f64, inst.r4.rs3);
    vm.set(f64, rd, @mulAdd(f64, -rs1, rs2, rs3));
}

pub fn @"fadd.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(f32, rd, rs1 + rs2);
}

pub fn @"fsub.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(f32, rd, rs1 - rs2);
}

pub fn @"fmul.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(f32, rd, rs1 * rs2);
}

pub fn @"fdiv.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(f32, rd, rs1 / rs2);
}

pub fn @"fsgnj.s"(vm: *VM, inst: Inst) !void {
    const sign_bit_mask: u32 = 1 << 31;

    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: u32 = @bitCast(vm.get(f32, inst.r.rs1));
    const rs2: u32 = @bitCast(vm.get(f32, inst.r.rs2));
    const mag = rs1 & ~sign_bit_mask;
    const sign = rs2 & sign_bit_mask;
    vm.set(f32, rd, @bitCast(mag | sign));
}

pub fn @"fsgnjn.s"(vm: *VM, inst: Inst) !void {
    const sign_bit_mask: u32 = 1 << 31;

    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: u32 = @bitCast(vm.get(f32, inst.r.rs1));
    const rs2: u32 = @bitCast(vm.get(f32, inst.r.rs2));
    const mag = rs1 & ~sign_bit_mask;
    const sign = ~rs2 & sign_bit_mask;
    vm.set(f32, rd, @bitCast(mag | sign));
}

pub fn @"fsgnjx.s"(vm: *VM, inst: Inst) !void {
    const sign_bit_mask: u32 = 1 << 31;

    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: u32 = @bitCast(vm.get(f32, inst.r.rs1));
    const rs2: u32 = @bitCast(vm.get(f32, inst.r.rs2));
    const mag = rs1 & ~sign_bit_mask;
    const sign = (rs1 ^ rs2) & sign_bit_mask;
    vm.set(f32, rd, @bitCast(mag | sign));
}

pub fn @"fmin.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(f32, rd, @min(rs1, rs2));
}

pub fn @"fmax.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(f32, rd, @max(rs1, rs2));
}

pub fn @"fcvt.s.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(f32, rd, @floatCast(rs1));
}

pub fn @"fsqrt.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(f32, rd, @sqrt(rs1));
}

pub fn @"fle.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 <= rs2));
}

pub fn @"flt.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 < rs2));
}

pub fn @"feq.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    const rs2 = vm.get(f32, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 == rs2));
}

pub fn @"fcvt.w.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(i64, rd, @as(i32, @intFromFloat(rs1)));
}

pub fn @"fcvt.wu.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(i64, rd, @as(i32, @bitCast(@as(u32, @intFromFloat(rs1)))));
}

pub fn @"fcvt.l.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(i64, rd, @intFromFloat(rs1));
}

pub fn @"fcvt.lu.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(u64, rd, @intFromFloat(rs1));
}

pub fn @"fcvt.s.w"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    vm.set(f32, rd, @floatFromInt(rs1));
}

pub fn @"fcvt.s.wu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u32, inst.r.rs1);
    vm.set(f32, rd, @floatFromInt(rs1));
}

pub fn @"fcvt.s.l"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    vm.set(f32, rd, @floatFromInt(rs1));
}

pub fn @"fcvt.s.lu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u64, inst.r.rs1);
    vm.set(f32, rd, @floatFromInt(rs1));
}

pub fn @"fmv.x.w"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(i64, rd, @as(i32, @bitCast(rs1)));
}

pub fn @"fclass.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(u64, rd, floatClass(rs1));
}

pub fn @"fmv.w.x"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    vm.set(f32, rd, @bitCast(rs1));
}

pub fn @"fadd.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(f64, rd, rs1 + rs2);
}

pub fn @"fsub.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(f64, rd, rs1 - rs2);
}

pub fn @"fmul.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(f64, rd, rs1 * rs2);
}

pub fn @"fdiv.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(f64, rd, rs1 / rs2);
}

pub fn @"fsgnj.d"(vm: *VM, inst: Inst) !void {
    const sign_bit_mask: u64 = 1 << 63;

    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: u64 = @bitCast(vm.get(f64, inst.r.rs1));
    const rs2: u64 = @bitCast(vm.get(f64, inst.r.rs2));
    const mag = rs1 & ~sign_bit_mask;
    const sign = rs2 & sign_bit_mask;
    vm.set(f64, rd, @bitCast(mag | sign));
}

pub fn @"fsgnjn.d"(vm: *VM, inst: Inst) !void {
    const sign_bit_mask: u64 = 1 << 63;

    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: u64 = @bitCast(vm.get(f64, inst.r.rs1));
    const rs2: u64 = @bitCast(vm.get(f64, inst.r.rs2));
    const mag = rs1 & ~sign_bit_mask;
    const sign = ~rs2 & sign_bit_mask;
    vm.set(f64, rd, @bitCast(mag | sign));
}

pub fn @"fsgnjx.d"(vm: *VM, inst: Inst) !void {
    const sign_bit_mask: u64 = 1 << 63;

    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1: u64 = @bitCast(vm.get(f64, inst.r.rs1));
    const rs2: u64 = @bitCast(vm.get(f64, inst.r.rs2));
    const mag = rs1 & ~sign_bit_mask;
    const sign = (rs1 ^ rs2) & sign_bit_mask;
    vm.set(f64, rd, @bitCast(mag | sign));
}

pub fn @"fmin.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(f64, rd, @min(rs1, rs2));
}

pub fn @"fmax.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(f64, rd, @max(rs1, rs2));
}

pub fn @"fcvt.d.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f32, inst.r.rs1);
    vm.set(f64, rd, @floatCast(rs1));
}

pub fn @"fsqrt.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(f64, rd, @sqrt(rs1));
}

pub fn @"fle.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 <= rs2));
}

pub fn @"flt.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 < rs2));
}

pub fn @"feq.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    const rs2 = vm.get(f64, inst.r.rs2);
    vm.set(i64, rd, @intFromBool(rs1 == rs2));
}

pub fn @"fcvt.w.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(i64, rd, @as(i32, @intFromFloat(rs1)));
}

pub fn @"fcvt.wu.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(i64, rd, @as(i32, @bitCast(@as(u32, @intFromFloat(rs1)))));
}

pub fn @"fcvt.l.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(i64, rd, @intFromFloat(rs1));
}

pub fn @"fcvt.lu.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(u64, rd, @intFromFloat(rs1));
}

pub fn @"fcvt.d.w"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i32, inst.r.rs1);
    vm.set(f64, rd, @floatFromInt(rs1));
}

pub fn @"fcvt.d.wu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u32, inst.r.rs1);
    vm.set(f64, rd, @floatFromInt(rs1));
}

pub fn @"fcvt.d.l"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    vm.set(f64, rd, @floatFromInt(rs1));
}

pub fn @"fcvt.d.lu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(u64, inst.r.rs1);
    vm.set(f64, rd, @floatFromInt(rs1));
}

pub fn @"fmv.x.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(i64, rd, @bitCast(rs1));
}

pub fn @"fclass.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(f64, inst.r.rs1);
    vm.set(i64, rd, floatClass(rs1));
}

pub fn @"fmv.d.x"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = vm.get(i64, inst.r.rs1);
    vm.set(f64, rd, @bitCast(rs1));
}

pub fn beq(vm: *VM, inst: Inst) !void {
    const rs1 = vm.get(u64, inst.b.rs1);
    const rs2 = vm.get(u64, inst.b.rs2);
    if (rs1 == rs2) {
        vm.goto(vm.pc +% @as(u64, @bitCast(inst.unpackBranchOffset())));
    } else {
        vm.pc +%= 4;
    }
}

pub fn bne(vm: *VM, inst: Inst) !void {
    const rs1 = vm.get(u64, inst.b.rs1);
    const rs2 = vm.get(u64, inst.b.rs2);
    if (rs1 != rs2) {
        vm.goto(vm.pc +% @as(u64, @bitCast(inst.unpackBranchOffset())));
    } else {
        vm.pc +%= 4;
    }
}

pub fn blt(vm: *VM, inst: Inst) !void {
    const rs1 = vm.get(u64, inst.b.rs1);
    const rs2 = vm.get(u64, inst.b.rs2);
    if (rs1 < rs2) {
        vm.goto(vm.pc +% @as(u64, @bitCast(inst.unpackBranchOffset())));
    } else {
        vm.pc +%= 4;
    }
}

pub fn bge(vm: *VM, inst: Inst) !void {
    const rs1 = vm.get(u64, inst.b.rs1);
    const rs2 = vm.get(u64, inst.b.rs2);
    if (rs1 >= rs2) {
        vm.goto(vm.pc +% @as(u64, @bitCast(inst.unpackBranchOffset())));
    } else {
        vm.pc +%= 4;
    }
}

pub fn bltu(vm: *VM, inst: Inst) !void {
    const rs1 = vm.get(u64, inst.b.rs1);
    const rs2 = vm.get(u64, inst.b.rs2);
    if (rs1 < rs2) {
        vm.goto(vm.pc +% @as(u64, @bitCast(inst.unpackBranchOffset())));
    } else {
        vm.pc +%= 4;
    }
}

pub fn bgeu(vm: *VM, inst: Inst) !void {
    const rs1 = vm.get(u64, inst.b.rs1);
    const rs2 = vm.get(u64, inst.b.rs2);
    if (rs1 >= rs2) {
        vm.goto(vm.pc +% @as(u64, @bitCast(inst.unpackBranchOffset())));
    } else {
        vm.pc +%= 4;
    }
}

pub fn jalr(vm: *VM, inst: Inst) !void {
    const rd = inst.i.rd;
    const rs1 = vm.get(u64, inst.i.rs1);
    const imm12: u64 = @bitCast(@as(i64, inst.i.imm12));
    vm.set(u64, rd, vm.pc +% 4);
    vm.goto((rs1 +% imm12) & ~@as(u64, 1));
}

pub fn jal(vm: *VM, inst: Inst) !void {
    const rd = inst.j.rd;
    const offset: u64 = @bitCast(inst.unpackJumpOffset());
    vm.set(u64, rd, vm.pc +% 4);
    vm.goto(vm.pc +% @as(u64, @bitCast(offset)));
}

pub fn csrrw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}

pub fn csrrs(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}

pub fn csrrc(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}

pub fn csrrwi(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}

pub fn csrrsi(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}

pub fn csrrci(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}

pub fn ecall(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
    switch (vm.get(u64, .a7)) {
        0 => {
            const ptr = vm.get(u64, .a0);
            const len = vm.get(u64, .a1);
            // vm.dumpIntRegs();
            // std.debug.print("program output:\n", .{});
            std.debug.print("{s}", .{vm.memory[@truncate(ptr)..][0..@truncate(len)]});
        },
        else => vm.dumpIntRegs(),
    }
}

pub fn ebreak(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}
