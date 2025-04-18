VCS = vcs -kdb -sverilog -debug_access+all+reverse

TB = top_tb.sv
TB = loeffler2d_idct_tb.sv
TB_LIBS = displays.sv
RTL = huffman_decoder.sv input_buffer.sv entropy_decoding.sv deQuant.sv jpeg_decoder_top.sv loeffler_idct.sv loeffler2d_idct.sv supersample_8x8.sv supersample.sv channel_buffer.sv YCbCr_to_RGB_8x8.sv loeffler2d_idct_new.sv

DEFS = sys_defs.svh

.DEFAULT_GOAL = sim

SOURCES = $(addprefix tb/, $(TB_LIBS) $(TB)) $(addprefix rtl/, $(RTL)) $(DEFS)

simv: $(SOURCES)
	$(VCS) $^ -o $@

sim: simv
	./simv | tee program.out 

.PHONY: sim

verdi: $(SOURCES)
	$(VCS) $^ -R -gui 

.PHONY: verdi

clean:
	rm -rvf *simv csrc *.key vcdplus.vpd vc_hdrs.h
	rm -rf verdiLog
	rm -rf simv.daidir
	rm -rvf verdi* novas* *fsdb*
	rm -rvf *.out *.dump
	rm -rvf *.log
	rm -rf *.DB
	rm -rf *.lib++ 
	rm -rf *.vpd DVEfiles
	rm -rf .inter* .vcs* .restart*
	rm -rf *.chk *.rep

