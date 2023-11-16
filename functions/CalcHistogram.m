function [histBuff, meanNoiseBuff,meanNoiseMag] = CalcHistogram(rdmapData,histogram_col)

global  RDM_MAG_PER_HIST_BIN_EXP

rangeBins=size(rdmapData,1);
dopplerBins=size(rdmapData,2);
histBuff=zeros(rangeBins,histogram_col);
sumNoiseBuff = zeros(rangeBins,histogram_col);
meanNoiseBuff = zeros(rangeBins,histogram_col);
meanNoiseMag = zeros(rangeBins,2);

for i = 1:rangeBins
    for j = 1:dopplerBins
        colHist = floor(rdmapData(i,j)/RDM_MAG_PER_HIST_BIN_EXP) + 1;
%         colHist = floor(rdmapData(i,j)/768) + 1;
%         colHist = floor(rdmapData(i,j)/256/log2(rangeBins/histogram_col)) + 1;
        histBuff(i,colHist) = histBuff(i,colHist) + 1;
        sumNoiseBuff(i,colHist) = sumNoiseBuff(i,colHist) + rdmapData(i,j);
    end
    
    %% 直方图众数均值底噪
    for j = 1:histogram_col
        if (histBuff(i,j) > 0)
            meanNoiseBuff(i,j) = sumNoiseBuff(i,j)/histBuff(i,j);
        end
    end
    
    %% 均值底噪
    meanNoiseMag(i,1) = mean(rdmapData(i,:));
    meanNoiseMag(i,2) = max(rdmapData(i,:));
    
end

end