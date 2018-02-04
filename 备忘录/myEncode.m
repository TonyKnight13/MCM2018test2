
function myEncode(img)
  
    % img = imread(path);
    % subplot(121);
    % imshow(img);
    % title('原图');
     % rgb->yuv
    tic;
    '开始处理'

    img_ycbcr = rgb2ycbcr(img);
    % 取出行列数，~表示3个通道算1列   
    [row, col, ~] = size(img_ycbcr);

    % 对图像进行扩展
    %行数上取整再乘16，及扩展成16的倍数
    row_expand = ceil(row/16)*16;           
    %行数不是16的倍数，用最后一行进行扩展
    if mod(row, 16) ~= 0
        for i = row:row_expand
            img_ycbcr(i, :, :) = img_ycbcr(row, :, :);
        end
    end

    col_expand = ceil(col/16)*16;         %列数上取整
    if mod(col,16) ~= 0                   %列数不是16的倍数，用最后一列进行扩展
        for j = col:col_expand
            img_ycbcr(:, j, :) = img_ycbcr(:, col, :);
        end
    end

    % 对Y,Cb,Cr分量进行4:2:0采样
    Y = img_ycbcr(:,:,1);                        %Y分量
    Cb=zeros(row_expand/2, col_expand/2);        %Cb分量
    Cr=zeros(row_expand/2, col_expand/2);        %Cr分量

    for i = 1:row_expand/2
        % 奇数列
        for j = 1:2:col_expand/2-1                
            Cb(i,j) = double(img_ycbcr(i*2-1,j*2-1,2));     
            Cr(i,j) = double(img_ycbcr(i*2-1,j*2+1,3));    
        end
    end

    for i = 1:row_expand/2
        % 偶数列
        for j = 2:2:col_expand/2            
            Cb(i,j) = double(img_ycbcr(i*2-1,j*2-2,2));     
            Cr(i,j) = double(img_ycbcr(i*2-1,j*2,3));    
        end
    end

    %分别对三种颜色分量进行编码
    Y_Table = [
        16  11  10  16  24  40  51  61
        12  12  14  19  26  58  60  55
        14  13  16  24  40  57  69  56
        14  17  22  29  51  87  80  62
        18  22  37  56  68 109 103  77
        24  35  55  64  81 104 113  92
        49  64  78  87 103 121 120 101
        72  92  95  98 112 100 103  99];%亮度量化表

    CbCr_Table = [
        17, 18, 24, 47, 99, 99, 99, 99;
        18, 21, 26, 66, 99, 99, 99, 99;
        24, 26, 56, 99, 99, 99, 99, 99;
        47, 66, 99 ,99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99;
        99, 99, 99, 99, 99, 99, 99, 99];%色差量化表

    % 量化因子,最小为0.01,最大为255,建议在0.5和3之间,越小质量越好文件越大
    Qua_Factor = 0.5;

    toc;
    tic;
    '开始DCT和量化'
    % 对三个通道分别DCT和量化
    Y_dct_q = Dct_Quantize(Y, Qua_Factor, Y_Table);
    Cb_dct_q = Dct_Quantize(Cb, Qua_Factor, CbCr_Table);
    Cr_dct_q = Dct_Quantize(Cr, Qua_Factor, CbCr_Table);
    toc;
    printmat(size(Y_dct_q));
    printmat(size(Cb_dct_q));
    printmat(size(Cr_dct_q));
    tic;
    '对三个通道分别8*8分块并进行Z型编码和游程编码'
    % 对三个通道分别8*8分块并进行Z型编码和游程编码
    threeEncoding(Y_dct_q);
    toc;

    % 性能指标
    % encoded_lenght = numel(dcencoded) + numel(acencoded); %编码长度
 
    % AverageBit = encoded_lenght/(am*an); %计算编码比特率（每个像素所占的比特数）
    
    % disp('压缩比：');
    
    % cr = am*an*8/encoded_lenght     %计算压缩比
    
    % e = double(myImage)-double(ReImage);
    
    % MSE = sqrt(sum(e(:).^2)/(an*am)); % 均方误差：指参数估计值与参数真值之差平方的期望值，记为MSE
    
    % PSNR = 10*log(255*255/MSE)/log(10); %计算峰值信噪比(dB)
    
    % disp('编码比特率：');
    
    % disp(AverageBit);
    
    % disp('峰值信噪比(dB)');
    
    % disp(PSNR);
end

% 传入一个图像通道 进行分块 zigZag, RLU编码最后进行huffman编码，返回huffman编码值
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
            % '开始分块处理'
            temp = chan(i:i+7, j:j+7);
            vec = RLC(myZigZag(temp));  
            p = count_vec_p(vec);
            dict = huffmandict(-128:127, p);
            code = huffmanenco(vec, dict);

            bits = bits + size(code);
            % 用cell存放每个块的编码值
            cell{block_i, block_j} = code;
            % toc;
        end
    end
end

% 输入向量，返回RLU编码向量
function [countVec] = RLC(vec)
    [m, n] = size(vec);

    % 编码规则：遇见0以外的保留原值push，遇见0计数，把计数值放在0后面。各个块的编码用`00`进行分割。
    % 编码器
    % 特殊处理第一个和最后一个

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
        % 前1个和当前均不为0，则把前一个push
        if vec(i) ~= 0 && vec(i-1) ~= 0
            countVec(index) = vec(i-1);
            index = index + 1;
            continue
        end

        % 第1次遇见0，则把前一个push
        if vec(i) == 0 && vec(i-1) ~= 0
            count = 1;
            countVec(index) = vec(i-1);
            index = index + 1;
            continue
        end

         % 第n次遇见0，计数，继续前进
        if vec(i-1) == 0 && vec(i) == 0
            count = count + 1;
            continue
        end

        % 前一个是0当前不是0则把0编码push
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

% 输入是8*8图像块，返回是行程顺序向量
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


% 输入向量，返回各个取值的概率
function [p] = count_vec_p(vec)
    [m, n] = size(vec);
    temp = zeros(1, 256);
    % -128 ~ 127
    for i = 1:n
        temp(vec(i)+129) = temp(vec(i)+129) + 1;
    end
    p = temp / m / n;
end

% 输入图像和长宽返回各个取值的概率
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
% 输入图片和概率统计表，返回编码向量和编码表
function [encode_value, dict] = encode(I, p)
    % size(I)
    k = -128:127;
    % k = min(I):max(I);
    dict = huffmandict(k, p);
    enco = huffmanenco(I(:), dict);
    encode_value = enco;
end

% 整幅图片和其长宽
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
    % 层次移动128个灰度级，详见书本P401
    I = double(I) - 128;   
    I = blkproc(I,[8 8],'dct2(x)');
    Qua_Matrix = Qua_Factor.*Qua_Table;              %量化矩阵
    I = blkproc(I,[8 8],'round(x./P1)',Qua_Matrix);  %量化，四舍五入
    Matrix = I;          %得到量化后的矩阵
end

function [Matrix] = Inverse_Quantize_Dct(I, Qua_Factor, Qua_Table)
    % 反量化矩阵
    Qua_Matrix = Qua_Factor.*Qua_Table;
    % 反量化，四舍五入
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

    Matrix = I;       %反量化和反Dct后的矩阵
end
