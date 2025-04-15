clc;
clear;
close all;

rgbImage = imread('../images/Lenna.png');

tform = [65.738/256, 129.057/256, 25.064/256;
        -37.945/256, -74.494/256, 112.439/256;
        112.439/256, - 94.154/256, -18.285/256];

% Separate the R, G, and B channels
R_mat = double(rgbImage(:,:,1));
G_mat = double(rgbImage(:,:,2));
B_mat = double(rgbImage(:,:,3));

% Calculate Y, Cb, Cr components
Y  = tform(1,1) * R_mat + tform(1,2) * G_mat + tform(1,3) * B_mat + 16;
Cb = tform(2,1) * R_mat + tform(2,2) * G_mat + tform(2,3) * B_mat + 128;
Cr = tform(3,1) * R_mat + tform(3,2) * G_mat + tform(3,3) * B_mat + 128;

Y = round(Y);
Cb = round(Cb);
Cr = round(Cr);

figure;
subplot(2, 3, 1);
imshow(R_mat,[]); title('Matlab: R');
subplot(2, 3, 2);
imshow(G_mat,[]); title('Matlab: G');
subplot(2, 3, 3);
imshow(B_mat,[]); title('Matlab: B');


% Write Y, Cb, Cr values to text files
fileID_Y = fopen('Y_in.txt', 'w');
fileID_Cb = fopen('Cb_in.txt', 'w');
fileID_Cr = fopen('Cr_in.txt', 'w');

% Get the size of the image
[rows, cols] = size(Y);

% Write R, G, B values to text files
for i = 1:rows
    for j = 1:cols
        fprintf(fileID_Y,  '%d\n', Y(i, j));
        fprintf(fileID_Cb, '%d\n', Cb(i, j));
        fprintf(fileID_Cr, '%d\n', Cr(i, j));
    end
end

% Close the files
fclose(fileID_Y);
fclose(fileID_Cb);
fclose(fileID_Cr);

load 'R_out.txt'; load 'G_out.txt'; load 'B_out.txt';

R_v = reshape(R_out, 512, 512)';
G_v = reshape(G_out, 512, 512)';
B_v = reshape(B_out, 512, 512)';

subplot(2, 3, 4);
imshow(R_v,[]); title('Verilog: R');
subplot(2, 3, 5);
imshow(G_v,[]); title('Verilog: G');
subplot(2, 3, 6);
imshow(B_v,[]); title('Verilog: B');

rgbImage_v = uint8(cat(3, R_v, G_v, B_v));

figure;
subplot(1, 2, 1);
imshow(rgbImage); title('Original Image');
subplot(1, 2, 2);
imshow(rgbImage_v); title('Verilog outputs');

error_R = abs(R_v - R_mat);
error_G = abs(G_v - G_mat);
error_B = abs(B_v - B_mat);

max_error_R = max(max(error_R));
max_error_G = max(max(error_G));
max_error_B = max(max(error_B));

min_error_R = min(min(error_R));
min_error_G = min(min(error_G));
min_error_B = min(min(error_B));
