import struct
import sys
import zlib

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage : {} PBM_FILE".format(sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1], "rb") as pbm_file:
        assert pbm_file.readline() == b"P4\n"
        assert pbm_file.readline() == b"128 96\n"
        pbm_data = pbm_file.read()
        assert len(pbm_data) == 1536

    image_data = b""
    for b in pbm_data:
        image_data += struct.pack("B", b ^ 0xff)

    compressobj = zlib.compressobj(strategy=zlib.Z_FIXED)
    compressed_data = compressobj.compress(image_data)
    compressed_data += compressobj.flush()

    # Zlib header
    assert compressed_data[:2] == b"x\x01"
    compressed_data = compressed_data[2:]
    # Zlib ADLER Checksum
    compressed_data = compressed_data[:-4]

    assert (compressed_data[0] >> 0) & 1 == 1 # BFINAL
    assert (compressed_data[0] >> 1) & 1 == 1 # BTYPE : Compressed with fixed huffman codes
    assert (compressed_data[0] >> 2) & 1 == 0

    bit_offset = 3
    byte_offset = 0

    current_byte = 0
    current_byte_bits = 0
    while byte_offset < len(compressed_data):
        bit = (compressed_data[byte_offset] >> bit_offset) & 1
        bit_offset += 1
        if bit_offset >= 8:
            bit_offset = 0
            byte_offset += 1

        current_byte = (bit << 7) | (current_byte >> 1)
        current_byte_bits += 1
        if current_byte_bits >= 8:
            sys.stdout.buffer.write(struct.pack("B", current_byte))
            current_byte = 0
            current_byte_bits = 0

    if current_byte_bits > 0:
        current_byte = current_byte >> (8 - current_byte_bits)
        sys.stdout.buffer.write(struct.pack("B", current_byte))
