import os
import sys

from instructions import Branch, Inst, opcode_tree

GENERATE_TEMPLATE = False


def split_by_line(full_string: str, split_text: str):
    content_index = full_string.find(split_text)
    if content_index == -1:
        raise ValueError("String not found")

    line_start = full_string.rfind("\n", 0, content_index)
    line_start = 0 if line_start == -1 else line_start
    line_end = full_string.find("\n", content_index + len(split_text))
    line_end = len(full_string) if line_end == -1 else line_end + 1

    a = full_string[:line_start]
    b = full_string[line_start:line_end]
    c = full_string[line_end:]
    return a, b, c


def generate_parser(item: Branch | Inst, indent: int):
    if isinstance(item, Inst):
        print(f'@call(.always_inline, impl.@"{item.name}", .{{ vm, inst }})', end="")
        return

    low, high = item.range
    print(f"switch (@as(u{high - low}, @truncate(inst.raw >> {low}))) {{")
    indent += 4

    for value, child in item.children.items():
        print(f"{' ' * indent}{value} => ", end="")
        generate_parser(child, indent)
        print(",")

    if len(item.children) < 1 << high - low:
        if item.other is None:
            print(f"{' ' * indent}else => error.InvalidInstruction,")
        else:
            print(f"{' ' * indent}else => ", end="")
            generate_parser(item.other, indent)
            print(",")

    indent -= 4
    print(f"{' ' * indent}}}", end="")


arg_fomatting = {
    "rd": ["{t}", "inst.r.rd"],
    "rs1": ["{t}", "inst.r.rs1"],
    "imm12": ["{f}", "fmtHex(inst.i.imm12)"],
    "succ": ["{f}", "fmtHex(@as(u4, @truncate(@as(u12, @bitCast(inst.i.imm12)))))"],
    "pred": [
        "{f}",
        "fmtHex(@as(u4, @truncate(@as(u12, @bitCast(inst.i.imm12)) >> 4)))",
    ],
    "fm": ["{f}", "fmtHex(@as(u4, @truncate(@as(u12, @bitCast(inst.i.imm12)) >> 8)))"],
    "shamtd": ["{f}", "fmtHex(inst.i.imm12)"],
    "imm20": ["{f}", "fmtHex(inst.u.imm20)"],
    "shamtw": ["{f}", "fmtHex(inst.i.imm12)"],
    "imm12lo": ["{f}", "fmtHex(inst.unpackStoreOffset())"],
    "rs2": ["{t}", "inst.r.rs2"],
    "imm12hi": None,
    "rm": ["{f}", "fmtHex(inst.r.func3)"],
    "rs3": ["{t}", "inst.r4.rs3"],
    "bimm12lo": ["{f}", "fmtHex(inst.unpackBranchOffset())"],
    "bimm12hi": None,
    "jimm20": ["{f}", "fmtHex(inst.unpackJumpOffset())"],
    "csr": ["{f}", "fmtHex(inst.i.imm12)"],
    "zimm5": ["{f}", "fmtHex(inst.i.imm12)"],
}


def generate_disassembler(item: Branch | Inst, indent: int):
    if isinstance(item, Inst):
        print("return writer.print(", end="")
        print(f'"{item.name}', end="")
        for arg in item.full_args_raw:
            fmt = arg_fomatting[arg]
            if fmt is None:
                continue
            print(f" {fmt[0]}", end="")
        print('", .{ ', end="")
        first = True
        for arg in item.full_args_raw:
            fmt = arg_fomatting[arg]
            if fmt is None:
                continue
            if first:
                first = False
            else:
                print(", ", end="")
            print(fmt[1], end="")
        print(" })", end="")
        # print(f'"{item.name}"', end="")
        return

    low, high = item.range
    print(f"switch (@as(u{high - low}, @truncate(inst.raw >> {low}))) {{")
    indent += 4

    for value, child in item.children.items():
        print(f"{' ' * indent}{value} => ", end="")
        generate_disassembler(child, indent)
        print(",")

    if len(item.children) < 1 << high - low:
        if item.other is None:
            print(f"{' ' * indent}else => {{}},")
        else:
            print(f"{' ' * indent}else => ", end="")
            generate_disassembler(item.other, indent)
            print(",")

    indent -= 4
    print(f"{' ' * indent}}}", end="")


original_stdout = sys.stdout
try:
    with open("src/dis.zig", "w") as f:
        sys.stdout = f
        print('const std = @import("std");')
        print("const Io = std.Io;")
        print()
        print('const emu = @import("emu.zig");')
        print("const Inst = emu.Inst;")
        print()
        print("pub fn formatHex(value: i64, w: *Io.Writer) Io.Writer.Error!void {")
        print(
            '    return w.print("{s}0x{X}", .{ if (value < 0) "-" else "", @abs(value) });'
        )
        print("}")
        print()
        print("pub fn fmtHex(value: i64) std.fmt.Alt(i64, formatHex) {")
        print("    return .{ .data = value };")
        print("}")
        print()
        print("pub fn disassemble(writer: *Io.Writer, inst: Inst) !void {")
        print("    ", end="")
        generate_disassembler(opcode_tree, 4)
        print()
        print('    return writer.print(".word 0x{X}", .{inst.raw});')
        print("}")
finally:
    sys.stdout = original_stdout


# def generate_implementation(item: Branch | Inst):
#     if isinstance(item, Inst):
#         print(f'pub fn @"{item.name}"(vm: *VM, inst: Inst) !void {{')
#         if item.name in instructions:
#             print(instructions[item.name])
#         print("}")
#         print()
#         return

#     for child in item.children.values():
#         generate_implementation(child)

#     if not item.other is None:
#         generate_implementation(item.other)


# original_stdout = sys.stdout
# try:
#     if GENERATE_TEMPLATE:
#         instructions = {}
#         with open('src/impl.zig') as f:
#             code = f.read()
#             template_start, _, code = split_by_line(code, "// Instruction implementation")
#             while True:
#                 try:
#                     prev_code, fn_line, code = split_by_line(code, "pub fn ")
#                 except:
#                     break
#                 name = fn_line.split("pub fn ", 1)[1].split("(", 1)[0].strip("@\"")
#                 fn_code, code = code.split("\n}\n", 1)
#                 instructions[name] = fn_code

#         with open('src/impl.zig', 'w') as f:
#             sys.stdout = f
#             print(template_start)
#             print("// Instruction implementation")
#             print()
#             generate_implementation(opcode_tree)

#         os.system('zig fmt src/impl.zig')
#     else:
#         with open("src/decode.zig") as f:
#             code = f.read()
#             template_start, _, code = split_by_line(code, "// exec start")
#             _, _, code = split_by_line(code, "// exec end")
#             template_middle, _, code = split_by_line(code, "// disassemble start")
#             _, _, template_end = split_by_line(code, "// disassemble end")

#         with open('src/decode.zig', 'w') as f:
#             sys.stdout = f
#             print(template_start)
#             print("    // exec start")
#             print("    return ", end="")
#             generate_parser(opcode_tree, 4)
#             print(";")
#             print("    // exec end")
#             print(template_middle)
#             print("    // disassemble start")
#             print("    return ", end="")
#             generate_disassembler(opcode_tree, 4)
#             print(";")
#             print("    // disassemble end")
#             print(template_end)

#         os.system('zig fmt src/decode.zig')
# finally:
#     sys.stdout = original_stdout
