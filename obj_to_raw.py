#!/bin/python3

import sys

MAGIC_NUMBER = b'\x1c\x30\x15\xc0\x01'

def print_bytes(bytes):
  for byte in bytes:
    print("{:02x}".format(byte))

def read_data(object_file):
    num_chars = int.from_bytes(object_file.read(4), 'little')
    return object_file.read(num_chars).decode("utf-8")

object_file = open(sys.argv[1], 'rb')
magic_number = object_file.read(5)
if magic_number == MAGIC_NUMBER:
  print("v2.0 raw")
else:
  print("{} is not an LC-3 Object file".format(sys.argv[1]))
  sys.exit()

version = object_file.read(2)

origin = 0

while True:
  eof = object_file.read(2)
  if not eof:
    break
  value = int.from_bytes(eof, 'little')
  
  is_orig = object_file.read(1) == b'\x01'
  if is_orig:
    for zero in range(origin, value):
      print("{:04X}".format(0))
      origin = origin + 1
    data = read_data(object_file)
  else:
    data = read_data(object_file)
    print("{:04X} ".format(value))

    origin = origin + 1
