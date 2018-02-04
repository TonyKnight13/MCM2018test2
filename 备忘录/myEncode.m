
function myEncode(img)
  
    % img = imread(path);
    % subplot(121);
    % imshow(img);
    % title('ԭͼ');
     % rgb->yuv
    tic;
    '��ʼ����'

    img_ycbcr = rgb2ycbcr(img);
    % ȡ����������~��ʾ3��ͨ����1��   
    [row, col, ~] = size(img_ycbcr);

    % ��ͼ�������չ
    %������ȡ���ٳ�16������չ��16�ı���
    row_expand = ceil(row/16)*16;           
    %��������16�ı����������һ�н�����չ
    if mod(row, 16) ~= 0
        for i = row:row_expand
            img_ycbcr(i, :, :) = img_ycbcr(row, :, :);
        end
    end

    col_expand = ceil(col/16)*16;         %������ȡ��
    if mod(col,16) ~= 0                   %��������16�ı����������һ�н�����չ
        for j = col:col_expand
            img_ycbcr(:, j, :) = img_ycbcr(:, col, :);
        end
    end

    % ��Y,Cb,Cr��������4:2:0����
    Y = img_ycbcr(:,:,1);                        %Y����
    Cb=zeros(row_expand/2, col_expand/2);        %Cb����
    Cr=zeros(row_expand/2, col_expand/2);        %Cr����

    for i = 1:row_expand/2
        % ������
        for j = 1:2:col_expand/2-1                
            Cb(i,j) = double(img_ycbcr(i*2-1,j*2-1,2));     
            Cr(i,j) = double(img_ycbcr(i*2-1,j*2+1,3));    
        end
    end

    for i = 1:row_expand/2
        % ż����
        for j = 2:2:col_expand/2            
            Cb(i,j) = double(img_ycbcr(i*2-1,j*2-2,2));     
            Cr(i,j) = double(img_ycbcr(i*2-1,j*2,3));    
        end
    end

    %�ֱ��������ɫ�������б���
    Y_Table = [
        16  11  10  16  24  40  51  61
        12  12  14  19  26  58  60  55
        14  13  16  24  40  57  69  56
        14  17  22  29  51  87  80  62
        18  22  37  56  68 109 103  77
        24  35  55  64  81 104 113  92
        49  64  78  87 103 121 120 101
        72  92  95  98 112 100 103  99];%����������

    CbCr_Table = [
        17, 18, 24, 47, 99, 99, 99, 99;
        18, 21, 26, 66, 99, 99, 99, 99;
        24, 26, 56, 99, 99, 99, 99, 99;
        47, 66, 99 ,99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99];%ɫ��������

    % ��������,��СΪ0.01,���Ϊ255,������0.5��3֮��,ԽС����Խ���ļ�Խ��
    Qua_Factor = 0.5;

    toc;
    tic;
    '��ʼDCT������'
    % ������ͨ���ֱ�DCT������
    Y_dct_q = Dct_Quantize(Y, Qua_Factor, Y_Table);
    Cb_dct_q = Dct_Quantize(Cb, Qua_Factor, CbCr_Table);
    Cr_dct_q = Dct_Quantize(Cr, Qua_Factor, CbCr_Table);
    toc;
    printmat(size(Y_dct_q));
    printmat(size(Cb_dct_q));
    printmat(size(Cr_dct_q));
    tic;
    '������ͨ���ֱ�8*8�ֿ鲢����Z�ͱ�����γ̱���'
    % ������ͨ���ֱ�8*8�ֿ鲢����Z�ͱ�����γ̱���
    threeEncoding(Y_dct_q);
    toc;

    % ����ָ��
    % encoded_lenght = numel(dcencoded) + numel(acencoded); %���볤��
 
    % AverageBit = encoded_lenght/(am*an); %�����������ʣ�ÿ��������ռ�ı�������
    
    % disp('ѹ���ȣ�');
    
    % cr = am*an*8/encoded_lenght     %����ѹ����
    
    % e = double(myImage)-double(ReImage);
    
    % MSE = sqrt(sum(e(:).^2)/(an*am)); % ������ָ��������ֵ�������ֵ֮��ƽ��������ֵ����ΪMSE
    
    % PSNR = 10*log(255*255/MSE)/log(10); %�����ֵ�����(dB)
    
    % disp('��������ʣ�');
    
    % disp(AverageBit);
    
    % disp('��ֵ�����(dB)');
    
    % disp(PSNR);
end

% ����һ��ͼ��ͨ�� ���зֿ� zigZag, RLU����������huffman���룬����huffman����ֵ
function [cell, bits] = threeEncoding(chan)
    [m, n] = size(chan);
    cell = {};
    block_i = 0;
    block_j = 0;
    bits = 0
    for i = 1:8:m
        block_i = block_i + 1;
        for j = 1:8:n
            block_j = block_j + 1;
            % tic;
            % '��ʼ�ֿ鴦��'
            temp = chan(i:i+7, j:j+7);
            vec = RLC(myZigZag(temp));  
            p = count_vec_p(vec);
            dict = huffmandict(-128:127, p);
            code = huffmanenco(vec, dict);

            bits = bits + size(code);
            % ��cell���ÿ����ı���ֵ
            cell{block_i, block_j} = code;
            % toc;
        end
    end
end

% ��������������RLU��������
function [countVec] = RLC(vec)
    [m, n] = size(vec);

    % �����������0����ı���ԭֵpush������0�������Ѽ���ֵ����0���档������ı�����`00`���зָ
    % ������
    % ���⴦���һ�������һ��

    % init
    countVec = [];
    index = 1;

    % first
    if vec(1) == 0
        count = 1;
    else
        countVec(index) = vec(1);
        index = index + 1;
    end

    % loop
    for i = 2:n
        % ǰ1���͵�ǰ����Ϊ0�����ǰһ��push
        if vec(i) ~= 0 && vec(i-1) ~= 0
            countVec(index) = vec(i-1);
            index = index + 1;
            continue
        end

        % ��1������0�����ǰһ��push
        if vec(i) == 0 && vec(i-1) ~= 0
            count = 1;
            countVec(index) = vec(i-1);
            index = index + 1;
            continue
        end

         % ��n������0������������ǰ��
        if vec(i-1) == 0 && vec(i) == 0
            count = count + 1;
            continue
        end

        % ǰһ����0��ǰ����0���0����push
        if vec(i-1) == 0 && vec(i) ~= 0
            countVec(index) = 0;
            index = index + 1;  
            countVec(index) = count;
            index = index + 1;
        end
    end

    % last
    if vec(n) == 0
        countVec(index) = 0;
        index = index + 1;   
        countVec(index) = count;
        index = index + 1;
    else 
        countVec(index) = vec(n);
        index = index + 1;
    end
end

% ������8*8ͼ��飬�������г�˳������
function output = myZigZag(in)

    % initializing the variables
    %----------------------------------
    h = 1;
    v = 1;

    vmin = 1;
    hmin = 1;

    vmax = size(in, 1);
    hmax = size(in, 2);

    i = 1;

    output = zeros(1, vmax * hmax);
    %----------------------------------

    while ((v <= vmax) & (h <= hmax))
        
        if (mod(h + v, 2) == 0)                 % going up

            if (v == vmin)       
                output(i) = in(v, h);        % if we got to the first line

                if (h == hmax)
            v = v + 1;
            else
                h = h + 1;
                end;

                i = i + 1;

            elseif ((h == hmax) & (v < vmax))   % if we got to the last column
                output(i) = in(v, h);
                v = v + 1;
                i = i + 1;

            elseif ((v > vmin) & (h < hmax))    % all other cases
                output(i) = in(v, h);
                v = v - 1;
                h = h + 1;
                i = i + 1;
        end;
            
        else                                    % going down

        if ((v == vmax) & (h <= hmax))       % if we got to the last line
                output(i) = in(v, h);
                h = h + 1;
                i = i + 1;
            
        elseif (h == hmin)                   % if we got to the first column
                output(i) = in(v, h);

                if (v == vmax)
            h = h + 1;
            else
                v = v + 1;
                end;

                i = i + 1;

        elseif ((v < vmax) & (h > hmin))     % all other cases
                output(i) = in(v, h);
                v = v + 1;
                h = h - 1;
                i = i + 1;
            end;

        end;

        if ((v == vmax) & (h == hmax))          % bottom right element
            output(i) = in(v, h);
            break
        end;

    end;
end


% �������������ظ���ȡֵ�ĸ���
function [p] = count_vec_p(vec)
    [m, n] = size(vec);
    temp = zeros(1, 256);
    % -128 ~ 127
    for i = 1:n
        temp(vec(i)+129) = temp(vec(i)+129) + 1;
    end
    p = temp / m / n;
end

% ����ͼ��ͳ����ظ���ȡֵ�ĸ���
function [p] = count_value_p(I, m, n)
    % min(I), max(I) = left, right
    temp = zeros(1, 256);
    % -128 ~ 127
    for i = 1:m
        for j = 1:n
            temp(I(i, j)+129) = temp(I(i, j)+129) + 1;
        end
    end
    p = temp / m / n;
    % temp
end
% ����ͼƬ�͸���ͳ�Ʊ����ر��������ͱ����
function [encode_value, dict] = encode(I, p)
    % size(I)
    k = -128:127;
    % k = min(I):max(I);
    dict = huffmandict(k, p);
    enco = huffmanenco(I(:), dict);
    encode_value = enco;
end

% ����ͼƬ���䳤��
function encode_all(I, m, n)
    for i = 1:8:m
        for j = 1:8:n
            % temp = I(i:i+7, j:j+7);
            % p = count_value_p(temp, 8, 8);
            % [encode_value, dict] = encode(temp, p);
            % size(dict)
            % size(encode_value)
            % count = count + 1
        end
    end
end

function [Matrix] = Dct_Quantize(I, Qua_Factor, Qua_Table)
    % ����ƶ�128���Ҷȼ�������鱾P401
    I = double(I) - 128;   
    I = blkproc(I,[8 8],'dct2(x)');
    Qua_Matrix = Qua_Factor.*Qua_Table;              %��������
    I = blkproc(I,[8 8],'round(x./P1)',Qua_Matrix);  %��������������
    Matrix = I;          %�õ�������ľ���
end

function [Matrix] = Inverse_Quantize_Dct(I, Qua_Factor, Qua_Table)
    % ����������
    Qua_Matrix = Qua_Factor.*Qua_Table;
    % ����������������
    I = blkproc(I,[8 8],'x.*P1',Qua_Matrix);
    [row,column] = size(I);
    
    I = blkproc(I,[8 8],'idct2(x)');
    I = uint8(I + 128);

    for i=1:row
        for j=1:column
            if I(i,j)>255
                I(i,j)=255;
            elseif I(i,j)<0
                I(i,j)=0;
            end
        end
    end

    Matrix = I;       %�������ͷ�Dct��ľ���
end
