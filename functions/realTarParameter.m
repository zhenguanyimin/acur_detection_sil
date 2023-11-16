
%% =======================================1、mode=1时修改参数，第1部分start =============================================%%
g_byDevHwGen = 4;%%雷达型号：(1)2：2代雷达（包含2#、3#、5#雷达）；(2)3：3代雷达（包含4#雷达,收发天线拉开）；(3)4：4代雷达（包含4代1、2、3、5、7#）；默认4代
cfarTest = 0;%%是否进行cfar阈值调整:1是，否0；
curveSimulate = 1;%%检测点选取模式：1：进行（帧号-距离）一次曲线拟合筛选无人机目标（需同步修改43-58行参数）；2：筛选noiseR固定距离杂散点（需同步修改61行noiseR参数）====== 点迹画出确认目标轨迹信息（直线选点）后再进行统计
choseWF = 1;%%筛选无人机检测点的模式：1往返，2仅远离，3仅靠近 ============== 依据数据实测及关注情况选取
probEnable = 0;%%是否进行检测概率统计：1是，0否,默认0 ===================== 点迹画出确认目标轨迹信息后再进行统计（需同步修改53行统计距离段probR信息）
plotScanLine = 0;%%是否画波束扫描线：1是，0否,默认0======================== 用于看一轮扫描检测情况
plotEnable = 0;%%是否画图显示检测相关信息：1是，0否,默认0================== 显示3维信噪比，幅值，底噪等信息
saveRealFlag = 0;%%是否保存每帧处理结果图：1是，0否,默认0================== 数据较多时可保存不同场景的处理结果，后面还可用MATLAB打开查看（需同步修改33行数据主题描述和34行保存路径）
otherPoint = 1;%%是否统计平均无效检测点：1是，0否

%% ===================== 无人机检测点筛选参数设置，受传输精度限制，各参数均保留部分冗余 ============================%%
choseR = 620;%%无人机目标最远距离限制520,1010============================= 依据数据实测及关注情况选取，对空默认520，平视默认1010
% choseV = [6*Vres-0.2,8*Vres+0.2,-6*Vres+0.2,-8*Vres-0.2];%%5m/s,无人机目标往返速度限制(1,2项为远离，3,4项为靠近)，由实测情况选取（如无人机3-5m/s往返，速度分辨率0.73m/s，设置[4*Vres-0.2,8*Vres+0.2,-4*Vres+0.2,-8*Vres-0.2]，保留部分冗余）
choseV = [14*Vres-0.2,16*Vres+0.2,-14*Vres+0.2,-16*Vres-0.2];%%9m/s,无人机目标往返速度限制(1,2项为远离，3,4项为靠近)，由实测情况选取（如无人机3-5m/s往返，速度分辨率0.73m/s，设置[4*Vres-0.2,8*Vres+0.2,-4*Vres+0.2,-8*Vres-0.2]，保留部分冗余）
choseAE = [15,10];%%挑选无人机目标方位角（±18）和俯仰角（±15）限制，保留冗余，默认[20,16]，仅看该方位内的无人机检测点
% probR = [0,51,51,210,210,327,327,630];%%[0,99,99,201,201,300,300,402,402,501,501,600,600,702];[0,51,51,210,210,327,327,630,630,1110]统计无人机目标检测概率的距离段，默认100m为1段,两两为一组[0,99,99,201,201,300,300,402,402,501,501,600,600,702,702,801,801,900,900,1002]
probR = [0,99,99,201,201,300,300,402,402,501,501,600];%%[0,99,99,201,201,300,300,402,402,501,501,600]
%% ===================== 杂散点筛选距离设置，需为分辨率3的整数倍 ============================%%
noiseR = [369:Rres:375];%%杂散点的距离范围，可以有多段，Rres为一个距离分辨率


%% =================== CFAR参数修改（随检测版本参数变化，跟算法人员对齐，当前默认0221CFAR） ==============================%%
%% --------（1）mag阈值及分段 -----------------------%%
%% --------（1）mag阈值及分段 -----------------------%%
% %%0320mag值
% Range_THRESHOLD = [0,51,51,210,210,306,306,405,405,600,600,800,800,1002];
% MAG_THRESHOLD_st = [39,35,35,40,41,45,48];%%距离维mag阈值下限
% MAG_THRESHOLD_ed = [100,90,72,70,68,68,68];%%距离维mag阈值下限



if (3 == g_byDevHwGen)
    
%     rangeSegment = [6,51,210,327,630,1050];%%距离分段
    rangeSegment = [6,51,210,501,801,1050];%%距离分段
    choseR = 1050;
    probR = [0,99,99,201,201,300,300,402,402,501,501,600,600,702,702,801,801,900,900,1002];
    
    % %%0620mag值-适配3代的
    Range_THRESHOLD = [0,100,100,210,210,306,306,405,405,633,633,723,723,1110];%%距离段
    MAG_THRESHOLD_st = [38,38,38,37,37,37,37];%%距离维mag阈值下限
    MAG_THRESHOLD_ed = [100,90,80,75,74,72,72.5];%%距离维mag阈值上限
    
%     % %%0612mag值-适配3代的4#雷达
%     Range_THRESHOLD = [0,100,100,210,210,306,306,405,405,633,633,723,723,1110];%%距离段
%     MAG_THRESHOLD_st = [38,38,38,40,40,40,41];%%距离维mag阈值下限
% %     MAG_THRESHOLD_ed = [100,90,74,73,75,72,71];%%距离维mag阈值上限
%     MAG_THRESHOLD_ed = [100,90,80,75,74,72,72.5];%%距离维mag阈值上限
    
%     % %%0423mag值-适配3代的4#雷达
%     Range_THRESHOLD = [0,51,51,210,210,306,306,405,405,633,633,723,723,1110];%%距离段
%     MAG_THRESHOLD_st = [34,31,32,34,40,40,41];%%距离维mag阈值下限
% %     MAG_THRESHOLD_ed = [100,90,74,73,75,72,71];%%距离维mag阈值上限
%     MAG_THRESHOLD_ed = [100,90,73.5,70,72,70,71];%%距离维mag阈值上限

elseif (2 == g_byDevHwGen)
    
    rangeSegment = [6,51,210,327,630,720];%%距离分段
    choseR = 620;
%     probR = [0,99,99,201,201,300,300,402,402,501,501,600];
    
    %%0423mag值-适配2代的2#、3#，5#雷达
    Range_THRESHOLD = [0,51,51,210,210,306,306,405,405,633,633,723,723,1110];%%距离段
    MAG_THRESHOLD_st = [38,34,32,32,33,35,35];%%距离维mag阈值下限
    MAG_THRESHOLD_ed = [90,80,60,54,53,48,48];%%距离维mag阈值上限
    
else %%if (4 == g_byDevHwGen)
    
    rangeSegment = [6,51,210,501,801,1200];%%距离分段
    choseR = 1050;
    probR = [0,99,99,201,201,300,300,402,402,501,501,600,600,702,702,801,801,900,900,1002,1002,1101,1101,1200];
    
    % %%0620mag值-适配4代的
    Range_THRESHOLD = [0,100,100,210,210,306,306,405,405,633,633,723,723,1200];%%距离段
    MAG_THRESHOLD_st = [25,24,24,23,23,23,23];%%距离维mag阈值下限
%     MAG_THRESHOLD_st = [22,21,20,20,19,19,19];%%距离维mag阈值下限
%     MAG_THRESHOLD_st = [27,27,27,26,26,26,24];%%距离维mag阈值下限    
    MAG_THRESHOLD_ed = [100,90,80,75,74,72,72.5];%%距离维mag阈值上限
    
end


%% --------（2）CFAR阈值 -----------------------%%
%% 下限
% %% 9dBCFAR——OK
% CFAR_RANGE_THRESHOLD = [22,12,9,9,9,90];%%距离维CFAR阈值
% CFAR_DOPPLER_THRESHOLD = [19,12,9,9,9,100];%%速度维CFAR阈值
% CFAR_GLOBAL_THRESHOLD = [15,12,9,9,9,90];%%全局CFAR阈值

%% 0804CFAR:210-501m:rCMLD,CA;501-801m:rCA,cGOO;801-1200m:rCMLD,vGO,其余GO,new OK
CFAR_RANGE_THRESHOLD = [22,16,16,12,15,90];
CFAR_DOPPLER_THRESHOLD = [19,15,14,12,12,100];
CFAR_GLOBAL_THRESHOLD = [15,13,12,12,11,90];

% %% 0420CFAR——rCA,VGO-2 3代雷达基础版本OK
% CFAR_RANGE_THRESHOLD = [22,16,13,12,12.5,90];%%距离维CFAR阈值
% CFAR_DOPPLER_THRESHOLD = [19,15,13,12,13,100];%%速度维CFAR阈值
% CFAR_GLOBAL_THRESHOLD = [15,13,12,12,11,90];%%全局CFAR阈值


%% 上限
% %% 0320CFAR——上限
% CFAR_RANGE_THRESHOLD_end = [60,60,45,26,26,90];%%距离维CFAR阈值
% CFAR_DOPPLER_THRESHOLD_end = [50,35,42,26,26,90];%%距离维CFAR阈值
% CFAR_GLOBAL_THRESHOLD_end = [50,43,42,30,30,90];%%距离维CFAR阈值

% %% 0420CFAR——上限 OK
% CFAR_RANGE_THRESHOLD_end = [60,50,35,26,24,90];%%距离维CFAR阈值
% CFAR_DOPPLER_THRESHOLD_end = [52,45,38,30,24,90];%%距离维CFAR阈值
% CFAR_GLOBAL_THRESHOLD_end = [55,48,36,28,24,90];%%距离维CFAR阈值

%% 0620CFAR—3rd Gen Radar
CFAR_RANGE_THRESHOLD_end = [80,80,80,80,80,90];%%距离维CFAR阈值
CFAR_DOPPLER_THRESHOLD_end = [80,80,80,80,80,90];%%距离维CFAR阈值
CFAR_GLOBAL_THRESHOLD_end = [80,80,80,80,80,90];%%距离维CFAR阈值

% SNR = [CFAR_RANGE_THRESHOLD(end-1),CFAR_DOPPLER_THRESHOLD(end-1),CFAR_GLOBAL_THRESHOLD(end-1)];%%仅看RSNR > SNR的检测点
SNR = [0,0,0];

%% =======================================1、mode=1时修改参数，第1部分end，跳转130行修改第2部分的参数 =============================================%%
probR_plot = probR;

N_pro = length(Range_THRESHOLD);
MAG_THRESHOLD_start(1:2:N_pro) = MAG_THRESHOLD_st;%%距离维mag阈值下限
MAG_THRESHOLD_start(2:2:N_pro) = MAG_THRESHOLD_st;%%距离维mag阈值下限
MAG_THRESHOLD_end(1:2:N_pro) = MAG_THRESHOLD_ed;%%距离维mag阈值上限   
MAG_THRESHOLD_end(2:2:N_pro) = MAG_THRESHOLD_ed;%%距离维mag阈值上限  

N_r = 2*(length(rangeSegment)-1);
rangeSegment_Plot(1:2:N_r) = rangeSegment(1:end-1);%%CFAR距离分段
rangeSegment_Plot(2:2:N_r) = rangeSegment(2:end);%%CFAR距离分段[0,rangeSegment(1:end-1)]
CFAR_RANGE_THRESHOLD_endPlot(1:2:N_r) = CFAR_RANGE_THRESHOLD_end(1:end-1);%%距离维CFAR阈值下限
CFAR_RANGE_THRESHOLD_endPlot(2:2:N_r) = CFAR_RANGE_THRESHOLD_end(1:end-1);%%距离维CFAR阈值下限
CFAR_DOPPLER_THRESHOLD_endPlot(1:2:N_r) = CFAR_DOPPLER_THRESHOLD_end(1:end-1);%%速度维CFAR阈值上限   
CFAR_DOPPLER_THRESHOLD_endPlot(2:2:N_r) = CFAR_DOPPLER_THRESHOLD_end(1:end-1);%%速度维CFAR阈值上限  
CFAR_GLOBAL_THRESHOLD_endPlot(1:2:N_r) = CFAR_GLOBAL_THRESHOLD_end(1:end-1);%%全局CFAR阈值上限   
CFAR_GLOBAL_THRESHOLD_endPlot(2:2:N_r) = CFAR_GLOBAL_THRESHOLD_end(1:end-1);%%全局CFAR阈值上限  

%% =======================================2、mode=1时修改参数，第2部分start =============================================%%


%% D:\ACUR100_ADC\0.adc\5thGenRadar\1016\T5-5#-alg32-A7-50d6c
Xw = [131578,135756];%%远离帧号，临近2点为1条直线
Yw = [414,768];%%远离距离，与帧号一一对应，由近及远依次选取
WframeID = [126732,142421];%%远离不同直线段的分段帧ID，1条直线就是起始2个帧ID，中间多加一条直线，就在起始值中间加上对应的分段帧ID（2段直线，邻近两两为1次起始，共3个分段帧ID）

%%靠近检测点——仅远离时，靠近参数可不更新，不影响计算
Xf = [150972,154461];%%靠近帧号，临近2点为1条直线
Yf = [657,363];%%靠近距离，与帧号一一对应，由远及近依次选取
FframeID = [142421,158789];%%靠近不同直线段的起始帧ID，1条直线就是起始2个帧ID，中间多加一条直线，就在起始值中间加上对应的分段帧ID（2段直线，邻近两两为1次起始，共3个分段帧ID）

% %% E:\3.data\1.adc\3GenRadar\0705\精灵4远离560_originalADC
% Xw = [273070,282391];%%远离帧号，临近2点为1条直线
% Yw = [51,486];%%远离距离，与帧号一一对应，由近及远依次选取
% WframeID = [271903,294010];%%远离不同直线段的分段帧ID，1条直线就是起始2个帧ID，中间多加一条直线，就在起始值中间加上对应的分段帧ID（2段直线，邻近两两为1次起始，共3个分段帧ID）
% 
% %%靠近检测点——仅远离时，靠近参数可不更新，不影响计算
% Xf = [205328,207687];%%靠近帧号，临近2点为1条直线
% Yf = [165,63];%%靠近距离，与帧号一一对应，由远及近依次选取
% FframeID = [186237,208933];%%靠近不同直线段的起始帧ID，1条直线就是起始2个帧ID，中间多加一条直线，就在起始值中间加上对应的分段帧ID（2段直线，邻近两两为1次起始，共3个分段帧ID）


%% =======================================2、mode=1时修改参数，第2部分end，下面无需修改 =============================================%%

