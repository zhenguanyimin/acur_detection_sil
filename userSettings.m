%% Resolution ——by hxj
c = 3e8;
f = 24.1e9;%%24GHz,24.1GHz
TD = 270e-6;%%460us,260us.265us
NumSample = 2048;
NumChirp = 32;
T_frame = TD * NumChirp;%%总的TX发波时长
lambda = (c/f);
% BW = 4096/25/205*50*1e6;%%带宽39.961MHz
BW = 50000000;

Rres = c/(2*BW);
Rmax_ideal = Rres * NumSample;%%最大距离

Vres = lambda/(2*T_frame);
VMax = lambda/(4*TD);

% ADCdataPath = 'D:\7.data\20221220_adc\ADC_pingshi_azi10ele0_25m_kongcai_3';
% ADCdataPath = 'D:\7.data\20221220_adc\ADC_pingshi_azi0ele0_25m_kongcai_3';
% dataTitle = '对空方位±10°，俯仰0°扫描-巴车空采';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\1220_adc\ADC_pingshi_azi10ele0_25m_kongcai_3';%%每帧处理结果图保存路径

% ADCdataPath = 'D:\7.data\20221213_adc\ADC_duikong_JL4wangfan_azi20ele5_200m_2mps_1';
% dataTitle = '对空方位±20°，俯仰±5°扫描-无人机200m往返';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\1213_adc\ADC_duikong_JL4wangfan_azi20ele5_200m_2mps_1_sil_master_RvM\rangeBin13_mtd2^6';%%每帧处理结果图保存路径

% ADCdataPath = 'D:\7.data\20230106AM1111_ADCdata';
% dataTitle = '7ev底噪';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\20231106_7evNoise\20230106AM1111_ADCdata';%%每帧处理结果图保存路径

% ADCdataPath = 'D:\7.data\20221126_adc\duikong_JL4_azi0ele0_100-50m_kaojin_2mps';%%
% dataTitle = '雷达对空单波位00-精灵4无人机100-50m靠近-2m/s';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\1126_adc\duikong_JL4_azi0ele0_100-50m_kaojin_2mps_RvM\rangeBin15_mtd2^6';%%每帧处理结果图保存路径
% 
% ADCdataPath = 'Z:\射频测试\反无雷达\20230109雷达采无人机数据（公司旁小山顶）\ADC数据\wureji-daboshu-10mi-500mwangfan-3mps-2';
% % ADCdataPath = 'Z:\射频测试\反无雷达\adcdizao';
% dataTitle = '小山坡精灵4无人机500m往返-3m/s——对空单波位';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0109_wureji-daboshu-10mi-500mwangfan-3mps';%%每帧处理结果图保存路径

% ADCdataPath = 'D:\ACUR100_ADC\0.adc\20230111\ADC_duikong_autel_Jiaofan_azi0ele0_500m_3mps';
% dataTitle = '小山坡（EV2+角反+锡纸）无人机500m往返-3m/s——对空单波位';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0111\test_duikong_autel_Jiaofan_azi0ele0_500m_3mps\all_Fram_gap16';%%每帧处理结果图保存路径

% ADCdataPath = 'R:\路试测试组\ACUR100测试\2023年1月\0113\ADC\ADC_duikong_azi0ele0_EV2_JiaoFan_800mwangfan_3mps';
% dataTitle = '小山坡（EV2+角反+锡纸）无人机800m往返-3m/s——对空单波位';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0113\ADC_duikong_azi0ele0_EV2_JiaoFan_800mwangfan_3mps\all_Fram_gap16_choseRV';%%每帧处理结果图保存路径

% ADCdataPath = 'Z:\路试测试组\ACUR100测试\2023年1月\0119\ADC\pingshi_danbowei_900m_3mps_1';
% dataTitle = '惠州宝塔山，精灵4无人机900m，3m/s远离，0119平视单波位ADC——R-CA26-V-CA44——newCFARcutDC';%%数据主题描述，优化结果，0113实测结果
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA26-V_CA44_newCFAR_cutDC';%%每帧处理结果图保存路径
% % savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA44-V_CA44_cutDC';%%每帧处理结果图保存路径

% ADCdataPath = 'D:\ACUR100_ADC\0.adc\20230111\ADC_duikong_JL4_azi30ele5_500m_4mps_9bit_1';
% dataTitle = '小山坡（精灵4）无人机500m往返-4m/s——对空单波位';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0111\test_duikong_JL4_azi30ele5_500m_4mps_9bit\all_Fram_gap16';%%每帧处理结果图保存路径

% ADCdataPath = 'R:\射频测试\反无雷达\20230112雷达采模拟器数据\采模拟器ADC数据-模拟器目标200米发射衰减30-1';
% dataTitle = '模拟器目标200米发射衰减30';%%数据主题描述
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0113\采模拟器ADC数据-模拟器目标200米发射衰减30-1';%%每帧处理结果图保存路径

% ADCdataPath = 'D:\ACUR100_ADC\0.adc\20230204anshiTest\TRfullEnable_anshi_kongcai_afterDebug';
% dataTitle = '惠州宝塔山，精灵4无人机900m，3m/s远离，0119平视单波位ADC——R-CA26-V-CA44——newCFARcutDC';%%数据主题描述，优化结果，0113实测结果
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA26-V_CA44_newCFAR_cutDC';%%每帧处理结果图保存路径
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA44-V_CA44_cutDC';%%每帧处理结果图保存路径

% ADCdataPath = 'R:\路试测试组\ACUR100测试\2023年2月\0204\ADC\ADCduikong_JL4wangfan_azi0ele0_500m_3mps';
    
%     rBin = 13;
%     frameIdxList = 1240:1:1318;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改
%     vBin = 6;

%     rBin = 21;
%     frameIdxList = 2141:1:2231;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改
%     vBin = 6;

%     rBin = 31;
%     frameIdxList = 3283;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改
% %     frameIdxList = 3261:1:3342;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改
%     vBin = 6;

%     rBin = 48;
%     frameIdxList = 5081:1:5141;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改
%     vBin = 6;

%     rBin = 7;
%     frameIdxList = 2:1:fileNum/2;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改    
%     vBin = 32;



%% 单波位
%     rBin = 11;
%     frameIdxList = 721:1:801;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改    
%     vBin = 6;

%     rBin = 15;
%     frameIdxList = 2061:1:2181;%%1:20:fileNum/2，1:20:fileNum，读取数据帧下标范围！！！！！！！！！！！！！！！！！！！！！！！可修改    
%     vBin = 28;
