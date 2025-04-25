VCS = vcs -kdb -sverilog -debug_access+all+reverse

# Original files (NO verilog/ prefix)
TB = top_tb.sv
TB_LIBS = displays.sv
RTL = unzigzag.sv huffman_decoder.sv vli_decoder.sv input_buffer.sv block_buffer.sv entropy_decoding.sv \
      diff_decoder.sv deQuant.sv top.sv loeffler_idct.sv loeffler2d_idct.sv supersample_4x4.sv \
      supersample_8x8.sv supersample_top.sv supersample_buffer_top.sv channel_buffer.sv \
      sup_buf_ycbcr2rgb.sv ycbcr2rgb_block.sv ycbcr2rgb.sv

DEFS = sys_defs.svh
RAW = segmented_raw.svh

# Original sources (NO verilog/ prefix)
SOURCES = $(addprefix tb/, $(TB_LIBS) $(TB)) $(addprefix rtl/, $(RTL)) $(DEFS)

.DEFAULT_GOAL = sim

# Original simulation compile and run
simv: $(SOURCES)
	$(VCS) $^ -o $@

sim: simv
	./simv | tee program.out 

.PHONY: sim

# Verdi visualization
verdi: $(SOURCES)
	$(VCS) $^ -R -gui 

.PHONY: verdi

# header_reader-specific sources (matching original structure)
HEADER_READER_TB = tb/header_reader_tb.sv
HEADER_READER_RTL = rtl/header_reader.sv $(RAW) $(DEFS)

HEADER_READER_SOURCES = $(HEADER_READER_TB) $(HEADER_READER_RTL)

# Compile header_reader simulation
header_reader_simv: $(HEADER_READER_SOURCES)
	$(VCS) $^ -o $@

# Run header_reader simulation
header_reader: header_reader_simv
	./header_reader_simv | tee header_reader.out 

.PHONY: header_reader

# Cleanup (original)
clean:
	rm -rvf *simv csrc *.key vcdplus.vpd vc_hdrs.h
	rm -rf verdiLog simv.daidir verdi* novas* *fsdb*
	rm -rvf *.out *.dump *.log *.DB *.lib++ *.vpd DVEfiles
	rm -rf .inter* .vcs* .restart* *.chk *.rep
