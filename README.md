# LC3_realized

The LC3 Processor realized now in schematic capture in Digital, and hopefully soon in Verilog.

## Usage

In Digital load the file lc3.dig. You might need to change the path for the hex and verilog. To change the path for 
the hex file loaded to initialize RAM go to Edit -> Settings -> Circuit specific settings. Under the Advanced tab go
to "Program File" and navigate to where you cloned this repo and select the file lc3_os.hex. To change the path to
the verilog for lc-pc.v, right click on module labeled PC with the type External File On the Basic tab go to the 
field "Program code" and navigate to where you cloned this repo and select the file lc-pc.v.

To run the program in lc3_os.hex, press the play button. This will start the simulation, but not run the program. You
can eitehr step throught each state of executing the program by continuously clicking the Clk clock or run the entire
program by pressing the fast forward button next to the play button. The default program in lc3_os.hex is the "Hello,
World!" program which willopen the terminal and print the following:

```
Hello, World!


--- Halting the LC-3 ---
```

**NOTE** You will need to have iverilog installed on your computer because the PC is implemented using Verilog.