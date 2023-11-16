function [usefulDetectList,usefulDetToClot,detectProb_plot] = choseRealTarget
%CHOSEREALTARGET 无人机真实目标往返曲线拟合筛选
        
global  savePicsPath HIST_THRESHOLD_GUARD ADCdataPath ADCdataPath processGap NumScan Vres Rres useNumScan enableAB

tic,

%% 加载真实目标筛选参数------------------------需进realTarParameter函数修改筛选参数--------------------
realTarParameter;


%% 加载所有检测点数据
%% TargetList各列含义：( 帧号，距离，速度，幅值，距离维幅值阈值，速度维幅值阈值，距离维信噪比，速度维信噪比，全局信噪比-直方图底噪，全局信噪比-均值底噪，方位角，俯仰角  )
filepath = pwd;%%保存当前工作目录
cd(savePicsPath)
% load TargetList_plot.mat
load detectResT.mat
TargetList = detectResT( find(detectResT(:,1)>0),: );

if (0)
%% 
Idx = find(abs(TargetList(:,3)) < 0.7);
f = unique(TargetList(:,1));
Nframe = length(f);
figure(100),hold on;
plot3(TargetList(:,1),TargetList(:,2),TargetList(:,3),'kO');
plot3(TargetList(Idx,1),TargetList(Idx,2),TargetList(Idx,3),'r*');
grid on
title(ADCdataPath,'FontSize',14);
legend(['所有实测检测点：',num2str(size(TargetList,1)),'个'],['速度小于±0.7的检测点：',num2str(length(Idx)),'个,平均每帧',num2str(length(Idx)/Nframe)]);

figure(101),hold on;
plot(TargetList(:,2),TargetList(:,7),'kO');
plot(TargetList(Idx,2),TargetList(Idx,7),'r*');
grid on
title(ADCdataPath,'FontSize',14);
legend('所有实测检测点rSNR','速度小于±0.7的检测点rSNR');

figure(102),hold on;
plot(TargetList(:,2),TargetList(:,8),'kO');
plot(TargetList(Idx,2),TargetList(Idx,8),'r*');
grid on
title(ADCdataPath,'FontSize',14);
legend('所有实测检测点dSNR','速度小于±0.7的检测点dSNR');

figure(103),hold on;
plot(TargetList(:,2),TargetList(:,9),'kO');
plot(TargetList(Idx,2),TargetList(Idx,9),'r*');
grid on
title(ADCdataPath,'FontSize',14);
legend('所有实测检测点gSNR','速度小于±0.7的检测点gSNR');

end

% cd(filepath) %%切回之前的工作目录

if (cfarTest)
%% CFAR参数调优
Idx_plot = [];
for i_plot = 1:size(TargetList,1)
     range = TargetList(i_plot,2);%%距离

     rSNR = TargetList(i_plot,7);%%距离维信噪比
     dSNR = TargetList(i_plot,8);%%速度维信噪比
     gSNR = TargetList(i_plot,9);%%全局信噪比
        
    %% 通用版本
    %%第1段：(2,10]rangeBin
    if ( (range > rangeSegment(1)) && (range <= rangeSegment(2)) )%%原始
        if ( (rSNR > CFAR_RANGE_THRESHOLD(1)) && (dSNR > CFAR_DOPPLER_THRESHOLD(1))&& (gSNR > CFAR_GLOBAL_THRESHOLD(1)) )%%原始
            Idx_plot = [Idx_plot,i_plot];
        end
        %%第2段：(10,100]rangeBin
    elseif ( (range > rangeSegment(2)) && (range <= rangeSegment(3)) )%%原始
        if ( (rSNR > CFAR_RANGE_THRESHOLD(2)) && (dSNR > CFAR_DOPPLER_THRESHOLD(2))&& (gSNR > CFAR_GLOBAL_THRESHOLD(2)) )%%原始
            Idx_plot = [Idx_plot,i_plot];
        end
        %%第3段：(100,167]rangeBin
    elseif ( (range > rangeSegment(3)) && (range <= rangeSegment(4)) )%%原始
        if ( (rSNR > CFAR_RANGE_THRESHOLD(3)) && (dSNR > CFAR_DOPPLER_THRESHOLD(3))&& (gSNR > CFAR_GLOBAL_THRESHOLD(3)) )%%原始
            Idx_plot = [Idx_plot,i_plot];
        end
        %%第4段：(167,267]rangeBin
    elseif ( (range > rangeSegment(4)) && (range <= rangeSegment(5)) )%%原始
        if ( (rSNR > CFAR_RANGE_THRESHOLD(4)) && (dSNR > CFAR_DOPPLER_THRESHOLD(4))&& (gSNR > CFAR_GLOBAL_THRESHOLD(4)) )%%原始
            Idx_plot = [Idx_plot,i_plot];
        end
        %%第5段：(267,430]rangeBin
    elseif ( (range > rangeSegment(5)) && (range <= rangeSegment(6)) )%%(267,430]
        if ( (rSNR > CFAR_RANGE_THRESHOLD(5)) && (dSNR > CFAR_DOPPLER_THRESHOLD(5)) && (gSNR > CFAR_GLOBAL_THRESHOLD(5)) )
            Idx_plot = [Idx_plot,i_plot];
        end
        %%第6段：[1,(430,end]]rangeBin
    else  %%( (range > 1290) && (range <= 30) ) %%(430,end]
        if ( (rSNR > CFAR_RANGE_THRESHOLD(3)) && (dSNR > CFAR_DOPPLER_THRESHOLD(3)) && (gSNR > CFAR_GLOBAL_THRESHOLD(3)) )
            Idx_plot = [Idx_plot,i_plot];
        end
    end
end

%% 过CFAR的有效检测点
TargetList_plot = TargetList(Idx_plot,:);

else
    TargetList_plot = TargetList;
end



idet_useful = [];
idet_clotUse = [];

Kw = zeros(1,length(Xw)/2);
bw = zeros(1,length(Xw)/2);

Kf = zeros(1,length(Xf)/2);
bf = zeros(1,length(Xf)/2);

for i_w = 1:length(Xw)/2
    Kw(i_w) = (Yw(2*i_w)-Yw(2*i_w-1))/(Xw(2*i_w)-Xw(2*i_w-1));%%远离曲线1
    bw(i_w) = Yw(2*i_w-1) - Kw(i_w) * Xw(2*i_w-1);
end

for i_f = 1:length(Xf)/2
    Kf(i_f) = (Yf(2*i_f)-Yf(2*i_f-1))/(Xf(2*i_f)-Xf(2*i_f-1));%%远离曲线1
    bf(i_f) = Yf(2*i_f-1) - Kf(i_f) * Xf(2*i_f-1);
end

%% 无人机目标筛选
YL_v = sort(choseV(1:2));KJ_v = sort(choseV(3:4));
r = find( TargetList_plot(:,2) <= choseR );%%range

[Idx12,~] = find( TargetList_plot(r,1) <= WframeID(end) );%%远离frameID
[Idx34,~] = find( TargetList_plot(r,1) > FframeID(1) );%%远离frameID
v1 = find( TargetList_plot(r(Idx12),3) >= YL_v(1) );%%远离速度下限
v2 = find( TargetList_plot(r(Idx12),3) <=  YL_v(2) );%%远离速度上限
v3 = find( TargetList_plot(r(Idx34),3) >=  KJ_v(1) );%%靠近速度下限
v4 = find( TargetList_plot(r(Idx34),3) <=  KJ_v(2) );%%靠近速度上限

v12 = intersect(v1,v2);
v34 = intersect(v3,v4);
idx_chose12 = r(Idx12(v12));%%(2)
idx_chose34 = r(Idx34(v34));%%(2)

if (choseWF == 2)
    idet_chose = idx_chose12;
else
    if (choseWF == 3)
        idet_chose = idx_chose34;
    else
        if (size(idx_chose12,2)==1)    
            idet_chose = [idx_chose12;idx_chose34];
        else
            idet_chose = [idx_chose12,idx_chose34];
        end
    end
end
            

%% CFAR参数调优
for jj = 1:length(idet_chose)
    i_use = idet_chose(jj);
    
    FrameID = TargetList_plot(i_use,1);%%帧号
    range = TargetList_plot(i_use,2);%%距离
    azimuth = TargetList_plot(i_use,11);%%方位角
    Elevation = TargetList_plot(i_use,12);%%俯仰角
    
    rSNR = TargetList_plot(i_use,7);%%距离维信噪比
    dSNR = TargetList_plot(i_use,8);%%速度维信噪比
    gSNR = TargetList_plot(i_use,9);%%全局信噪比
    mag = TargetList_plot(i_use,4);%%幅值
              
    inWF  = 0;
    if (curveSimulate == 1)
        
        tmpYw = zeros(1,length(Xw)/2);
        tmpYf = zeros(1,length(Xf)/2);
        inW = zeros(1,length(Xw)/2);
        inF = zeros(1,length(Xf)/2);
        
        for i_w = 1:length(Xw)/2
            tmpYw(i_w) = Kw(i_w) * FrameID + bw(i_w);%%远离曲线1;%%远离曲线
        end
        
        for i_f = 1:length(Xf)/2
            tmpYf(i_f) = Kf(i_f) * FrameID + bf(i_f);%%靠近曲线
        end
        
        if ( (range<=choseR) && abs(azimuth)<= choseAE(1) && abs(Elevation)<= choseAE(2) )
%         if ( (range<=choseR) && azimuth== 2 && Elevation == -3 )
            
            for i_w = 1:length(Xw)/2
                inW(i_w) = (FrameID>=WframeID(i_w) && FrameID<=WframeID(i_w+1) && ((tmpYw(i_w) >= range-4*Rres)&&(tmpYw(i_w) <= range+4*Rres)));%%远离曲线
            end
            
            for i_f = 1:length(Xf)/2
                inF(i_f) = (FrameID>=FframeID(i_f) && FrameID<=FframeID(i_f+1) && ((tmpYf(i_f) >= range-4*Rres)&&(tmpYf(i_f) <= range+4*Rres)));%%远离曲线
            end
            
            if (choseWF == 2)
                inWF = sum(inW);
            else
                if (choseWF == 3)
                    inWF =  sum(inF);
                else
                    inWF = sum(inW) + sum(inF);
                end
            end
        end
    else
        inWF  = 1;
    end
    
    if (inWF > 0)
        idet_useful = [idet_useful,i_use];
        
        %% 过mag阈值的检测点送往凝聚
        for i_r = 1:length(Range_THRESHOLD)/2
            if ( (range > Range_THRESHOLD(2*i_r-1)) && (range <= Range_THRESHOLD(2*i_r)) )
                if ( (mag >= MAG_THRESHOLD_start(2*i_r)) && (mag <= MAG_THRESHOLD_end(2*i_r)) )
                    idet_clotUse = [idet_clotUse,i_use];
                    break;
                end
                
            end
        end
        
    end
end

%% 无人机目标有效数据提取
usefulDetectList_s = TargetList_plot(idet_useful,:);%%有效目标检测点
usefulDetToClot_s = TargetList_plot(idet_clotUse,:);%%送往凝聚的有效目标检测点

[~,Idx_det] = sort( usefulDetectList_s(:,1) );
[~,Idx_clot] = sort( usefulDetToClot_s(:,1) );
usefulDetectList = usefulDetectList_s(Idx_det,:);
usefulDetToClot = usefulDetToClot_s(Idx_clot,:);

%% 保存有效检测点数据
savePath = [savePicsPath '\usefulDetectList.mat'];
save(savePath,'usefulDetectList');  % 保存到其他文件夹的写法


if (otherPoint == 1)
    Idx_use = 1:size(TargetList_plot,1);
    idet_noise = setdiff(Idx_use,idet_useful);   
    noiseDetectList_s = TargetList_plot(idet_noise,:);%%无效目标检测点

    [~,Idx_noise] = sort( noiseDetectList_s(:,1) );
    noiseDetectList = noiseDetectList_s(Idx_noise,:);

    Num_noise = size(noiseDetectList,1);
    meanNum_noise = ( Num_noise / ( (noiseDetectList(end,1) - noiseDetectList(1,1) + 1) / NumScan * useNumScan ) );%%回灌ADC只取中间24个波位处理
%     meanNum_noise = ceil( Num_noise / ( (noiseDetectList(end,1) - noiseDetectList(1,1) + 1) / NumScan * useNumScan ) );%%回灌ADC只取中间24个波位处理
    
    Num_useful = length(idet_useful);
end
%% 1、无人机目标数据及检测概率统计
N_prob = length(probR);
detectProb_plot = zeros(1,N_prob);


if (probEnable == 1)
    probDetectList = usefulDetectList;%%有效目标检测点
%     probDetectList = usefulDetToClot;%%送往凝聚的有效目标检测点
    
    NumScan = NumScan + processGap-1;%%间隔processGap读取数据，更新帧数+（processGap-1）
    
    if (choseWF == 1)
        probV = choseV;
        Np = 2;
    elseif (choseWF == 2)
        probV = choseV(1:2);
        Np = 1;
    elseif (choseWF == 3)
        probV = choseV(3:4);
        Np = 1;
    end
    
    rangeSNR = zeros(Np,N_prob/2);
    dopplerSNR = zeros(Np,N_prob/2);
    globalSNR = zeros(Np,N_prob/2);
    rangeSNR_plot = zeros(Np,N_prob);
    dopplerSNR_plot = zeros(Np,N_prob);
    globalSNR_plot = zeros(Np,N_prob);
    
    for i_p = 1:Np
        pV = sort([probV(2*i_p-1),probV(2*i_p)]);
        if (pV(1) < 0)
            probR = probR(end:-1:1);
        end
        detectProb = zeros(1,N_prob/2);
        detectProb_plot = zeros(1,N_prob);
        for pp = 1:N_prob/2
            pR = sort([probR(2*pp-1),probR(2*pp)]);
            pr1 = find( probDetectList(:,2) >= pR(1) );%%距离下边界
            pr2 = find( probDetectList(:,2) <= pR(2) );%%距离上边界
            pv1 = find( probDetectList(:,3) >= pV(1) );%%速度下边界
            pv2 = find( probDetectList(:,3) <= pV(2) );%%速度上边界
            
            pr12 = intersect(pr1,pr2);
            pv12 = intersect(pv1,pv2);
            probIdx = intersect(pr12,pv12);
            
            if (~isempty(probIdx))
                probDetList1 = probDetectList(probIdx,:);%%需要统计检测概率的有效数据
                probDetList2 = [probDetList1(2:end,:);probDetList1(1,:)];%%需要统计检测概率的有效数据
                diffFrame = probDetList2(:,1) - probDetList1(:,1);
                freq_lost = round(diffFrame ./ NumScan);
                time_lost = freq_lost;
                Num = length(freq_lost);
                for kk = 1:Num-1
                    if (time_lost(kk) > 1)
                        time_lost(kk) = time_lost(kk) - 1;
                    else
                        time_lost(kk) = 0;
                    end
                end
                if (probR(1)<=probR(end))
                    [~,Idx_wn] = find( probDetList1(1,1) - WframeID >= 0 );
                    
                    FrameS_tmp = (pR(1)- bw(Idx_wn(end))) / Kw(Idx_wn(end));
                    FrameE_tmp = (pR(2)- bw(Idx_wn(end))) / Kw(Idx_wn(end));
                    if ( (probDetList1(1,2) > pR(1)) && (FrameS_tmp < probDetList1(1,1)) )
                        Frame_start = FrameS_tmp;
                    else
                        Frame_start = probDetList1(1,1);
                    end
                    
                    if ( (probDetList1(end,2) < pR(2)) && (FrameE_tmp > probDetList1(end,1)) )
                        Frame_end = FrameE_tmp;
                    else
                        Frame_end = probDetList1(end,1);
                    end
                     
                    plotName = 'range-detectProb-YL';
                    
                    rangeSNR(i_p,pp) = mean(probDetList1(:,7));
                    dopplerSNR(i_p,pp) = mean(probDetList1(:,8));
                    globalSNR(i_p,pp) = mean(probDetList1(:,9));
                else
                    [~,Idx_fn] = find( probDetList1(1,1) - FframeID >= 0 );
                    
                    FrameS_tmp = (pR(2)- bf(Idx_fn(end))) / Kf(Idx_fn(end));
                    FrameE_tmp = (pR(1)- bf(Idx_fn(end))) / Kf(Idx_fn(end));
                    if ( (probDetList1(1,2) > pR(2)) && (FrameS_tmp < probDetList1(1,1)) )
                        Frame_start = FrameS_tmp;
                    else
                        Frame_start = probDetList1(1,1);
                    end
                    
                    if ( (probDetList1(end,2) < pR(1)) && (FrameE_tmp > probDetList1(end,1)) )
                        Frame_end = FrameE_tmp;
                    else
                        Frame_end = probDetList1(end,1);
                    end

                    plotName = 'range-detectProb-KJ';
                    
                    rangeSNR(i_p,N_prob/2-pp+1) = mean(probDetList1(:,7));
                    dopplerSNR(i_p,N_prob/2-pp+1) = mean(probDetList1(:,8));
                    globalSNR(i_p,N_prob/2-pp+1) = mean(probDetList1(:,9));
                end
                Total_Frame = Frame_end - Frame_start; %%远离曲线1
                diff_start = round( ( probDetList1(1,1) - Frame_start ) / NumScan );
                diff_end = round( ( Frame_end - probDetList1(end,1) ) / NumScan );
                if (diff_start > 1)
                    time_start = diff_start-1;
                else
                    time_start = 0;
                end
                if (diff_end > 1)
                    time_end = diff_end-1;
                else
                    time_end = 0;
                end
                if (Total_Frame > 0)
                    detectProb(pp) = 1 - (sum(time_lost(1:Num-1)) + time_start +  time_end)/(Total_Frame/NumScan);%%检测概率
                else
                    detectProb(pp) = 0;
                end
                
            else
                detectProb(pp) = 0;
                plotName = 'range-detectProb';
            end
        end
        
        detectProb_plot(1:2:end) = detectProb;
        detectProb_plot(2:2:end) = detectProb;
        figure(i_p);plot(probR,detectProb_plot,'r-');hold on;
        title(ADCdataPath,'FontSize',14);xlabel("距离(m)",'FontSize',14);ylabel(plotName,'FontSize',14);
        if(saveRealFlag)
            cd(savePicsPath)
            saveas(gcf, plotName, 'fig')
        end
        
        rangeSNR_plot(:,1:2:end) = rangeSNR;
        rangeSNR_plot(:,2:2:end) = rangeSNR;
        dopplerSNR_plot(:,1:2:end) = dopplerSNR;
        dopplerSNR_plot(:,2:2:end) = dopplerSNR;
        globalSNR_plot(:,1:2:end) = globalSNR;
        globalSNR_plot(:,2:2:end) = globalSNR;
    end
else
    Np = 0;
end

fprintf("筛选无人机目标处理耗时：%f\n", toc);
   
if (~plotEnable)
    %% 画图显示
    figure(100),plot3(TargetList_plot(:,1),TargetList_plot(:,2),TargetList_plot(:,3),'k.'),hold on;%%figure(fileNum+1),
    figure(100),plot3(usefulDetectList(:,1),usefulDetectList(:,2),usefulDetectList(:,3),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('距离/m','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
        h = legend(['(1)ADC回灌SiL得到的检测点,误检总数',num2str(Num_noise),'个,平均每帧假点数',num2str(meanNum_noise),'个'],['(2)无人机目标点,有效检测点数',num2str(Num_useful),'个']);
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
end
    
%     Rp = find( usefulDetectList(:,7)<= 12 );
%     Dp = find( usefulDetectList(Rp,8)<= 12 );
%     Gp = find( usefulDetectList(Rp(Dp),7)<= 12 );
%     N12 = length(Rp(Dp(Gp)));
%     Nall = length(find( usefulDetectList(:,2)>= 210 ));
%     N12/Nall
%     figure,plot3(usefulDetectList(Rp(Dp(Gp)),2),usefulDetectList(Rp(Dp(Gp)),7),usefulDetectList(Rp(Dp(Gp)),11),'*'),hold on;
    
%     figure(101),plot3(TargetList_plot(:,2),TargetList_plot(:,7),TargetList_plot(:,11),'*'),hold on;
%     figure(101),plot3(usefulDetectList(:,2),usefulDetectList(:,7),usefulDetectList(:,11),'*'),hold on;
%     xlabel('距离/m','FontSize',14);ylabel('距离维信噪比/m','FontSize',14);zlabel('方位角/m','FontSize',14);title(ADCdataPath,'FontSize',14);%
%     if(saveRealFlag)
%         cd(savePicsPath)
%         saveas(gcf, 'chose_R-rSNR-Azi', 'fig')
%     end
%     
%     figure(102),plot3(usefulDetectList(:,2),usefulDetectList(:,8),usefulDetectList(:,11),'*'),hold on;
%     xlabel('距离/m','FontSize',14);ylabel('速度维信噪比/m','FontSize',14);zlabel('方位角/m','FontSize',14);title(ADCdataPath,'FontSize',14);%    
%     figure(103),plot3(usefulDetectList(:,2),usefulDetectList(:,9),usefulDetectList(:,11),'*'),hold on;
%     xlabel('距离/m','FontSize',14);ylabel('全局信噪比/m','FontSize',14);zlabel('方位角/m','FontSize',14);title(ADCdataPath,'FontSize',14);%

    
    
if (plotEnable == 1)  
       
%     if (0)
    figure(Np + 1),plot3(TargetList_plot(:,1),TargetList_plot(:,2),TargetList_plot(:,3),'k.'),hold on;%%figure(fileNum+1),
    figure(Np + 1),plot3(usefulDetectList(:,1),usefulDetectList(:,2),usefulDetectList(:,3),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('距离/m','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
         h = legend(['(1)ADC回灌SiL得到的检测点,误检总数',num2str(Num_noise),'个,平均每帧假点数',num2str(meanNum_noise),'个'],['(2)无人机目标点,有效检测点数',num2str(Num_useful),'个']);
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_FrameID-R', 'fig')
    end
      
%     if (0)
    figure(Np + 2),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,7),'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,7),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('距离维信噪比/dB','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 2),subplot(212),hold on;
    p1 = plot(TargetList_plot(:,2),TargetList_plot(:,7),'ko');
    p2 = plot(usefulDetectList(:,2),usefulDetectList(:,7),'r*'),hold on;
    plot(ones(1,45)+rangeSegment(2),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(3),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(4),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(5),1:45,'g-');hold on;
    p3 = plot(rangeSegment_Plot,CFAR_RANGE_THRESHOLD_endPlot,'m-','LineWidth',2);hold on;
    if (probEnable)
        p4 = plot(probR_plot,rangeSNR_plot(1,:),'g-','LineWidth',1);hold on;
        if ( Np==2 )
            p5 = plot(probR_plot,rangeSNR_plot(2,:),'c-','LineWidth',1);hold on;
        end               
        if (curveSimulate == 1)
            h = legend([p1,p2,p3,p4],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)距离维CFAR筛选阈值上限','(4)距离维SNR均值');
            if ( Np==2 )
                h = legend([p1,p2,p3,p4,p5],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)距离维CFAR筛选阈值上限','(4)距离维SNR均值-远离','(5)距离维SNR均值-靠近');
            end
        elseif (curveSimulate == 2)
            h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
        end
        set(h,'FontSize',11)
    else
        if (curveSimulate == 1)
            h = legend([p1,p2,p3],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)距离维CFAR筛选阈值上限');
        elseif (curveSimulate == 2)
            h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
        end
        set(h,'FontSize',11)        
    end
    title(ADCdataPath,'FontSize',14);xlabel("距离(m)",'FontSize',14);ylabel("距离维信噪比(dB)",'FontSize',14);
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf,  'chose_FrameID_R-rSNR', 'fig')
    end
    
    figure(Np + 3),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,8),'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,8),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('速度维信噪比/dB','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 3),subplot(212),hold on;
    p1 = plot(TargetList_plot(:,2),TargetList_plot(:,8),'ko');
    p2 = plot(usefulDetectList(:,2),usefulDetectList(:,8),'r*'),hold on;
    p3 = plot(rangeSegment_Plot,CFAR_DOPPLER_THRESHOLD_endPlot,'m-','LineWidth',2);hold on;
    plot(ones(1,45)+rangeSegment(2),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(3),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(4),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(5),1:45,'g-');hold on;
    if (probEnable)
        p4 = plot(probR_plot,dopplerSNR_plot(1,:),'g-','LineWidth',1);hold on;
        if ( Np==2 )
            p5 = plot(probR_plot,dopplerSNR_plot(2,:),'c-','LineWidth',1);hold on;
        end       
        if (curveSimulate == 1)
            h = legend([p1,p2,p3,p4],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)速度维CFAR筛选阈值上限','(4)速度维SNR均值');
            if ( Np==2 )
                h = legend([p1,p2,p3,p4,p5],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)速度维CFAR筛选阈值上限','(4)速度维SNR均值-远离','(5)速度维SNR均值-靠近');
            end
        elseif (curveSimulate == 2)
            h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
        end
        set(h,'FontSize',11)
    else
        if (curveSimulate == 1)
            h = legend([p1,p2,p3],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)速度维CFAR筛选阈值上限');
        elseif (curveSimulate == 2)
            h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
        end
        set(h,'FontSize',11)
    end
    title(ADCdataPath,'FontSize',14);xlabel("距离(m)",'FontSize',14);ylabel("速度维信噪比(dB)",'FontSize',14);
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_FrameID_R-dSNR', 'fig')
    end
    
    figure(Np + 4),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,9),'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,9),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('全局信噪比/dB','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 4),subplot(212),hold on;
    p1 = plot(TargetList_plot(:,2),TargetList_plot(:,9),'ko');
    p2 = plot(usefulDetectList(:,2),usefulDetectList(:,9),'r*'),hold on;
    p3 = plot(rangeSegment_Plot,CFAR_GLOBAL_THRESHOLD_endPlot,'m-','LineWidth',2);hold on;
    plot(ones(1,45)+rangeSegment(2),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(3),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(4),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(5),1:45,'g-');hold on;
    if (probEnable)
        p4 = plot(probR_plot,globalSNR_plot(1,:),'g-','LineWidth',1);hold on;
        if ( Np==2 )
            p5 = plot(probR_plot,globalSNR_plot(2,:),'c-','LineWidth',1);hold on;
        end    
        if (curveSimulate == 1)
            h = legend([p1,p2,p3,p4],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)全局CFAR筛选阈值上限','(4)全局SNR均值');
            if ( Np==2 )
                h = legend([p1,p2,p3,p4,p5],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)全局CFAR筛选阈值上限','(4)全局SNR均值-远离','(5)全局SNR均值-靠近');
            end
        elseif (curveSimulate == 2)
            h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
        end
        set(h,'FontSize',11)
    else
        if (curveSimulate == 1)
            h = legend([p1,p2,p3],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)全局CFAR筛选阈值上限');
        elseif (curveSimulate == 2)
            h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
        end
        set(h,'FontSize',11)
    end    
    title(ADCdataPath,'FontSize',14);xlabel("距离(m)",'FontSize',14);ylabel("全局信噪比(dB)",'FontSize',14);
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_FrameID_R-gSNR', 'fig')
    end

    figure(Np + 5),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,4),'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,4),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('幅值mag/dB','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 5),subplot(212),hold on;
    p1 = plot(TargetList_plot(:,2),TargetList_plot(:,4),'ko');
    p2 = plot(usefulDetectList(:,2),usefulDetectList(:,4),'r*'),hold on;
    plot(ones(1,90)+rangeSegment(2),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(3),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(4),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(5),1:90,'g-');hold on;
    p3 = plot(Range_THRESHOLD,MAG_THRESHOLD_start,'m-','LineWidth',2);hold on;
    p4 = plot(Range_THRESHOLD,MAG_THRESHOLD_end,'c-','LineWidth',2);hold on;
    title(ADCdataPath,'FontSize',14);xlabel("距离(m)",'FontSize',14);ylabel("幅值mag(dB)",'FontSize',14);
    if (curveSimulate == 1)
        h = legend([p1,p2,p3,p4],'(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点','(3)mag筛选阈值下限','(4)mag筛选阈值上限');
    elseif (curveSimulate == 2)
        h = legend([p1,p2,p3,p4],'(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点','(3)mag筛选阈值下限','(4)mag筛选阈值上限');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_chose_FrameID_R-mag', 'fig')
    end
    
    figure(Np + 6),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,4)-TargetList_plot(:,9)+(HIST_THRESHOLD_GUARD-1)*3.0103,'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,4)-usefulDetectList(:,9)+(HIST_THRESHOLD_GUARD-1)*3.0103,'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('直方图底噪/dB','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 6),subplot(212),hold on;
    plot(TargetList_plot(:,2),TargetList_plot(:,4)-TargetList_plot(:,9)+(HIST_THRESHOLD_GUARD-1)*3.0103,'ko');
    plot(usefulDetectList(:,2),usefulDetectList(:,4)-usefulDetectList(:,9)+(HIST_THRESHOLD_GUARD-1)*3.0103,'r*'),hold on;
    plot(ones(1,90)+rangeSegment(2),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(3),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(4),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(5),1:90,'g-');hold on;
    xlabel('距离/m','FontSize',14);ylabel('直方图底噪/dB','FontSize',14);title(ADCdataPath,'FontSize',14);
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_FrameID_R-noiseMag', 'fig')
    end
    
    Age_st = -10;
    Age_ed = -2;
    Range = 350;
    Idx_1 = find(usefulDetectList(:,15) <= Age_ed);
    Idx_2 = find(usefulDetectList(Idx_1,15) >= Age_st);
    Idxa = Idx_1(Idx_2);
    Idxd = find(usefulDetectList(:,2) > Range);
    
    figure(Np + 7),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,11),'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,15),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('方位角-和差比幅/°','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 7),subplot(212),hold on;
    plot(TargetList_plot(:,2),TargetList_plot(:,11),'ko');
    plot(usefulDetectList(:,2),usefulDetectList(:,15),'r*'),hold on;
    plot(ones(1,90)+rangeSegment(2),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(3),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(4),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(5),1:90,'g-');hold on;
    xlabel('距离/m','FontSize',14);ylabel('方位角-和差比幅/°','FontSize',14);title(ADCdataPath,'FontSize',14);
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点',['(2)无人机目标检测点，标准差',num2str(std(usefulDetectList(:,15))),'°,[',num2str(Age_st),'°,',num2str(Age_ed),'°]外标准差',num2str(std(usefulDetectList(Idxa,15))),'°,',num2str(Range),'m外标准差',num2str(std(usefulDetectList(Idxd,15))),'°']);
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_FrameID_R-azimuth', 'fig')
    end
    
    Idx_1 = find(usefulDetectList(:,16) <= Age_ed);
    Idx_2 = find(usefulDetectList(Idx_1,16) >= Age_st);
    Idxb = Idx_1(Idx_2);    
    
    figure(Np + 8),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,11),'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,16),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('方位角-和差比相/°','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 8),subplot(212),hold on;
    plot(TargetList_plot(:,2),TargetList_plot(:,11),'ko');
    plot(usefulDetectList(:,2),usefulDetectList(:,16),'r*'),hold on;
    plot(ones(1,90)+rangeSegment(2),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(3),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(4),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(5),1:90,'g-');hold on;
    xlabel('距离/m','FontSize',14);ylabel('方位角-和差比相/°','FontSize',14);title(ADCdataPath,'FontSize',14);
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点',['(2)无人机目标检测点，标准差',num2str(std(usefulDetectList(:,16))),'°,[',num2str(Age_st),'°,',num2str(Age_ed),'°]外标准差',num2str(std(usefulDetectList(Idxb,16))),'°,',num2str(Range),'m外标准差',num2str(std(usefulDetectList(Idxd,16))),'°']);
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_FrameID_R-azimuth', 'fig')
    end
    
    if (enableAB)
        Idx_1 = find(usefulDetectList(:,17) <= Age_ed);
        Idx_2 = find(usefulDetectList(Idx_1,17) >= Age_st);
        Idxc = Idx_1(Idx_2);

        figure(Np + 800),subplot(211),hold on;
        plot(TargetList_plot(:,1),TargetList_plot(:,11),'ko');
        plot(usefulDetectList(:,1),usefulDetectList(:,17),'r*'),hold on;
        xlabel('帧号/FrameID','FontSize',14);ylabel('方位角-AB通道比相/°','FontSize',14);title(ADCdataPath,'FontSize',14);
        figure(Np + 800),subplot(212),hold on;
        plot(TargetList_plot(:,2),TargetList_plot(:,11),'ko');
        plot(usefulDetectList(:,2),usefulDetectList(:,17),'r*'),hold on;
        plot(ones(1,90)+rangeSegment(2),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(3),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(4),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(5),1:90,'g-');hold on;
        xlabel('距离/m','FontSize',14);ylabel('方位角-AB通道比相/°','FontSize',14);title(ADCdataPath,'FontSize',14);
        if (curveSimulate == 1)
            h = legend('(1)ADC回灌SiL得到的检测点',['(2)无人机目标检测点，标准差',num2str(std(usefulDetectList(:,17))),'°,[',num2str(Age_st),'°,',num2str(Age_ed),'°]外标准差',num2str(std(usefulDetectList(Idxc,17))),'°,',num2str(Range),'m外标准差',num2str(std(usefulDetectList(Idxd,17))),'°']);
        elseif (curveSimulate == 2)
            h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
        end
        set(h,'FontSize',11)
        if(saveRealFlag)
            cd(savePicsPath)
            saveas(gcf, 'chose_FrameID_R-azimuth', 'fig')
        end   
    end
    
    figure(Np + 9),subplot(211),hold on;
    plot(TargetList_plot(:,1),TargetList_plot(:,12),'ko');
    plot(usefulDetectList(:,1),usefulDetectList(:,12),'r*'),hold on;
    xlabel('帧号/FrameID','FontSize',14);ylabel('俯仰角/°','FontSize',14);title(ADCdataPath,'FontSize',14);
    figure(Np + 9),subplot(212),hold on;
    plot(TargetList_plot(:,2),TargetList_plot(:,12),'ko');
    plot(usefulDetectList(:,2),usefulDetectList(:,12),'r*'),hold on;
    plot(ones(1,90)+rangeSegment(2),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(3),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(4),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(5),1:90,'g-');hold on;
    xlabel('距离/m','FontSize',14);ylabel('俯仰角/°','FontSize',14);title(ADCdataPath,'FontSize',14);
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_FrameID_R-elevation', 'fig')
    end
    
%     end
    
if (0)
    figure(Np + 10),plot3(TargetList_plot(:,2),TargetList_plot(:,7),TargetList_plot(:,11),'k.'),hold on;
    figure(Np + 10),plot3(usefulDetectList(:,2),usefulDetectList(:,7),usefulDetectList(:,11),'r*'),hold on;
    xlabel('距离/m','FontSize',14);ylabel('距离维信噪比/dB','FontSize',14);zlabel('方位角/°','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_R-rSNR-Azi', 'fig')
    end
    
    figure(Np + 11),plot3(TargetList_plot(:,2),TargetList_plot(:,8),TargetList_plot(:,11),'k.'),hold on;
    figure(Np + 11),plot3(usefulDetectList(:,2),usefulDetectList(:,8),usefulDetectList(:,11),'r*'),hold on;
    xlabel('距离/m','FontSize',14);ylabel('速度维信噪比/dB','FontSize',14);zlabel('方位角/°','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_R-dSNR-Azi', 'fig')
    end

    figure(Np + 12),plot3(TargetList_plot(:,2),TargetList_plot(:,9),TargetList_plot(:,11),'k.'),hold on;
    figure(Np + 12),plot3(usefulDetectList(:,2),usefulDetectList(:,9),usefulDetectList(:,11),'r*'),hold on;
    xlabel('距离/m','FontSize',14);ylabel('全局信噪比/dB','FontSize',14);zlabel('方位角/°','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_R-gSNR-Azi', 'fig')
    end
    
    figure(Np + 13),plot3(TargetList_plot(:,2),TargetList_plot(:,4),TargetList_plot(:,7),'k.'),hold on;
    figure(Np + 13),plot3(usefulDetectList(:,2),usefulDetectList(:,4),usefulDetectList(:,7),'r*'),hold on;
    xlabel('距离/m','FontSize',14);ylabel('幅值/dB','FontSize',14);zlabel('距离维信噪比/dB','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_R-mag-rSNR', 'fig')
    end
    
    figure(Np + 14),plot3(TargetList_plot(:,2),TargetList_plot(:,4),TargetList_plot(:,8),'k.'),hold on;
    figure(Np + 14),plot3(usefulDetectList(:,2),usefulDetectList(:,4),usefulDetectList(:,8),'r*'),hold on;
    xlabel('距离/m','FontSize',14);ylabel('幅值/dB','FontSize',14);zlabel('速度维信噪比/dB','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_R-mag-dSNR', 'fig')
    end
    
    figure(Np + 15),plot3(TargetList_plot(:,2),TargetList_plot(:,4),TargetList_plot(:,9),'k.'),hold on;
    figure(Np + 15),plot3(usefulDetectList(:,2),usefulDetectList(:,4),usefulDetectList(:,9),'r*'),hold on;
    xlabel('距离/m','FontSize',14);ylabel('幅值/dB','FontSize',14);zlabel('全局信噪比/dB','FontSize',14);title(ADCdataPath,'FontSize',14);%
    if (curveSimulate == 1)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的无人机目标实测检测点');
    elseif (curveSimulate == 2)
        h = legend('(1)ADC回灌SiL得到的检测点','(2)筛选出的杂散检测点');
    end
    set(h,'FontSize',11)
    if(saveRealFlag)
        cd(savePicsPath)
        saveas(gcf, 'chose_R-mag-gSNR', 'fig')
    end
    
    
    %% 新加+++++++++++++
% IdxT_tas = find(usefulDetectList(:,13)==1);
% IdxT_tws = find(usefulDetectList(:,13)==0);
%  
% figure,hold on;
% plot(usefulDetectList(:,11),usefulDetectList(:,15)-usefulDetectList(:,25),'bo');plot(usefulDetectList(:,11),usefulDetectList(:,16)-usefulDetectList(:,25),'r*');plot(usefulDetectList(:,11),usefulDetectList(:,17)-usefulDetectList(:,25),'go');
% title(ADCdataPath,'FontSize',14);xlabel("外场目标角(°)",'FontSize',14);ylabel("方位角误差(°)",'FontSize',14);
% h = legend( ['和差比幅，误差均值',num2str(mean(abs(usefulDetectList(:,15)-usefulDetectList(:,11)))),'°'],['和差比相，误差均值',num2str(mean(abs(usefulDetectList(:,16)-usefulDetectList(:,11)))),'°'],['AB单通道比相，误差均值',num2str(mean(abs(usefulDetectList(:,17)-usefulDetectList(:,11)))),'°'],'FontSize',12);
% 
% %% 保存图形
% cd(savePicsPath)
% saveas(gcf, 'azi_R-Beam_3aziDiff', 'fig')
% 
% 
% figure,hold on;
% subplot(211),p1 = plot(usefulDetectList(IdxT_tas,11),usefulDetectList(IdxT_tas,21)-usefulDetectList(IdxT_tas,22),'b*');hold on;p2 = plot(usefulDetectList(IdxT_tws,11),usefulDetectList(IdxT_tws,21)-usefulDetectList(IdxT_tws,22),'ro');hold on;
% xlabel("外场目标角(°)",'FontSize',14);ylabel("幅值(dB)",'FontSize',14); 
% h = legend([p1,p2], '(1)A-B通道幅值差——TAS波束', '(2)A-B通道幅值差——TWS波束','FontSize',12);
% set(h,'FontSize',11)
% subplot(212),p1 = plot(usefulDetectList(IdxT_tas,11),usefulDetectList(IdxT_tas,23),'b*');hold on;p2 = plot(usefulDetectList(IdxT_tws,11),usefulDetectList(IdxT_tws,23),'r*');hold on;
% p3 = plot(usefulDetectList(IdxT_tas,11),usefulDetectList(IdxT_tas,24),'bo');hold on;p4 = plot(usefulDetectList(IdxT_tws,11),usefulDetectList(IdxT_tws,24),'ro');hold on
% xlabel("外场目标角(°)",'FontSize',14);ylabel("相位差(°)",'FontSize',14);
% h = legend( [p1,p2,p3,p4],'(1)实测A-B通道相位差——TAS波束','(2)实测A-B通道相位差——TWS波束','(3)理论A-B通道相位差——TAS波束','(4)理论A-B通道相位差——TWS波束','FontSize',14,'FontSize',12);
% set(h,'FontSize',11)
% 
% %% 保存图形
% cd(savePicsPath)
% saveas(gcf, 'azi_R-mag_phase', 'fig')

Idx_tas = find(usefulDetectList(:,13) == 1);
figure,subplot(211),hold on;
plot(usefulDetectList(:,1),usefulDetectList(:,15),'b.',usefulDetectList(Idx_tas,1),usefulDetectList(Idx_tas,15),'bo'),hold on;
plot(usefulDetectList(:,1),usefulDetectList(:,16),'r.',usefulDetectList(Idx_tas,1),usefulDetectList(Idx_tas,16),'ro'),hold on;
if (enableAB)
    plot(usefulDetectList(:,1),usefulDetectList(:,17),'g.',usefulDetectList(Idx_tas,1),usefulDetectList(Idx_tas,17),'go'),hold on;
end
xlabel('帧号/FrameID','FontSize',14);ylabel('方位角/°','FontSize',14);title(ADCdataPath,'FontSize',14);
h = legend(['和差比幅，标准差',num2str(std(usefulDetectList(:,15))),'°'],'和差比幅-TAS',['和差比相，标准差',num2str(std(usefulDetectList(:,16))),'°'],'和差比相-TAS',['AB比相，标准差',num2str(std(usefulDetectList(:,17))),'°'],'AB比相-TAS');
subplot(212),hold on;
plot(usefulDetectList(:,2),usefulDetectList(:,15),'bo'),hold on;
plot(usefulDetectList(:,2),usefulDetectList(:,16),'ro'),hold on;
if (enableAB)
    plot(usefulDetectList(:,2),usefulDetectList(:,17),'go'),hold on;
end
plot(ones(1,90)+rangeSegment(2),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(3),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(4),1:90,'g-');hold on; plot(ones(1,90)+rangeSegment(5),1:90,'g-');hold on;
xlabel('距离/m','FontSize',14);ylabel('方位角/°','FontSize',14);title(ADCdataPath,'FontSize',14);
% h = legend(['和差比幅，标准差',num2str(std(usefulDetectList(:,14))),'°'],['和差比相，标准差',num2str(std(usefulDetectList(:,15))),'°'],['AB比相，标准差',num2str(std(usefulDetectList(:,16))),'°']);

set(h,'FontSize',11)
if(saveRealFlag)
    cd(savePicsPath)
    saveas(gcf, 'chose_FrameID_R-3Azi', 'fig')
end

    
end
    
end

end

