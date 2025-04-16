clear;
close all;

fileID = fopen('../python/imageName.txt','r');
imageName = fscanf(fileID,'%s\n',1);
fclose(fileID);

%%%%%%%%%% Manual image select %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%imageName = 'smallCat'; 

%%%%%%%%%% USER: DO NOT EDIT BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Read Header Info
Header = readmatrix(['../python/',imageName,'/HeaderInfo.txt']);

height = Header(1,1);
width = Header(1,2);
blocksWide = ceil(width/16)*2;
blocksTall = ceil(height/16)*2;

Rch = load (['../verilog/out/',imageName,'_R.txt']);
Gch = load (['../verilog/out/',imageName,'_G.txt']);
Bch = load (['../verilog/out/',imageName,'_B.txt']);

RGB = uint8(cat(3, Rch, Gch, Bch));

%Assemble BlockStream into Correct Image Dimensions
finalImg = uint8(zeros(blocksTall*8,blocksWide*8,3));
lrudTracker = 0; %UpperLeft, UppperRight, LowerLeft, LowerRight
xpos = 1;
ypos = 1;
for i = 1:8:length(RGB)
    finalImg(ypos:ypos+7,xpos:xpos+7,1:3) = RGB(i:i+7,1:8,1:3);
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

finalImgCropped = finalImg(1:height,1:width,1:3);

figure(1)
imshow(finalImg)
title('Image (Uncropped)')

figure(2)
subplot(1,2,1)
imshow(finalImgCropped)
title('Verilog')

matlabDecode = imread(['../images/',imageName,'.jpg']);

subplot(1,2,2)
imshow(matlabDecode)
title('Matlab')

posErrorR = double(finalImgCropped(:,:,1) - matlabDecode(:,:,1));
posErrorG = double(finalImgCropped(:,:,2) - matlabDecode(:,:,2));
posErrorB = double(finalImgCropped(:,:,3) - matlabDecode(:,:,3));
maxPosER = max(max(posErrorR)); 
maxPosEG = max(max(posErrorG));
maxPosEB = max(max(posErrorB));

pause(1)

figure(3)
imshow(uint8(cat(3, posErrorR*255/maxPosER, posErrorG*255/maxPosEG, posErrorB*255/maxPosEB)), []);
title('Spots where Verilog is brighter than MATLAB');

negErrorR = double(matlabDecode(:,:,1) - finalImgCropped(:,:,1));
negErrorG = double(matlabDecode(:,:,2) - finalImgCropped(:,:,2));
negErrorB = double(matlabDecode(:,:,3) - finalImgCropped(:,:,3));
maxNegER = max(max(negErrorR));
maxNegEG = max(max(negErrorG));
maxNegEB = max(max(negErrorB));

pause(1)

figure(4)
imshow(uint8(cat(3, negErrorR*255/maxNegER, negErrorG*255/maxNegEG, negErrorB*255/maxNegEB)), []);
title('Spots where MATLAB is brighter than Verilog')

maxDeltaR = maxPosER + maxNegER;
maxDeltaG = maxPosEG + maxNegEG;
maxDeltaB = maxPosEB + maxNegEB;

avgDeltaR = mean(mean(posErrorR + negErrorR));
avgDeltaG = mean(mean(posErrorG + negErrorG));
avgDeltaB = mean(mean(posErrorB + negErrorB));

psnr = psnr(finalImgCropped,matlabDecode);



