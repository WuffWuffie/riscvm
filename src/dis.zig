const std = @import("std");
const Io = std.Io;

const emu = @import("emu.zig");
const Inst = emu.Inst;

pub fn formatHex(value: i64, w: *Io.Writer) Io.Writer.Error!void {
    return w.print("{s}0x{X}", .{ if (value < 0) "-" else "", @abs(value) });
}

pub fn fmtHex(value: i64) std.fmt.Alt(i64, formatHex) {
    return .{ .data = value };
}

pub fn disassemble(writer: *Io.Writer, inst: Inst) !void {
    switch (@as(u2, @truncate(inst.raw >> 0))) {
        3 => switch (@as(u5, @truncate(inst.raw >> 2))) {
            0 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                0 => return writer.print("lb {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                1 => return writer.print("lh {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                2 => return writer.print("lw {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                3 => return writer.print("ld {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                4 => return writer.print("lbu {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                5 => return writer.print("lhu {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                6 => return writer.print("lwu {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                else => {},
            },
            1 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                2 => return writer.print("flw {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                3 => return writer.print("fld {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                else => {},
            },
            3 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                0 => return writer.print("fence {t} {t} {f} {f} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(@as(u4, @truncate(@as(u12, @bitCast(inst.i.imm12))))), fmtHex(@as(u4, @truncate(@as(u12, @bitCast(inst.i.imm12)) >> 4))), fmtHex(@as(u4, @truncate(@as(u12, @bitCast(inst.i.imm12)) >> 8))) }),
                else => {},
            },
            4 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                0 => return writer.print("addi {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                1 => switch (@as(u6, @truncate(inst.raw >> 26))) {
                    0 => return writer.print("slli {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                    else => {},
                },
                2 => return writer.print("slti {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                3 => return writer.print("sltiu {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                4 => return writer.print("xori {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                5 => switch (@as(u6, @truncate(inst.raw >> 26))) {
                    0 => return writer.print("srli {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                    16 => return writer.print("srai {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                    else => {},
                },
                6 => return writer.print("ori {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                7 => return writer.print("andi {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
            },
            5 => return writer.print("auipc {t} {f}", .{ inst.r.rd, fmtHex(inst.u.imm20) }),
            6 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                0 => return writer.print("addiw {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                1 => switch (@as(u7, @truncate(inst.raw >> 25))) {
                    0 => return writer.print("slliw {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                    else => {},
                },
                5 => switch (@as(u7, @truncate(inst.raw >> 25))) {
                    0 => return writer.print("srliw {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                    32 => return writer.print("sraiw {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                    else => {},
                },
                else => {},
            },
            8 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                0 => return writer.print("sb {f} {t} {t}", .{ fmtHex(inst.unpackStoreOffset()), inst.r.rs1, inst.r.rs2 }),
                1 => return writer.print("sh {f} {t} {t}", .{ fmtHex(inst.unpackStoreOffset()), inst.r.rs1, inst.r.rs2 }),
                2 => return writer.print("sw {f} {t} {t}", .{ fmtHex(inst.unpackStoreOffset()), inst.r.rs1, inst.r.rs2 }),
                3 => return writer.print("sd {f} {t} {t}", .{ fmtHex(inst.unpackStoreOffset()), inst.r.rs1, inst.r.rs2 }),
                else => {},
            },
            9 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                2 => return writer.print("fsw {f} {t} {t}", .{ fmtHex(inst.unpackStoreOffset()), inst.r.rs1, inst.r.rs2 }),
                3 => return writer.print("fsd {f} {t} {t}", .{ fmtHex(inst.unpackStoreOffset()), inst.r.rs1, inst.r.rs2 }),
                else => {},
            },
            12 => switch (@as(u7, @truncate(inst.raw >> 25))) {
                0 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                    0 => return writer.print("add {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    1 => return writer.print("sll {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    2 => return writer.print("slt {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    3 => return writer.print("sltu {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    4 => return writer.print("xor {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    5 => return writer.print("srl {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    6 => return writer.print("or {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    7 => return writer.print("and {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                },
                1 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                    0 => return writer.print("mul {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    1 => return writer.print("mulh {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    2 => return writer.print("mulhsu {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    3 => return writer.print("mulhu {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    4 => return writer.print("div {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    5 => return writer.print("divu {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    6 => return writer.print("rem {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    7 => return writer.print("remu {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                },
                32 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                    0 => return writer.print("sub {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    5 => return writer.print("sra {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    else => {},
                },
                else => {},
            },
            13 => return writer.print("lui {t} {f}", .{ inst.r.rd, fmtHex(inst.u.imm20) }),
            14 => switch (@as(u7, @truncate(inst.raw >> 25))) {
                0 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                    0 => return writer.print("addw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    1 => return writer.print("sllw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    5 => return writer.print("srlw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    else => {},
                },
                1 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                    0 => return writer.print("mulw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    4 => return writer.print("divw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    5 => return writer.print("divuw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    6 => return writer.print("remw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    7 => return writer.print("remuw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    else => {},
                },
                32 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                    0 => return writer.print("subw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    5 => return writer.print("sraw {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                    else => {},
                },
                else => {},
            },
            16 => switch (@as(u2, @truncate(inst.raw >> 25))) {
                0 => return writer.print("fmadd.s {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                1 => return writer.print("fmadd.d {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                else => {},
            },
            17 => switch (@as(u2, @truncate(inst.raw >> 25))) {
                0 => return writer.print("fmsub.s {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                1 => return writer.print("fmsub.d {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                else => {},
            },
            18 => switch (@as(u2, @truncate(inst.raw >> 25))) {
                0 => return writer.print("fnmsub.s {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                1 => return writer.print("fnmsub.d {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                else => {},
            },
            19 => switch (@as(u2, @truncate(inst.raw >> 25))) {
                0 => return writer.print("fnmadd.s {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                1 => return writer.print("fnmadd.d {t} {f} {t} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2, inst.r4.rs3 }),
                else => {},
            },
            20 => switch (@as(u2, @truncate(inst.raw >> 25))) {
                0 => switch (@as(u5, @truncate(inst.raw >> 27))) {
                    0 => return writer.print("fadd.s {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    1 => return writer.print("fsub.s {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    2 => return writer.print("fmul.s {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    3 => return writer.print("fdiv.s {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    4 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                        0 => return writer.print("fsgnj.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        1 => return writer.print("fsgnjn.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        2 => return writer.print("fsgnjx.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        else => {},
                    },
                    5 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                        0 => return writer.print("fmin.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        1 => return writer.print("fmax.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        else => {},
                    },
                    8 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        1 => return writer.print("fcvt.s.d {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    11 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("fsqrt.s {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    20 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                        0 => return writer.print("fle.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        1 => return writer.print("flt.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        2 => return writer.print("feq.s {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        else => {},
                    },
                    24 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("fcvt.w.s {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        1 => return writer.print("fcvt.wu.s {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        2 => return writer.print("fcvt.l.s {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        3 => return writer.print("fcvt.lu.s {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    26 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("fcvt.s.w {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        1 => return writer.print("fcvt.s.wu {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        2 => return writer.print("fcvt.s.l {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        3 => return writer.print("fcvt.s.lu {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    28 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                            0 => return writer.print("fmv.x.w {t} {t}", .{ inst.r.rd, inst.r.rs1 }),
                            1 => return writer.print("fclass.s {t} {t}", .{ inst.r.rd, inst.r.rs1 }),
                            else => {},
                        },
                        else => {},
                    },
                    30 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                            0 => return writer.print("fmv.w.x {t} {t}", .{ inst.r.rd, inst.r.rs1 }),
                            else => {},
                        },
                        else => {},
                    },
                    else => {},
                },
                1 => switch (@as(u5, @truncate(inst.raw >> 27))) {
                    0 => return writer.print("fadd.d {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    1 => return writer.print("fsub.d {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    2 => return writer.print("fmul.d {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    3 => return writer.print("fdiv.d {t} {f} {t} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1, inst.r.rs2 }),
                    4 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                        0 => return writer.print("fsgnj.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        1 => return writer.print("fsgnjn.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        2 => return writer.print("fsgnjx.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        else => {},
                    },
                    5 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                        0 => return writer.print("fmin.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        1 => return writer.print("fmax.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        else => {},
                    },
                    8 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("fcvt.d.s {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    11 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("fsqrt.d {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    20 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                        0 => return writer.print("fle.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        1 => return writer.print("flt.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        2 => return writer.print("feq.d {t} {t} {t}", .{ inst.r.rd, inst.r.rs1, inst.r.rs2 }),
                        else => {},
                    },
                    24 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("fcvt.w.d {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        1 => return writer.print("fcvt.wu.d {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        2 => return writer.print("fcvt.l.d {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        3 => return writer.print("fcvt.lu.d {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    26 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("fcvt.d.w {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        1 => return writer.print("fcvt.d.wu {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        2 => return writer.print("fcvt.d.l {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        3 => return writer.print("fcvt.d.lu {t} {f} {t}", .{ inst.r.rd, fmtHex(inst.r.func3), inst.r.rs1 }),
                        else => {},
                    },
                    28 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                            0 => return writer.print("fmv.x.d {t} {t}", .{ inst.r.rd, inst.r.rs1 }),
                            1 => return writer.print("fclass.d {t} {t}", .{ inst.r.rd, inst.r.rs1 }),
                            else => {},
                        },
                        else => {},
                    },
                    30 => switch (@as(u5, @truncate(inst.raw >> 20))) {
                        0 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                            0 => return writer.print("fmv.d.x {t} {t}", .{ inst.r.rd, inst.r.rs1 }),
                            else => {},
                        },
                        else => {},
                    },
                    else => {},
                },
                else => {},
            },
            24 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                0 => return writer.print("beq {f} {t} {t}", .{ fmtHex(inst.unpackBranchOffset()), inst.r.rs1, inst.r.rs2 }),
                1 => return writer.print("bne {f} {t} {t}", .{ fmtHex(inst.unpackBranchOffset()), inst.r.rs1, inst.r.rs2 }),
                4 => return writer.print("blt {f} {t} {t}", .{ fmtHex(inst.unpackBranchOffset()), inst.r.rs1, inst.r.rs2 }),
                5 => return writer.print("bge {f} {t} {t}", .{ fmtHex(inst.unpackBranchOffset()), inst.r.rs1, inst.r.rs2 }),
                6 => return writer.print("bltu {f} {t} {t}", .{ fmtHex(inst.unpackBranchOffset()), inst.r.rs1, inst.r.rs2 }),
                7 => return writer.print("bgeu {f} {t} {t}", .{ fmtHex(inst.unpackBranchOffset()), inst.r.rs1, inst.r.rs2 }),
                else => {},
            },
            25 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                0 => return writer.print("jalr {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                else => {},
            },
            27 => return writer.print("jal {t} {f}", .{ inst.r.rd, fmtHex(inst.unpackJumpOffset()) }),
            28 => switch (@as(u3, @truncate(inst.raw >> 12))) {
                1 => return writer.print("csrrw {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                2 => return writer.print("csrrs {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                3 => return writer.print("csrrc {t} {t} {f}", .{ inst.r.rd, inst.r.rs1, fmtHex(inst.i.imm12) }),
                5 => return writer.print("csrrwi {t} {f} {f}", .{ inst.r.rd, fmtHex(inst.i.imm12), fmtHex(inst.i.imm12) }),
                6 => return writer.print("csrrsi {t} {f} {f}", .{ inst.r.rd, fmtHex(inst.i.imm12), fmtHex(inst.i.imm12) }),
                7 => return writer.print("csrrci {t} {f} {f}", .{ inst.r.rd, fmtHex(inst.i.imm12), fmtHex(inst.i.imm12) }),
                else => switch (@as(u13, @truncate(inst.raw >> 7))) {
                    0 => switch (@as(u12, @truncate(inst.raw >> 20))) {
                        0 => return writer.print("ecall", .{}),
                        1 => return writer.print("ebreak", .{}),
                        else => {},
                    },
                    else => {},
                },
            },
            else => {},
        },
        else => {},
    }
    return writer.print(".word 0x{X}", .{inst.raw});
}
