function Target_Para_out  =  sincInterp(Target_Para_out,mtd_data_sumIQ)

nRange=size(mtd_data_sumIQ,1);
nDoppler=size(mtd_data_sumIQ,2);
nCol=size(Target_Para_out,1);
detNum=size(Target_Para_out,2);
nInterpSample=5;
sideNum=(nInterpSample-1)/2;
for iDet=1:detNum
    rangeBin=Target_Para_out(1,iDet);
    dopplerBin=Target_Para_out(2,iDet);
    if(rangeBin>=3&&rangeBin<=nRange-2)
        rangeData=mtd_data_sumIQ(rangeBin-sideNum:rangeBin+sideNum,dopplerBin);
        rangeOffset=sincInterp1D(rangeData);
        Target_Para_out(nCol+1,iDet)=rangeBin+rangeOffset;
    end
    if(dopplerBin>=4&&dopplerBin<=nDoppler-4)
        dopplerData=mtd_data_sumIQ(rangeBin,dopplerBin-sideNum:dopplerBin+sideNum);
        dopplerOffset=sincInterp1D(dopplerData);
        Target_Para_out(nCol+2,iDet)=dopplerBin+dopplerOffset;
    end
end

end

function Offset=sincInterp1D(rangeData)
n=length(rangeData);
nCenter=(n+1)/2;
interpRes=zeros(3,1);
interpRes(2)=rangeData(nCenter);
index=1;
for x=[nCenter-1/3 nCenter+1/3]
    g=0;
    for i=1:n
        g=g+rangeData(i)*sinc(x-i);
    end
    interpRes(index)=g;
    index=index+2;
end
interpAmp=abs(interpRes);
[~,maxIndex]=max(interpAmp);
if(maxIndex==1)
    Offset=-1/3;
elseif (maxIndex==2)
    Offset=0;
else
    Offset=1/3;
end
end









