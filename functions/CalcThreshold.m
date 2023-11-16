function [hististMaxIndex, threshold_5mean,noiseMag] = CalcThreshold(histBuff,meanNoiseBuff)
global HIST_THRESHOLD_GUARD  RDM_MAG_PER_HIST_BIN_EXP RANGE_BIN_ENABLE;%%3(3������ȣ�3*3.0103dB),256

% rangeBins = size(histBuff,1);
rangeBins = RANGE_BIN_ENABLE;%%ֻ��ǰ512bin����ֵ��CFAR
histBin = size(histBuff,2);
hististMaxIndex = zeros(rangeBins,1);
threshold = zeros(rangeBins,1);
threshold_5mean = zeros(rangeBins,1);
noiseMag = zeros(rangeBins,1);
noiseIdxList = 3:histBin;%%��ֵ��С������(��1-2��)������������
tmpThrd = 0;
iL = 1;iR = 1;

for i = 1:rangeBins
    [~,iMaxIndex] = max(histBuff(i,noiseIdxList));
    hististMaxIndex(i) = noiseIdxList(iMaxIndex);
    threshold(i) = (hististMaxIndex(i)-1 + HIST_THRESHOLD_GUARD) * RDM_MAG_PER_HIST_BIN_EXP;%%����+9dB�����(10*log10)
    
    if (meanNoiseBuff(i,hististMaxIndex(i)) ~=0)
        noiseMag(i) = meanNoiseBuff(i,hististMaxIndex(i));
    else
        noiseMag(i) = (hististMaxIndex(i)-1) *RDM_MAG_PER_HIST_BIN_EXP;
    end
end

%% ��ǰ+���Ҹ�2��rangeBin�ĵ���ȡƽ��
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
    
    threshold_5mean(i) = floor(tmpThrd + (threshold(i) / 5));%%���Ҹ�2��rangeBin�ĵ���ƽ��
end


% figure(1);hold on;
% plot(threshold./256.*3.01,'k-.','LineWidth',2);
% plot(threshold_5mean./256.*3.01,'r-.','LineWidth',2);
% h = legend('(1)256����','(2)256����+�ڽ�5��ƽ��');

end