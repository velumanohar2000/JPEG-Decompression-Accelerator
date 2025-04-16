export MK_COURSE_NAME = EECS598-002
# please refer to scripts/synth.tcl for synthesis details

# Following is an example file structure:
# .
# ├── Makefile
# ├── memory
# │   ├── memgen.sh
# │   └── src
# │       └── SRAM8x32_single.config
# ├── scripts
# │   ├── constraints.tcl
# │   └── synth.tcl
# └── src
#     └── test.sv
#
# if you need to use memory compiler, do this before synthesis flow: {
# 	1. write your memory config file in memory/src
# 	2. modify memory/memgen.sh
# 	3. run "make memgen"
# }
#
# 1. put your RTL codes in src/ folder
# 2. modify scripts/constraints.tcl and/or synth.tcl for synthesis
# 3. run "make syn" 
# 4. check reports/ and results/ folders for reports and mapped files
#

#############
# variables #
#############

# your top-level module name
export MK_DESIGN_NAME = top

# CPU core usage, capped at 6
export MK_USE_NUM_CORES = 6

# memory library selection
export MK_MEM_SUFFIX = typ_1d05_25

###########
# recipes #
###########

all: syn

syn: 
	dc_shell -f scripts/synth.tcl | tee logs/synth.log

clean:
	-rm -rvf temp_files
	-rm -rvf alib-52 temp_files/
	-rm -rvf *_dclib temp_files/
	-rm -rvf command.log temp_files/
	-rm -rvf default.svf temp_files/
	-rm -rvf filenames*log 

