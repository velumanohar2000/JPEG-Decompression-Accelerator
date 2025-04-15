clear; close all;
x1 = [
488	-1	-1	0	0	0	0	0;
14	1	0	0	0	0	0	0;
-7	0	0	0	0	0	0	0;
2	-1	0	0	0	0	0	0;
0	0	0	0	0	0	0	0;
-1	0	0	0	0	0	0	0;
0	0	0	0	0	0	0	0;
0	0	0	0	0	0	0	0;
];

x2 = magic(8);
x = x1;

flip = false;
count = 1;

% Zig Zag 
% Very complicated. Store indices in lookup tables r_lut and c_lut

N = length(x);
r_lut = zeros(1, N);
c_lut = zeros(1, N); 

out = zeros(1, N*N);
out(1) = x(1, 1);
h = 1;

for i=1:2*N-1
    if i <= N
        if mod(i, 2) == 0
            j = i;
            for k = 1:i
                out(h) = x(k,j);
                r_lut(h) = k;
                c_lut(h) = j;
                h = h + 1;
                j = j - 1;
            end
        else
            k = i;
            for j = 1:i
                out(h) = x(k, j);
                r_lut(h) = k;
                c_lut(h) = j;
                h = h + 1;
                k = k - 1;
            end
        end
    else
        if mod(i, 2) == 0
            j = N;
            for k = mod(i, N) + 1 : N
                out(h) = x(k, j);
                r_lut(h) = k;
                c_lut(h) = j;
                h = h + 1;
                j = j - 1;
            end
        else
            k = N;
            for j = mod(i, N) + 1 : N
                out(h) = x(k, j);
                r_lut(h) = k;
                c_lut(h) = j;
                h = h + 1;
                k = k - 1;
            end
        end
    end
end

% AC RLE / Kinda Huffman 
ac = out(2:end);
rl = 1;

count = 1;

for i=1:length(ac)
    if (ac(i) ~= 0) || (rl == 16)
        ac_rle(count).r = rl-1;
        if (ac(i) ~= 0) 
            ac_rle(count).s = floor(log(abs(ac(i)))/log(2)) + 1;
        elseif (rl == 16) 
            ac_rle(count).s = 0;
        end
        ac_rle(count).v = ac(i);
        rl = 0;
        count = count + 1;
    end
    rl = rl + 1;
end
if (rl > 1) 
    ac_rle(count).r = rl-2; 
    ac_rle(count).s = 0;
    ac_rle(count).v = 0;
end

% Add EOB

ind = 1;
for i=1:length(ac_rle)
    if ac_rle(i).v ~= 0
        ind = i+1;
    end
end

if ind <= length(ac_rle)
    ac_rle(ind:end) = [];
    ac_rle(ind).r = 0;
    ac_rle(ind).s = 0;
    ac_rle(ind).v = 0;
end

% Differnetial Puse Code Modulation (DPCM)
% dc coeffs of image blocks (entire image is 64x64)
dc = [ 488, -30, -20, -10, 10, 20, 30, 40 ];

pred = 0;
dpcm = zeros(1, length(dc));
for i=1:length(dc)
   dcpm(i) = dc(i) - pred; 
   pred = dc(i);
end

% DC Kinda Huffman

for i=1:length(dcpm)
    if dcpm(i) == 0
        dc_huff(i).s = 0;
        dc_huff(i).v = 0;
    else 
        dc_huff(i).s = floor(log(abs(dcpm(i)))/log(2)) + 1;
        dc_huff(i).v = dcpm(i);
    end
end


% DC Decode (trivial since size doesn't really matter...)

x_dec_zz(1) = dc_huff(1).v;

% AC Decode

count = 2;
for i=1:length(ac_rle)
    if (ac_rle(i).s == 0) 
        x_dec_zz(count:length(out)) = 0;
    else
        for j=1:ac_rle(i).r
            x_dec_zz(count) = 0;
            count = count + 1;
        end
        x_dec_zz(count) = ac_rle(i).v;
        count = count + 1;
    end
end

% UnZigZag

x_dec = zeros(length(x));
for i = 1:length(r_lut)
    x_dec(r_lut(i), c_lut(i)) = x_dec_zz(i);
end

disp("Row LUT");
for i=1:length(r_lut)
    fprintf("4'd%d, ", r_lut(i)-1);
end

disp(" ");
disp("Col LUT");
for i=1:length(c_lut)
    fprintf("4'd%d, ", c_lut(i)-1);
end

% disp(x);
% disp(out);
% disp(r_lut);
% disp(c_lut);
% disp(ac_rle);
% disp(x_dec == x);
