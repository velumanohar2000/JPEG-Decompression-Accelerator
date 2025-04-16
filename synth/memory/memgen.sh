# example memory compiler command
FILENAME=SRAM8x32_single
saed_mc src/${FILENAME}.config
mkdir -p results
mv mc_work results/${FILENAME}
mv saed_mc.*.log results/${FILENAME}

# verilog model
mkdir -p verilog
cp -vf results/${FILENAME}/*.v verilog

# db model
mkdir -p db
cp -vf results/${FILENAME}/*.db db

