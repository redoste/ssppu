import serial
import struct
import sys

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage : {} SERIAL_INTERFACE PROGRAM_FILE".format(sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[2], "rb") as program_file:
        program = program_file.read()
        program_len = len(program)
        assert program_len <= 0x4000

        if program_len & 0xFF != 0:
            program_len = (program_len + 0x100) & 0xFFFFFF00
        assert program_len >= 0x100
        assert program_len <= 0x4000

        program = program + b"\xaa" * (program_len - len(program))

    ser = serial.Serial(sys.argv[1], 9600)

    for _ in range(2):
        print(" < welcome msg {}".format(ser.readline()))

    blocks_amount = program_len >> 8
    ser.write(struct.pack("!Q", blocks_amount))
    blocks_amount_ack = ser.read(1)[0]
    print(" > blocks amount {} {}".format(hex(blocks_amount), hex(blocks_amount_ack)))
    assert blocks_amount == blocks_amount_ack

    for i in range(blocks_amount):
        query = ser.read(1)[0]
        print(" > block {} {}".format(hex(i), hex(query)))
        assert query == i
        for j in range(32):
            query = ser.read(1)[0]
            assert query == j * 8
            offset = (i * 0x100) + (j * 8)
            ser.write(program[offset:offset+8])
