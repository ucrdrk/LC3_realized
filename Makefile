filename = lc3_HDL
pcf_file = ./io.pcf

# arachne-pnr -d 5k -P sg48 -p $(pcf_file) $(filename).blif -o $(filename).asc
build:
	yosys -p "synth_ice40 -json $(filename).json" $(filename).v -D SYNTH_FPGA
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

#prog: #for sram, not useful to read flash
#	iceprog -S $(filename).bin

prog:
	icesprog $(filename).bin

red:
	icesprog -o 0x100000 ./flash_master/red.hex

green:
	icesprog -o 0x100000 ./flash_master/green.hex

blue:
	icesprog -o 0x100000 ./flash_master/blue.hex

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).bin
