clc;
clear;
close all;

% STEP 1: Color transforamtion %
% RGB -> YCbCr
rgbImage = imread('../images/my_cat.png');
figure()
imshow(rgbImage)

% Transformation matrix
tform = [ 0.299,  0.587,  0.114; 
         -0.1687, -0.3313, 0.5; 
          0.5,   -0.4187, -0.0813];

% Separate the R, G, and B channels
R = double(rgbImage(:,:,1));
G = double(rgbImage(:,:,2));
B = double(rgbImage(:,:,3));

% Calculate Y, Cb, Cr components
Y  = tform(1,1) * R + tform(1,2) * G + tform(1,3) * B;
Cb = tform(2,1) * R + tform(2,2) * G + tform(2,3) * B + 128;
Cr = tform(3,1) * R + tform(3,2) * G + tform(3,3) * B + 128;

% Combine Y, Cb, Cr into a single image
ycbcrImage = uint8(cat(3, Y, Cb, Cr));
Y = ycbcrImage(:,:,1); Cb = ycbcrImage(:,:,2); Cr = ycbcrImage(:,:,3);

% Display the original and converted images
figure;
subplot(1, 3, 1);
imshow(Y); title('Y');
subplot(1, 3, 2);
imshow(Cb); title('Cb');
subplot(1, 3, 3);
imshow(Cr); title('Cr');

% Step 2: Chroma subsampling (4:2:2) %
Cb_subsampled = Cb(:, 1:2:end);
Cr_subsampled = Cr(:, 1:2:end);

Cb_tmp = zeros(size(double(Cb))); 
Cr_tmp = zeros(size(double(Cr)));

Cb_tmp(:, 1:2:end) = Cb_subsampled; 
Cb_tmp(:, 2:2:end) = Cb_subsampled;
Cr_tmp(:, 1:2:end) = Cr_subsampled; 
Cr_tmp(:, 2:2:end) = Cr_subsampled;

ycbcrImage_subsampled = uint8(cat(3, Y, Cb_tmp, Cr_tmp));
figure;
subplot(1,2,1);
imshow(ycbcrImage); title("ycbcrImage");
subplot(1,2,2);


imshow(ycbcrImage_subsampled); title("ycbcrImage subsampled 4:2:2");

% Y_sub = ycbcrImage_subsampled(:,:,1);
% Cb_sub = ycbcrImage_subsampled(:,:,2);
% Cr_sub = ycbcrImage_subsampled(:,:,3);
