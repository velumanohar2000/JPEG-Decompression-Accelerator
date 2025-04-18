clear; close all;

% --------------------------
% Load image name from file
% --------------------------
imgNameFile = fopen('../python/imageName.txt','r');
imageName = fscanf(imgNameFile,'%s\n',1);
fclose(imgNameFile);

% Manual override (optional)
% imageName = 'smallCat';

% --------------------------
% Read Header Info
% --------------------------
headerPath = fullfile('..', 'python', 'out', imageName, 'HeaderInfo.txt');
headerData = readmatrix(headerPath);
height = headerData(1);
width = headerData(2);

blocksWide = ceil(width / 16) * 2;
blocksTall = ceil(height / 16) * 2;

% --------------------------
% Load RGB outputs from Verilog
% --------------------------
baseVerilogOut = fullfile('..', 'verilog', 'out', imageName);
Rch = load([baseVerilogOut, '_R.txt']);
Gch = load([baseVerilogOut, '_G.txt']);
Bch = load([baseVerilogOut, '_B.txt']);

RGB = uint8(cat(3, Rch, Gch, Bch));

% --------------------------
% Reconstruct full image block-by-block
% --------------------------
finalImg = uint8(zeros(blocksTall * 8, blocksWide * 8, 3));

xpos = 1; ypos = 1; lrudTracker = 0;
for i = 1:8:size(RGB, 1)
    finalImg(ypos:ypos+7, xpos:xpos+7, :) = RGB(i:i+7, 1:8, :);

    switch lrudTracker
        case 0
            xpos = xpos + 8;
        case 1
            xpos = xpos - 8;
            ypos = ypos + 8;
        case 2
            xpos = xpos + 8;
        case 3
            if xpos == blocksWide * 8 - 7
                xpos = 1;
                ypos = ypos + 8;
            else
                xpos = xpos + 8;
                ypos = ypos - 8;
            end
    end
    lrudTracker = mod(lrudTracker + 1, 4);
end

% --------------------------
% Crop and display results
% --------------------------
finalCropped = finalImg(1:height, 1:width, :);

figure(1); imshow(finalImg);
title('Image (Uncropped)');

figure(2);
subplot(1,2,1); imshow(finalCropped); title('Verilog');

matlabRef = imread(fullfile('..', 'images', [imageName, '.jpg']));
subplot(1,2,2); imshow(matlabRef); title('MATLAB');

% --------------------------
% Compute error analysis
% --------------------------
posError = double(finalCropped) - double(matlabRef);
negError = double(matlabRef) - double(finalCropped);

maxPos = squeeze(max(max(posError, [], 1), [], 2));
maxNeg = squeeze(max(max(negError, [], 1), [], 2));
maxDelta = maxPos + maxNeg;

avgDelta = squeeze(mean(mean(posError + negError, 1), 2));

pause(1);
figure(3);
imshow(uint8(255 * bsxfun(@rdivide, max(posError, 0), reshape(maxPos, 1, 1, 3))), []);
title('Spots where Verilog is brighter');

pause(1);
figure(4);
imshow(uint8(255 * bsxfun(@rdivide, max(negError, 0), reshape(maxNeg, 1, 1, 3))), []);
title('Spots where MATLAB is brighter');

% --------------------------
% PSNR Calculation
% --------------------------
psnrVal = psnr(finalCropped, matlabRef);
fprintf('PSNR: %.2f dB\n', psnrVal);
