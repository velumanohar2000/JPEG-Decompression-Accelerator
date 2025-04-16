clc;
clear;
close all;

% Read Huffman DC, AC table and encoded values %
fileID1 = fopen('huff_dc_table.txt', 'r');
fileID2 = fopen('huff_ac_table.txt', 'r');
fileID3 = fopen('huff_code_ex.txt', 'r');
formatSpec = '%s %d';
DC = textscan(fileID1, formatSpec);
AC = textscan(fileID2, formatSpec);

huff_dc_codes  = DC{1};
huff_dc_values = DC{2};
huff_ac_codes  = AC{1};
huff_ac_values = AC{2};

huffman_dc_map = containers.Map(huff_dc_codes, huff_dc_values);
huffman_ac_map = containers.Map(huff_ac_codes, huff_ac_values);

values_in = fscanf(fileID3, '%s');

encoded_values = [];
dc_flag = 1;
cnt = 0;

while (~isempty(values_in))
    if dc_flag == 1 % DC
        [values_out, b_size] = decode_huffman_dc(values_in, huffman_dc_map);
        encoded_values = [encoded_values, vli(values_out(1:b_size))];
        values_in = values_out(b_size+1:end);
        dc_flag = 0;
        cnt = cnt + 1;
    else % AC
        [values_out, run_length, b_size] = decode_huffman_ac(values_in, huffman_ac_map);
        if run_length == 0 && b_size == 0  % EOB
            zeros_to_append = zeros(1, 64-cnt);
            encoded_values = [encoded_values, zeros_to_append];
            values_in = values_out(b_size+1:end);
            dc_flag = 1;
            cnt = 64;
        else
            zeros_to_append = zeros(1, run_length);
            encoded_values = [encoded_values, zeros_to_append];   % adding zeros
            encoded_values = [encoded_values, vli(values_out(1:b_size))]; 
            values_in = values_out(b_size+1:end);
            cnt = cnt + size(zeros_to_append,2) + 1;
        end
    end
    display(cnt)
end

% Inverse Zigzag scan
result = inv_zigzag(encoded_values, 8);

fileID1 = fclose(fileID1);
fileID2 = fclose(fileID2);
fileID3 = fclose(fileID3);

function [values_out, b_size] = decode_huffman_dc(values_in, huffman_dc_map)
    current_str = "";
    
    for i=1:length(values_in)
        current_str = strcat(current_str, values_in(i));
        if isKey(huffman_dc_map, current_str)
            b_size = huffman_dc_map(current_str);
            break;
        end
    end
    values_out = values_in(i+1:end);
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
    values_out = values_in(i+1:end);
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