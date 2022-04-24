import math
import struct
import sys

# =================================================================================
# WARNING : You are about to read the worst parser you have ever seen
#           ASTs are only a delusion, real programmers only use splits and regexes
# =================================================================================
# This assembler was written quickly to help debug things, I will *one day* rewrite
# it properly. Please, don't look too much at this, it will hurt.

code = bytearray()
pc = 0
pc_base = 0
relocations = {}
labels = {}

def emit_byte(b):
    global code
    global pc
    code += struct.pack("B", b)
    pc += 1

def emit_relocation(label_name, base=False):
    global code
    global relocations
    global pc
    relocations[pc] = (label_name, base)
    if base:
        code += b"X"
        pc += 1
    else:
        code += b"XX"
        pc += 2

def parse_gpr(register_name, may_fail=False):
    gpr_str = ["ra", "rb"]
    register_name = register_name.lower()
    if register_name not in gpr_str:
        if may_fail:
            return -1
        print("Unexpected word : {}".format(register_name), file=sys.stderr)
        print("Expected general purpouse register name", file=sys.stderr)
        sys.exit(1)
    return gpr_str.index(register_name)

def parse_register(register_name, may_fail=False):
    reg_str = ["ra", "rb", "lrh", "lrl"]
    register_name = register_name.lower()
    if register_name not in reg_str:
        if may_fail:
            return -1
        print("Unexpected word : {}".format(register_name), file=sys.stderr)
        print("Expected register name", file=sys.stderr)
        sys.exit(1)
    return reg_str.index(register_name)

def parse_integer(integer_str, may_fail=False):
    try:
        if integer_str[:2] == "0b":
            return int(integer_str, 2)
        elif integer_str[:2] == "0x":
            return int(integer_str, 16)
        else:
            return int(integer_str, 10)
    except ValueError:
        if may_fail:
            return -1
        print("Unexpected word : {}".format(integer_str), file=sys.stderr)
        print("Expected integer", file=sys.stderr)
        sys.exit(1)

def parse_integer_or_label(integer_str, may_fail=False):
    integer = parse_integer(integer_str, True)
    if integer == -1:
        return integer_str
    return integer

def parse_address(address_str, may_fail=False):
    if address_str[0] != '[' or address_str[-1] != ']':
        if may_fail:
            return -1
        print("Unexpected word : {}".format(address_str), file=sys.stderr)
        print("Expected address in brackets", file=sys.stderr)
        sys.exit(1)
    address_str = address_str[1:-1].split(",")
    if len(address_str) == 1:
        return parse_integer_or_label(address_str[0], may_fail)
    elif len(address_str) == 2:
        base = parse_integer_or_label(address_str[0], may_fail)
        index_register = parse_gpr(address_str[1], may_fail)

        if base == -1 or index_register == -1:
            return -1
        if type(base) is int and base > 0xff:
            print("Invalid instruction : {}".format(hex(base)), file=sys.stderr)
            print("Relative addresses can only control the high byte of the address. (base <= 0xff)", file=sys.stderr)
            sys.exit(1)
        return (base, index_register)
    else:
        if may_fail:
            return -1
        print("Too many elements : {}".format(address_str), file=sys.stderr)
        print("Expected absolute address or relative address indexed by a general purpouse register", file=sys.stderr)
        sys.exit(1)

def inst_alu(line):
    alu_operations = ["add", "sub", "shl", "shr", "and", "or", "xor", "not"]
    alu_operation_number = alu_operations.index(line.pop(0).lower())

    no_flags_str = ["nf", "no_flags"]
    no_flags = False
    no_write_str = ["nw", "no_write"]
    no_write = False
    while line[0].lower() in no_flags_str + no_write_str:
        option = line.pop(0).lower()
        if option in no_flags_str:
            no_flags = True
        elif option in no_write_str:
            no_write = True
        else:
            raise Exception("unreachable")

    output_register = parse_gpr(line[0])

    emit_byte((alu_operation_number << 4) |
              (output_register << 3) |
              (int(not no_write) << 2) |
              (int(not no_flags) << 1))

def inst_trans(line):
    line.pop(0) # mnemonic
    dest = parse_gpr(line.pop(0))

    source_str = line.pop(0).lower()
    source_addr = -1

    source = parse_register(source_str, True)
    if source == -1:
        source_addr = parse_address(source_str, True)
        if source_addr == -1:
            if source_str[0] == "#":
                source_addr = parse_integer(source_str[1:], True)
                source = 0b100
            if source_addr == -1:
                print("Invalid transfer source : {}".format(source_str), file=sys.stderr)
                print("Expected relative address, absolute address or register", file=sys.stderr)
                sys.exit(1)
        else:
            if type(source_addr) is tuple:
                source = 0b110 | source_addr[1]
            else:
                source = 0b101

    emit_byte(0b10000000 | (dest << 3) | source)
    if source == 0b101:
        if type(source_addr) is str:
            emit_relocation(source_addr)
        else:
            emit_byte((source_addr & 0xFF00) >> 8)
            emit_byte(source_addr & 0xFF)
    elif (source & 0b110) == 0b110:
        if type(source_addr[0]) is str:
            emit_relocation(source_addr[0], True)
        else:
            emit_byte(source_addr[0])
    elif source == 0b100:
        emit_byte(source_addr)

def inst_st(line):
    line.pop(0) # mnemonic

    dest_addr = parse_address(line.pop(0))
    source_register = parse_register(line.pop(0))

    dest_flags = 0b00
    if type(dest_addr) is tuple:
        dest_flags = 0b10 | dest_addr[1]

    emit_byte(0b10010000 | (dest_flags << 2) | source_register)
    if dest_flags == 0b00:
        if type(dest_addr) is str:
            emit_relocation(dest_addr)
        else:
            emit_byte((dest_addr & 0xFF00) >> 8)
            emit_byte(dest_addr & 0xFF)
    else:
        if type(dest_addr[0]) is str:
            emit_relocation(dest_addr[0], True)
        else:
            emit_byte(dest_addr[0])

def inst_jmp(line):
    mnemonic = line.pop(0).lower()
    zf = mnemonic[0] == "j" and (mnemonic[-1] == "e" or mnemonic[-1] == "z")
    cf = mnemonic[0] == "j" and mnemonic[-1] == "c"
    no = mnemonic[1] == "n"

    call = mnemonic == "call"
    ret = mnemonic == "ret"

    if not ret:
        dest_addr = parse_integer_or_label(line.pop(0))

    emit_byte(0b11000000 |
             (int(call) << 4) |
             (int(ret) << 3) |
             (int(no) << 2) |
             (int(cf) << 1) |
             (int(zf) << 0))
    if not ret:
        if type(dest_addr) is str:
            emit_relocation(dest_addr)
        else:
            emit_byte((dest_addr & 0xFF00) >> 8)
            emit_byte(dest_addr & 0xFF)

def inst_hlt(line):
    emit_byte(0b11111111)

def inst_nop(line):
    emit_byte(0b10101010)

def inst_org(line):
    global code
    global pc
    global pc_base

    line.pop(0) # mnemonic
    org_dest = parse_integer(line.pop(0))
    if pc == 0:
        pc = org_dest
        pc_base = org_dest
    else:
        if org_dest < pc:
            print("Unable to move backward with the org mnemonic", file=sys.stderr)
            sys.exit(1)
        code += b"\xaa" * (org_dest - pc)
        pc = org_dest

def inst_db(line):
    line.pop(0) # mnemonic
    for byte in line:
        emit_byte(parse_integer(byte))

def apply_relocations():
    for rel_location in relocations:
        label_name = relocations[rel_location][0]
        base = relocations[rel_location][1]

        if label_name not in labels:
            print("Label {} not found".format(label_name), file=sys.stderr)
            sys.exit(1)
        label_location = labels[label_name]
        if base and label_location & 0xFF != 0:
            print("Label {} is used as a base but has its lower byte different to zero".format(label_name), file=sys.stderr)
            sys.exit(1)

        code[rel_location - pc_base] = (label_location & 0xff00) >> 8
        if not base:
            code[rel_location+1 - pc_base] = label_location & 0xff

OPCODES_LIST = {
    "add": inst_alu,
    "sub": inst_alu,
    "shl": inst_alu,
    "shr": inst_alu,
    "and": inst_alu,
    "or": inst_alu,
    "xor": inst_alu,
    "not": inst_alu,
    "ld": inst_trans,
    "trans": inst_trans,
    "st": inst_st,
    "jmp": inst_jmp,
    "jz": inst_jmp,
    "jc": inst_jmp,
    "je": inst_jmp,
    "jnz": inst_jmp,
    "jnc": inst_jmp,
    "jne": inst_jmp,
    "call": inst_jmp,
    "ret": inst_jmp,
    "hlt": inst_hlt,
    "nop": inst_nop,

    "org": inst_org,
    "db": inst_db
}

if __name__ == "__main__":
    output_format = "bin"
    if len(sys.argv) > 1:
        output_format = sys.argv[1]
    if output_format not in ["bin", "vhdl"]:
        print("Usage : {} FORMAT".format(sys.argv[0]), file=sys.stderr)
        print("format : bin or vhdl", file=sys.stderr)
        print("source assembly file is read from stdin", file=sys.stderr)
        print("output file is written to stdout", file=sys.stderr)
        sys.exit(1)

    while True:
        line = sys.stdin.readline()
        if line == "":
            break
        line = line.strip()
        if line == "" or line[0] == "#":
            continue
        line = line.split()

        opcode = line[0].lower()
        if opcode not in OPCODES_LIST:
            if opcode[-1] == ":":
                label_name = opcode[:-1]
                if label_name in labels:
                    print("Label already defined : {}".format(label_name), file=sys.stderr)
                    sys.exit(1)
                labels[label_name] = pc
            else:
                print("Unexpected word : {}".format(opcode), file=sys.stderr)
                print("Expected opcode or label", file=sys.stderr)
                sys.exit(1)
        else:
            OPCODES_LIST[opcode](line)

    apply_relocations()

    if output_format == "bin":
        sys.stdout.buffer.write(code)
        sys.stdout.buffer.flush()
    else:
        address_length = int(math.log2(len(code)) // 4) + 1
        assert address_length < 10 and address_length > 0
        format_str = "x\"{:02X}\" when x\"{:0" + str(address_length) + "X}\","
        for i in range(len(code)):
            if code[i] != 0xaa:
                print(format_str.format(code[i], i))
        print("x\"AA\" when others;")
