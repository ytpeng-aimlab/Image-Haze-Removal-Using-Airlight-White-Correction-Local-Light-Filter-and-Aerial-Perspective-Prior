%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Y.-T. Peng, Z. Lu, F.-C. Cheng, Y. Zheng, and S.-C. Huang, 
%¡§Image Haze Removal Using Airlight White Correction, Local Light Filter, 
% and Aerial Perspective Prior,¡¨ IEEE Trans. on CSVT, Mar, 2019.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear, clc;
close all

frm_str = 1;
frm_end = 8;

speedup = 1;

tau = 5;
patchRate = 0.005;
guideRate = 0.10;
boundProb = 0.01;
darkRatio = 0.05;
diamLLF = 5;
t0 = 0.1;
imgOri = './pic/';
imnames=[dir([imgOri '*' 'bmp']) ; dir([imgOri '*' 'jpg']) ; dir([imgOri '*' 'png'])];
    
for frm_num = 1:length(imnames)
    imfile  = sprintf('%s%s', imgOri, imnames(frm_num).name);
    RGBin = double(imread(imfile));
    Oriin = RGBin;
    [hei,wid,~] = size(RGBin);
    imsize = hei*wid;
    
    patchD = round( sqrt( imsize * patchRate ) );
    guideD = round( sqrt( imsize * guideRate ) );
    bountT = imsize * boundProb;
    darkTh = imsize * darkRatio;
    
    tic;
    
    HSVin = rgb2hsv(uint8(RGBin));
    edges = linspace(0,360, 361);
    edges = full(real(edges));
    edges(1) = -Inf;
    edges(end) = Inf;

    H = round(HSVin(:,:,1) * 360);
    S = uint8(round(HSVin(:,:,2) * 255 ));
    HisH = histc(H(:), edges, 1)';
    HisH(1) = HisH(1) + HisH(361);
    HisH(361) = [];
    HisS = imhist(S(:), 256);
    m_HisH = imsize/360;
    HisB = HisH > m_HisH;
        
    HisC = max(bwlabel(HisB,4));
    
    if HisC < tau
        j = 0;
        DarkS = 0;
        Thr = imsize * boundProb;
        for i = 1 : 1 : 256
            j = j + HisS(i);
            DarkS = DarkS + (i-1) * HisS(i);
            if j > Thr
                break;
            end
        end
        DarkS = DarkS / j / 255;
        HSVin(:,:,2) = max( 0, ( HSVin(:,:,2) - DarkS ) );
        RGBin = round(hsv2rgb(HSVin).*255);
    end
    
    % color channel estimation
    RGBmin = min(min(RGBin(:,:,1),RGBin(:,:,2)), RGBin(:,:,3));
    RGBmax = max(max(RGBin(:,:,1),RGBin(:,:,2)), RGBin(:,:,3));
    RGBsat = ( RGBmax - RGBmin ) ./ max(1, RGBmax);
    
    % local light filter
    HisV = imhist(RGBmin./255)';
    PrV = HGW(HisV,diamLLF,0);
    PrV = PrV ./ sum(PrV);
    Aind = PrV(256);
    for i = 255 : -1 : 1
        Aind = Aind + PrV(i);
        if Aind > boundProb
            Aind = i - 1;
            break;
        end
    end    
    ImVec = reshape(RGBin,imsize, 3);
    Ac = round(mean(ImVec(RGBmin>=Aind,:)));
    
    fprintf('airlight: index %d, intensity (%d, %d, %d)\n', Aind, Ac(1), Ac(2), Ac(3));
    
    Din = RGBmin .* ( 1 - RGBsat );
    Din = HGW( Din, patchD, 0); % scan horziontal line (min)
    Din = HGW( Din', patchD, 0); % % scan vertical line (min)
    Din = Din';
    tc = 1 - imguidedfilter(Din, RGBmin,'NeighborhoodSize',[guideD guideD]) ./ 255;
    tc = max(t0, tc);
    
    ImVecOut = ImVec;
    for c = 1:3
        ImVecTmp = reshape(( RGBin(:, :, c) - Ac(c) ) ./ tc + Ac(c), imsize, 1);
        ImVecOut(ImVec(:,c)<Ac(c),c) = ImVecTmp(ImVec(:,c)<Ac(c));
    end
    RGBout = round(reshape(ImVecOut, hei, wid, 3));
    
    HisDc = imhist(uint8(min(min(RGBout(:,:,1), RGBout(:,:,2)), RGBout(:,:,3))));
    DarkLv = 0;
    j = 0;
    % j is the number of the bottom 5% darkest pixels
    for i = 1 : 1 : 256
        j = j + HisDc(i);
        DarkLv = DarkLv + HisDc(i) * (i-1);
        if j >= darkTh
            DarkLv = round( DarkLv / j );
            break;
        end
    end
    for c = 1 : 1 : 3
        RGBout(:,:,c) = 255 * max( 0, ( RGBout(:,:,c) - DarkLv ) ./ ( 255 - DarkLv ) );
    end
    
    toc;
    strin = sprintf('%04d_dehazed.bmp',frm_num);
    imwrite(uint8(RGBout),strin);
    figure, imshow([uint8(Oriin) uint8(RGBout)])
end