from instructions import Inst, Branch, opcode_tree
import sys
import os 

GENERATE_TEMPLATE = False

def split_by_line(full_string: str, split_text: str):
    content_index = full_string.find(split_text)
    if content_index == -1:
        raise ValueError("String not found")

    line_start = full_string.rfind('\n', 0, content_index)
    line_start = 0 if line_start == -1 else line_start
    line_end = full_string.find('\n', content_index + len(split_text))
    line_end = len(full_string) if line_end == -1 else line_end + 1

    a = full_string[:line_start]
    b = full_string[line_start:line_end]
    c = full_string[line_end:]
    return a, b, c

def generate_parser(item: Branch | Inst, indent: int):
    if isinstance(item, Inst):
        print(f"@call(.always_inline, impl.@\"{item.name}\", .{{ vm, inst }})", end="")
        return
    
    low, high = item.range
    print(f"switch (@as(u{high - low}, @truncate(inst.raw >> {low}))) {{")
    indent += 4

    for value, child in item.children.items():
        print(f"{" " * indent}{value} => ", end="")
        generate_parser(child, indent)
        print(",")
    
    if len(item.children) < 1 << high - low:
        if item.other is None:
            print(f"{" " * indent}else => error.InvalidInstruction,")
        else:
            print(f"{" " * indent}else => ", end="")
            generate_parser(item.other, indent)
            print(",")

    indent -= 4
    print(f"{" " * indent}}}", end="")

def generate_disassembler(item: Branch | Inst, indent: int):
    if isinstance(item, Inst):
        print(f"\"{item.name}\"", end="")
        return
    
    low, high = item.range
    print(f"switch (@as(u{high - low}, @truncate(inst >> {low}))) {{")
    indent += 4

    for value, child in item.children.items():
        print(f"{" " * indent}{value} => ", end="")
        generate_disassembler(child, indent)
        print(",")
    
    if len(item.children) < 1 << high - low:
        if item.other is None:
            print(f"{" " * indent}else => null,")
        else:
            print(f"{" " * indent}else => ", end="")
            generate_disassembler(item.other, indent)
            print(",")

    indent -= 4
    print(f"{" " * indent}}}", end="")

def generate_implementation(item: Branch | Inst):
    if isinstance(item, Inst):
        print(f"pub fn @\"{item.name}\"(vm: *VM, inst: Inst) !void {{")
        if item.name in instructions:
            print(instructions[item.name])
        print("}")
        print()
        return
    
    for child in item.children.values():
        generate_implementation(child)
    
    if not item.other is None:
        generate_implementation(item.other)

original_stdout = sys.stdout
try:
    if GENERATE_TEMPLATE:
        instructions = {}
        with open('src/impl.zig') as f:
            code = f.read()
            template_start, _, code = split_by_line(code, "// Instruction implementation")
            while True:
                try:
                    prev_code, fn_line, code = split_by_line(code, "pub fn ")
                except:
                    break
                name = fn_line.split("pub fn ", 1)[1].split("(", 1)[0].strip("@\"")
                fn_code, code = code.split("\n}\n", 1)
                instructions[name] = fn_code

        with open('src/impl.zig', 'w') as f:
            sys.stdout = f
            print(template_start)
            print("// Instruction implementation")
            print()
            generate_implementation(opcode_tree)

        os.system('zig fmt src/impl.zig')
    else:
        with open("src/decode.zig") as f:
            code = f.read()
            template_start, _, code = split_by_line(code, "// exec start")
            _, _, code = split_by_line(code, "// exec end")
            template_middle, _, code = split_by_line(code, "// disassemble start")
            _, _, template_end = split_by_line(code, "// disassemble end")
        
        with open('src/decode.zig', 'w') as f:
            sys.stdout = f
            print(template_start)
            print("    // exec start")
            print("    return ", end="")
            generate_parser(opcode_tree, 4)
            print(";")
            print("    // exec end")
            print(template_middle)
            print("    // disassemble start")
            print("    return ", end="")
            generate_disassembler(opcode_tree, 4)
            print(";")
            print("    // disassemble end")
            print(template_end)
        
        os.system('zig fmt src/decode.zig')
finally:
    sys.stdout = original_stdout


# @contextmanager
# def change_directory(new_path):
#     original_cwd = os.getcwd()
#     try:
#         os.chdir(new_path)
#         yield
#     finally:
#         os.chdir(original_cwd)

# with change_directory("riscv-opcodes"):
#     lib_path = os.path.abspath('constants.py')
#     spec = importlib.util.spec_from_file_location("riscv_opcodes.constants", lib_path)
#     riscv_constants = importlib.util.module_from_spec(spec)
#     spec.loader.exec_module(riscv_constants)

# arg_lut = {}
# for name, (high, low) in riscv_constants.arg_lut.items():
#     arg_lut[name] = (low, high + 1)

# def sort_args(args: list[str]) -> list[str]:
#     return sorted(args, key=lambda arg: arg_lut[arg][0])

# with open("args_code.json", 'r') as f:
#     args_code = json.load(f)

# inst_code = {}

# print(instructions)

# def create_opcode_tree(instructions: list[Inst]) -> Branch | Inst:
#     if len(instructions) == 1 and len(instructions[0].opcodes) == 0:
#         return instructions[0]
    
#     if len(instructions) == 0:
#         return
    
#     contained_insts = [inst.name for inst in instructions]
    
#     # Find the opcode ranges that are present in each instruction
#     common_ranges = None
#     for inst in instructions:
#         current_ranges = set(inst.opcodes.keys())
#         if common_ranges is None:
#             common_ranges = current_ranges
#         else:
#             common_ranges.intersection_update(current_ranges)
    
#     # Find the opcode range which splits into the least amount of instruction groups
#     range_value_sets = {r: {} for r in common_ranges}
    
#     for inst in instructions:
#         for opcode_range, value in inst.opcodes.items():
#             if opcode_range in range_value_sets:
#                 value_ints = range_value_sets[opcode_range].setdefault(value, [])
#                 value_ints.append(inst)
    
#     range = None
#     min_unique_values = float('inf')

#     for opcode_range, value_set in range_value_sets.items():
#         num_unique = len(value_set)
#         if num_unique < min_unique_values:
#             min_unique_values = num_unique
#             range = opcode_range
    
#     if not range:
#         raise ValueError("Failed to find fitting opcode group")

#     for inst in instructions:
#         del inst.opcodes[range]
    
#     opcodes = range_value_sets[range]

#     if UNSAFE_OPTIMIZE_DECODE and len(opcodes) == 1:
#         # Any invalid instruction is considered unspecified behavior, so the decoder 
#         # can emit whatever it wants in place of what would otherwise be undefined
#         # This shouldn't make correct instructions work incorrectly
#         return create_opcode_tree(next(iter(opcodes.values())))
    
#     # Find common arguments
#     args = None
#     for inst in instructions:
#         current_args = set(inst.args)
#         if args is None:
#             args = current_args
#         else:
#             args.intersection_update(current_args)

#     for inst in instructions:
#         inst.args = [arg for arg in inst.args if arg not in args]

#     args = sort_args(args)

#     children = {}

#     for value, insts in sorted(opcodes.items()):
#         children[value] = create_opcode_tree(insts)

#     return Branch(args, range, children, contained_insts)

# instructions = create_opcode_tree(instructions)

# def output_arg(item: Branch | Inst, indent: int, arg: str):
#     rule = args_code[arg]
#     if type(rule) is str:
#         code = rule
#     else:
#         if len(rule) == 0:
#             return
#         rule: dict = rule
#         code = rule["code"]
#         if "any" in rule:
#             if isinstance(item, Branch):
#                 return
#             if not item.names in rule["any"]:
#                 return
#         else:
#             if isinstance(item, Inst):
#                 return
#             else:
#                 for inst in item.contained_insts:
#                     if not inst in rule["all"]:
#                         return
#     for line in code.splitlines():
#         print(f"{" " * indent}{line}")

# def generate_parser(item: Branch | Inst, indent: int):
#     # for arg in item.args:
#     #     output_arg(item, indent, arg)
#     if isinstance(item, Inst):
#         for arg in item.full_args:
#             output_arg(item, indent, arg)
#         print(f"{" " * indent}// {item.name}")
#         for line in inst_code.get(item.name) or []:
#             print(f"{" " * indent}{line}")
#         print(f"{" " * indent}return;")
#         return
    
#     low, high = item.range
#     print(f"{" " * indent}switch (@as(u{high - low}, @truncate(inst >> {low}))) {{")
#     indent += 4

#     for value, child in item.children.items():
#         print(f"{" " * indent}{value} => {{")
#         indent += 4
#         generate_parser(child, indent)
#         indent -= 4
#         print(f"{" " * indent}}},")
    
#     # print(low, high, (1 << high - low) - 1, len(item.children))
#     if len(item.children) < 1 << high - low:
#         print(f"{" " * indent}else => {{}},")

#     indent -= 4
#     print(f"{" " * indent}}}")

# def generate_template(item: Branch | Inst):
#     if isinstance(item, Inst):
#         print("    {")
#         for arg in item.full_args:
#             output_arg(item, 8, arg)
#         print(f"        // op start: {item.name}")
#         for line in inst_code.get(item.name) or []:
#             print(f"        {line}")
#         print(f"        // op end")
#         print("    }")
#         return
    
#     for child in item.children.values():
#         generate_template(child)

# def generate_template(item: Branch | Inst):
#     if isinstance(item, Inst):
#         print(f"pub fn @\"{item.name}\"(vm: *VM, inst: Inst) !void {{")
#         print("    const curr_pc = vm.pc;")
#         print("    vm.pc += 4;")
#         for arg in item.full_args:
#             output_arg(item, 4, arg)
#         for line in inst_code.get(item.name) or []:
#             print(f"    {line}")
#         print("}")
#         print()
#         return
    
#     for child in item.children.values():
#         generate_template(child)

# print(instructions)

    # if output_parser:
    #     # Find common dymanic arguments
    #     common_args = None
    #     for inst in instructions:
    #         current_args = set(inst["args"])
    #         if common_args is None:
    #             common_args = current_args
    #         else:
    #             common_args.intersection_update(current_args)

    #     for inst in instructions:
    #         inst["args"] = [arg for arg in inst["args"] if arg not in common_args]

    #     low, high = best_range
    #     for arg in sorted_args(common_args):
    #         output_arg(instructions, ident, arg)
    #     print(f"{" " * ident}switch (@as(u{high - low}, @truncate(inst >> {low}))) {{")
    
    # ident += 4
    # for inst in instructions:
    #     del inst["opcodes"][best_range]
    # for value, insts in sorted(opcodes.items()):
    #     if output_parser:
    #         print(f"{" " * ident}{value} => {{")
    #     ident += 4
    #     traverse_opcodes(insts, ident)
    #     ident -= 4
    #     if output_parser:
    #         print(f"{" " * ident}}},")
    # if output_parser:
    #     if len(opcodes) < (1 << high - low) - 1:
    #         print(f"{" " * ident}else => {{}},")
    # ident -= 4
    # if output_parser:
    #     print(f"{" " * ident}}}")


# output_parser = False

# for ext in extensions:
#     filepath = f"riscv-opcodes/extensions/{ext}"
#     with open(filepath, 'r') as f:
#         for line in f:
#             line = line.split('#', 1)[0].split('$pseudo_op', 1)[0].strip()
#             if not line:
#                 continue
#             name, parts = line.split(maxsplit=1)
#             yield (name, parts.split())

# arg_lut = {}
# with open("riscv-opcodes/arg_lut.csv", 'r') as f:
#     for line in f:
#         line = line.strip()
#         if not line:
#             continue
#         arg_name_str, high, low = [p.strip() for p in line.split(",")]
#         arg = arg_name_str[1:-1]
#         low, high = int(low), int(high) + 1
#         arg_lut[arg] = (low, high)

# with open("args_code.json", 'r') as f:
#     args_code = json.load(f)

# inst_code = {}
# with open("src/parser_template.zig") as f:
#     template_start, code = f.read().split("// template start")
#     code, template_end = code.split("// template end")
#     for code in code.strip().split("// op end"):
#         parts = code.split("// op start: ")
#         if len(parts) < 2:
#             continue
#         lines = parts[1].splitlines()
#         name = lines[0]
#         inst_code[name] = [line.strip() for line in lines[1:] if line.strip()]

# instructions = []

# for name, parts in instruction_generator():
#     opcodes = {}
#     args = []
#     for part in parts:
#         if "=" in part:
#             range_str, value_str = part.split('=', 1)
#             if '..' in range_str:
#                 high_bit, low_bit = map(int, range_str.split('..'))
#             else:
#                 high_bit, low_bit = int(range_str), int(range_str)
#             high_bit += 1 # turn into exclusive range
#             if value_str.startswith('0x'):
#                 value = int(value_str, 16)
#             else:
#                 value = int(value_str)
#             opcodes[(low_bit, high_bit)] = value
#         else:
#             args.append(part)
#     instructions.append({
#         "name": name,
#         "opcodes": opcodes,
#         "args": args,
#     })

# def sorted_args(args):
#     return sorted(args, key=lambda arg: arg_lut[arg][0])

# def output_arg(insts, ident, arg):
#     rule = args_code[arg]
#     if type(rule) is str:
#         code = rule
#     else:
#         if len(rule) == 0:
#             return
#         rule: dict = rule
#         code = rule["code"]
#         if "any" in rule:
#             if len(insts) != 1:
#                 return
#             if not insts[0]["name"] in rule["any"]:
#                 return
#         else:
#             for inst in insts:
#                 if not inst in rule["all"]:
#                     return
#     for line in code.splitlines():
#         print(f"{" " * ident}{line}")

# def traverse_opcodes(instructions, ident):
#     if len(instructions) == 1 and len(instructions[0]["opcodes"]) == 0:
#         inst = instructions[0]
#         if not output_parser:
#             print("    {")
#             for arg in sorted_args(inst["args"]):
#                 output_arg(instructions, 8, arg)
#             print(f"        // op start: {inst["name"]}")
#             for line in inst_code[inst["name"]]:
#                 print(f"        {line}")
#             print("        // op end")
#             print("    }")
#             return
#         for arg in sorted_args(inst["args"]):
#             output_arg(instructions, ident, arg)
#         # print(f"{" " * ident}std.debug.print(\"{inst["name"]}\", .{{}});")
#         print(f"{" " * ident}// {inst["name"]}")
#         for line in inst_code[inst["name"]]:
#             print(f"{" " * ident}{line}")
#         return
    
#     if len(instructions) == 0:
#         return
    
#     # Find the opcode ranges that are present in each instruction
#     common_ranges = None
#     for inst in instructions:
#         current_ranges = set(inst["opcodes"].keys())
#         if common_ranges is None:
#             common_ranges = current_ranges
#         else:
#             common_ranges.intersection_update(current_ranges)
    
#     # Find the opcode range which splits into the least amount of instruction groups
#     range_value_sets = {r: {} for r in common_ranges}
    
#     for inst in instructions:
#         for range_tuple, value in inst["opcodes"].items():
#             if range_tuple in range_value_sets:
#                 value_ints = range_value_sets[range_tuple].setdefault(value, [])
#                 value_ints.append(inst)
    
#     best_range = None
#     min_unique_values = float('inf')

#     for range_tuple, value_set in range_value_sets.items():
#         low, high = range_tuple
#         num_unique = len(value_set)
        
#         if num_unique < min_unique_values:
#             min_unique_values = num_unique
#             best_range = range_tuple
    
#     if not best_range:
#         raise ValueError("Failed to find fitting opcode group")
    
#     opcodes = range_value_sets[best_range]

#     if output_parser:
#         # Find common dymanic arguments
#         common_args = None
#         for inst in instructions:
#             current_args = set(inst["args"])
#             if common_args is None:
#                 common_args = current_args
#             else:
#                 common_args.intersection_update(current_args)

#         for inst in instructions:
#             inst["args"] = [arg for arg in inst["args"] if arg not in common_args]

#         low, high = best_range
#         for arg in sorted_args(common_args):
#             output_arg(instructions, ident, arg)
#         print(f"{" " * ident}switch (@as(u{high - low}, @truncate(inst >> {low}))) {{")
    
#     ident += 4
#     for inst in instructions:
#         del inst["opcodes"][best_range]
#     for value, insts in sorted(opcodes.items()):
#         if output_parser:
#             print(f"{" " * ident}{value} => {{")
#         ident += 4
#         traverse_opcodes(insts, ident)
#         ident -= 4
#         if output_parser:
#             print(f"{" " * ident}}},")
#     if output_parser:
#         if len(opcodes) < (1 << high - low) - 1:
#             print(f"{" " * ident}else => {{}},")
#     ident -= 4
#     if output_parser:
#         print(f"{" " * ident}}}")

# print(template_start.strip())
# if not output_parser:
#     print("    // template start")
# traverse_opcodes(instructions, 4)
# if not output_parser:
#     print("    // template end")
# print(template_end.strip())
