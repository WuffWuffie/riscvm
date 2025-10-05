from dataclasses import dataclass
from typing import Union

EXTENSIONS = ["rv_i", "rv64_i", "rv_m", "rv64_m", "rv_zicsr", "rv_f", "rv64_f", "rv_d", "rv64_d"]
UNSAFE_OPTIMIZE_DECODE = True

@dataclass
class Inst:
    name: str
    opcodes: dict[tuple[int, int], int]
    args: list[str]
    full_args: list[str]

@dataclass
class Branch:
    args: list[str]
    range: tuple[int, int]
    children: dict[int, Inst]
    contained_insts: list[str]
    other: Union['Branch', Inst, None]

arg_lut = {}
with open("riscv-opcodes/arg_lut.csv", 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        arg_name_str, high, low = [p.strip() for p in line.split(",")]
        arg_lut[arg_name_str[1:-1]] = (int(low), int(high) + 1)

def sort_args(args: list[str]) -> list[str]:
    return sorted(args, key=lambda arg: arg_lut[arg][0])

instruction_files = {}
def collect_instructions(ext: str):
    if ext in instruction_files:
        return instruction_files[ext]
    
    info = {
        "pseudo_ops": set(),
        "ops": {},
    }
    instruction_files[ext] = info

    filepath = f"riscv-opcodes/extensions/{ext}"
    with open(filepath, 'r') as f:
        for line in f:
            line = line.split('#', 1)[0].strip()
            if line.startswith("$pseudo_op"):
                info["pseudo_ops"].add(line.split()[1])
                continue
            if not line:
                continue
            opcodes = {}
            args = []
            name, parts = line.split(maxsplit=1)
            for part in parts.split():
                if "=" in part:
                    range_str, value_str = part.split('=', 1)
                    if '..' in range_str:
                        high_bit, low_bit = map(int, range_str.split('..'))
                    else:
                        high_bit, low_bit = int(range_str), int(range_str)
                    high_bit += 1 # turn into exclusive range
                    if value_str.startswith('0x'):
                        value = int(value_str, 16)
                    else:
                        value = int(value_str)
                    opcodes[(low_bit, high_bit)] = value
                else:
                    args.append(part)
            info["ops"][name] = Inst(name, opcodes, args, sort_args(args))
    
    return info

instruction_map = {}
for ext_name in EXTENSIONS:
    info = collect_instructions(ext_name)
    for path in info["pseudo_ops"]:
        pseudo_ext, name = path.split("::")
        other_info = collect_instructions(pseudo_ext)
        instruction_map[name] = other_info["ops"][name]
    for name, op in info["ops"].items():
        instruction_map[name] = op
instructions = list(instruction_map.values())

def create_opcode_branch(instructions: list[Inst]) -> Branch | Inst:
    if len(instructions) == 0:
        return None
    
    if len(instructions) == 1 and len(instructions[0].opcodes) == 0:
        return instructions[0]
    
    contained_insts = [inst.name for inst in instructions]

    ranges = {}
    for inst in instructions:
        for opcode_range, value in inst.opcodes.items():
            range_set = ranges.setdefault(opcode_range, {})
            value_group = range_set.setdefault(value, [])
            value_group.append(inst)

    candidate_scores = []
    for opcode_range, value_set in ranges.items():
        num_instructions_covered = sum(len(inst_list) for inst_list in value_set.values())
        
        num_unique_values = len(value_set)
        
        candidate_scores.append((
            num_instructions_covered,
            num_unique_values,
            opcode_range
        ))

    candidate_scores.sort(key=lambda x: (-x[0], x[1]))

    range = candidate_scores[0][2]
    opcodes = ranges[range]
    other_instructions = []

    for inst in instructions:
        if range in inst.opcodes:
            del inst.opcodes[range]
        else:
            other_instructions.append(inst)
    
    if UNSAFE_OPTIMIZE_DECODE and len(opcodes) == 1 and len(other_instructions) == 0:
        # Any invalid instruction is considered unspecified behavior, so the decoder 
        # can emit whatever it wants in place of what would otherwise be undefined
        # This shouldn't make correct instructions work incorrectly
        return create_opcode_branch(next(iter(opcodes.values())))
    
    # Find common arguments
    args = None
    for inst in instructions:
        current_args = set(inst.args)
        if args is None:
            args = current_args
        else:
            args.intersection_update(current_args)

    for inst in instructions:
        inst.args = [arg for arg in inst.args if arg not in args]

    args = sort_args(args)

    children = {}

    for value, insts in sorted(opcodes.items()):
        children[value] = create_opcode_branch(insts)

    other = create_opcode_branch(other_instructions)

    return Branch(args, range, children, contained_insts, other)

print(f"instructions: {len(instructions)}")
opcode_tree = create_opcode_branch(instructions)
