% STEP 1: Color transforamtion %
% RGB -> YCbCr
rgbImage = imread('../images/my_cat.png');

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

%Chroma subsampling
Cb_subsampled = Cb(:, 1:2:end);
Cr_subsampled = Cr(:, 1:2:end);

Cb_tmp = zeros(size(double(Cb))); 
Cr_tmp = zeros(size(double(Cr)));

Cb_tmp(:, 1:2:end) = Cb_subsampled; 
Cb_tmp(:, 2:2:end) = Cb_subsampled;
Cr_tmp(:, 1:2:end) = Cr_subsampled; 
Cr_tmp(:, 2:2:end) = Cr_subsampled;

%DCT
N=8;
n=0:N-1;
k=0:N-1;
k=k.';
t=k*(pi()/N*(n+.5));
dct = cos(t);

%quantization table
qtable=[16 11 10 16 24 40 51 61;
        12 12 14 19 26 58 60 55;
        14 13 16 24 40 57 69 56;
        14 17 22 29 51 87 80 62;
        18 22 37 56 68 109 103 77;
        24 35 55 64 81 104 113 92;
        49 64 78 87 103 121 120 101;
        72 92 95 98 112 100 103 99;
        ];
%Need other tables for cb and cr

%Luma DCT
rows=size(Y,1);
cols=size(Y,2);
Y_dct=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        Y_dct(i:i+N-1,j:j+N-1)=round((dct*Y(i:i+N-1,j:j+N-1)*dct.')./qtable);
    end
end

%R Chroma DCT
rows=size(Cr_subsampled,1);
cols=size(Cr_subsampled,2);
CR_dct=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        CR_dct(i:i+N-1,j:j+N-1)=round((dct*Cr_subsampled(i:i+N-1,j:j+N-1)*dct.')./qtable);
    end
end

%B Chroma DCT
rows=size(Cb_subsampled,1);
cols=size(Cb_subsampled,2);
CB_dct=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        CB_dct(i:i+N-1,j:j+N-1)=round((dct*Cb_subsampled(i:i+N-1,j:j+N-1)*dct.')./qtable);
    end
end

%Entropy Encoding





%%%%%%% Decode %%%%%%%%%%

%IDCT
%Luma
rows=size(Y_dct,1);
cols=size(Y_dct,2);
y_inv=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        y_inv(i:i+N-1,j:j+N-1)=inv(dct)*(Y_dct(i:i+N-1,j:j+N-1).*qtable)*inv(dct.');
    end
end
%R chroma IDCT
rows=size(CR_dct,1);
cols=size(CR_dct,2);
cr_inv=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        cr_inv(i:i+N-1,j:j+N-1)=inv(dct)*(CR_dct(i:i+N-1,j:j+N-1).*qtable)*inv(dct.');
    end
end
%B chroma IDCT
rows=size(CB_dct,1);
cols=size(CB_dct,2);
cb_inv=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        cb_inv(i:i+N-1,j:j+N-1)=inv(dct)*(CB_dct(i:i+N-1,j:j+N-1).*qtable)*inv(dct.');
    end
end

%Up-sample Cr & CB
Cb_up = zeros(size(double(y_inv))); 
Cr_up = zeros(size(double(y_inv)));

Cb_up(:, 1:2:end) = cb_inv; 
Cb_up(:, 2:2:end) = cb_inv;
Cr_up(:, 1:2:end) = cr_inv; 
Cr_up(:, 2:2:end) = cr_inv;

ycrcbImg = uint8(cat(3, y_inv, Cb_up, Cr_up));
%imshow(ycrcbImg,[])

tform_inv = [255/219, 0, 255/224*1.402;
             255/219, -255/224*1.772*0.114/0.587, -255/224*1.402*0.299/0.587;   
             255/219, 255/224*1.772, 0];

% R = tform_inv(1,1) * y_inv + tform_inv(1,2) * Cb_up + tform_inv(1,3) * Cr_up - 222.921;
% G = tform_inv(2,1) * y_inv + tform_inv(2,2) * Cb_up + tform_inv(2,3) * Cr_up + 135.576;
% B = tform_inv(3,1) * y_inv + tform_inv(3,2) * Cb_up + tform_inv(3,3) * Cr_up - 276.836;

R = tform_inv(1,1) * (y_inv-16) + tform_inv(1,2) * (Cb_up-128) + tform_inv(1,3) * (Cr_up-128);
G = tform_inv(2,1) * (y_inv-16) + tform_inv(2,2) * (Cb_up-128) + tform_inv(2,3) * (Cr_up-128);
B = tform_inv(3,1) * (y_inv-16) + tform_inv(3,2) * (Cb_up-128) + tform_inv(3,3) * (Cr_up-128);


finalImg = uint8(cat(3,R, G, B));
tmp = finalImg - rgbImage;
tmp1 = tmp(:,:,1); 
tmp2 = tmp(:,:,2);
tmp3 = tmp(:,:,3);
figure(1)
subplot(1,2,1)
imshow(rgbImage,[])
title("Input Image")
subplot(1,2,2)
imshow(finalImg,[])
title("Reconstructed Image")
% figure(2)
% subplot(1,2,2)
% imshow(rgbImage,[])
% subplot(1,2,1)
% imshow(finalImg,[])


% q=ones(32);
% for i = 1:N:rows
%     for j = 1:N:cols
%         q(i:i+N-1,j:j+N-1)=inv(dct)*(Q(i:i+N-1,j:j+N-1).*qtable.*filter)*inv(dct.');
%     end
% end
