% STEP 1: Color transforamtion %
% RGB -> YCbCr
rgbImage = imread('../images/smallCat.jpg');

% Transformation matrix
tform = [65.481/255, 128.553/255, 24.966/255;
            -37.797/255, -74.203/255, 112/255;
            112/255, -93.786/255 -18.214/255];

% Separate the R, G, and B channels
R = double(rgbImage(:,:,1));
G = double(rgbImage(:,:,2));
B = double(rgbImage(:,:,3));

% Calculate Y, Cb, Cr components
Y  = tform(1,1) * R + tform(1,2) * G + tform(1,3) * B + 16;
Cb = tform(2,1) * R + tform(2,2) * G + tform(2,3) * B + 128;
Cr = tform(3,1) * R + tform(3,2) * G + tform(3,3) * B + 128;

Image = uint8(cat(3,Y,Cb,Cr));
figure()
subplot(1, 3, 1);
imshow(Y, []); title('Y');
subplot(1, 3, 2);
imshow(Cb, []); title('Cb');
subplot(1, 3, 3);
imshow(Cr, []); title('Cr');

%Chroma subsampling
Cb_subsampled = Cb(:, 1:2:end);
Cr_subsampled = Cr(:, 1:2:end);

%Up-sample Cr & CB
Cb_up = zeros(size(double(Y))); 
Cr_up = zeros(size(double(Y)));

Cb_up(:, 1:2:end) = Cb_subsampled; 
Cb_up(:, 2:2:end) = Cb_subsampled;
Cr_up(:, 1:2:end) = Cr_subsampled; 
Cr_up(:, 2:2:end) = Cr_subsampled;

Image = uint8(cat(3,Y,Cb_up,Cr_up));
figure()
subplot(1, 3, 1);
imshow(Y, []); title('Y');
subplot(1, 3, 2);
imshow(Cb_up, []); title('Cb_sub');
subplot(1, 3, 3);
imshow(Cr_up, []); title('Cr_sub');
