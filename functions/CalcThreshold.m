function [hististMaxIndex, threshold_5mean,noiseMag] = CalcThreshold(histBuff,meanNoiseBuff)
global HIST_THRESHOLD_GUARD  RDM_MAG_PER_HIST_BIN_EXP RANGE_BIN_ENABLE;%%3(3格信噪比，3*3.0103dB),256

% rangeBins = size(histBuff,1);
rangeBins = RANGE_BIN_ENABLE;%%只对前512bin做阈值及CFAR
histBin = size(histBuff,2);
hististMaxIndex = zeros(rangeBins,1);
threshold = zeros(rangeBins,1);
threshold_5mean = zeros(rangeBins,1);
noiseMag = zeros(rangeBins,1);
noiseIdxList = 3:histBin;%%幅值较小的区域(第1-2列)不参与底噪计算
tmpThrd = 0;
iL = 1;iR = 1;

for i = 1:rangeBins
    [~,iMaxIndex] = max(histBuff(i,noiseIdxList));
    hististMaxIndex(i) = noiseIdxList(iMaxIndex);
    threshold(i) = (hististMaxIndex(i)-1 + HIST_THRESHOLD_GUARD) * RDM_MAG_PER_HIST_BIN_EXP;%%底噪+9dB信噪比(10*log10)
    
    if (meanNoiseBuff(i,hististMaxIndex(i)) ~=0)
        noiseMag(i) = meanNoiseBuff(i,hististMaxIndex(i));
    else
        noiseMag(i) = (hististMaxIndex(i)-1) *RDM_MAG_PER_HIST_BIN_EXP;
    end
end

%% 当前+左右各2个rangeBin的底噪取平均
for i = 1:rangeBins
    tmpThrd = 0;
    for j = 1:2
        if ( (i - j) < 1 )
            iL = i + 2 + j;
        else
            iL = i - j;
        end
        
        if ( (i + j) > rangeBins )
            iR = i - 2 - j;
        else
            iR = i + j;
        end
        
        tmpThrd = tmpThrd + (threshold(iL) / 5) + (threshold(iR) / 5);
    end    
    
    threshold_5mean(i) = floor(tmpThrd + (threshold(i) / 5));%%左右各2个rangeBin的底噪平均
end


% figure(1);hold on;
% plot(threshold./256.*3.01,'k-.','LineWidth',2);
% plot(threshold_5mean./256.*3.01,'r-.','LineWidth',2);
% h = legend('(1)256量化','(2)256量化+邻近5格平均');

end