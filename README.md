# JPEG Decoder Hardware Accelerator

This project implements a hardware accelerator for JPEG decoding. The accelerator processes baseline sequential JFIF files and outputs RGB pixel channels.

## Overview

The decoding process consists of three main steps:
1. Extract the JPEG bitstream and supporting information from a JFIF file
2. Process the bitstream through the SystemVerilog hardware simulation to generate RGB outputs
3. Display the decoded RGB channels as an image

**Note:** In a real system implementation, step 1 would be handled by the CPU (as JPEG standards evolve), and step 3 would be managed by the display driver. The hardware accelerator focuses on the core decoding process (step 2).

## Supported JPEG Format

This decoder supports **baseline sequential encoded JFIF files** with **4:2:0 chroma subsampling** only.

**Unsupported formats:**
- Progressive JPEGs
- 4:2:2 or 4:4:4 subsampling
- EXIF format
- Multi-scan images
- 10-bit color
- Reset blocks

## Getting Started

### Prerequisites
- Python 3
- SystemVerilog simulator (VCS)
- MATLAB
- Required modules:
  ```
  module load eecs598-002/f23
  module load verdi
  module load vcs
  ```

### Step 0: Image Preparation
1. Download a JPEG file (`.jpg`)
2. Place it in the `./images` directory
3. For ease of use, choose a filename without spaces or special characters

### Step 1: Extract JPEG Bitstream
1. Navigate to the `./python` directory
2. Run the extraction script:
   ```
   python3 extractImgStream.py <filename>
   ```
3. This creates a new folder `<filename>` containing:
   - Bitstream data
   - Huffman tables
   - Quantization tables
   - Header information
4. Verify that the script reports recovering:
   - Bitstream
   - 4 Huffman Tables
   - 2 Quantization tables
   - Header information

### Step 2: Run the SystemVerilog Simulation
1. Navigate to the `./verilog` directory
2. Load required modules
3. Build and run the simulation:
   ```
   make
   ```
4. The simulation automatically uses the most recently extracted image
5. For a different image, edit `./verilog/tb/top_tb.sv`:
   ```systemverilog
   /* Or set image name manually */
   string imgname = "smallCat";  // Replace with your <filename>
   ```
6. Output files are created in `./verilog/out` as:
   - `<filename>_R.txt`
   - `<filename>_G.txt`
   - `<filename>_B.txt`

**Additional commands:**
- `make verdi` - Run simulation with Verdi waveform viewer
- `make clean` - Clean the directory

### Step 3: Visualize Results
1. Open `./matlab/verilog_rgb_plot.m` in MATLAB
2. Run the script to display the image
3. By default, it shows the most recently processed image
4. To display a different image, modify:
   ```matlab
   imageName = 'smallCat';  % Replace with your <filename>
   ```

## Project Structure

### Python
- `./python/extractImgStream.py` - Main script for JPEG extraction
- `./python/functions.py` - Helper functions
- `./python/huffman.py` - Huffman decoding utilities

### Verilog
- `./verilog/rtl/top.sv` - Top-level module
- `./verilog/tb/top_tb.sv` - Top module testbench
- `./verilog/sys_defs.svh` - System parameters and definitions
- `./verilog/tb/` - Individual submodule testbenches

### MATLAB
- `./matlab/verilog_rgb_plot.m` - Image display script
- `./matlab/entropy_decoding_eli.m` - Reference decoder implementation
- `./matlab/loeffler_model.m` - Loeffler DCT algorithm model

## Troubleshooting

- If the Python script fails to extract all required components, your image likely uses an unsupported format
- For large images, the simulation may take longer to complete
- Ensure the image name in the MATLAB script matches the output files in `./verilog/out`