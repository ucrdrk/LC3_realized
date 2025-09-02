#!/usr/bin/env python3
version = "0.1"
name = "LC-3 Command Line"

import re
import sys
import serial
from lc3_obj_reader import read_lc3_obj

def send_range(port, min, max):
    port.write(min.to_bytes(2, 'big'))
    port.write(max.to_bytes(2, 'big'))

cmd_re = re.compile(r"([a-zA-Z]+)(.*)")

print(name + " version " + version)
print("(C) University of California Riverside, 2023")
print()

port_names = ['/dev/ttyACM0', '/dev/ttyACM1']

lc3_port = None

for port_name in port_names: 
    try:
        lc3_port = serial.Serial(port_name, baudrate=115200, timeout=3.0)
        lc3_port.reset_input_buffer()
        break
    except Exception as error:
        print("Unable to connect to " + port_name + ". Trying another port name")

run_status = ['INIT', 'LOAD_OS', 'LOAD_PROG', 'READY', 'RESETTING', 'DUMPING', 'STARTING', 'RUNNING', 'DONE', 'STALLED']
while True:
    cmd_str = input('$ ')

    cmd_match = cmd_re.match(cmd_str)
    if cmd_match is None:
        sys.stderr.write("Illegal command\n")
        continue
    else:
        cmd = cmd_match.group(1)
        args = cmd_match.group(2).split()

    response_size = 1;
    match cmd.lower():
        case "status": 
            print("Getting status from device...")
            cmd_code = 1;
        case "run": 
            print("Sending RUN command...")
            cmd_code = 2;
        case "s" | "stop":
            print("Sending STOP command")
            cmd_code = 3;
        case "load":
            print ("Loading program...")
            program = args[0]
            cmd_code = 4
        case "d" | "dump":
            print ("Dumping memory...")
            response_size = 2
            min = int((args[0:] or [0])[0], 16)
            max = int((args[1:] or [0])[0], 16)
            cmd_code = 5
        case "restart": 
            print("Restart computer...")
            cmd_code = 6;
        case "q" | "quit": 
            print("Quitting...")
            sys.exit()
        case _:
            print("Unknown command")
            continue

    bytes_written = lc3_port.write(cmd_code.to_bytes(1, 'big'))

    match cmd.lower():
        case "status":
            response = lc3_port.read(response_size)
            response_value = int.from_bytes(response, "big")
            if (response_value < len(run_status)):
                print("LC-3 status is " + run_status[response_value])
                lc3_port.reset_input_buffer()
                lc3_port.reset_output_buffer()
            else:
                print("Unknown status returned: ", response_value)
        case "load":
            obj_data = read_lc3_obj(program)

            for origin in obj_data.keys():
                if type(origin) is int:
                    obj = obj_data[origin]
                    min = origin
                    max = origin + len(obj) - 1

                    send_range(lc3_port, min, max)
                    print("Min: {:04x}, Max: {:04x}".format(min, max))
                    for x in range(min, max+1):
                        lc3_port.write(obj[x - min].to_bytes(2, 'big'))
                        print("Loading x{:04X} into address x{:04X}".format(obj[x - min], x));
            
                    response = lc3_port.read(response_size)
                    response_value = int.from_bytes(response, "big")
                    print("LC-3 load response is " + str(response_value))

                    if (origin != list(obj_data.keys())[-1]):
                        lc3_port.write(cmd_code.to_bytes(1, 'big'))

        case "d" | "dump":
            send_range(lc3_port, min, max)
            for x in range(min, max+1):
                response = lc3_port.read(response_size)
                print("x{:04x}\tx{:04X}\t{:4d}".format(x, int.from_bytes(response, "big"), int.from_bytes(response, "big", signed=True)))
        case _:
            response = lc3_port.read(response_size)
            print(response)

