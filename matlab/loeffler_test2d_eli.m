idct_in = [
                    24 -8 84 96 -20 -16 0 0;
                    -30	55 -42 16 -10 0 0 0;
                    150	40	-54	-100	32	0	28	22;
                    24	-42	72	-60	20	0	0	0;
                    -7	-18	45	0	-27	0	0	0;
                    0	14	0	-26	-32	0	0	0;
                    0	26	-31	0	0	0	0	0;
                    0	0	0	0	0	0	0	0
                    ];




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
