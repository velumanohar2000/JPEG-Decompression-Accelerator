clc;
clear;
close all;

%%% USER: Enter Path to Folder with Python Outputs %%%%%%%%%%%%%%
folderName = './tiny'; %Use ./Name if the folder is in this directory
verbose = 1;
intermediatePlots = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Read Header Info
Header = readmatrix([folderName,'/HeaderInfo.txt']);
%Read Quantization Tables
QuantTable0 = readmatrix([folderName,'/QuantTable0.txt']);
QuantTable1 = readmatrix([folderName,'/QuantTable1.txt']);
%Read Read Huffman DC, AC table and BitStream From 
file_DCHuff0 = fopen([folderName,'/DC_HuffTable_Index0.txt'], 'r');
file_ACHuff0 = fopen([folderName,'/AC_HuffTable_Index0.txt'], 'r');
file_DCHuff1 = fopen([folderName,'/DC_HuffTable_Index1.txt'], 'r');
file_ACHuff1 = fopen([folderName,'/AC_HuffTable_Index1.txt'], 'r');
file_bitstream = fopen([folderName,'/bitStream.txt'], 'r');

height = Header(1,1);
width = Header(1,2);
blocksWide = ceil(width/16)*2;
blocksTall = ceil(height/16)*2;

quantTables = {QuantTable0,QuantTable1,QuantTable1};
values_in = fscanf(file_bitstream, '%s');

formatSpec = '%s %d %d';
DC0 = textscan(file_DCHuff0, formatSpec);
AC0 = textscan(file_ACHuff0, formatSpec);
DC1 = textscan(file_DCHuff1, formatSpec);
AC1 = textscan(file_ACHuff1, formatSpec);

file_DCHuff0 = fclose(file_DCHuff0);
file_ACHuff0 = fclose(file_ACHuff0);
file_DCHuff1 = fclose(file_DCHuff1);
file_ACHuff1 = fclose(file_ACHuff1);
file_bitstream = fclose(file_bitstream);
 
huff_dc0_codes  = DC0{1};
huff_dc0_values = DC0{2};
huff_ac0_codes  = AC0{1};
huff_ac0_values = AC0{2};
huff_dc1_codes  = DC1{1};
huff_dc1_values = DC1{2};
huff_ac1_codes  = AC1{1};
huff_ac1_values = AC1{2};

huffman_dc0_map = containers.Map(huff_dc0_codes, huff_dc0_values);
huffman_ac0_map = containers.Map(huff_ac0_codes, huff_ac0_values);
huffman_dc1_map = containers.Map(huff_dc1_codes, huff_dc1_values);
huffman_ac1_map = containers.Map(huff_ac1_codes, huff_ac1_values);

dcHuffTables = {huffman_dc0_map,huffman_dc1_map,huffman_dc1_map};
acHuffTables = {huffman_ac0_map,huffman_ac1_map,huffman_ac1_map};

encoded_values = [];
dc_flag = 1;
cnt = 0;
lastDc = [0,0,0];
decodingOrder = [1,1,1,1,2,3];
orderTracker = 0;
blockCount = 1;

while (length(encoded_values)<blocksTall*blocksWide*1.5*64)
    if dc_flag == 1 % DC
        if verbose ==1 fprintf('Huff:%s ',values_in(1:16));end
        [values_out, b_size] = decode_huffman_dc(values_in, dcHuffTables{decodingOrder(orderTracker+1)});
        if (b_size == 0) %DC val is 0
            encoded_values = [encoded_values, lastDc(decodingOrder(orderTracker+1))];
        else
            diff = vli(values_out(1:b_size));
            if verbose ==1 fprintf('VLI:%s Size:%d Amp:%d',values_out(1:b_size),b_size,diff); end
            newDc = lastDc(decodingOrder(orderTracker+1)) + diff;
            lastDc(decodingOrder(orderTracker+1)) = newDc;
            encoded_values = [encoded_values, newDc];
        end
        values_in = values_out(b_size+1:end);
        dc_flag = 0;
        cnt = cnt + 1;
        disp(blockCount)
        blockCount = blockCount +1;
    else % AC
        [values_out, run_length, b_size] = decode_huffman_ac(values_in, acHuffTables{decodingOrder(orderTracker+1)});
        if run_length == 0 && b_size == 0  % EOB
            zeros_to_append = zeros(1, 64-cnt);
            encoded_values = [encoded_values, zeros_to_append];
            if(isempty(values_out))%Check if at end of bitstream
                break
            end
            values_in = values_out(b_size+1:end);
            dc_flag = 1;
            cnt = 0;
            orderTracker = mod(orderTracker + 1,length(decodingOrder));
        else
            zeros_to_append = zeros(1, run_length);
            encoded_values = [encoded_values, zeros_to_append];   % adding zeros
            if (b_size == 0)
                encoded_values = [encoded_values, 0];
            else
                encoded_values = [encoded_values, vli(values_out(1:b_size))];
            end 
            values_in = values_out(b_size+1:end);
            cnt = cnt + size(zeros_to_append,2) + 1;
            if cnt == 64 %Reached end of block with no EOB symbol
                dc_flag = 1;
                cnt = 0;
                orderTracker = mod(orderTracker + 1,length(decodingOrder));
            elseif cnt>64
                disp("Error 01")
            end
        end
    end
end
disp("Finished Dehuff Process")

%Inverse Zigzag scan
blocks = zeros(8,1.5*blocksTall*blocksWide*8);
pos = 1;
for i = 1:64:length(encoded_values)
    blocks(1:8,pos:pos+7) = inv_zigzag(encoded_values(i:i+63), 8);
    pos = pos+8;
end

%Dequant
orderTracker = 0;
blocksDQ = zeros(8,1.5*blocksTall*blocksWide*8);
for i = 1:8:length(blocks)
    blocksDQ(1:8,i:i+7) = blocks(1:8,i:i+7) .*quantTables{decodingOrder(orderTracker+1)};
    orderTracker = mod(orderTracker + 1,length(decodingOrder));
end

%IDCT
blocksIDCT = zeros(8,1.5*blocksTall*blocksWide*8);
for i = 1:8:length(blocksDQ)
    blocksIDCT(1:8,i:i+7) = idct2(blocksDQ(1:8,i:i+7));
end
blocksShifted = blocksIDCT+128;

if intermediatePlots == 1
    figure;
    imshow(blocksShifted, []);
    title('Post IDCT');
end

%Supersample and convert to RGB
%Supersampling
Ychan = []; 
Cbchan = []; 
Crchan = [];
channelOrder = [1, 1, 1, 1, 2, 3]; % 4:2:0, 1=Y, 2=Cb, 3=Cr
orderTracker = 0;
for i = 1:8:length(blocksShifted)
    channel = channelOrder(orderTracker+1);
    orderTracker = mod(orderTracker+1, length(channelOrder));
    if channel == 1  % Y
        Ychan = [Ychan, blocksShifted(1:8,i:i+7)];
    elseif channel == 2  % Cb
        Cbchan = [Cbchan, supersample420(blocksShifted(1:8,i:i+7))];
    else  % Cr
        Crchan = [Crchan, supersample420(blocksShifted(1:8,i:i+7))];
    end
end

if intermediatePlots == 1
    figure;
    subplot(1, 3, 1);
    imshow(Ychan, []); title('Y');
    subplot(1, 3, 2);
    imshow(Cbchan, []); title('Cb');
    subplot(1, 3, 3);
    imshow(Crchan, []); title('Cr');
end

% YCbCr to RGB
tform = [298.082/256, 0, 408.583/256;
         298.082/256, -100.291/256, -208.12/256;
         298.082/256, 516.412/256, 0];
Rchan = [];
Gchan = [];
Bchan = [];
for i = 1:8:length(Ychan)
    Yblock  =  Ychan(1:8, i:i+7);
    Cbblock = Cbchan(1:8, i:i+7);
    Crblock = Crchan(1:8, i:i+7);
    Rblock = Yblock * tform(1,1) + Cbblock * tform(1,2) + Crblock * tform(1,3) - 222.921;
    Gblock = Yblock * tform(2,1) + Cbblock * tform(2,2) + Crblock * tform(2,3) + 135.576;
    Bblock = Yblock * tform(3,1) + Cbblock * tform(3,2) + Crblock * tform(3,3) - 276.836;
    
    Rblock = round(max(0, min(255, Rblock)));
    Gblock = round(max(0, min(255, Gblock)));
    Bblock = round(max(0, min(255, Bblock)));
    Rchan = [Rchan, Rblock];
    Gchan = [Gchan, Gblock];
    Bchan = [Bchan, Bblock];
end

RGB = uint8(cat(3, Rchan, Gchan, Bchan));

if intermediatePlots == 1
    figure;
    subplot(1, 3, 1);
    imshow(Rchan, []); title('R');
    subplot(1, 3, 2);
    imshow(Gchan, []); title('G');
    subplot(1, 3, 3);
    imshow(Bchan, []); title('B');
    figure;
    imshow(RGB,[]); 
    title('RBG');
end

%Assemble BlockStream into Correct Image Dimensions
finalImg = uint8(zeros(blocksTall*8,blocksWide*8,3));
lrudTracker = 0; %UpperLeft, UppperRight, LowerLeft, LowerRight
xpos = 1;
ypos = 1;
for i = 1:8:length(RGB)
    finalImg(ypos:ypos+7,xpos:xpos+7,1:3) = RGB(1:8,i:i+7,1:3);
    if lrudTracker == 0
        xpos = xpos + 8;
        lrudTracker = 1;
    elseif lrudTracker == 1
        xpos = xpos - 8;
        ypos = ypos + 8;
        lrudTracker = 2;
    elseif lrudTracker == 2
        xpos = xpos + 8;
        lrudTracker = 3;
    else %lrudTracker == 3;
        if(xpos == blocksWide*8-7) %Reached end of row
            xpos = 1;
            ypos = ypos + 8;
        else
            xpos = xpos + 8;
            ypos = ypos - 8;
        end
        lrudTracker = 0;
    end
end

finn = fopen(folderName+"/decoded_values.txt", "w");
oc = 0;
for i = 1:8:length(blocks)
    fprintf(finn, "=================================\n");
    fprintf(finn, "Block %4d\n", oc);
    fprintf(finn, "=================================\n");
    for j = 1:8
        fprintf(finn, "%4d %4d %4d %4d %4d %4d %4d %4d\n", blocks(j,i:i+7));
    end
    oc = oc + 1;
end
fclose(finn);

figure;
imshow(finalImg,[]); 
title('Final Image');

function [values_out, b_size] = decode_huffman_dc(values_in, huffman_dc_map)
    current_str = "";

    for i=1:length(values_in)
        current_str = strcat(current_str, values_in(i));
        if isKey(huffman_dc_map, current_str)
            b_size = huffman_dc_map(current_str);
            break;
        end
    end
    if(i+1 > length(values_in)) %Check if at end of bit stream
        values_out = '';
    else
        values_out = values_in(i+1:end);
    end
end

function [values_out, run_length, b_size] = decode_huffman_ac(values_in, huffman_ac_map)
    current_str = "";

    for i=1:length(values_in)
        current_str = strcat(current_str, values_in(i));
        if isKey(huffman_ac_map, current_str)
            bit8 = dec2bin(huffman_ac_map(current_str), 8);
            run_length = bin2dec(bit8(1:4));
            b_size = bin2dec(bit8(5:8));
            break;
        end
    end
    if(i+1 > length(values_in)) %Check if at end of bit stream
        values_out = '';
    else
        values_out = values_in(i+1:end);
    end
end

% Variable Length Integer (VLI)
function int4 = vli(binStr) 
    if binStr(1) == '1'  % Positive value
        int4 = bin2dec(binStr);
    else  % Negative value
        for i=1:length(binStr)
            if binStr(i) == '0'
                binStr(i) = '1';
            else
                binStr(i) = '0';
            end
        end
        int4 = -1*bin2dec(binStr);
    end 
end

function [A] = inv_zigzag(B,dim)
v = ones(1,dim); k = 1;
A = zeros(dim,dim);
    for i = 1:2*dim-1
        C1 = diag(v,dim-i);
        C2 = flip(C1(1:dim,1:dim),2);
        C3 = B(k:k+sum(C2(:))-1);
        k = k + sum(C2(:));
        if mod(i,2) == 0
           C3 = flip(C3);
        end
            C4 = zeros(1,dim-size(C3,2));
        if i >= dim
           C5 = cat(2,C4, C3); 
        else       
            C5 = cat(2,C3,C4);
        end
        C6 = C2*diag(C5);
        A = C6 + A;
    end
end

function sup_array = supersample420(block)
    
    sup_array = [];
    sup_block = [];
    for i = 0:1
        for j = 0:1
            for k = 1:4
                row = [];
                for l = 1:4
                    row = [row, repmat(block(4*i+k,4*j+l),2,2)];
                end
                sup_block = cat(1, sup_block, row);
            end
            sup_array = [sup_array, sup_block];
            sup_block = [];
        end
    end
end