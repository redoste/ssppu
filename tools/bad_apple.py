import math
import os
import serial
import struct
import sys
import time

import ssppu_tx

def tx_dma(ser, data):
    data_len = len(data)
    assert data_len < 0x10000
    ser.write(struct.pack("!H", data_len))
    data_len_ack = struct.unpack("!H", ser.read(2))[0]
    print("> data len : {} {}".format(hex(data_len), hex(data_len_ack)))
    assert data_len == data_len_ack
    ser.write(data)

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage : {} SERIAL_INTERFACE PROGRAM_FILE FRAMES_FOLDER FRAME_RATE".format(sys.argv[0]), file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[2], "rb") as program_file:
        program = program_file.read()

    frame_names = os.listdir(sys.argv[3])
    frame_names.sort()
    frame_names = [sys.argv[3] + "/" + x for x in frame_names]
    frames = []
    for frame_name in frame_names:
        with open(frame_name, "rb") as frame_file:
            frame_data = frame_file.read()
        frames.append(frame_data)

    fps = int(sys.argv[4])

    ser = serial.Serial(sys.argv[1], 9600)
    ssppu_tx.tx_program(ser, program)

    switch_to_115200_byte = ser.read(1)[0]
    print("switching to 115200bps {}".format(hex(switch_to_115200_byte)))
    assert switch_to_115200_byte == 0xaa

    ser.close()
    ser = serial.Serial(sys.argv[1], 115200)

    current_frame = 0
    time_start = time.perf_counter()
    while current_frame < len(frames):
        print("sending {}".format(current_frame))
        time_start_frame = time.perf_counter()

        tx_dma(ser, frames[current_frame])
        print("waiting for end of frame byte...", end="")
        end_of_frame_byte = ser.read(1)[0]
        print(" {}".format(hex(end_of_frame_byte)))
        assert end_of_frame_byte == 0xbb

        time_end_frame = time.perf_counter()
        time_frame = time_end_frame - time_start_frame
        print("image sent in {}s".format(time_frame))

        current_frame = math.ceil((time_end_frame - time_start) * fps)
