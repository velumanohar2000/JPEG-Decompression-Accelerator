`ifndef __SYS_DEFS_SVH__
`define __SYS_DEFS_SVH__

`timescale 1ns/100ps

`define Q  8                    // Precision (bits)
`define DC_H 12                    // Max Size of DC Huffman table (number of entries)
`define AC_H 162                    // Max Size of AC Huffman table (number of entries)
`define H 162                     // Max Size of any Huffman table (num entries)
`define HN 2                    // Number of Huffman table destinations/indexes
`define CH 3                    // Number of channels in image
`define QN 2                    // Number of Quantization table destinations/indexes
`define IN 32                   // Int to decoder (bits per cycle)
`define PERIOD 20               // Clock period (ns)
`define IN_BUS_WIDTH 32         // Input bus bit width 
`define IN_BUFF_SIZE 64         // Size of input buffer (bits)
`define BLOCK_BUFF_SIZE 64      // Size of block buffer (#coeffs)

typedef struct packed {
    logic [4:0]  size;
    logic [15:0] code;
    logic [7:0]  symbol;
} HUFF_TABLE_ENTRY;

typedef struct packed {
    HUFF_TABLE_ENTRY [`DC_H-1:0] dc_tab;
    logic [$clog2(`DC_H+1)-1:0] dc_size;
    HUFF_TABLE_ENTRY [`AC_H-1:0] ac_tab;
    logic [$clog2(`AC_H+1)-1:0] ac_size;
} HUFF_TABLE;

typedef struct packed {
    HUFF_TABLE [`HN-1:0] tabs;        // Array of huffman tables
    logic [`CH-1:0][$clog2(`HN+1)-1:0] map; // Maps channel to huffman table number
} HUFF_PACKET;

typedef struct {
    logic signed [`Q-1:0] tab [7:0][7:0]; //8 by 8 array of quantization values
} QUANT_TABLE;

typedef struct {
    QUANT_TABLE tabs [`QN-1:0] ;        // Array of quantization tables
    logic [$clog2(`QN+1)-1:0] map [`CH-1:0]; // Maps channel to quantization table number
} QUANT_PACKET;

typedef struct {
    logic [`Q-1:0] block [7:0][7:0];
} BLOCK;

`endif
