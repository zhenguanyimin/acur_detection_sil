function [peakBitmap,peakNum]=CalcPeakSearchBitmap(rdmapData, threshold)
global  RANGE_BIN_ENABLE

PS_RANGE_START_INDEX = 4+1;
peakNum = 0;
rangeBins = size(rdmapData,1);
dopplerBins = size(rdmapData,2);
dopplerPeakFlag = zeros(rangeBins,dopplerBins);
peakBitmap = zeros(rangeBins,dopplerBins);
rangeBinEnable = RANGE_BIN_ENABLE;

%% 1.doppler dimension peak search
for i = PS_RANGE_START_INDEX:rangeBinEnable
    rdmMagAux = rdmapData(i,:);
    for j = 1:dopplerBins
        rdmMag = rdmMagAux(j);
        if (rdmMag < threshold(i))
            continue;
        else
            if (j == 1)
                rdmMagLeft =  rdmMagAux(dopplerBins);
                rdmMagRight =  rdmMagAux(j+1);
            elseif (j == dopplerBins)
                rdmMagLeft =  rdmMagAux(j-1);
                rdmMagRight =  rdmMagAux(1);   
            else
                rdmMagLeft =  rdmMagAux(j-1);
                rdmMagRight =  rdmMagAux(j+1);
            end        
            if ( (rdmMag > rdmMagLeft) && (rdmMag > rdmMagRight))
                dopplerPeakFlag(i,j) = 1;
            end
        end
    end                       
end

%% 2.range dimension peak search
% for i = 1:dopplerBins  %%¿¼ÂÇdoppler×óÓÒ±ßÔµ
% for i = 2:dopplerBins-1
% for i = 3:dopplerBins-1 %%È¥³ý[-1,0,1]bin£¬µÍËÙ²»×ö¼ì²â
for i = 2:dopplerBins %%È¥³ý[0]bin£¬0ËÙ²»×ö¼ì²â
    rdmTransposMagAux = rdmapData(:,i);
    for j = PS_RANGE_START_INDEX:rangeBinEnable  
        if ( dopplerPeakFlag(j,i) == 0)
            continue;
        else        
            rdmMag = rdmTransposMagAux(j);
            if (j == 1)
                rdmMagLeft =  0;
                rdmMagRight =  rdmTransposMagAux(j+1);
            elseif (j == rangeBinEnable)
                rdmMagLeft =  rdmTransposMagAux(j-1);
                rdmMagRight =  0;   
            else
                rdmMagLeft =  rdmTransposMagAux(j-1);
                rdmMagRight =  rdmTransposMagAux(j+1);
            end        
            if ( (rdmMag > rdmMagLeft) && (rdmMag > rdmMagRight))
                peakBitmap(j,i) = 1;
                peakNum = peakNum + 1;
            end
        end
    end                       
end



% for i=PS_RANGE_START_INDEX:rangeBinEnable
%     for j=2:dopplerBins-1    
%         if ( (rdmapData(i,j) > threshold(i)) && (rdmapData(i,j) > rdmapData(i,j-1)) && (rdmapData(i,j) > rdmapData(i,j+1)))
% %     for j=1:dopplerBins
% %         if (j == 1)
% %             rdmMagLeft =  rdmapData(i,dopplerBins);
% %             rdmMagRight = rdmapData(i,j+1);
% %         elseif (j == dopplerBins)
% %             rdmMagLeft = rdmapData(i,j-1);
% %             rdmMagRight = rdmapData(i,1);   
% %         else
% %             rdmMagLeft = rdmapData(i,j-1);
% %             rdmMagRight = rdmapData(i,j+1);
% %         end        
% %         if ( (rdmapData(i,j) > threshold(i)) && (rdmapData(i,j) > rdmMagLeft) && (rdmapData(i,j) >rdmMagRight))
%             
%             if (i > 1 && i < rangeBinEnable)
%                 if (rdmapData(i,j) > rdmapData(i-1,j) && rdmapData(i,j) > rdmapData(i+1,j))
%                     peakBitmap(i,j) = 1;
%                     peakNum = peakNum + 1;
%                 end
%             elseif (i == 1)
%                 if (rdmapData(i,j) > rdmapData(i+1,j))
%                     peakBitmap(i,j) = 1;
%                     peakNum = peakNum + 1;
%                 end
%             elseif (i == rangeBinEnable)
%                  if (rdmapData(i,j) > rdmapData(i-1,j))
%                     peakBitmap(i,j) = 1;
%                     peakNum = peakNum + 1;
%                 end
%             end
%         end        
%     end  
% %     if(rdmapData(i,1)>rdmapData(i,dopplerBins)&&rdmapData(i,1)>rdmapData(i,2)&&rdmapData(i,1)>threshold(i))
% %         if(i>1&&i<rangeBins)
% %             if(rdmapData(i,1)>rdmapData(i-1,1)&&rdmapData(i,1)>rdmapData(i+1,1))
% %                 peakBitmap(i,1)=1;
% %                 peakNum=peakNum+1;
% %             end
% %         elseif i==1
% %             if(rdmapData(i,1)>rdmapData(i+1,1))
% %                 peakBitmap(i,1)=1;
% %                 peakNum=peakNum+1;
% %             end
% %         elseif i==rangeBins
% %              if(rdmapData(i,1)>rdmapData(i-1,1))
% %                 peakBitmap(i,1)=1;
% %                 peakNum=peakNum+1;
% %             end
% %         end
% %     end
% 
% %     if(rdmapData(i,dopplerBins)>rdmapData(i,1)&&rdmapData(i,dopplerBins)>rdmapData(i,dopplerBins-1)&&...
% %             rdmapData(i,dopplerBins)>threshold(i))
% %         if(i>1&&i<rangeBins)
% %             if(rdmapData(i,dopplerBins)>rdmapData(i-1,dopplerBins)&&rdmapData(i,dopplerBins)>rdmapData(i+1,dopplerBins))
% %                 peakBitmap(i,dopplerBins)=1;
% %                 peakNum=peakNum+1;
% %             end
% %         elseif i==1
% %             if(rdmapData(i,dopplerBins)>rdmapData(i+1,dopplerBins))
% %                 peakBitmap(i,dopplerBins)=1;
% %                 peakNum=peakNum+1;
% %             end
% %         elseif i==rangeBins
% %              if(rdmapData(i,dopplerBins)>rdmapData(i-1,dopplerBins))
% %                 peakBitmap(i,dopplerBins)=1;
% %                 peakNum=peakNum+1;
% %             end
% %         end
% %     end
% end

end