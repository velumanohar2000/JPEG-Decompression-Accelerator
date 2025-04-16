%% Clear any data before runnning to avoid erros
clear;

%% Comparing Matlab's DCT/IDCT vs Loeffler's DCT/IDCT implementation
%test_data = [255  255  255  255  0  0  0  0];
test_data = [50 60 70 80 90 100 110 120];

idct_2d_test_data = [
                    24 -8 84 96 -20 -16 0 0;
                    -30	55 -42 16 -10 0 0 0;
                    150	40	-54	-100	32	0	28	22;
                    24	-42	72	-60	20	0	0	0;
                    -7	-18	45	0	-27	0	0	0;
                    0	14	0	-26	-32	0	0	0;
                    0	26	-31	0	0	0	0	0;
                    0	0	0	0	0	0	0	0
                    ];


idct_2d_test_dataPos = abs(idct_2d_test_data);

% Write file to be used with 2D IDCT Testbench
fileID = fopen('idct_input_block3.mem','w');
for row = 1:8
    for col = 1:8
        fprintf(fileID,'%s ', dec2hex(idct_2d_test_dataPos(row,col),2)); %dec2hex(idct_2d_test_data(row,col),2)
    end
    fprintf(fileID,'\n');
end
fclose(fileID);

% Matlab
matlab_dct  = dct(test_data);
matlab_idct = idct(test_data);

% Loeffler's implementation (must normalize to match matlab output)
%improved_loeffler_dct = loefflersDCT(test_data)/sqrt(8);
%improved_loeffler_idct = loefflersIDCT(test_data)/sqrt(8);

idct2d_test_result = loefflersIDCT_2D(idct_2d_test_dataPos); 
idct2d_test_result_fixed = fix(loefflersIDCT_2D_fixed(idct_2d_test_dataPos));
idct2d_matlab = idct2(idct_2d_test_dataPos);

%% Loeffler's Original DCT (Works correctly)
function dct_out = loefflerDCT(dct_in)

    stage1_output = zeros(1,8);

    constant_b = cos(pi/16); 
    constant_c = sqrt(2) * cos(pi/8); 
    constant_d = cos(3*pi/16); 
    constant_e = cos(5*pi/16); 
    constant_f = sqrt(2) * cos(3*pi/8); 
    constant_g = cos(7*pi/16); 
    constant_h = sqrt(2);

    % Stage 1
    stage1_output(1) = dct_in(1) + dct_in(8);
    stage1_output(2) = dct_in(2) + dct_in(7);
    stage1_output(3) = dct_in(3) + dct_in(6);
    stage1_output(4) = dct_in(4) + dct_in(5);
    stage1_output(5) = dct_in(4) - dct_in(5);
    stage1_output(6) = dct_in(3) - dct_in(6);
    stage1_output(7) = dct_in(2) - dct_in(7);
    stage1_output(8) = dct_in(1) - dct_in(8);

    stage2_output = zeros(1,8);

    % Stage 2
    stage2_output(1) = stage1_output(1) + stage1_output(4);
    stage2_output(2) = stage1_output(2) + stage1_output(3);
    stage2_output(3) = stage1_output(2) - stage1_output(3);
    stage2_output(4) = stage1_output(1) - stage1_output(4);
    stage2_output(5) = (stage1_output(5) + stage1_output(8))*constant_d+(constant_e-constant_d)*stage1_output(8);
    stage2_output(6) = (stage1_output(6) + stage1_output(7))*constant_b+(constant_g-constant_b)*stage1_output(7);
    stage2_output(7) = (stage1_output(6) + stage1_output(7))*constant_b-(constant_g+constant_b)*stage1_output(6);
    stage2_output(8) = (stage1_output(5) + stage1_output(8))*constant_d-(constant_e+constant_d)*stage1_output(5);

    stage3_output = zeros(1,8);

    % Stage 3
    stage3_output(1) = stage2_output(1) + stage2_output(2);
    stage3_output(2) = stage2_output(1) - stage2_output(2);
    stage3_output(3) = (stage2_output(3) + stage2_output(4))*constant_f+(constant_c-constant_f)*stage2_output(4);
    stage3_output(4) = (stage2_output(3) + stage2_output(4))*constant_f-(constant_c+constant_f)*stage2_output(3);
    stage3_output(5) = stage2_output(5) + stage2_output(7);
    stage3_output(6) = stage2_output(8) - stage2_output(6);
    stage3_output(7) = stage2_output(5) - stage2_output(7);
    stage3_output(8) = stage2_output(8) + stage2_output(6);

    dct_out = zeros(1,8);

    % Stage 4
    dct_out(1) = stage3_output(1);
    dct_out(5) = stage3_output(2);
    dct_out(3) = stage3_output(3);
    dct_out(7) = stage3_output(4);
    dct_out(8) = stage3_output(8) - stage3_output(5);
    dct_out(4) = stage3_output(6) * constant_h;
    dct_out(6) = stage3_output(7) * constant_h;
    dct_out(2) = stage3_output(8) + stage3_output(5);

end

%% Loeffler's Original IDCT (Works correctly)
function idct_out = loefflerIDCT(idct_in)

    stage1_output = zeros(1,8);

    constant_b = cos(pi/16); 
    constant_c = sqrt(2) * cos(pi/8); 
    constant_d = cos(3*pi/16); 
    constant_e = cos(5*pi/16); 
    constant_f = sqrt(2) * cos(3*pi/8); 
    constant_g = cos(7*pi/16); 
    constant_h = sqrt(2);

    idct_in_rearranged = zeros(1,8);

    idct_in_rearranged(1) = idct_in(1);
    idct_in_rearranged(2) = idct_in(5);
    idct_in_rearranged(3) = idct_in(3);
    idct_in_rearranged(4) = idct_in(7);
    idct_in_rearranged(5) = idct_in(8);
    idct_in_rearranged(6) = idct_in(4);
    idct_in_rearranged(7) = idct_in(6);
    idct_in_rearranged(8) = idct_in(2);


    % Stage 1
    stage1_output(1) = idct_in_rearranged(1);
    stage1_output(2) = idct_in_rearranged(2);
    stage1_output(3) = idct_in_rearranged(3);
    stage1_output(4) = idct_in_rearranged(4);
    stage1_output(5) = idct_in_rearranged(8) - idct_in_rearranged(5);
    stage1_output(6) = idct_in_rearranged(6) * constant_h;
    stage1_output(7) = idct_in_rearranged(7) * constant_h;
    stage1_output(8) = idct_in_rearranged(8) + idct_in_rearranged(5);

    stage2_output = zeros(1,8);

    % Stage 2
    stage2_output(1) = stage1_output(1) + stage1_output(2);
    stage2_output(2) = stage1_output(1) - stage1_output(2);
    stage2_output(3) = (stage1_output(3) + stage1_output(4))*constant_f-(constant_c+constant_f)*stage1_output(4);
    stage2_output(4) = (stage1_output(3) + stage1_output(4))*constant_f+(constant_c-constant_f)*stage1_output(3);
    stage2_output(5) = stage1_output(5) + stage1_output(7);
    stage2_output(6) = stage1_output(8) - stage1_output(6);
    stage2_output(7) = stage1_output(5) - stage1_output(7);
    stage2_output(8) = stage1_output(8) + stage1_output(6);

    stage3_output = zeros(1,8);

    % Stage 3
    stage3_output(1) = stage2_output(1) + stage2_output(4);
    stage3_output(2) = stage2_output(2) + stage2_output(3);
    stage3_output(3) = stage2_output(2) - stage2_output(3);
    stage3_output(4) = stage2_output(1) - stage2_output(4);
    stage3_output(5) = (stage2_output(5) + stage2_output(8))*constant_d-(constant_e+constant_d)*stage2_output(8);
    stage3_output(6) = (stage2_output(6) + stage2_output(7))*constant_b-(constant_g+constant_b)*stage2_output(7);
    stage3_output(7) = (stage2_output(6) + stage2_output(7))*constant_b+(constant_g-constant_b)*stage2_output(6);
    stage3_output(8) = (stage2_output(5) + stage2_output(8))*constant_d+(constant_e-constant_d)*stage2_output(5);

    idct_out = zeros(1,8);

    % Stage 4
    idct_out(1) = stage3_output(1) + stage3_output(8);
    idct_out(2) = stage3_output(2) + stage3_output(7);
    idct_out(3) = stage3_output(3) + stage3_output(6);
    idct_out(4) = stage3_output(4) + stage3_output(5);
    idct_out(5) = stage3_output(4) - stage3_output(5);
    idct_out(6) = stage3_output(3) - stage3_output(6);
    idct_out(7) = stage3_output(2) - stage3_output(7);
    idct_out(8) = stage3_output(1) - stage3_output(8);

end

%% Improved Loeffler's DCT (Works correctly)
function dct_out = loefflersDCT(dct_in)

    % Stage 1 % Checked
    stage1_out = zeros(8,1);

    stage1_out(1) = dct_in(1) + dct_in(8);
    stage1_out(2) = dct_in(2) + dct_in(7);
    stage1_out(3) = dct_in(3) + dct_in(6);
    stage1_out(4) = dct_in(4) + dct_in(5);
    stage1_out(5) = dct_in(4) - dct_in(5);
    stage1_out(6) = dct_in(3) - dct_in(6);
    stage1_out(7) = dct_in(2) - dct_in(7);
    stage1_out(8) = dct_in(1) - dct_in(8);

    % Stage 2 % Checked
    stage2_out = zeros(10,1);

    stage2_out(1)  = stage1_out(1) + stage1_out(4);
    stage2_out(2)  = stage1_out(2) + stage1_out(3);
    stage2_out(3)  = stage1_out(2) - stage1_out(3);
    stage2_out(4)  = stage1_out(1) - stage1_out(4);
    stage2_out(5)  = stage1_out(8) * (-71);
    stage2_out(6)  = stage1_out(7);
    stage2_out(7)  = stage1_out(6);
    stage2_out(8)  = stage1_out(5) * (355);
    stage2_out(9)  = stage1_out(5) + stage1_out(8);
    stage2_out(10) = stage1_out(6) + stage1_out(7);

    % Stage 3 % Checked
    stage3_out = zeros(10,1);

    stage3_out(1)  = stage2_out(1) + stage2_out(2);
    stage3_out(2)  = stage2_out(1) - stage2_out(2);
    stage3_out(3)  = stage2_out(3);
    stage3_out(4)  = stage2_out(4);
    stage3_out(5)  = stage2_out(5);
    stage3_out(6)  = stage2_out(6);
    stage3_out(7)  = stage2_out(7);
    stage3_out(8)  = stage2_out(8);
    stage3_out(9)  = stage2_out(9)  * (213);
    stage3_out(10) = stage2_out(10) * (251);

    % Stage 4 % Checked
    stage4_out = zeros(10,1);

    stage4_out(1)  = stage3_out(1);
    stage4_out(2)  = stage3_out(2);
    stage4_out(3)  = stage3_out(3);
    stage4_out(4)  = stage3_out(4);
    stage4_out(5)  = stage3_out(5);
    stage4_out(6)  = stage3_out(6) * (-201);
    stage4_out(7)  = stage3_out(7) * (301);
    stage4_out(8)  = stage3_out(8);
    stage4_out(9)  = stage3_out(9);
    stage4_out(10) = stage3_out(10);

    % Stage 5 % Checked
    stage5_out = zeros(9,1);

    stage5_out(1) = stage4_out(1);
    stage5_out(2) = stage4_out(2);
    stage5_out(3) = stage4_out(4);
    stage5_out(4) = stage4_out(3);
    stage5_out(5) = stage4_out(9) + stage4_out(5);
    stage5_out(6) = stage4_out(10) + stage4_out(6);
    stage5_out(7) = stage4_out(10) - stage4_out(7);
    stage5_out(8) = stage4_out(9) - stage4_out(8);
    stage5_out(9) = stage4_out(3) + stage4_out(4);

    % Stage 6 % Checked
    stage6_out = zeros(9,1);

    stage6_out(1) = stage5_out(1);
    stage6_out(2) = stage5_out(2);
    stage6_out(3) = stage5_out(3);
    stage6_out(4) = stage5_out(4);
    stage6_out(5) = stage5_out(5) + stage5_out(7);
    stage6_out(6) = stage5_out(8) - stage5_out(6);
    stage6_out(7) = stage5_out(5) - stage5_out(7);
    stage6_out(8) = stage5_out(8) + stage5_out(6);
    stage6_out(9) = stage5_out(9) * (139);

    % Stage 7 % Checked
    stage7_out = zeros(9,1);

    stage7_out(1) = stage6_out(1);
    stage7_out(2) = stage6_out(2);
    stage7_out(3) = stage6_out(3) * (196);
    stage7_out(4) = stage6_out(4) * (473);
    stage7_out(5) = stage6_out(8) - stage6_out(5);
    stage7_out(6) = stage6_out(6);
    stage7_out(7) = stage6_out(7);
    stage7_out(8) = stage6_out(8) + stage6_out(5);
    stage7_out(9) = stage6_out(9);

    % Stage 8 % Checked
    % Outputs are assign in reverse bit order
    stage8_out = zeros(8,1);

    stage8_out(1) = stage7_out(1);
    stage8_out(5) = stage7_out(2);
    stage8_out(3) = (stage7_out(9) + stage7_out(3)) * 2^(-8);
    stage8_out(7) = (stage7_out(9) - stage7_out(4)) * 2^(-8);
    stage8_out(8) = stage7_out(5) * 2^(-8);
    stage8_out(4) = (stage7_out(6) * (362)) * 2^(-16);
    stage8_out(6) = (stage7_out(7) * (362)) * 2^(-16);
    stage8_out(2) = stage7_out(8) * 2^(-8);

    dct_out = stage8_out;

end

%% Improved Loeffler's IDCT (Works correctly)
function idct_out = loefflersIDCT(idct_in_reversed)

    constant_b = cos(pi/16); 
    constant_c = sqrt(2) * cos(pi/8); 
    constant_d = cos(3*pi/16); 
    constant_e = cos(5*pi/16); 
    constant_f = sqrt(2) * cos(3*pi/8); 
    constant_g = cos(7*pi/16); 
    constant_h = sqrt(2);

    % Undoing the bit-reverse order of the input
    idct_in = zeros(1,8);

    idct_in(1) = idct_in_reversed(1);
    idct_in(2) = idct_in_reversed(5);
    idct_in(3) = idct_in_reversed(3);
    idct_in(4) = idct_in_reversed(7);
    idct_in(5) = idct_in_reversed(8);
    idct_in(6) = idct_in_reversed(4);
    idct_in(7) = idct_in_reversed(6);
    idct_in(8) = idct_in_reversed(2);

    % Stage 1 Checked
    stage1_out = zeros(8,1);

    stage1_out(1) = idct_in(1);
    stage1_out(2) = idct_in(2);
    stage1_out(3) = idct_in(3);
    stage1_out(4) = idct_in(4);
    stage1_out(5) = idct_in(5);
    stage1_out(6) = idct_in(6) * (362);
    stage1_out(7) = idct_in(7) * (362);
    stage1_out(8) = idct_in(8);

    % Stage 2 Checked
    stage2_out = zeros(9,1);

    stage2_out(1)  = stage1_out(1);
    stage2_out(2)  = stage1_out(2);
    stage2_out(3)  = stage1_out(4) * (473);
    stage2_out(4)  = stage1_out(3) * (196);
    stage2_out(5)  = (stage1_out(8) - stage1_out(5)) * 2^(8);
    stage2_out(6)  = stage1_out(6);
    stage2_out(7)  = stage1_out(7);
    stage2_out(8)  = (stage1_out(8) + stage1_out(5)) * 2^(8);
    stage2_out(9)  = stage1_out(3) + stage1_out(4);

    % Stage 3 Checked
    stage3_out = zeros(9,1);

    stage3_out(1)  = stage2_out(1);
    stage3_out(2)  = stage2_out(2);
    stage3_out(3)  = stage2_out(3);
    stage3_out(4)  = stage2_out(4);
    stage3_out(5)  = stage2_out(5) + stage2_out(7);
    stage3_out(6)  = stage2_out(8) - stage2_out(6);
    stage3_out(7)  = stage2_out(5) - stage2_out(7);
    stage3_out(8)  = stage2_out(8) + stage2_out(6);
    stage3_out(9)  = stage2_out(9)  * (139);

    % Stage 4 Checked
    stage4_out = zeros(9,1);

    stage4_out(1)  = stage3_out(1);
    stage4_out(2)  = stage3_out(2);
    stage4_out(3)  = stage3_out(9) - stage3_out(3);
    stage4_out(4)  = stage3_out(9) + stage3_out(4);
    stage4_out(5)  = stage3_out(8) * (355);
    stage4_out(6)  = stage3_out(6);
    stage4_out(7)  = stage3_out(7);
    stage4_out(8)  = stage3_out(5) * (-71);
    stage4_out(9)  = stage3_out(5) + stage3_out(8);

    % Stage 5 Checked
    stage5_out = zeros(10,1);

    stage5_out(1)  = stage4_out(1);
    stage5_out(2)  = stage4_out(2);
    stage5_out(3)  = stage4_out(3);
    stage5_out(4)  = stage4_out(4);
    stage5_out(5)  = stage4_out(5);
    stage5_out(6)  = stage4_out(7) * (301);
    stage5_out(7)  = stage4_out(6) * (-201);
    stage5_out(8)  = stage4_out(8);
    stage5_out(9)  = stage4_out(9);
    stage5_out(10) = stage4_out(6) + stage4_out(7);

    % Stage 6 Checked
    stage6_out = zeros(10,1);

    stage6_out(1)  = stage5_out(1) + stage5_out(2);
    stage6_out(2)  = stage5_out(1) - stage5_out(2);
    stage6_out(3)  = stage5_out(3) * 2^(-8);
    stage6_out(4)  = stage5_out(4) * 2^(-8);
    stage6_out(5)  = stage5_out(5);
    stage6_out(6)  = stage5_out(6);
    stage6_out(7)  = stage5_out(7);
    stage6_out(8)  = stage5_out(8);
    stage6_out(9)  = stage5_out(9) * (213);
    stage6_out(10) = stage5_out(10) * (251);

    % Stage 7 Checked
    stage7_out = zeros(8,1);

    stage7_out(1) = stage6_out(1) + stage6_out(4);
    stage7_out(2) = stage6_out(2) + stage6_out(3);
    stage7_out(3) = stage6_out(2) - stage6_out(3);
    stage7_out(4) = stage6_out(1) - stage6_out(4);
    stage7_out(5) = (stage6_out(9) - stage6_out(5)) * 2^(-16);
    stage7_out(6) = (stage6_out(10) - stage6_out(6)) * 2^(-16);
    stage7_out(7) = (stage6_out(10) + stage6_out(7)) * 2^(-16);
    stage7_out(8) = (stage6_out(9) + stage6_out(8)) * 2^(-16);

    % Stage 8 Checked
    stage8_out = zeros(8,1);

    stage8_out(1) = stage7_out(1) + stage7_out(8);
    stage8_out(2) = stage7_out(2) + stage7_out(7);
    stage8_out(3) = stage7_out(3) + stage7_out(6);
    stage8_out(4) = stage7_out(4) + stage7_out(5);
    stage8_out(5) = stage7_out(4) - stage7_out(5);
    stage8_out(6) = stage7_out(3) - stage7_out(6);
    stage8_out(7) = stage7_out(2) - stage7_out(7);
    stage8_out(8) = stage7_out(1) - stage7_out(8);

    idct_out = stage8_out;
end

%% Loeffler's 2D DCT 
function dct_out = loefflersDCT_2D(dct_in)

    row_dct = zeros(8,8);
    dct_out = zeros(8,8);

    % DCT of the row
    for row=1:size(dct_in,1)
        row_dct(row,:) = loefflersDCT(dct_in(row,:));
    end

    % Tranpose
    transposed_matrix = transpose(row_dct);

    % In the transpose matrix, the rows contain
    % the values of each column. Compute the DCT
    % of the columns by computing the DCT of each row
    % of the transposed matrix
    for row=1:size(transposed_matrix,1)
        dct_out(row,:) = loefflersDCT(transposed_matrix(row,:));
    end

    dct_out = transpose(dct_out)/8;
end

%% Loeffler's 2D IDCT (Works correctly)
function idct_out = loefflersIDCT_2D(idct_in)

    row_idct = zeros(8,8);
    idct_out = zeros(8,8);

    % DCT of the row
    for row=1:size(idct_in,1)
        row_idct(row,:) = loefflersIDCT(idct_in(row,:));
    end

    % Tranpose
    transposed_matrix = transpose(row_idct);

    % In the transpose matrix, the rows contain
    % the values of each column. Compute the DCT
    % of the columns by computing the DCT of each row
    % of the transposed matrix
    for row=1:size(transposed_matrix,1)
        idct_out(row,:) = loefflersIDCT(transposed_matrix(row,:));
    end

    idct_out = transpose(idct_out)/8;
end

%% Improved Loeffler's DCT (Works correctly)
function dct_out = loefflersDCT_fixed(dct_in)

    % Stage 1 % Checked
    stage1_out = zeros(8,1);

    stage1_out(1) = dct_in(1) + dct_in(8);
    stage1_out(2) = dct_in(2) + dct_in(7);
    stage1_out(3) = dct_in(3) + dct_in(6);
    stage1_out(4) = dct_in(4) + dct_in(5);
    stage1_out(5) = dct_in(4) - dct_in(5);
    stage1_out(6) = dct_in(3) - dct_in(6);
    stage1_out(7) = dct_in(2) - dct_in(7);
    stage1_out(8) = dct_in(1) - dct_in(8);

    % Stage 2 % Checked
    stage2_out = zeros(10,1);

    stage2_out(1)  = stage1_out(1) + stage1_out(4);
    stage2_out(2)  = stage1_out(2) + stage1_out(3);
    stage2_out(3)  = stage1_out(2) - stage1_out(3);
    stage2_out(4)  = stage1_out(1) - stage1_out(4);
    stage2_out(5)  = stage1_out(8) * (-71);
    stage2_out(6)  = stage1_out(7);
    stage2_out(7)  = stage1_out(6);
    stage2_out(8)  = stage1_out(5) * (355);
    stage2_out(9)  = stage1_out(5) + stage1_out(8);
    stage2_out(10) = stage1_out(6) + stage1_out(7);

    % Stage 3 % Checked
    stage3_out = zeros(10,1);

    stage3_out(1)  = stage2_out(1) + stage2_out(2);
    stage3_out(2)  = stage2_out(1) - stage2_out(2);
    stage3_out(3)  = stage2_out(3);
    stage3_out(4)  = stage2_out(4);
    stage3_out(5)  = stage2_out(5);
    stage3_out(6)  = stage2_out(6);
    stage3_out(7)  = stage2_out(7);
    stage3_out(8)  = stage2_out(8);
    stage3_out(9)  = stage2_out(9)  * (213);
    stage3_out(10) = stage2_out(10) * (251);

    % Stage 4 % Checked
    stage4_out = zeros(10,1);

    stage4_out(1)  = stage3_out(1);
    stage4_out(2)  = stage3_out(2);
    stage4_out(3)  = stage3_out(3);
    stage4_out(4)  = stage3_out(4);
    stage4_out(5)  = stage3_out(5);
    stage4_out(6)  = stage3_out(6) * (-201);
    stage4_out(7)  = stage3_out(7) * (301);
    stage4_out(8)  = stage3_out(8);
    stage4_out(9)  = stage3_out(9);
    stage4_out(10) = stage3_out(10);

    % Stage 5 % Checked
    stage5_out = zeros(9,1);

    stage5_out(1) = stage4_out(1);
    stage5_out(2) = stage4_out(2);
    stage5_out(3) = stage4_out(4);
    stage5_out(4) = stage4_out(3);
    stage5_out(5) = stage4_out(9) + stage4_out(5);
    stage5_out(6) = stage4_out(10) + stage4_out(6);
    stage5_out(7) = stage4_out(10) - stage4_out(7);
    stage5_out(8) = stage4_out(9) - stage4_out(8);
    stage5_out(9) = stage4_out(3) + stage4_out(4);

    % Stage 6 % Checked
    stage6_out = zeros(9,1);

    stage6_out(1) = stage5_out(1);
    stage6_out(2) = stage5_out(2);
    stage6_out(3) = stage5_out(3);
    stage6_out(4) = stage5_out(4);
    stage6_out(5) = stage5_out(5) + stage5_out(7);
    stage6_out(6) = stage5_out(8) - stage5_out(6);
    stage6_out(7) = stage5_out(5) - stage5_out(7);
    stage6_out(8) = stage5_out(8) + stage5_out(6);
    stage6_out(9) = stage5_out(9) * (139);

    % Stage 7 % Checked
    stage7_out = zeros(9,1);

    stage7_out(1) = stage6_out(1);
    stage7_out(2) = stage6_out(2);
    stage7_out(3) = stage6_out(3) * (196);
    stage7_out(4) = stage6_out(4) * (473);
    stage7_out(5) = stage6_out(8) - stage6_out(5);
    stage7_out(6) = stage6_out(6);
    stage7_out(7) = stage6_out(7);
    stage7_out(8) = stage6_out(8) + stage6_out(5);
    stage7_out(9) = stage6_out(9);

    % Stage 8 % Checked
    % Outputs are assign in reverse bit order
    stage8_out = zeros(8,1);

    stage8_out(1) = stage7_out(1);
    stage8_out(5) = stage7_out(2);
    stage8_out(3) = fix((stage7_out(9) + stage7_out(3)) * 2^(-8));
    stage8_out(7) = fix((stage7_out(9) - stage7_out(4)) * 2^(-8));
    stage8_out(8) = fix(stage7_out(5) * 2^(-8));
    stage8_out(4) = fix((stage7_out(6) * (362)) * 2^(-16));
    stage8_out(6) = fix((stage7_out(7) * (362)) * 2^(-16));
    stage8_out(2) = fix(stage7_out(8) * 2^(-8));

    dct_out = stage8_out;

end

%% Loeffler's 2D DCT 
function dct_out = loefflersDCT_2D_fixed(dct_in)

    row_dct = zeros(8,8);
    dct_out = zeros(8,8);

    % DCT of the row
    for row=1:size(dct_in,1)
        row_dct(row,:) = loefflersDCT_fixed(dct_in(row,:));
    end

    % Tranpose
    transposed_matrix = transpose(row_dct);

    % In the transpose matrix, the rows contain
    % the values of each column. Compute the DCT
    % of the columns by computing the DCT of each row
    % of the transposed matrix
    for row=1:size(transposed_matrix,1)
        dct_out(row,:) = loefflersDCT_fixed(transposed_matrix(row,:));
    end

    dct_out = transpose(dct_out)/8;
end

%% Improved Loeffler's IDCT (Works correctly)
function idct_out = loefflersIDCT_fixed(idct_in_reversed)

    % Undoing the bit-reverse order of the input
    idct_in = zeros(1,8);

    idct_in(1) = idct_in_reversed(1);
    idct_in(2) = idct_in_reversed(5);
    idct_in(3) = idct_in_reversed(3);
    idct_in(4) = idct_in_reversed(7);
    idct_in(5) = idct_in_reversed(8);
    idct_in(6) = idct_in_reversed(4);
    idct_in(7) = idct_in_reversed(6);
    idct_in(8) = idct_in_reversed(2);

    % Stage 1 Checked
    stage1_out = zeros(8,1);

    stage1_out(1) = idct_in(1);
    stage1_out(2) = idct_in(2);
    stage1_out(3) = idct_in(3);
    stage1_out(4) = idct_in(4);
    stage1_out(5) = idct_in(5);
    stage1_out(6) = idct_in(6) * (362);
    stage1_out(7) = idct_in(7) * (362);
    stage1_out(8) = idct_in(8);

    % Stage 2 Checked
    stage2_out = zeros(9,1);

    stage2_out(1)  = stage1_out(1);
    stage2_out(2)  = stage1_out(2);
    stage2_out(3)  = stage1_out(4) * (473);
    stage2_out(4)  = stage1_out(3) * (196);
    stage2_out(5)  = (stage1_out(8) - stage1_out(5)) * 2^(8);
    stage2_out(6)  = stage1_out(6);
    stage2_out(7)  = stage1_out(7);
    stage2_out(8)  = (stage1_out(8) + stage1_out(5)) * 2^(8);
    stage2_out(9)  = stage1_out(3) + stage1_out(4);

    % Stage 3 Checked
    stage3_out = zeros(9,1);

    stage3_out(1)  = stage2_out(1);
    stage3_out(2)  = stage2_out(2);
    stage3_out(3)  = stage2_out(3);
    stage3_out(4)  = stage2_out(4);
    stage3_out(5)  = stage2_out(5) + stage2_out(7);
    stage3_out(6)  = stage2_out(8) - stage2_out(6);
    stage3_out(7)  = stage2_out(5) - stage2_out(7);
    stage3_out(8)  = stage2_out(8) + stage2_out(6);
    stage3_out(9)  = stage2_out(9)  * (139);

    % Stage 4 Checked
    stage4_out = zeros(9,1);

    stage4_out(1)  = stage3_out(1);
    stage4_out(2)  = stage3_out(2);
    stage4_out(3)  = stage3_out(9) - stage3_out(3);
    stage4_out(4)  = stage3_out(9) + stage3_out(4);
    stage4_out(5)  = stage3_out(8) * (355);
    stage4_out(6)  = stage3_out(6);
    stage4_out(7)  = stage3_out(7);
    stage4_out(8)  = stage3_out(5) * (-71);
    stage4_out(9)  = stage3_out(5) + stage3_out(8);

    % Stage 5 Checked
    stage5_out = zeros(10,1);

    stage5_out(1)  = stage4_out(1);
    stage5_out(2)  = stage4_out(2);
    stage5_out(3)  = stage4_out(3);
    stage5_out(4)  = stage4_out(4);
    stage5_out(5)  = stage4_out(5);
    stage5_out(6)  = stage4_out(7) * (301);
    stage5_out(7)  = stage4_out(6) * (-201);
    stage5_out(8)  = stage4_out(8);
    stage5_out(9)  = stage4_out(9);
    stage5_out(10) = stage4_out(6) + stage4_out(7);

    % Stage 6 Checked
    stage6_out = zeros(10,1);

    stage6_out(1)  = stage5_out(1) + stage5_out(2);
    stage6_out(2)  = stage5_out(1) - stage5_out(2);
    stage6_out(3)  = fix(stage5_out(3) * 2^(-8));
    stage6_out(4)  = fix(stage5_out(4) * 2^(-8));
    stage6_out(5)  = stage5_out(5);
    stage6_out(6)  = stage5_out(6);
    stage6_out(7)  = stage5_out(7);
    stage6_out(8)  = stage5_out(8);
    stage6_out(9)  = stage5_out(9) * (213);
    stage6_out(10) = stage5_out(10) * (251);

    % Stage 7 Checked
    stage7_out = zeros(8,1);

    stage7_out(1) = stage6_out(1) + stage6_out(4);
    stage7_out(2) = stage6_out(2) + stage6_out(3);
    stage7_out(3) = stage6_out(2) - stage6_out(3);
    stage7_out(4) = stage6_out(1) - stage6_out(4);
    stage7_out(5) = fix((stage6_out(9) - stage6_out(5)) * 2^(-16));
    stage7_out(6) = fix((stage6_out(10) - stage6_out(6)) * 2^(-16));
    stage7_out(7) = fix((stage6_out(10) + stage6_out(7)) * 2^(-16));
    stage7_out(8) = fix((stage6_out(9) + stage6_out(8)) * 2^(-16));

    % Stage 8 Checked
    stage8_out = zeros(8,1);

    stage8_out(1) = stage7_out(1) + stage7_out(8);
    stage8_out(2) = stage7_out(2) + stage7_out(7);
    stage8_out(3) = stage7_out(3) + stage7_out(6);
    stage8_out(4) = stage7_out(4) + stage7_out(5);
    stage8_out(5) = stage7_out(4) - stage7_out(5);
    stage8_out(6) = stage7_out(3) - stage7_out(6);
    stage8_out(7) = stage7_out(2) - stage7_out(7);
    stage8_out(8) = stage7_out(1) - stage7_out(8);

    idct_out = stage8_out;
end

%% Loeffler's 2D IDCT Fixed
function idct_out = loefflersIDCT_2D_fixed(idct_in)

    row_idct = zeros(8,8);
    idct_out = zeros(8,8);

    % IDCT of the row
    for row=1:size(idct_in,1)
        row_idct(row,:) = loefflersIDCT_fixed(idct_in(row,:));
    end

    % Tranpose
    transposed_matrix = transpose(row_idct);

    % In the transpose matrix, the rows contain
    % the values of each column. Compute the DCT
    % of the columns by computing the DCT of each row
    % of the transposed matrix
    for row=1:size(transposed_matrix,1)
        idct_out(row,:) = loefflersIDCT_fixed(transposed_matrix(row,:));
    end

    idct_out = transpose(idct_out)/8;
end






%% Testing Loeffler's DCT/IDCT with actual data

% STEP 1: Color transforamtion %
% RGB -> YCbCr
rgbImage = imread('my_cat.png');

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
%dct = cos(t);

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
        Y_dct(i:i+N-1,j:j+N-1)=round(loefflersDCT_2D_fixed(Y(i:i+N-1,j:j+N-1))./qtable);
    end
end

%R Chroma DCT
rows=size(Cr_subsampled,1);
cols=size(Cr_subsampled,2);
CR_dct=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        CR_dct(i:i+N-1,j:j+N-1)=round(loefflersDCT_2D_fixed(Cr_subsampled(i:i+N-1,j:j+N-1))./qtable);
    end
end

%B Chroma DCT
rows=size(Cb_subsampled,1);
cols=size(Cb_subsampled,2);
CB_dct=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        CB_dct(i:i+N-1,j:j+N-1)=round(loefflersDCT_2D_fixed(Cb_subsampled(i:i+N-1,j:j+N-1))./qtable);
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
        y_inv(i:i+N-1,j:j+N-1)=loefflersIDCT_2D_fixed(Y_dct(i:i+N-1,j:j+N-1).*qtable);
    end
end
%R chroma IDCT
rows=size(CR_dct,1);
cols=size(CR_dct,2);
cr_inv=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        cr_inv(i:i+N-1,j:j+N-1)=loefflersIDCT_2D_fixed(CR_dct(i:i+N-1,j:j+N-1).*qtable);
    end
end
%B chroma IDCT
rows=size(CB_dct,1);
cols=size(CB_dct,2);
cb_inv=ones(rows,cols);
for i = 1:N:rows
    for j = 1:N:cols
        cb_inv(i:i+N-1,j:j+N-1)=loefflersIDCT_2D_fixed(CB_dct(i:i+N-1,j:j+N-1).*qtable);
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

finalImg_uint8 = uint8((finalImg - min(finalImg(:))) / (max(finalImg(:)) - min(finalImg(:))) * 255);
rgbImage_uint8 = uint8(rgbImage);
[peaksnr, snr] = psnr(finalImg_uint8,rgbImage);
