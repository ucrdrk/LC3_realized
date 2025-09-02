#!/bin/python3

import sys

MAGIC_NUMBER = b'\x1c\x30\x15\xc0\x01'

def read_lc3_obj(obj_file):
  obj_data = {}
  object_file = open(obj_file, 'rb')
  
  magic_number = object_file.read(5)
  if magic_number != MAGIC_NUMBER:
    raise Exception("{} is not an LC-3 Object file".format(obj_file))

  obj_data['version'] = object_file.read(2)

  origin = 0

  while True:
    bytes_read = object_file.read(2)
    if not bytes_read:
      break
    value = int.from_bytes(bytes_read, 'little')
    
    is_orig = object_file.read(1) == b'\x01'
    if is_orig:
      if value < origin:
        raise Exception("Origin address of {:s} at x{:x} is less than current address x{:x}\n" % (obj_file, value, origin))
      origin = value
      obj_data[origin] = []
      data = read_data(object_file)
    else:
      data = read_data(object_file)
      obj_data[origin].append(value)

  return obj_data

def read_data(object_file):
    num_chars = int.from_bytes(object_file.read(4), 'little')
    return object_file.read(num_chars).decode("utf-8")
