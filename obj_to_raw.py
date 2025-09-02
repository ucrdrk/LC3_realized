#!/bin/python3

import sys
import getopt

MAGIC_NUMBER = b'\x1c\x30\x15\xc0\x01'

def print_bytes(bytes):
  for byte in bytes:
    print("{:02x}".format(byte))

def read_data(object_file):
    num_chars = int.from_bytes(object_file.read(4), 'little')
    return object_file.read(num_chars).decode("utf-8")

def write_hex(file, data):
  file.write("{:04X}\n".format(data))

def write_raw(file, data):
  file.write(data.to_bytes(2, byteorder='big'))


raw = True
out_file = sys.stdout
writer = write_hex

opts, args = getopt.getopt(sys.argv[1:], "hrxo:", ["help", "raw", "hex", "out"])

for opt, arg in opts:
  if opt in ('-h', '--help'):
    sys.stdout.write("This is for help\n")
    sys.exit()
  elif opt in ('-r', '--raw'):
    raw = True;
    writer = write_raw
  elif opt in ('-x', '--hex'):
    raw = False
    writer = write_hex
  elif opt in ('-o', '--out'):
    if raw:
      out_file = open(arg, 'wb')
    else:
      out_file = open(arg, "w")

origin = 0

file_no = 0
while file_no < len(args):
  object_file = open(args[file_no], 'rb')
  magic_number = object_file.read(5)
  if magic_number == MAGIC_NUMBER:
    if not raw and file_no == 0: out_file.write("v2.0 raw\n")
  else:
    sys.stderr.write("{} is not an LC-3 Object file".format(args[file_no]))
    sys.exit()

  version = object_file.read(2)

  while True:
    eof = object_file.read(2)
    if not eof:
      break
    value = int.from_bytes(eof, 'little')
    
    is_orig = object_file.read(1) == b'\x01'
    if is_orig:
      if value < origin:
        sys.stderr.write("Origin address of %s at x%x is less than current address x%x\n" % (sys.argv[file_no], value, origin))
        sys.exit()
      for zero in range(origin, value):
        writer(out_file, 0)
        origin = origin + 1
      data = read_data(object_file)
    else:
      data = read_data(object_file)
      writer(out_file, value)

      origin = origin + 1

  file_no = file_no + 1