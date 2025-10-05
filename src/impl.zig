const std = @import("std");
const emu = @import("emu.zig");
const Inst = emu.Inst;
const Reg = emu.Reg;
const VM = emu.VM;

inline fn floatClass(x: anytype) u10 {
    const F = @TypeOf(x);
    const U = @Type(.{ .int = .{
        .signedness = .unsigned,
        .bits = @bitSizeOf(F),
    } });
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
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, try vm.load(vm.getInt(rs1) + imm12, i8));
}

pub fn lh(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, try vm.load(vm.getInt(rs1) + imm12, i16));
}

pub fn lw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, try vm.load(vm.getInt(rs1) + imm12, i32));
}

pub fn ld(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, try vm.load(vm.getInt(rs1) + imm12, i64));
}

pub fn lbu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, try vm.load(vm.getInt(rs1) + imm12, u8));
}

pub fn lhu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, try vm.load(vm.getInt(rs1) + imm12, u16));
}

pub fn lwu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, try vm.load(vm.getInt(rs1) + imm12, u32));
}

pub fn flw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setFloat(rd, try vm.load(vm.getInt(rs1) + imm12, f32));
}

pub fn fld(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setDouble(rd, try vm.load(vm.getInt(rs1) + imm12, f64));
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
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, vm.getInt(rs1) +% imm12);
}

pub fn slli(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const shamtd: u6 = @truncate(@as(u12, @bitCast(imm12)));
    vm.setInt(rd, vm.getInt(rs1) << shamtd);
}

pub fn slti(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, @intFromBool(vm.getInt(rs1) < imm12));
}

pub fn sltiu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, @intFromBool(@as(u64, @bitCast(vm.getInt(rs1))) < @as(u64, @bitCast(@as(i64, imm12)))));
}

pub fn xori(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, vm.getInt(rs1) ^ imm12);
}

pub fn srli(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const shamtd: u6 = @truncate(@as(u12, @bitCast(imm12)));
    vm.setInt(rd, @bitCast(@as(u64, @bitCast(vm.getInt(rs1))) >> shamtd));
}

pub fn srai(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const shamtd: u6 = @truncate(@as(u12, @bitCast(imm12)));
    vm.setInt(rd, vm.getInt(rs1) >> shamtd);
}

pub fn ori(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, vm.getInt(rs1) | imm12);
}

pub fn andi(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, vm.getInt(rs1) & imm12);
}

pub fn auipc(vm: *VM, inst: Inst) !void {
    const curr_pc = vm.pc;
    vm.pc +%= 4;
    const rd = inst.u.rd;
    const imm20 = inst.u.imm20;
    vm.setInt(rd, curr_pc +% (@as(i64, imm20) << 12));
}

pub fn addiw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) +% @as(i32, @truncate(@as(i64, imm12))));
}

pub fn slliw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const shamtw: u5 = @truncate(@as(u12, @bitCast(imm12)));
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) << shamtw);
}

pub fn srliw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const shamtw: u5 = @truncate(@as(u12, @bitCast(imm12)));
    vm.setInt(rd, @as(i32, @bitCast(@as(u32, @bitCast(@as(i32, @truncate(vm.getInt(rs1))))) >> shamtw)));
}

pub fn sraiw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const shamtw: u5 = @truncate(@as(u12, @bitCast(imm12)));
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) >> shamtw);
}

pub fn sb(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = inst.s.rs1;
    const rs2 = inst.s.rs2;
    const offset = inst.unpackStoreOffset();
    // std.debug.print(
    //     "SB: rs1={t}={}, rs2={t}={}, offset={}, final_addr={}\n",
    //     .{ rs1, vm.getInt(rs1), rs2, vm.getInt(rs2), offset, vm.getInt(rs1) + offset },
    // );
    try vm.store(vm.getInt(rs1) + offset, @as(i8, @truncate(vm.getInt(rs2))));
}

pub fn sh(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = inst.s.rs1;
    const rs2 = inst.s.rs2;
    const offset = inst.unpackStoreOffset();
    try vm.store(vm.getInt(rs1) + offset, @as(i16, @truncate(vm.getInt(rs2))));
}

pub fn sw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = inst.s.rs1;
    const rs2 = inst.s.rs2;
    const offset = inst.unpackStoreOffset();
    try vm.store(vm.getInt(rs1) + offset, @as(i32, @truncate(vm.getInt(rs2))));
}

pub fn sd(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = inst.s.rs1;
    const rs2 = inst.s.rs2;
    const offset = inst.unpackStoreOffset();
    try vm.store(vm.getInt(rs1) + offset, vm.getInt(rs2));
}

pub fn fsw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = inst.s.rs1;
    const rs2 = inst.s.rs2;
    const offset = inst.unpackStoreOffset();
    try vm.store(vm.getInt(rs1) + offset, vm.getFloat(rs2));
}

pub fn fsd(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rs1 = inst.s.rs1;
    const rs2 = inst.s.rs2;
    const offset = inst.unpackStoreOffset();
    try vm.store(vm.getInt(rs1) + offset, vm.getDouble(rs2));
}

pub fn add(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    // std.debug.print("add {t} {t} {t}\n", .{ rd, rs1, rs2 });
    vm.setInt(rd, vm.getInt(rs1) +% vm.getInt(rs2));
}

pub fn sll(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, vm.getInt(rs1) << @truncate(@as(u64, @bitCast(vm.getInt(rs2)))));
}

pub fn slt(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(vm.getInt(rs1) < vm.getInt(rs2)));
}

pub fn sltu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(@as(u64, @bitCast(vm.getInt(rs1))) < @as(u64, @bitCast(vm.getInt(rs2)))));
}

pub fn xor(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, vm.getInt(rs1) ^ vm.getInt(rs2));
}

pub fn srl(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @bitCast(@as(u64, @bitCast(vm.getInt(rs1))) >> @truncate(@as(u64, @bitCast(vm.getInt(rs2))))));
}

pub fn @"or"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, vm.getInt(rs1) | vm.getInt(rs2));
}

pub fn @"and"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, vm.getInt(rs1) & vm.getInt(rs2));
}

pub fn mul(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, vm.getInt(rs1) * vm.getInt(rs2));
}

pub fn mulh(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i64, @truncate(@as(i128, vm.getInt(rs1)) * @as(i128, vm.getInt(rs2)) >> 64)));
}

pub fn mulhsu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i64, @truncate(@as(i128, vm.getInt(rs1)) * @as(i128, @as(u64, @bitCast(vm.getInt(rs2)))) >> 64)));
}

pub fn mulhu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i64, @truncate(@as(i128, @as(u64, @bitCast(vm.getInt(rs1)))) * @as(i128, @as(u64, @bitCast(vm.getInt(rs2)))) >> 64)));
}

pub fn div(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) ~@as(i64, 0) else @divTrunc(vm.getInt(rs1), vm.getInt(rs2)));
}

pub fn divu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) ~@as(i64, 0) else @bitCast(@divTrunc(@as(u64, @bitCast(vm.getInt(rs1))), @as(u64, @bitCast(vm.getInt(rs2))))));
}

pub fn rem(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) vm.getInt(rs1) else @rem(vm.getInt(rs1), vm.getInt(rs2)));
}

pub fn remu(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) vm.getInt(rs1) else @bitCast(@rem(@as(u64, @bitCast(vm.getInt(rs1))), @as(u64, @bitCast(vm.getInt(rs2))))));
}

pub fn sub(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, vm.getInt(rs1) -% vm.getInt(rs2));
}

pub fn sra(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, vm.getInt(rs1) >> @truncate(@as(u64, @bitCast(vm.getInt(rs2)))));
}

pub fn lui(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.u.rd;
    const imm20 = inst.u.imm20;
    vm.setInt(rd, @as(i64, imm20) << 12);
}

pub fn addw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) +% @as(i32, @truncate(vm.getInt(rs2))));
}

pub fn sllw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) << @truncate(@as(u64, @bitCast(vm.getInt(rs2)))));
}

pub fn srlw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i32, @bitCast(@as(u32, @truncate(@as(u64, @bitCast(vm.getInt(rs1))))) >> @truncate(@as(u64, @bitCast(vm.getInt(rs2)))))));
}

pub fn mulw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) *% @as(i32, @truncate(vm.getInt(rs2))));
}

pub fn divw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) ~@as(i64, 0) else @divTrunc(@as(i32, @truncate(vm.getInt(rs1))), @as(i32, @truncate(vm.getInt(rs2)))));
}

pub fn divuw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) ~@as(i64, 0) else @as(i32, @bitCast(@divTrunc(@as(u32, @truncate(@as(u64, @bitCast(vm.getInt(rs1))))), @as(u32, @truncate(@as(u64, @bitCast(vm.getInt(rs2)))))))));
}

pub fn remw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) vm.getInt(rs1) else @rem(@as(i32, @truncate(vm.getInt(rs1))), @as(i32, @truncate(vm.getInt(rs2)))));
}

pub fn remuw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, if (vm.getInt(rs2) == 0) vm.getInt(rs1) else @as(i32, @bitCast(@rem(@as(u32, @truncate(@as(u64, @bitCast(vm.getInt(rs1))))), @as(u32, @truncate(@as(u64, @bitCast(vm.getInt(rs2)))))))));
}

pub fn subw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) -% @as(i32, @truncate(vm.getInt(rs2))));
}

pub fn sraw(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @as(i32, @truncate(vm.getInt(rs1))) >> @truncate(@as(u64, @bitCast(vm.getInt(rs2)))));
}

pub fn @"fmadd.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setFloat(rd, @mulAdd(f32, vm.getFloat(rs1), vm.getFloat(rs2), vm.getFloat(rs3)));
}

pub fn @"fmadd.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setDouble(rd, @mulAdd(f64, vm.getDouble(rs1), vm.getDouble(rs2), vm.getDouble(rs3)));
}

pub fn @"fmsub.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setFloat(rd, @mulAdd(f32, vm.getFloat(rs1), vm.getFloat(rs2), -vm.getFloat(rs3)));
}

pub fn @"fmsub.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setDouble(rd, @mulAdd(f64, vm.getDouble(rs1), vm.getDouble(rs2), -vm.getDouble(rs3)));
}

pub fn @"fnmsub.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setFloat(rd, @mulAdd(f32, -vm.getFloat(rs1), vm.getFloat(rs2), -vm.getFloat(rs3)));
}

pub fn @"fnmsub.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setDouble(rd, @mulAdd(f64, -vm.getDouble(rs1), vm.getDouble(rs2), -vm.getDouble(rs3)));
}

pub fn @"fnmadd.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setFloat(rd, @mulAdd(f32, -vm.getFloat(rs1), vm.getFloat(rs2), vm.getFloat(rs3)));
}

pub fn @"fnmadd.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r4.rd;
    const rs1 = inst.r4.rs1;
    const rs2 = inst.r4.rs2;
    const rs3 = inst.r4.rs3;
    vm.setDouble(rd, @mulAdd(f64, -vm.getDouble(rs1), vm.getDouble(rs2), vm.getDouble(rs3)));
}

pub fn @"fadd.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setFloat(rd, vm.getFloat(rs1) + vm.getFloat(rs2));
}

pub fn @"fsub.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setFloat(rd, vm.getFloat(rs1) - vm.getFloat(rs2));
}

pub fn @"fmul.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setFloat(rd, vm.getFloat(rs1) * vm.getFloat(rs2));
}

pub fn @"fdiv.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setFloat(rd, vm.getFloat(rs1) / vm.getFloat(rs2));
}

pub fn @"fsgnj.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    const sign_bit_mask: u32 = 1 << 31;
    const mag: u32 = @bitCast(vm.getFloat(rs1));
    const sign: u32 = @bitCast(vm.getFloat(rs2));
    vm.setFloat(rd, @bitCast((mag & ~sign_bit_mask) | (sign & sign_bit_mask)));
}

pub fn @"fsgnjn.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    const sign_bit_mask: u32 = 1 << 31;
    const mag: u32 = @bitCast(vm.getFloat(rs1));
    const sign: u32 = @bitCast(vm.getFloat(rs2));
    vm.setFloat(rd, @bitCast((mag & ~sign_bit_mask) | ((sign ^ sign_bit_mask) & sign_bit_mask)));
}

pub fn @"fsgnjx.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    const sign_bit_mask: u32 = 1 << 31;
    const mag: u32 = @bitCast(vm.getFloat(rs1));
    const sign: u32 = @bitCast(vm.getFloat(rs2));
    vm.setFloat(rd, @bitCast((mag & ~sign_bit_mask) | ((mag ^ sign) & sign_bit_mask)));
}

pub fn @"fmin.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setFloat(rd, @min(vm.getFloat(rs1), vm.getFloat(rs2)));
}

pub fn @"fmax.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setFloat(rd, @max(vm.getFloat(rs1), vm.getFloat(rs2)));
}

pub fn @"fcvt.s.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setFloat(rd, @floatCast(vm.getDouble(rs1)));
}

pub fn @"fsqrt.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setFloat(rd, @sqrt(vm.getFloat(rs1)));
}

pub fn @"fle.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(vm.getFloat(rs1) <= vm.getFloat(rs2)));
}

pub fn @"flt.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(vm.getFloat(rs1) < vm.getFloat(rs2)));
}

pub fn @"feq.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(vm.getFloat(rs1) == vm.getFloat(rs2)));
}

pub fn @"fcvt.w.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @as(i32, @intFromFloat(vm.getFloat(rs1))));
}

pub fn @"fcvt.wu.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @as(i32, @bitCast(@as(u32, @intFromFloat(vm.getFloat(rs1))))));
}

pub fn @"fcvt.l.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @intFromFloat(vm.getFloat(rs1)));
}

pub fn @"fcvt.lu.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @bitCast(@as(u64, @intFromFloat(vm.getFloat(rs1)))));
}

pub fn @"fcvt.s.w"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setFloat(rd, @floatFromInt(@as(i32, @truncate(vm.getInt(rs1)))));
}

pub fn @"fcvt.s.wu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setFloat(rd, @floatFromInt(@as(u32, @truncate(@as(u64, @bitCast(vm.getInt(rs1)))))));
}

pub fn @"fcvt.s.l"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setFloat(rd, @floatFromInt(vm.getInt(rs1)));
}

pub fn @"fcvt.s.lu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setFloat(rd, @floatFromInt(@as(u64, @bitCast(vm.getInt(rs1)))));
}

pub fn @"fmv.x.w"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @as(i32, @bitCast(vm.getFloat(rs1))));
}

pub fn @"fclass.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, floatClass(vm.getFloat(rs1)));
}

pub fn @"fmv.w.x"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setFloat(rd, @bitCast(@as(i32, @truncate(vm.getInt(rs1)))));
}

pub fn @"fadd.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setDouble(rd, vm.getDouble(rs1) + vm.getDouble(rs2));
}

pub fn @"fsub.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setDouble(rd, vm.getDouble(rs1) - vm.getDouble(rs2));
}

pub fn @"fmul.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setDouble(rd, vm.getDouble(rs1) * vm.getDouble(rs2));
}

pub fn @"fdiv.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setDouble(rd, vm.getDouble(rs1) / vm.getDouble(rs2));
}

pub fn @"fsgnj.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    const sign_bit_mask: u64 = 1 << 63;
    const mag: u64 = @bitCast(vm.getDouble(rs1));
    const sign: u64 = @bitCast(vm.getDouble(rs2));
    vm.setDouble(rd, @bitCast((mag & ~sign_bit_mask) | (sign & sign_bit_mask)));
}

pub fn @"fsgnjn.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    const sign_bit_mask: u64 = 1 << 63;
    const mag: u64 = @bitCast(vm.getDouble(rs1));
    const sign: u64 = @bitCast(vm.getDouble(rs2));
    vm.setDouble(rd, @bitCast((mag & ~sign_bit_mask) | ((sign ^ sign_bit_mask) & sign_bit_mask)));
}

pub fn @"fsgnjx.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    const sign_bit_mask: u64 = 1 << 63;
    const mag: u64 = @bitCast(vm.getDouble(rs1));
    const sign: u64 = @bitCast(vm.getDouble(rs2));
    vm.setDouble(rd, @bitCast((mag & ~sign_bit_mask) | ((mag ^ sign) & sign_bit_mask)));
}

pub fn @"fmin.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setDouble(rd, @min(vm.getDouble(rs1), vm.getDouble(rs2)));
}

pub fn @"fmax.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setDouble(rd, @max(vm.getDouble(rs1), vm.getDouble(rs2)));
}

pub fn @"fcvt.d.s"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setDouble(rd, @floatCast(vm.getFloat(rs1)));
}

pub fn @"fsqrt.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setDouble(rd, @sqrt(vm.getDouble(rs1)));
}

pub fn @"fle.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(vm.getDouble(rs1) <= vm.getDouble(rs2)));
}

pub fn @"flt.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(vm.getDouble(rs1) < vm.getDouble(rs2)));
}

pub fn @"feq.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    const rs2 = inst.r.rs2;
    vm.setInt(rd, @intFromBool(vm.getDouble(rs1) == vm.getDouble(rs2)));
}

pub fn @"fcvt.w.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @as(i32, @intFromFloat(vm.getDouble(rs1))));
}

pub fn @"fcvt.wu.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @as(i32, @bitCast(@as(u32, @intFromFloat(vm.getDouble(rs1))))));
}

pub fn @"fcvt.l.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @intFromFloat(vm.getDouble(rs1)));
}

pub fn @"fcvt.lu.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @bitCast(@as(u64, @intFromFloat(vm.getDouble(rs1)))));
}

pub fn @"fcvt.d.w"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setDouble(rd, @floatFromInt(@as(i32, @truncate(vm.getInt(rs1)))));
}

pub fn @"fcvt.d.wu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setDouble(rd, @floatFromInt(@as(u32, @truncate(@as(u64, @bitCast(vm.getInt(rs1)))))));
}

pub fn @"fcvt.d.l"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setDouble(rd, @floatFromInt(vm.getInt(rs1)));
}

pub fn @"fcvt.d.lu"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setDouble(rd, @floatFromInt(@as(u64, @bitCast(vm.getInt(rs1)))));
}

pub fn @"fmv.x.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, @bitCast(vm.getDouble(rs1)));
}

pub fn @"fclass.d"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setInt(rd, floatClass(vm.getDouble(rs1)));
}

pub fn @"fmv.d.x"(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    const rd = inst.r.rd;
    const rs1 = inst.r.rs1;
    vm.setDouble(rd, @bitCast(@as(i64, @truncate(vm.getInt(rs1)))));
}

pub fn beq(vm: *VM, inst: Inst) !void {
    const curr_pc = vm.pc;
    vm.pc +%= 4;
    const rs1 = inst.b.rs1;
    const rs2 = inst.b.rs2;
    if (vm.getInt(rs1) == vm.getInt(rs2)) {
        vm.pc = curr_pc +% inst.unpackBranchOffset();
    }
}

pub fn bne(vm: *VM, inst: Inst) !void {
    const curr_pc = vm.pc;
    vm.pc +%= 4;
    const rs1 = inst.b.rs1;
    const rs2 = inst.b.rs2;

    const rs1_val = vm.getInt(inst.b.rs1);
    const rs2_val = vm.getInt(inst.b.rs2);
    std.debug.print("BNE: PC=0x{X}, a0={}, x0={}. Taken? {}\n", .{ vm.pc, rs1_val, rs2_val, rs1_val != rs2_val });

    if (vm.getInt(rs1) != vm.getInt(rs2)) {
        vm.pc = curr_pc +% inst.unpackBranchOffset();
    }
}

pub fn blt(vm: *VM, inst: Inst) !void {
    const curr_pc = vm.pc;
    vm.pc +%= 4;
    const rs1 = inst.b.rs1;
    const rs2 = inst.b.rs2;
    if (vm.getInt(rs1) < vm.getInt(rs2)) {
        vm.pc = curr_pc +% inst.unpackBranchOffset();
    }
}

pub fn bge(vm: *VM, inst: Inst) !void {
    const curr_pc = vm.pc;
    vm.pc +%= 4;
    const rs1 = inst.b.rs1;
    const rs2 = inst.b.rs2;
    if (vm.getInt(rs1) >= vm.getInt(rs2)) {
        vm.pc = curr_pc +% inst.unpackBranchOffset();
    }
}

pub fn bltu(vm: *VM, inst: Inst) !void {
    const curr_pc = vm.pc;
    vm.pc +%= 4;
    const rs1 = inst.b.rs1;
    const rs2 = inst.b.rs2;
    if (@as(u64, @bitCast(vm.getInt(rs1))) < @as(u64, @bitCast(vm.getInt(rs2)))) {
        vm.pc = curr_pc +% inst.unpackBranchOffset();
    }
}

pub fn bgeu(vm: *VM, inst: Inst) !void {
    const curr_pc = vm.pc;
    vm.pc +%= 4;
    const rs1 = inst.b.rs1;
    const rs2 = inst.b.rs2;
    if (@as(u64, @bitCast(vm.getInt(rs1))) >= @as(u64, @bitCast(vm.getInt(rs2)))) {
        vm.pc = curr_pc +% inst.unpackBranchOffset();
    }
}

pub fn jalr(vm: *VM, inst: Inst) !void {
    const rd = inst.i.rd;
    const rs1 = inst.i.rs1;
    const imm12 = inst.i.imm12;
    const curr_pc = vm.pc;
    vm.setInt(rd, curr_pc +% 4);
    vm.pc = (vm.getInt(rs1) +% imm12) & ~@as(i64, 1);
}

pub fn jal(vm: *VM, inst: Inst) !void {
    const rd = inst.j.rd;
    const offset = inst.unpackJumpOffset();
    const curr_pc = vm.pc;
    vm.setInt(rd, curr_pc +% 4);
    vm.pc = curr_pc +% offset;
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
    switch (vm.getInt(.a7)) {
        0 => {
            const ptr: u64 = @bitCast(vm.getInt(.a0));
            const len: u64 = @bitCast(vm.getInt(.a1));
            vm.dumpIntRegs();
            std.debug.print("{any}\n", .{vm.memory[ptr..][0..len]});
            std.debug.print("written: {d}\n", .{len});
        },
        1 => {
            std.debug.print("debug int: {}\n", .{vm.getInt(.a0)});
        },
        else => {},
    }
}

pub fn ebreak(vm: *VM, inst: Inst) !void {
    vm.pc +%= 4;
    _ = inst;
}
