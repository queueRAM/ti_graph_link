#!/usr/bin/env python3

import csv

def csv2bin(csv_filename):
    cf = open(csv_filename, newline='')
    dictread = csv.DictReader(cf)
    # determine which version of Logic exported the CSV
    if 'Read/Write' in dictread.fieldnames:
        return csv2_to_bin(dictread)
    else:
        return csv1_to_bin(dictread)

# convert Logic v1 I2C exported CSV to binary data
# name,type,start_time,duration,"ack","address","read","data"
def csv1_to_bin(reader):
    bin_data = bytearray()
    state = 0
    # v1 has row for start, stop, addressing
    for row in reader:
        if state == 0:
            if row['read'] == 'true':
                state = 1
        elif state == 1:
            if row['type'] in ['stop', 'start']:
                state = 0
            else:
                bin_data.append(int(row['data'], 0))
    return bin_data

# convert Logic v2 I2C exported CSV to binary data
# Time [s],Packet ID,Address,Data,Read/Write,ACK/NAK
def csv2_to_bin(reader):
    bin_data = bytearray()
    # output all the read transactions
    for row in reader:
        if row['Read/Write'] == 'Read':
            bin_data.append(int(row['Data'], 0))
    return bin_data

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Convert Saleae Logic I2C CSV file to binary.')
    parser.add_argument('input', help='Input binary file name')
    parser.add_argument('output', help='Output binary file name')
    args = parser.parse_args()
    bin_data = csv2bin(args.input)
    with open(args.output, 'wb') as bin_file:
        bin_file.write(bin_data)

if __name__ == "__main__":
    main()
