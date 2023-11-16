clc;
clear
close all
algoVersion='';
addpath('functions');
addpath('xfft_v9_1_bitacc_cmodel_nt64');
userSettings;
%% ============================== 1.参数修改,start ===================================%%
global HIST_THRESHOLD_GUARD  RDM_MAG_PER_HIST_BIN_EXP sp RANGE_BIN_ENABLE cutDC RANGE_BIN DOPPLER_BIN scanMode savePicsPath ADCdataPath
global NumScan Vres Rres processGap dataTitle azimuthEnable elevationEnable useNumScan RDMdataPath
global AgeGap TableLen_Zheng TableLen_Fu Table_Zheng Table_Fu lambda D WaveForm radarID calcLostFrameID enableAB comparePL_flag

WaveForm = 4;%%波形1：原始4096*32，265ms波形；波形2：线性度提升4096*32，315ms波形；波形3：1024*128；波形4：315和265ms波形切换；默认4
Rwinid = 1;%加窗类型，0：矩形窗；1：汉明窗；2：凯撒窗；3：切比雪夫窗；4：海宁窗；默认1
Dwinid = 1;%加窗类型，0：矩形窗；1：汉明窗；2：凯撒窗；3：切比雪夫窗；4：海宁窗；默认1
RANGE_BIN_ENABLE = 512;%%只对前256bin做阈值计算及CFAR处理，默认256
azimuthEnable = 60;%%处理数据时只考虑方位15°内的波位，法线默认20
elevationEnable = 20;%%处理数据时只考虑俯仰10°内的波位，默认10
inputDataType = 0; %% 0 - ADC data; 1 - rdmap，默认0

truncationFlag = 1; %% drop bits off or not是否做截位处理，1是，0否,默认1
enableAB = 0; %%是否输出AB通道rdmap和IQ数据，1是，0否,默认0
comparePL_flag = 1; %%是否与PL输出rdmap做对比，1是，0否,默认0


%% =================== 模式参数，修改(1)-start ========================%%
%% （模式1）单帧RDMap
RDmapPlot = 0;%%是否画RDMAP：1是，0否
RDmapSave = 0;%%是否保存每帧处理结果图：1是，0否
noisePlot = 0;%%是否画底噪：1是，0否，默认0
calcLostFrameID = 0;%%是否统计丢帧情况：1是，0否；默认0

%% （模式2）所有帧出无人机轨迹图
detectionPlot = 1;%%是否画选定所有帧的检测输出：1是，0否
savePicsFlag = 0;%%是否保存处理结果：1是，0否
processGap = 1;%%数据处理间隔帧数，默认1


%% （模式3）模式2（2参数全部使能）得出无人机轨迹图后，修改realTarParameter.m里面参数,筛选无人机目标
detectProcess = 0;%%是否检测点筛选（无人机目标/杂散点）：1是，0否,=========== ！！！！注意：跑完ADC数据得到检测点后再使能1处理 ！！！！============
scanMode = 1;%%波束扫描范围：0单波位(无需修改TrackScanBeamSet)，1扫描模式(需修改TrackScanBeamSet),默认1
TrackScanBeamSet = [0 24 0 88];%%指令配置的扫描范围：全扫描[0 36 0 120],方位±44，俯仰±15：[0 36 0 88],方位±44，俯仰±9：[0 24 0 88]扫描范围配置[0 20 0 88][0 40 0 120] ============================修改

%%检测结构体输出字段
% detectResT.Properties.VariableNames=[{'FrameId'} {'range'} {'doppler'} {'mag'} {'rangeSnrTh'} {'dopplerSnrTh'} {'rangeSnr'} {'dopplerSnr'} {'globalSnr_hist'} {'globalSnr_meanNoise'} ...
%     {'AzimuthBeam'} {'ElevationBeam'} {'trackTwsTasFlag'} {'waveType'} {'Azimuth_compareAmp'} {'Azimuth_comparePhaseHeCha'} ...
%  if enableAB:    {'Azimuth_comparePhaseAB'} {'magSub'} {'magSum'} {'ratio_subSum'} {'magA'} {'magB'} {'phaseA-phaseB'} ];

%% 数据对应的雷达编号：4代 401/402/403/405/407/408/409/410 #;5代 502/503/505/506 #
radarID = 505;%%5代3#

%% 数据路径
ADCdataPath = 'D:\ACUR100_ADC\0.adc\PLvsSiL\1025\1025_originalADC\';%%ADC数据路径
RDMdataPath = 'D:\ACUR100_ADC\0.adc\PLvsSiL\1025\1025_RDMAP\';%%rdmap数据路径
dataTitle = '0418天台（精灵4）600m往返-5m/s，平视方位±44°，俯仰±9°扫描,只开接收温补ADC—基础版本—9dBCFAR—直方图5格平均';%%数据主题描述，R-GO26-V-GO46, 0406 9dB调优CFAR, R-CA35-V-CA56—检出率>0.7的CFAR , R-GO35-V-GO46
% savePicsPath = 'E:\3.data\1.adc\3GenRadar\0629\1#_eb2300_024088_温补52D60_originalADC\detection_9dB';%%每帧处理结果图保存路径
savePicsPath = [ADCdataPath,'detection_2Azi_DropBits_compare3'];%%每帧处理结果图保存路径



%% 数据处理范围选取
if (inputDataType == 1)
    dirpath=(RDMdataPath);
else
    dirpath=(ADCdataPath);
end
addpath(dirpath)
fileName='*.dat';
%     cd(dirpath);
namelist = dir([dirpath,fileName]);
fileNum=length(namelist);
fileSortId=zeros(fileNum,1);
for i=1:fileNum
    iframe=str2double(namelist(i,1).name(1:end-4));
    fileSortId(i)=iframe;
end 

%%ADC数据读取范围设置
if (RDmapPlot) %% 指定帧处理+adc和rdmap结果图输出
    if (calcLostFrameID)
        specificFrameId = [fileSortId(1):fileSortId(end)];  % [283534:288322] [280366:281423] [280366,280367,280450] specify frames to be analysed,单帧处理，rdmap
    else
        specificFrameId = [17655:17755];%%需处理的帧ID方范围
    end
    [~, frameIdxList] = ismember(specificFrameId, fileSortId);
%     frameIdxList = 1:fileNum;%%10:10:fileNum
elseif (detectionPlot) %%批量处理
    
%% （1）处理该路径下的所有数据，默认
    frameIdxList = 1:processGap:fileNum; %1:1:fileNum,批量处理，1:processGap:fileNum;  12240:processGap:17028;  

%% （2）处理指定帧号的数据
% specificFrameId = [600:1830];
% [~, frameIdxList] = ismember(specificFrameId, fileSortId);

%% （3）仅处理与PL端的rdmap对齐的帧
%     cd(savePicsPath)
%     load comparePL_List.mat
%     Idx_use = find(comparePL_List(2,:)==1);
%     specificFrameId = comparePL_List(1,Idx_use);
%     [~, frameIdxList] = ismember(specificFrameId, fileSortId);
    
else
    frameIdxList = 0;
end

%% =================== 模式参数，修改(1)-end ========================%%

%% ============================== 1.参数修改,end ===================================%%
if (calcLostFrameID)
    figure;plot(specificFrameId,specificFileIndex,'*-');title('丢帧情况，帧号下标为0的是丢失的帧');
    xlabel('帧号FrameID');ylabel('帧号下标');
end

%% =================== 默认参数，不修改start ========================%%
HIST_THRESHOLD_GUARD = 3;%%直方图底噪+（HIST_THRESHOLD_GUARD * RDM_MAG_PER_HIST_BIN_EXP）/256*3.01,对极值点做peacksearch,一般设置成3（即9dB）
RDM_MAG_PER_HIST_BIN_EXP = 256;%%直方图底噪量化单元，256/512
histogram_col = 64; %%直方图底噪量化个数，rdmap能量值[0,histogram_col]*RDM_MAG_PER_HIST_BIN_EXP，64/32
cutDC = 0;%%是否进行去直流偏置操作：1是，0否,默认1

% truncationFlag = 1; %% drop bits off or not是否做截位处理，1是，0否,默认1
cfarFlag = 1;%%是否进行CFAR处理：1是，0否,默认1
pickSpecificBeam = 0;%%是否筛选特定波位点：1是，0否,默认0
choseRV = 0;%%是否筛选固定距离和速度的检测点：1是，0否,默认0

if ( WaveForm == 1 )
    RANGE_BIN = 4096;%%采样点数4096/1024
    DOPPLER_BIN = 32;%%chirp数32/128
    TD = 265e-6;%%chirp周期：4096*32波形：265us ；1024*128波形：70us
elseif ( WaveForm == 2 )
    RANGE_BIN = 4096;%%采样点数4096/1024
    DOPPLER_BIN = 32;%%chirp数32/128
    TD = 315e-6;%%chirp周期：线性度提升4096*32波形：315us ；1024*128波形：70us
elseif ( WaveForm == 3 )
    RANGE_BIN = 1024;%%采样点数4096/1024
    DOPPLER_BIN = 128;%%chirp数32/128
    TD = 70e-6;%%chirp周期：4096*32波形：315us ；1024*128波形：70us
elseif ( WaveForm == 4 ) %%AB帧切换
    RANGE_BIN = 4096;%%采样点数4096/1024
    DOPPLER_BIN = 32;%%chirp数32/128
    TD = 315e-6;%%chirp周期：0波形315us
    TD1 = 265e-6;%%chirp周期：1波形265us   
end

%% 和差比曲线表
%%正负表
TableLen_Zheng = 200;%%±4°:400，±2°:200
TableLen_Fu = 200;%%±4°:400，±2°:200
AgeGap = 0.01;
%%10*log10，幅值平方,暂时不用
% Table_Zheng(1:TableLen_Zheng) = [ 0.0000, 0.0000, 0.0000, 0.0001, 0.0001, 0.0002, 0.0002, 0.0003, 0.0004, 0.0005, 0.0006, 0.0007, 0.0009, 0.0010, 0.0012, 0.0014, 0.0015, 0.0017, 0.0019, 0.0022, 0.0024, 0.0027, 0.0029, 0.0032, 0.0035, 0.0038, 0.0041, 0.0044, 0.0047, 0.0051, 0.0054, 0.0058, 0.0062, 0.0066, 0.0070, 0.0074, 0.0078, 0.0083, 0.0087, 0.0092, 0.0096, 0.0101, 0.0106, 0.0112, 0.0117, 0.0122, 0.0128, 0.0133, 0.0139, 0.0145, 0.0151, 0.0157, 0.0163, 0.0170, 0.0176, 0.0183, 0.0190, 0.0196, 0.0203, 0.0211, 0.0218, 0.0225, 0.0233, 0.0240, 0.0248, 0.0256, 0.0264, 0.0272, 0.0280, 0.0289, 0.0297, 0.0306, 0.0314, 0.0323, 0.0332, 0.0341, 0.0351, 0.0360, 0.0369, 0.0379, 0.0389, 0.0399, 0.0409, 0.0419, 0.0429, 0.0440, 0.0450, 0.0461, 0.0472, 0.0482, 0.0494, 0.0505, 0.0516, 0.0527, 0.0539, 0.0551, 0.0563, 0.0574, 0.0587, 0.0599, 0.0611, 0.0624, 0.0636, 0.0649, 0.0662, 0.0675, 0.0688, 0.0701, 0.0715, 0.0728, 0.0742, 0.0756, 0.0770, 0.0784, 0.0798, 0.0813, 0.0827, 0.0842, 0.0856, 0.0871, 0.0886, 0.0902, 0.0917, 0.0932, 0.0948, 0.0964, 0.0980, 0.0996, 0.1012, 0.1028, 0.1045, 0.1061, 0.1078, 0.1095, 0.1112, 0.1129, 0.1146, 0.1164, 0.1181, 0.1199, 0.1217, 0.1235, 0.1253, 0.1271, 0.1290, 0.1308, 0.1327, 0.1346, 0.1365, 0.1384, 0.1404, 0.1423, 0.1443, 0.1462, 0.1482, 0.1502, 0.1523, 0.1543, 0.1564, 0.1584, 0.1605, 0.1626, 0.1647, 0.1669, 0.1690, 0.1712, 0.1733, 0.1755, 0.1777, 0.1800, 0.1822, 0.1845, 0.1867, 0.1890, 0.1913, 0.1936, 0.1960, 0.1983, 0.2007, 0.2031, 0.2055, 0.2079, 0.2103, 0.2128, 0.2152, 0.2177, 0.2202, 0.2227, 0.2252, 0.2278, 0.2303, 0.2329, 0.2355, 0.2381, 0.2408, 0.2434, 0.2461, 0.2488, 0.2514, 0.2542, 0.2569, 0.2596, 0.2624, 0.2652, 0.2680, 0.2708, 0.2737, 0.2765, 0.2794, 0.2823, 0.2852, 0.2881, 0.2911, 0.2940, 0.2970, 0.3000, 0.3030, 0.3061, 0.3091, 0.3122, 0.3153, 0.3184, 0.3215, 0.3247, 0.3278, 0.3310, 0.3342, 0.3374, 0.3407, 0.3439, 0.3472, 0.3505, 0.3539, 0.3572, 0.3606, 0.3639, 0.3673, 0.3707, 0.3742, 0.3776, 0.3811, 0.3846, 0.3881, 0.3917, 0.3952, 0.3988, 0.4024, 0.4060, 0.4097, 0.4133, 0.4170, 0.4207, 0.4245, 0.4282, 0.4320, 0.4358, 0.4396, 0.4434, 0.4473, 0.4511, 0.4550, 0.4590, 0.4629, 0.4669, 0.4708, 0.4749, 0.4789, 0.4829, 0.4870, 0.4911, 0.4952, 0.4994, 0.5035, 0.5077, 0.5119, 0.5162, 0.5204, 0.5247, 0.5290, 0.5334, 0.5377, 0.5421, 0.5465, 0.5509, 0.5554, 0.5599, 0.5644, 0.5689, 0.5734, 0.5780, 0.5826, 0.5872, 0.5919, 0.5965, 0.6012, 0.6060, 0.6107, 0.6155, 0.6203, 0.6251, 0.6300, 0.6349, 0.6398, 0.6447, 0.6497, 0.6547, 0.6597, 0.6647, 0.6698, 0.6749, 0.6800, 0.6851, 0.6903, 0.6955, 0.7008, 0.7060, 0.7113, 0.7166, 0.7220, 0.7274, 0.7328, 0.7382, 0.7437, 0.7492, 0.7547, 0.7602, 0.7658, 0.7714, 0.7771, 0.7827, 0.7884, 0.7942, 0.7999, 0.8057, 0.8115, 0.8174, 0.8233, 0.8292, 0.8351, 0.8411, 0.8471, 0.8532, 0.8593, 0.8654, 0.8715, 0.8777, 0.8839, 0.8901, 0.8964, 0.9027, 0.9091, 0.9154, 0.9218, 0.9283, 0.9348, 0.9413, 0.9478, 0.9544, 0.9610, 0.9677, 0.9744, 0.9811, 0.9879, 0.9946, 1.0015, 1.0083, 1.0153, 1.0222, 1.0292, 1.0362, 1.0432, 1.0503, 1.0575, 1.0646, 1.0718, 1.0791, 1.0864, 1.0937, 1.1011, 1.1085, 1.1159, 1.1234, 1.1309, 1.1385, 1.1461, 1.1537, 1.1614, 1.1691, 1.1769, 1.1847, 1.1925, 1.2004, 1.2084, 1.2164, 1.2244, 1.2324, 1.2406, 1.2487, 1.2569, 1.2651, 1.2734 ];
% Table_Fu(1:TableLen_Fu) = [ 0.0000, 0.0000, 0.0000, 0.0001, 0.0001, 0.0002, 0.0002, 0.0003, 0.0004, 0.0005, 0.0006, 0.0007, 0.0009, 0.0010, 0.0012, 0.0014, 0.0015, 0.0017, 0.0019, 0.0022, 0.0024, 0.0027, 0.0029, 0.0032, 0.0035, 0.0038, 0.0041, 0.0044, 0.0047, 0.0051, 0.0054, 0.0058, 0.0062, 0.0066, 0.0070, 0.0074, 0.0078, 0.0083, 0.0087, 0.0092, 0.0096, 0.0101, 0.0106, 0.0112, 0.0117, 0.0122, 0.0128, 0.0133, 0.0139, 0.0145, 0.0151, 0.0157, 0.0163, 0.0170, 0.0176, 0.0183, 0.0190, 0.0196, 0.0203, 0.0211, 0.0218, 0.0225, 0.0233, 0.0240, 0.0248, 0.0256, 0.0264, 0.0272, 0.0280, 0.0289, 0.0297, 0.0306, 0.0314, 0.0323, 0.0332, 0.0341, 0.0351, 0.0360, 0.0369, 0.0379, 0.0389, 0.0399, 0.0409, 0.0419, 0.0429, 0.0440, 0.0450, 0.0461, 0.0472, 0.0482, 0.0494, 0.0505, 0.0516, 0.0527, 0.0539, 0.0551, 0.0563, 0.0574, 0.0587, 0.0599, 0.0611, 0.0624, 0.0636, 0.0649, 0.0662, 0.0675, 0.0688, 0.0701, 0.0715, 0.0728, 0.0742, 0.0756, 0.0770, 0.0784, 0.0798, 0.0813, 0.0827, 0.0842, 0.0856, 0.0871, 0.0886, 0.0902, 0.0917, 0.0932, 0.0948, 0.0964, 0.0980, 0.0996, 0.1012, 0.1028, 0.1045, 0.1061, 0.1078, 0.1095, 0.1112, 0.1129, 0.1146, 0.1164, 0.1181, 0.1199, 0.1217, 0.1235, 0.1253, 0.1271, 0.1290, 0.1308, 0.1327, 0.1346, 0.1365, 0.1384, 0.1404, 0.1423, 0.1443, 0.1462, 0.1482, 0.1502, 0.1523, 0.1543, 0.1564, 0.1584, 0.1605, 0.1626, 0.1647, 0.1669, 0.1690, 0.1712, 0.1733, 0.1755, 0.1777, 0.1800, 0.1822, 0.1845, 0.1867, 0.1890, 0.1913, 0.1936, 0.1960, 0.1983, 0.2007, 0.2031, 0.2055, 0.2079, 0.2103, 0.2128, 0.2152, 0.2177, 0.2202, 0.2227, 0.2252, 0.2278, 0.2303, 0.2329, 0.2355, 0.2381, 0.2408, 0.2434, 0.2461, 0.2488, 0.2514, 0.2542, 0.2569, 0.2596, 0.2624, 0.2652, 0.2680, 0.2708, 0.2737, 0.2765, 0.2794, 0.2823, 0.2852, 0.2881, 0.2911, 0.2940, 0.2970, 0.3000, 0.3030, 0.3061, 0.3091, 0.3122, 0.3153, 0.3184, 0.3215, 0.3247, 0.3278, 0.3310, 0.3342, 0.3374, 0.3407, 0.3439, 0.3472, 0.3505, 0.3539, 0.3572, 0.3606, 0.3639, 0.3673, 0.3707, 0.3742, 0.3776, 0.3811, 0.3846, 0.3881, 0.3917, 0.3952, 0.3988, 0.4024, 0.4060, 0.4097, 0.4133, 0.4170, 0.4207, 0.4245, 0.4282, 0.4320, 0.4358, 0.4396, 0.4434, 0.4473, 0.4511, 0.4550, 0.4590, 0.4629, 0.4669, 0.4708, 0.4749, 0.4789, 0.4829, 0.4870, 0.4911, 0.4952, 0.4994, 0.5035, 0.5077, 0.5119, 0.5162, 0.5204, 0.5247, 0.5290, 0.5334, 0.5377, 0.5421, 0.5465, 0.5509, 0.5554, 0.5599, 0.5644, 0.5689, 0.5734, 0.5780, 0.5826, 0.5872, 0.5919, 0.5965, 0.6012, 0.6060, 0.6107, 0.6155, 0.6203, 0.6251, 0.6300, 0.6349, 0.6398, 0.6447, 0.6497, 0.6547, 0.6597, 0.6647, 0.6698, 0.6749, 0.6800, 0.6851, 0.6903, 0.6955, 0.7008, 0.7060, 0.7113, 0.7166, 0.7220, 0.7274, 0.7328, 0.7382, 0.7437, 0.7492, 0.7547, 0.7602, 0.7658, 0.7714, 0.7771, 0.7827, 0.7884, 0.7942, 0.7999, 0.8057, 0.8115, 0.8174, 0.8233, 0.8292, 0.8351, 0.8411, 0.8471, 0.8532, 0.8593, 0.8654, 0.8715, 0.8777, 0.8839, 0.8901, 0.8964, 0.9027, 0.9091, 0.9154, 0.9218, 0.9283, 0.9348, 0.9413, 0.9478, 0.9544, 0.9610, 0.9677, 0.9744, 0.9811, 0.9879, 0.9946, 1.0015, 1.0083, 1.0153, 1.0222, 1.0292, 1.0362, 1.0432, 1.0503, 1.0575, 1.0646, 1.0718, 1.0791, 1.0864, 1.0937, 1.1011, 1.1085, 1.1159, 1.1234, 1.1309, 1.1385, 1.1461, 1.1537, 1.1614, 1.1691, 1.1769, 1.1847, 1.1925, 1.2004, 1.2084, 1.2164, 1.2244, 1.2324, 1.2406, 1.2487, 1.2569, 1.2651, 1.2734 ];

% %%20*log10，sqrt(幅值平方),±4°
% Table_Zheng(1:TableLen_Zheng) = [ 0.0025, 0.0049, 0.0074, 0.0098, 0.0123, 0.0147, 0.0172, 0.0196, 0.0221, 0.0245, 0.0270, 0.0294, 0.0319, 0.0343, 0.0368, 0.0392, 0.0417, 0.0442, 0.0466, 0.0491, 0.0515, 0.0540, 0.0564, 0.0589, 0.0613, 0.0638, 0.0662, 0.0687, 0.0712, 0.0736, 0.0761, 0.0785, 0.0810, 0.0835, 0.0859, 0.0884, 0.0908, 0.0933, 0.0958, 0.0982, 0.1007, 0.1031, 0.1056, 0.1081, 0.1105, 0.1130, 0.1155, 0.1179, 0.1204, 0.1229, 0.1253, 0.1278, 0.1303, 0.1327, 0.1352, 0.1377, 0.1401, 0.1426, 0.1451, 0.1476, 0.1500, 0.1525, 0.1550, 0.1575, 0.1599, 0.1624, 0.1649, 0.1674, 0.1699, 0.1723, 0.1748, 0.1773, 0.1798, 0.1823, 0.1848, 0.1872, 0.1897, 0.1922, 0.1947, 0.1972, 0.1997, 0.2022, 0.2047, 0.2072, 0.2097, 0.2122, 0.2147, 0.2172, 0.2197, 0.2222, 0.2247, 0.2272, 0.2297, 0.2322, 0.2347, 0.2372, 0.2397, 0.2422, 0.2447, 0.2472, 0.2497, 0.2522, 0.2548, 0.2573, 0.2598, 0.2623, 0.2648, 0.2674, 0.2699, 0.2724, 0.2749, 0.2775, 0.2800, 0.2825, 0.2851, 0.2876, 0.2901, 0.2927, 0.2952, 0.2977, 0.3003, 0.3028, 0.3054, 0.3079, 0.3104, 0.3130, 0.3155, 0.3181, 0.3206, 0.3232, 0.3258, 0.3283, 0.3309, 0.3334, 0.3360, 0.3386, 0.3411, 0.3437, 0.3463, 0.3488, 0.3514, 0.3540, 0.3566, 0.3591, 0.3617, 0.3643, 0.3669, 0.3695, 0.3721, 0.3746, 0.3772, 0.3798, 0.3824, 0.3850, 0.3876, 0.3902, 0.3928, 0.3954, 0.3980, 0.4006, 0.4033, 0.4059, 0.4085, 0.4111, 0.4137, 0.4163, 0.4190, 0.4216, 0.4242, 0.4269, 0.4295, 0.4321, 0.4348, 0.4374, 0.4400, 0.4427, 0.4453, 0.4480, 0.4506, 0.4533, 0.4559, 0.4586, 0.4612, 0.4639, 0.4666, 0.4692, 0.4719, 0.4746, 0.4773, 0.4799, 0.4826, 0.4853, 0.4880, 0.4907, 0.4934, 0.4961, 0.4987, 0.5014, 0.5041, 0.5069, 0.5096, 0.5123, 0.5150, 0.5177, 0.5204, 0.5231, 0.5258, 0.5286, 0.5313, 0.5340, 0.5368, 0.5395, 0.5422, 0.5450, 0.5477, 0.5505, 0.5532, 0.5560, 0.5587, 0.5615, 0.5643, 0.5670, 0.5698, 0.5726, 0.5753, 0.5781, 0.5809, 0.5837, 0.5865, 0.5893, 0.5921, 0.5949, 0.5977, 0.6005, 0.6033, 0.6061, 0.6089, 0.6117, 0.6145, 0.6174, 0.6202, 0.6230, 0.6258, 0.6287, 0.6315, 0.6344, 0.6372, 0.6401, 0.6429, 0.6458, 0.6486, 0.6515, 0.6544, 0.6572, 0.6601, 0.6630, 0.6659, 0.6688, 0.6717, 0.6746, 0.6775, 0.6804, 0.6833, 0.6862, 0.6891, 0.6920, 0.6949, 0.6979, 0.7008, 0.7037, 0.7067, 0.7096, 0.7126, 0.7155, 0.7185, 0.7214, 0.7244, 0.7273, 0.7303, 0.7333, 0.7363, 0.7393, 0.7422, 0.7452, 0.7482, 0.7512, 0.7542, 0.7572, 0.7603, 0.7633, 0.7663, 0.7693, 0.7724, 0.7754, 0.7784, 0.7815, 0.7845, 0.7876, 0.7907, 0.7937, 0.7968, 0.7999, 0.8029, 0.8060, 0.8091, 0.8122, 0.8153, 0.8184, 0.8215, 0.8246, 0.8277, 0.8309, 0.8340, 0.8371, 0.8403, 0.8434, 0.8465, 0.8497, 0.8529, 0.8560, 0.8592, 0.8624, 0.8655, 0.8687, 0.8719, 0.8751, 0.8783, 0.8815, 0.8847, 0.8879, 0.8912, 0.8944, 0.8976, 0.9009, 0.9041, 0.9073, 0.9106, 0.9139, 0.9171, 0.9204, 0.9237, 0.9270, 0.9303, 0.9335, 0.9369, 0.9402, 0.9435, 0.9468, 0.9501, 0.9534, 0.9568, 0.9601, 0.9635, 0.9668, 0.9702, 0.9736, 0.9769, 0.9803, 0.9837, 0.9871, 0.9905, 0.9939, 0.9973, 1.0007, 1.0042, 1.0076, 1.0110, 1.0145, 1.0179, 1.0214, 1.0249, 1.0283, 1.0318, 1.0353, 1.0388, 1.0423, 1.0458, 1.0493, 1.0528, 1.0564, 1.0599, 1.0634, 1.0670, 1.0705, 1.0741, 1.0777, 1.0813, 1.0848, 1.0884, 1.0920, 1.0956, 1.0993, 1.1029, 1.1065, 1.1102, 1.1138, 1.1175, 1.1211, 1.1248, 1.1285 ];
% Table_Fu(1:TableLen_Fu) = [ 0.0025, 0.0049, 0.0074, 0.0098, 0.0123, 0.0147, 0.0172, 0.0196, 0.0221, 0.0245, 0.0270, 0.0294, 0.0319, 0.0343, 0.0368, 0.0392, 0.0417, 0.0442, 0.0466, 0.0491, 0.0515, 0.0540, 0.0564, 0.0589, 0.0613, 0.0638, 0.0662, 0.0687, 0.0712, 0.0736, 0.0761, 0.0785, 0.0810, 0.0835, 0.0859, 0.0884, 0.0908, 0.0933, 0.0958, 0.0982, 0.1007, 0.1031, 0.1056, 0.1081, 0.1105, 0.1130, 0.1155, 0.1179, 0.1204, 0.1229, 0.1253, 0.1278, 0.1303, 0.1327, 0.1352, 0.1377, 0.1401, 0.1426, 0.1451, 0.1476, 0.1500, 0.1525, 0.1550, 0.1575, 0.1599, 0.1624, 0.1649, 0.1674, 0.1699, 0.1723, 0.1748, 0.1773, 0.1798, 0.1823, 0.1848, 0.1872, 0.1897, 0.1922, 0.1947, 0.1972, 0.1997, 0.2022, 0.2047, 0.2072, 0.2097, 0.2122, 0.2147, 0.2172, 0.2197, 0.2222, 0.2247, 0.2272, 0.2297, 0.2322, 0.2347, 0.2372, 0.2397, 0.2422, 0.2447, 0.2472, 0.2497, 0.2522, 0.2548, 0.2573, 0.2598, 0.2623, 0.2648, 0.2674, 0.2699, 0.2724, 0.2749, 0.2775, 0.2800, 0.2825, 0.2851, 0.2876, 0.2901, 0.2927, 0.2952, 0.2977, 0.3003, 0.3028, 0.3054, 0.3079, 0.3104, 0.3130, 0.3155, 0.3181, 0.3206, 0.3232, 0.3258, 0.3283, 0.3309, 0.3334, 0.3360, 0.3386, 0.3411, 0.3437, 0.3463, 0.3488, 0.3514, 0.3540, 0.3566, 0.3591, 0.3617, 0.3643, 0.3669, 0.3695, 0.3721, 0.3746, 0.3772, 0.3798, 0.3824, 0.3850, 0.3876, 0.3902, 0.3928, 0.3954, 0.3980, 0.4006, 0.4033, 0.4059, 0.4085, 0.4111, 0.4137, 0.4163, 0.4190, 0.4216, 0.4242, 0.4269, 0.4295, 0.4321, 0.4348, 0.4374, 0.4400, 0.4427, 0.4453, 0.4480, 0.4506, 0.4533, 0.4559, 0.4586, 0.4612, 0.4639, 0.4666, 0.4692, 0.4719, 0.4746, 0.4773, 0.4799, 0.4826, 0.4853, 0.4880, 0.4907, 0.4934, 0.4961, 0.4987, 0.5014, 0.5041, 0.5069, 0.5096, 0.5123, 0.5150, 0.5177, 0.5204, 0.5231, 0.5258, 0.5286, 0.5313, 0.5340, 0.5368, 0.5395, 0.5422, 0.5450, 0.5477, 0.5505, 0.5532, 0.5560, 0.5587, 0.5615, 0.5643, 0.5670, 0.5698, 0.5726, 0.5753, 0.5781, 0.5809, 0.5837, 0.5865, 0.5893, 0.5921, 0.5949, 0.5977, 0.6005, 0.6033, 0.6061, 0.6089, 0.6117, 0.6145, 0.6174, 0.6202, 0.6230, 0.6258, 0.6287, 0.6315, 0.6344, 0.6372, 0.6401, 0.6429, 0.6458, 0.6486, 0.6515, 0.6544, 0.6572, 0.6601, 0.6630, 0.6659, 0.6688, 0.6717, 0.6746, 0.6775, 0.6804, 0.6833, 0.6862, 0.6891, 0.6920, 0.6949, 0.6979, 0.7008, 0.7037, 0.7067, 0.7096, 0.7126, 0.7155, 0.7185, 0.7214, 0.7244, 0.7273, 0.7303, 0.7333, 0.7363, 0.7393, 0.7422, 0.7452, 0.7482, 0.7512, 0.7542, 0.7572, 0.7603, 0.7633, 0.7663, 0.7693, 0.7724, 0.7754, 0.7784, 0.7815, 0.7845, 0.7876, 0.7907, 0.7937, 0.7968, 0.7999, 0.8029, 0.8060, 0.8091, 0.8122, 0.8153, 0.8184, 0.8215, 0.8246, 0.8277, 0.8309, 0.8340, 0.8371, 0.8403, 0.8434, 0.8465, 0.8497, 0.8529, 0.8560, 0.8592, 0.8624, 0.8655, 0.8687, 0.8719, 0.8751, 0.8783, 0.8815, 0.8847, 0.8879, 0.8912, 0.8944, 0.8976, 0.9009, 0.9041, 0.9073, 0.9106, 0.9139, 0.9171, 0.9204, 0.9237, 0.9270, 0.9303, 0.9335, 0.9369, 0.9402, 0.9435, 0.9468, 0.9501, 0.9534, 0.9568, 0.9601, 0.9635, 0.9668, 0.9702, 0.9736, 0.9769, 0.9803, 0.9837, 0.9871, 0.9905, 0.9939, 0.9973, 1.0007, 1.0042, 1.0076, 1.0110, 1.0145, 1.0179, 1.0214, 1.0249, 1.0283, 1.0318, 1.0353, 1.0388, 1.0423, 1.0458, 1.0493, 1.0528, 1.0564, 1.0599, 1.0634, 1.0670, 1.0705, 1.0741, 1.0777, 1.0813, 1.0848, 1.0884, 1.0920, 1.0956, 1.0993, 1.1029, 1.1065, 1.1102, 1.1138, 1.1175, 1.1211, 1.1248, 1.1285 ];

%20*log10，sqrt(幅值平方),±2°
Table_Zheng(1:TableLen_Zheng) = [ 0.0025, 0.0049, 0.0074, 0.0098, 0.0123, 0.0147, 0.0172, 0.0196, 0.0221, 0.0245, 0.0270, 0.0294, 0.0319, 0.0343, 0.0368, 0.0392, 0.0417, 0.0442, 0.0466, 0.0491, 0.0515, 0.0540, 0.0564, 0.0589, 0.0613, 0.0638, 0.0662, 0.0687, 0.0712, 0.0736, 0.0761, 0.0785, 0.0810, 0.0835, 0.0859, 0.0884, 0.0908, 0.0933, 0.0958, 0.0982, 0.1007, 0.1031, 0.1056, 0.1081, 0.1105, 0.1130, 0.1155, 0.1179, 0.1204, 0.1229, 0.1253, 0.1278, 0.1303, 0.1327, 0.1352, 0.1377, 0.1401, 0.1426, 0.1451, 0.1476, 0.1500, 0.1525, 0.1550, 0.1575, 0.1599, 0.1624, 0.1649, 0.1674, 0.1699, 0.1723, 0.1748, 0.1773, 0.1798, 0.1823, 0.1848, 0.1872, 0.1897, 0.1922, 0.1947, 0.1972, 0.1997, 0.2022, 0.2047, 0.2072, 0.2097, 0.2122, 0.2147, 0.2172, 0.2197, 0.2222, 0.2247, 0.2272, 0.2297, 0.2322, 0.2347, 0.2372, 0.2397, 0.2422, 0.2447, 0.2472, 0.2497, 0.2522, 0.2548, 0.2573, 0.2598, 0.2623, 0.2648, 0.2674, 0.2699, 0.2724, 0.2749, 0.2775, 0.2800, 0.2825, 0.2851, 0.2876, 0.2901, 0.2927, 0.2952, 0.2977, 0.3003, 0.3028, 0.3054, 0.3079, 0.3104, 0.3130, 0.3155, 0.3181, 0.3206, 0.3232, 0.3258, 0.3283, 0.3309, 0.3334, 0.3360, 0.3386, 0.3411, 0.3437, 0.3463, 0.3488, 0.3514, 0.3540, 0.3566, 0.3591, 0.3617, 0.3643, 0.3669, 0.3695, 0.3721, 0.3746, 0.3772, 0.3798, 0.3824, 0.3850, 0.3876, 0.3902, 0.3928, 0.3954, 0.3980, 0.4006, 0.4033, 0.4059, 0.4085, 0.4111, 0.4137, 0.4163, 0.4190, 0.4216, 0.4242, 0.4269, 0.4295, 0.4321, 0.4348, 0.4374, 0.4400, 0.4427, 0.4453, 0.4480, 0.4506, 0.4533, 0.4559, 0.4586, 0.4612, 0.4639, 0.4666, 0.4692, 0.4719, 0.4746, 0.4773, 0.4799, 0.4826, 0.4853, 0.4880, 0.4907, 0.4934, 0.4961, 0.4987, 0.5014, 0.5041, 0.5069 ];
Table_Fu(1:TableLen_Fu) = [ 0.0025, 0.0049, 0.0074, 0.0098, 0.0123, 0.0147, 0.0172, 0.0196, 0.0221, 0.0245, 0.0270, 0.0294, 0.0319, 0.0343, 0.0368, 0.0392, 0.0417, 0.0442, 0.0466, 0.0491, 0.0515, 0.0540, 0.0564, 0.0589, 0.0613, 0.0638, 0.0662, 0.0687, 0.0712, 0.0736, 0.0761, 0.0785, 0.0810, 0.0835, 0.0859, 0.0884, 0.0908, 0.0933, 0.0958, 0.0982, 0.1007, 0.1031, 0.1056, 0.1081, 0.1105, 0.1130, 0.1155, 0.1179, 0.1204, 0.1229, 0.1253, 0.1278, 0.1303, 0.1327, 0.1352, 0.1377, 0.1401, 0.1426, 0.1451, 0.1476, 0.1500, 0.1525, 0.1550, 0.1575, 0.1599, 0.1624, 0.1649, 0.1674, 0.1699, 0.1723, 0.1748, 0.1773, 0.1798, 0.1823, 0.1848, 0.1872, 0.1897, 0.1922, 0.1947, 0.1972, 0.1997, 0.2022, 0.2047, 0.2072, 0.2097, 0.2122, 0.2147, 0.2172, 0.2197, 0.2222, 0.2247, 0.2272, 0.2297, 0.2322, 0.2347, 0.2372, 0.2397, 0.2422, 0.2447, 0.2472, 0.2497, 0.2522, 0.2548, 0.2573, 0.2598, 0.2623, 0.2648, 0.2674, 0.2699, 0.2724, 0.2749, 0.2775, 0.2800, 0.2825, 0.2851, 0.2876, 0.2901, 0.2927, 0.2952, 0.2977, 0.3003, 0.3028, 0.3054, 0.3079, 0.3104, 0.3130, 0.3155, 0.3181, 0.3206, 0.3232, 0.3258, 0.3283, 0.3309, 0.3334, 0.3360, 0.3386, 0.3411, 0.3437, 0.3463, 0.3488, 0.3514, 0.3540, 0.3566, 0.3591, 0.3617, 0.3643, 0.3669, 0.3695, 0.3721, 0.3746, 0.3772, 0.3798, 0.3824, 0.3850, 0.3876, 0.3902, 0.3928, 0.3954, 0.3980, 0.4006, 0.4033, 0.4059, 0.4085, 0.4111, 0.4137, 0.4163, 0.4190, 0.4216, 0.4242, 0.4269, 0.4295, 0.4321, 0.4348, 0.4374, 0.4400, 0.4427, 0.4453, 0.4480, 0.4506, 0.4533, 0.4559, 0.4586, 0.4612, 0.4639, 0.4666, 0.4692, 0.4719, 0.4746, 0.4773, 0.4799, 0.4826, 0.4853, 0.4880, 0.4907, 0.4934, 0.4961, 0.4987, 0.5014, 0.5041, 0.5069 ];


%% 和差通道间距
D = 0.0058*8;%%A路和B路阵列间距，单元间隔5.8mm，8个单元

%% 容错处理
if (RDmapPlot)
    detectionPlot = 0;
    savePicsFlag = 0;%%是否保存每帧处理结果图：1是，0否
    detectProcess = 0;
end

if(savePicsFlag)
%% 根据上述保存路径自动创建文件夹
if ~exist(savePicsPath,'dir')
    a=['mkdir ' savePicsPath];%创建命令
    system(a);%创建文件夹
end
end

if (comparePL_flag)
    truncationFlag = 1; %% drop bits off or not是否做截位处理，1是，0否,默认1
end

%% =================== 默认参数，不修改end ========================%%

%%  ===================== Resolution ——by hxj ============================%%
c = 3e8;
f = 24.1e9;%%24GHz,24.1GHz
% TD = 265e-6;%%帧周期：4096*32波形：265us ；1024*128波形：74us
NumSample = RANGE_BIN / 2;%%FFT后谱对称，只取单边谱
NumChirp = DOPPLER_BIN;
T_frame = TD * NumChirp;%%帧周期
lambda = (c/f);
BW = RANGE_BIN/20*(1000/RANGE_BIN)*1e6;%%带宽50MHz

Rres = c/(2*BW);
Rmax_ideal = Rres * NumSample;%%最大距离

Vres = lambda/(2*T_frame);
if ( WaveForm == 4 )
    Vres1 = lambda/(2*TD1 * NumChirp);
end
VMax = lambda/(4*TD);

Tf_frame = TD * 1e3 * NumChirp;%%一个波位的时间

%% 距离分段
% rangeSegment = [6,30,210,405,636,1290];%%CFAR距离分段，m
% rangeSegment = [6,51,210,327,630,720];%%距离分段
% rangeSegment = [6,51,210,327,630,1110];%%距离分段
rangeSegment = [6,51,210,501,801,1200];%%距离分段
detectResT = zeros(3e4,12);
PeakResT = zeros(3e4,12);

%% ===================== 扫描范围配置，目前只需修改第1行TrackScanBeamSet ============================%%
% scanMode = 0;%%波束扫描范围：0单波位(无需修改TrackScanBeamSet)，1扫描模式(需修改TrackScanBeamSet),默认1
% TrackScanBeamSet = [0 24 0 88];%%指令配置的扫描范围：全扫描[0 36 0 120],方位±44，俯仰±15：[0 36 0 88],方位±44，俯仰±9：[0 24 0 88]扫描范围配置[0 20 0 88][0 40 0 120] ============================修改
aziJG = 4;%%方位扫描间隔，默认4 ============================修改
eleJG = 6;%%方位扫描间隔，默认6，10 ============================修改

if (scanMode == 0)
    if (length(fileSortId)>1)
        NumScan = 1*(fileSortId(2)-fileSortId(1));
    else
        NumScan = 1;
    end
    useNumScan = 1;
else
    fov_azi = -(TrackScanBeamSet(4)/2-aziJG/2):aziJG:TrackScanBeamSet(4)/2;
    fov_ele = -(TrackScanBeamSet(2)/2-eleJG/2):eleJG:TrackScanBeamSet(2)/2;
    N_azi = length(fov_azi);
    N_ele = length(fov_ele);

    fov_ele2 = fov_ele(end:-1:1).';%%
    fov_scan = [fov_ele2.*ones(N_ele,N_azi);fov_azi];

    % fovPlot_azi = fov_azi( abs(fov_azi) <= choseAE(1) );

    if (length(fileSortId) > 2)
        NumScan = N_azi * N_ele *(fileSortId(2)-fileSortId(1));%%扫描波位总数：方位±60°，俯仰±15°全扫描总数（30*4）
    else
        NumScan = N_azi * N_ele ;
    end
%     NumScan = N_azi * N_ele * (fileSortId(2)-fileSortId(1));
    
    %% 计算处理的有效波位数
    useAziIdx = find( abs(fov_scan(end,:)) < azimuthEnable);
    useEleIdx = find( abs(fov_scan(:,1)) < elevationEnable);
    useNumScan = length(useAziIdx) * length(useEleIdx);
    
end


%% ============================== 2.数据处理 ===================================%%
%% 模式3-往返曲线拟合筛选
if (detectProcess == 1)
    [usefulDetectList,usefulDetToClot,detectProb_plot] = choseRealTarget;
    return;
end

%% reading data
allDetNum=0;
allpeakDetNum=0;


II = 0;

aziBeamList = zeros(1,fileNum);
pitchBeamList = zeros(1,fileNum);

if (comparePL_flag)
    comparePL_List = zeros(2,fileNum);
end

for iFlie = frameIdxList
    if(iFlie==0)
        continue;
    end
    II = II + 1;
    iFlie
    if inputDataType == 1
        if(namelist(iFlie).bytes ~= 2*RANGE_BIN*DOPPLER_BIN +128) %% 512k,256K+256K,+128
            return;
        end 
        file_name = namelist(iFlie).name; 

        Idx = 1;
        uniqueFrameNum = 1;
        Nts = 1;
        Nps = 1;
        K = 0;
        
        %获取文件路径
        fileID = fopen(file_name,'r');
        rdmap_bin_data = fread(fileID);
        fclose(fileID);
        
         rdmap_bin_data = rdmap_bin_data(129:end); 
        rdmap_ps = zeros(RANGE_BIN/2,DOPPLER_BIN);

        for row = 1 :RANGE_BIN/2
            for col = 1 : DOPPLER_BIN
                rdmap_ps(row,col) = rdmap_bin_data((row-1)*DOPPLER_BIN*4+(col-1)*4+2)*256+rdmap_bin_data((row-1)*DOPPLER_BIN*4+(col-1)*4+1) ;
            end 
        end
        
        rdmap = rdmap_ps;
%        rdmap(1,5) = rdmap(1,6);
    
    elseif inputDataType==0
    %     dirpath=uigetdir('D:\work\ACUR100\test data\20221013zhiyuanlouxia\dat035');
    %     dirpath=('D:\work\ACUR100\test data\20221013zhiyuanlouxia\dat035');
        frameIDarray=cell(fileNum,1);

        TargetAll = cell(1,fileNum);
        PeakTargetAll = cell(1,fileNum);
        TargetList = [];
        PeakTargetList = [];
        FrameIDall = zeros(1,fileNum);
        
        if (calcLostFrameID == 0)
        aziBeamList = zeros(1,fileNum);
        pitchBeamList = zeros(1,fileNum);
        end
        
        DClist = zeros(1,fileNum);
        choseTarget = zeros(10,6*fileNum);
        Idx = 1;  
        uniqueFrameNum = 1;
        Nts = 1;
        Nps = 1;
        K = 0;
        [rWin, dWin] = generateWin(Rwinid,Dwinid);
    

        str = namelist(iFlie,1).name;
        FrameID = str2double(str(isstrprop(str,'digit')));
%         if(mod((FrameID-64780),88)~=0)
%             continue;
%         end
tic
        %% 0. ADC processing
        if( truncationFlag == 1 )
%             [info,adc_data_deal,rdmap,mtd_data_sumIQ,mtd_data_subIQ,DC] = getRdmapFromADC16_16bit(namelist,iFlie,cfarFlag,rWin,dWin);
            if (enableAB)
                [info,adc_data_deal,rdmap,rdmapAB,mtd_data_sumIQ,mtd_data_subIQ,mtd_data_ABIQ,DC,comparePL] = getRdmapFromADC16_16bit_AB(namelist,iFlie,cfarFlag,rWin,dWin);
            else
                [info,adc_data_deal,rdmap,mtd_data_sumIQ,mtd_data_subIQ,DC,comparePL] = getRdmapFromADC16_16bit(namelist,iFlie,cfarFlag,rWin,dWin);
            end
%             fprintf('getRdmapFromADC function time %f\n',toc);
        else
            if (enableAB)
                [info,adc_data_deal,rdmap,rdmapAB,mtd_data_sumIQ,mtd_data_subIQ,mtd_data_ABIQ,DC] = getRdmapFromADC_withoutDropout_AB(namelist,iFlie,cfarFlag,rWin,dWin);
            else
                [info,adc_data_deal,rdmap,mtd_data_sumIQ,mtd_data_subIQ,DC] = getRdmapFromADC_withoutDropout(namelist,iFlie,cfarFlag,rWin,dWin);
            end         
        end
        if(size(adc_data_deal,1)==1)
            continue;
        end
        
        if (comparePL_flag)
            comparePL_List(:,iFlie) = comparePL;
            continue;
        end
        
        aziBeam = info.azimuth;
        eleBeam = info.elevation;       
        aziBeamList(iFlie) = aziBeam;
        pitchBeamList(iFlie) = eleBeam;
        DClist(iFlie) = DC;
%         RDmap{K} = rdmap;  
        if (enableAB)
                rdmapA = rdmapAB{1};
                rdmapB = rdmapAB{2};
                rd_AIQ = mtd_data_ABIQ{1};
                rd_BIQ = mtd_data_ABIQ{2};
        end
        if (pickSpecificBeam == 1)
            if aziBeam ~= -23
                continue;
            end
        end
        
    end
    %%新加
    if (calcLostFrameID)
        continue;
    end

%     load rdmap_ps.mat
%     diff = rdmap_ps(1:RANGE_BIN_ENABLE,:) - rdmap;
%     figure,mesh(diff);title('ADC处理的rdmap与实测输出rdmap的差值');
    
        rdmap = rdmap(1:RANGE_BIN_ENABLE,:);
                      
        if (RDmapPlot == 1)
%         if (0)
%             if (enableAB)
            if (0)
                figure;
                subplot(211),mesh(rdmapA);title([[namelist(iFlie,1).name,'，azimuth = ',num2str(aziBeam),' pitch = ',num2str(eleBeam)],"RDMAP-chA"]);
                subplot(212),mesh(rdmapB);title([[namelist(iFlie,1).name,'，azimuth = ',num2str(aziBeam),' pitch = ',num2str(eleBeam)],"RDMAP-chB"]);
            end
            
            figure(iFlie)
            set(gcf,'unit','centimeters','position',[20 1 15 18])
            if inputDataType==0   
                subplot(211)
                hold on
                for iRow = 1:size(adc_data_deal,1)
                    plot(adc_data_deal(iRow,:)),hold on;
    %                 plot(ones(size(adc_data_deal(iRow,:)))*DC),hold on;
                end  
                xlabel('samples');title(['ADC data  azimuth = ',num2str(aziBeam),' pitch = ',num2str(eleBeam)]);
                subplot(212)
                hold on
            end
            mesh(rdmap);title([namelist(iFlie,1).name,"RDMAP"])               
                       
        end
        
        if (cfarFlag == 1)

            sp.nrRangeBins = size(rdmap,1);
            sp.nrDopplerBins = size(rdmap,2);
%             histogram_col = 64;       % rdmap is bits of uint32
            detectObjData.rdmapData = rdmap;
            detectObjData.histBuff = zeros(sp.nrRangeBins,histogram_col);
            detectObjData.hististMaxIndex = zeros(sp.nrRangeBins,1);
            detectObjData.threshold = zeros(sp.nrRangeBins,1);
            detectObjData.peakBitmap = zeros(sp.nrRangeBins,sp.nrDopplerBins);
            %% 1. histogram statistic
            [detectObjData.histBuff, meanNoiseBuff,detectObjData.meanNoiseMag] =  CalcHistogram(detectObjData.rdmapData,histogram_col);
%             fprintf('CalcHistogram function time %f\n',toc);
            %% 2. calculate noise power threshold
            [detectObjData.hististMaxIndex, detectObjData.threshold,detectObjData.noiseMag] = CalcThreshold(detectObjData.histBuff,meanNoiseBuff);
%             fprintf('CalcThreshold function time %f\n',toc);
            %% 3. generate bitmap
            [detectObjData.peakBitmap,gPeakNum] = CalcPeakSearchBitmap(detectObjData.rdmapData, detectObjData.threshold);
%             fprintf('CalcPeakSearchBitmap function time %f\n',toc);
            %% 4. cfar
            [Target_Para, target_num, PeakTarget_Para] = CfarDetection(detectObjData.rdmapData, detectObjData.peakBitmap, detectObjData.threshold, detectObjData.noiseMag);
%             fprintf('CfarDetection function time %f\n',toc);
            %% 5. calculate azimuth
            if inputDataType == 1
                Target_Para_out = Target_Para;
                FrameID = 1;
                aziBeam = 0;
                eleBeam = 0;                
            else
%                 [Target_Para_out] = calcAzimuth_heCha(Target_Para,mtd_data_sumIQ,mtd_data_subIQ,aziBeam);
                if (enableAB)
                    [Target_Para_out] = calcAzimuth_heCha_AB(Target_Para,mtd_data_sumIQ,mtd_data_subIQ,mtd_data_ABIQ,aziBeam,eleBeam);
                else
                    [Target_Para_out] = calcAzimuth_heCha(Target_Para,mtd_data_sumIQ,mtd_data_subIQ,aziBeam,eleBeam);
                end
            end

            %% 6. store results
            %%%detectResT:
            %%%FrameID,R,V,mag,rMagThrd,dMagThrd,rSNR,dSNR,gSNR_hist,gSNR_noise,azimuth_compareAe,azimuth_comparePhase,classification,elevation
            N_tarPare = size(Target_Para_out,1);
            if(target_num>0) 
                detectResT(allDetNum+1:allDetNum+target_num,1) = FrameID;
                detectResT(allDetNum+1:allDetNum+target_num,2:1+N_tarPare) = Target_Para_out';
                detectResT(allDetNum+1:allDetNum+target_num,2+size(Target_Para,1))= aziBeam;
                detectResT(allDetNum+1:allDetNum+target_num,3+size(Target_Para,1)) = eleBeam;
                detectResT(allDetNum+1:allDetNum+target_num,4+size(Target_Para,1)) = info.trackTwsTasFlag;
                detectResT(allDetNum+1:allDetNum+target_num,5+size(Target_Para,1)) = info.waveType;
                if (enableAB)
                    for ii = 1:target_num
                        iR = Target_Para_out(1,ii) + 1;
                        iD = Target_Para_out(2,ii);
                        detectResT(allDetNum+ii,2+N_tarPare) = rdmapA(iR,iD)/256*3.0103;%%A通道幅值     
                        detectResT(allDetNum+ii,3+N_tarPare) = rdmapB(iR,iD)/256*3.0103;%%B通道幅值   
                        detectResT(allDetNum+ii,4+N_tarPare) = (angle(rd_AIQ(iR,iD))-angle(rd_BIQ(iR,iD)))/pi*180;%%A-B通道相位差 
                        if (detectResT(allDetNum+ii,4+N_tarPare) > 180)
                            detectResT(allDetNum+ii,4+N_tarPare) = detectResT(allDetNum+ii,4+N_tarPare) - 360;
                        elseif (detectResT(allDetNum+ii,4+N_tarPare) < -180)
                            detectResT(allDetNum+ii,4+N_tarPare) = detectResT(allDetNum+ii,4+N_tarPare) + 360;
                        end
                    end
                end
                
            end
            allDetNum = allDetNum + target_num;
            
            peak_num = size(PeakTarget_Para,2);
            N_peakPare = size(PeakTarget_Para,1);
            if( peak_num > 0 )
                PeakResT(allpeakDetNum+1:allpeakDetNum+peak_num,1) = FrameID;
                PeakResT(allpeakDetNum+1:allpeakDetNum+peak_num,2:1+N_peakPare) = PeakTarget_Para';
                PeakResT(allpeakDetNum+1:allpeakDetNum+peak_num,2+N_peakPare) = aziBeam;
                PeakResT(allpeakDetNum+1:allpeakDetNum+peak_num,3+N_peakPare) = eleBeam;
                PeakResT(allpeakDetNum+1:allpeakDetNum+peak_num,4+N_peakPare) = info.trackTwsTasFlag;
                PeakResT(allpeakDetNum+1:allpeakDetNum+peak_num,5+N_peakPare) = info.waveType;
                if (enableAB)
                    for ii = 1:peak_num
                        iR = PeakTarget_Para(1,ii) + 1;
                        iD = PeakTarget_Para(2,ii);
                        PeakResT(allpeakDetNum+ii,3+N_peakPare) = rdmapA(iR,iD)/256*3.0103;%%A通道幅值     
                        PeakResT(allpeakDetNum+ii,4+N_peakPare) = rdmapB(iR,iD)/256*3.0103;%%B通道幅值 
                        PeakResT(allpeakDetNum+ii,5+N_peakPare) = angle(rd_AIQ(iR,iD)-rd_BIQ(iR,iD))/pi*180;%%A-B通道相位差
                    end
                end
            end
            allpeakDetNum = allpeakDetNum + peak_num;
                    
        if(RDmapPlot)
            postProcess;
        end
        
        end
%         toc
%     end

end

if (calcLostFrameID)
    % figure,plot(aziBeamList,pitchBeamList);
    figure,plot(fileSortId,aziBeamList);title(ADCdataPath,'FontSize',12);xlabel("帧号frameID",'FontSize',14);ylabel("方位角(°)",'FontSize',14);
    figure,plot(fileSortId,pitchBeamList);title(ADCdataPath,'FontSize',12);xlabel("帧号frameID",'FontSize',14);ylabel("俯仰角(°)",'FontSize',14);
    return;
end

%% plot
allDetIdx = find(detectResT(:,1)>0);
allDetNum = length(allDetIdx);
detectResT = detectResT(1:allDetNum,:);

allPeakIdx = find(PeakResT(:,1)>0);
allPeakNum = length(allPeakIdx);
PeakResT = PeakResT(1:allPeakNum,:);

%%
if ( allDetNum > 0 )
 dopplerBinList = 1:sp.nrDopplerBins;
 for ii = 1:sp.nrDopplerBins
     tmpDopplerBin = dopplerBinList(ii)-1;%%MATLAB下标从1开始
     if (tmpDopplerBin >= sp.nrDopplerBins/2) %%-16~15
         tmpDopplerBin = tmpDopplerBin - sp.nrDopplerBins;%% + 1
     end
     dopplerBinList(ii) = tmpDopplerBin;%% + 1
 end
 for ii = 1:allDetNum
     dopplerBinIdx = detectResT(ii,3);
     dopplerBin = dopplerBinList(dopplerBinIdx);
     detectResT(ii,3) = dopplerBin;
 end
 
  for jj = 1:allPeakNum     
     peakDopplerBinIdx = PeakResT(jj,3);
     peakDopplerBin = dopplerBinList(peakDopplerBinIdx);
     PeakResT(jj,3) = peakDopplerBin;
  end
 
detectResT(:,2) = detectResT(:,2)*Rres;
if ( WaveForm == 4 )
    Idx0 = find(detectResT(:,14) == 0);
    Idx1 = find(detectResT(:,14) == 1);
    detectResT(Idx0,3) = detectResT(Idx0,3)*Vres;
    detectResT(Idx1,3) = detectResT(Idx1,3)*Vres1;
else
    detectResT(:,3) = detectResT(:,3)*Vres;
end

PeakResT(:,2) = PeakResT(:,2)*Rres;
if ( WaveForm == 4 )
    Idx0 = find(PeakResT(:,14) == 0);
    Idx1 = find(PeakResT(:,14) == 1);
    PeakResT(Idx0,3) = PeakResT(Idx0,3)*Vres;
    PeakResT(Idx1,3) = PeakResT(Idx1,3)*Vres1;
else
    PeakResT(:,3) = PeakResT(:,3)*Vres;
end
 
figure(fileNum + 100),hold on;
plot3(detectResT(1:allDetNum,1),detectResT(1:allDetNum,2),detectResT(1:allDetNum,3),'.')
grid on
title(ADCdataPath,'FontSize',14);
 
if(savePicsFlag)
    
%% 保存图形
cd(savePicsPath)
saveas(gcf, 'FrameID_R-V', 'fig')

%% 保存所有检测点数据
savePath = [savePicsPath '\detectResT.mat'];
save(savePath,'detectResT');  % 保存到其他文件夹的写法
   
end

% figure(2),hold on;
% plot3(brushedData(:,1),detectResT(:,2)*Rres,detectResT(:,3)*Vres,'.')
% grid on
% 
% figure(2),hold on;
% for kk = brushedData(1,1):NumScan:brushedData(end,1)
%     plot(kk+zeros(1,length(1:rangeSegment(end-1))),[1:rangeSegment(end-1)],'g-');hold on;
% end

%% plot
% % allDetNum=size(detectResT,1);
% detectResT=detectResT(1:allDetNum,:);
% figure
% plot3(detectResT(1:allDetNum,1),detectResT(1:allDetNum,2)*3,detectResT(1:allDetNum,3)*0.72,'.')
% grid on

end



% figure,hold on;plot3(detectResT(:,1),detectResT(:,2),detectResT(:,3),'b*')
% load detectResT.mat
% plot3(detectResT(:,1),detectResT(:,2),detectResT(:,3),'ro')
% legend('不截位','截位')

if (comparePL_flag)
    
Idx = find(comparePL_List(1,:)>0);
comparePL_List = comparePL_List(:,Idx);
[~,idx] = sort(comparePL_List(1,:)); 
comparePL_List = comparePL_List(:,idx); 
figure,plot(comparePL_List(1,:),comparePL_List(2,:),'-*');title('rdmap对齐结果，1为对齐，255为未对齐，0为rdmap数据丢包或异常','FontSize',14)
xlabel("帧号frameID",'FontSize',14);ylabel("d对齐结果",'FontSize',14);


%% 保存图形
cd(savePicsPath)
saveas(gcf, 'FrameID_alignFlag', 'fig')

if(savePicsFlag)
    %% 保存rdmap对齐信息
    savePath = [savePicsPath '\comparePL_List.mat'];
    save(savePath,'comparePL_List');  % 保存到其他文件夹的写法
end

end


