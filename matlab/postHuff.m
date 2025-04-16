% %Inverse Zigzag scan
% blocks = zeros(8,1.5*blocksTall*blocksWide*8);
% pos = 1;
% for i = 1:64:length(encoded_values)
%     blocks(1:8,pos:pos+7) = inv_zigzag(encoded_values(i:i+63), 8);
%     pos = pos+8;
% end
% 
% %Dequant
% QuantTable0 = readmatrix('./tiny/QuantTable0.txt');
% QuantTable1 = readmatrix('./tiny/QuantTable1.txt');
% 
% quantTables = {QuantTable0,QuantTable1};
% 
% orderTracker = 0;
% blocksDQ = zeros(8,1.5*blocksTall*blocksWide*8);
% for i = 1:8:length(blocks)
%     blocksDQ(1:8,i:i+7) = blocks(1:8,i:i+7) .*quantTables{decodingOrder(orderTracker+1)};
%     orderTracker = mod(orderTracker + 1,length(decodingOrder));
% end
% 
% %IDCT
% blocksIDCT = zeros(8,1.5*blocksTall*blocksWide*8);
% for i = 1:8:length(blocksDQ)
%     blocksIDCT(1:8,i:i+7) = idct2(blocksDQ(1:8,i:i+7));
% end
% imshow(blocksIDCT,[])
% 
% function [A] = inv_zigzag(B,dim)
% v = ones(1,dim); k = 1;
% A = zeros(dim,dim);
% for i = 1:2*dim-1
%     C1 = diag(v,dim-i);
%     C2 = flip(C1(1:dim,1:dim),2);
%     C3 = B(k:k+sum(C2(:))-1);
%     k = k + sum(C2(:));
%     if mod(i,2) == 0
%        C3 = flip(C3);
%     end
%         C4 = zeros(1,dim-size(C3,2));
%     if i >= dim
%        C5 = cat(2,C4, C3); 
%     else       
%         C5 = cat(2,C3,C4);
%     end
%     C6 = C2*diag(C5);
%     A = C6 + A;
% end
% end


%Assemble BlockStream into Correct Image Dimensions
RBlocks = rand(8,8*blocksWide*blocksTall);
RBlocks = RBlocks * 255;
GBlocks = rand(8,8*blocksWide*blocksTall);
GBlocks = GBlocks * 255;
BBlocks = rand(8,8*blocksWide*blocksTall);
BBlocks = BBlocks * 255;

RGBBlocks = uint8(cat(3,RBlocks,GBlocks,BBlocks));

figure()
imshow(RGBBlocks,[])

finalImg = uint8(zeros(blocksTall*8,blocksWide*8,3));
lrudTracker = 0; %UpperLeft, UppperRight, LowerLeft, LowerRight
xpos = 1;
ypos = 1;
for i = 1:8:length(RGBBlocks)
    finalImg(ypos:ypos+7,xpos:xpos+7,1:3) = RGBBlocks(1:8,i:i+7,1:3);
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

figure()
imshow(finalImg,[])