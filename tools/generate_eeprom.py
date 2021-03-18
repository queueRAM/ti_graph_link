#!/usr/bin/env python3

import struct

def calculate_checksum(bin_data):
    return sum(bin_data) & 0xFF

def output_eeprom_bin(input_filename, output_filename):
    with open(input_filename, 'rb') as in_file:
        in_data = in_file.read()
        checksum = calculate_checksum(in_data)
        header = struct.pack('<HBHB', 0x3410, 0x07, len(in_data), checksum)
        with open(output_filename, 'wb') as out_file:
            out_file.write(header)
            out_file.write(in_data)

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Encapsulate firmware binary with TUSB3410 header')
    parser.add_argument('input', help='Input binary firmware filename')
    parser.add_argument('output', help='Output binary EEPROM filename')
    args = parser.parse_args()

    output_eeprom_bin(args.input, args.output)

if __name__ == "__main__":
    main()
