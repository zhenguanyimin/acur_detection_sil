%% Resolution ����by hxj
c = 3e8;
f = 24.1e9;%%24GHz,24.1GHz
TD = 270e-6;%%460us,260us.265us
NumSample = 2048;
NumChirp = 32;
T_frame = TD * NumChirp;%%�ܵ�TX����ʱ��
lambda = (c/f);
% BW = 4096/25/205*50*1e6;%%����39.961MHz
BW = 50000000;

Rres = c/(2*BW);
Rmax_ideal = Rres * NumSample;%%������

Vres = lambda/(2*T_frame);
VMax = lambda/(4*TD);

% ADCdataPath = 'D:\7.data\20221220_adc\ADC_pingshi_azi10ele0_25m_kongcai_3';
% ADCdataPath = 'D:\7.data\20221220_adc\ADC_pingshi_azi0ele0_25m_kongcai_3';
% dataTitle = '�Կշ�λ��10�㣬����0��ɨ��-�ͳ��ղ�';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\1220_adc\ADC_pingshi_azi10ele0_25m_kongcai_3';%%ÿ֡������ͼ����·��

% ADCdataPath = 'D:\7.data\20221213_adc\ADC_duikong_JL4wangfan_azi20ele5_200m_2mps_1';
% dataTitle = '�Կշ�λ��20�㣬������5��ɨ��-���˻�200m����';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\1213_adc\ADC_duikong_JL4wangfan_azi20ele5_200m_2mps_1_sil_master_RvM\rangeBin13_mtd2^6';%%ÿ֡������ͼ����·��

% ADCdataPath = 'D:\7.data\20230106AM1111_ADCdata';
% dataTitle = '7ev����';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\20231106_7evNoise\20230106AM1111_ADCdata';%%ÿ֡������ͼ����·��

% ADCdataPath = 'D:\7.data\20221126_adc\duikong_JL4_azi0ele0_100-50m_kaojin_2mps';%%
% dataTitle = '�״�Կյ���λ00-����4���˻�100-50m����-2m/s';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\1126_adc\duikong_JL4_azi0ele0_100-50m_kaojin_2mps_RvM\rangeBin15_mtd2^6';%%ÿ֡������ͼ����·��
% 
% ADCdataPath = 'Z:\��Ƶ����\�����״�\20230109�״�����˻����ݣ���˾��Сɽ����\ADC����\wureji-daboshu-10mi-500mwangfan-3mps-2';
% % ADCdataPath = 'Z:\��Ƶ����\�����״�\adcdizao';
% dataTitle = 'Сɽ�¾���4���˻�500m����-3m/s�����Կյ���λ';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0109_wureji-daboshu-10mi-500mwangfan-3mps';%%ÿ֡������ͼ����·��

% ADCdataPath = 'D:\ACUR100_ADC\0.adc\20230111\ADC_duikong_autel_Jiaofan_azi0ele0_500m_3mps';
% dataTitle = 'Сɽ�£�EV2+�Ƿ�+��ֽ�����˻�500m����-3m/s�����Կյ���λ';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0111\test_duikong_autel_Jiaofan_azi0ele0_500m_3mps\all_Fram_gap16';%%ÿ֡������ͼ����·��

% ADCdataPath = 'R:\·�Բ�����\ACUR100����\2023��1��\0113\ADC\ADC_duikong_azi0ele0_EV2_JiaoFan_800mwangfan_3mps';
% dataTitle = 'Сɽ�£�EV2+�Ƿ�+��ֽ�����˻�800m����-3m/s�����Կյ���λ';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0113\ADC_duikong_azi0ele0_EV2_JiaoFan_800mwangfan_3mps\all_Fram_gap16_choseRV';%%ÿ֡������ͼ����·��

% ADCdataPath = 'Z:\·�Բ�����\ACUR100����\2023��1��\0119\ADC\pingshi_danbowei_900m_3mps_1';
% dataTitle = '���ݱ���ɽ������4���˻�900m��3m/sԶ�룬0119ƽ�ӵ���λADC����R-CA26-V-CA44����newCFARcutDC';%%���������������Ż������0113ʵ����
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA26-V_CA44_newCFAR_cutDC';%%ÿ֡������ͼ����·��
% % savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA44-V_CA44_cutDC';%%ÿ֡������ͼ����·��

% ADCdataPath = 'D:\ACUR100_ADC\0.adc\20230111\ADC_duikong_JL4_azi30ele5_500m_4mps_9bit_1';
% dataTitle = 'Сɽ�£�����4�����˻�500m����-4m/s�����Կյ���λ';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0111\test_duikong_JL4_azi30ele5_500m_4mps_9bit\all_Fram_gap16';%%ÿ֡������ͼ����·��

% ADCdataPath = 'R:\��Ƶ����\�����״�\20230112�״��ģ��������\��ģ����ADC����-ģ����Ŀ��200�׷���˥��30-1';
% dataTitle = 'ģ����Ŀ��200�׷���˥��30';%%������������
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0113\��ģ����ADC����-ģ����Ŀ��200�׷���˥��30-1';%%ÿ֡������ͼ����·��

% ADCdataPath = 'D:\ACUR100_ADC\0.adc\20230204anshiTest\TRfullEnable_anshi_kongcai_afterDebug';
% dataTitle = '���ݱ���ɽ������4���˻�900m��3m/sԶ�룬0119ƽ�ӵ���λADC����R-CA26-V-CA44����newCFARcutDC';%%���������������Ż������0113ʵ����
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA26-V_CA44_newCFAR_cutDC';%%ÿ֡������ͼ����·��
% savePicsPath = 'E:\0.anti-drone\1.MATLABworkspace\6.rdnapFigureSave\2023\0119ADC\pingshi_danbowei_900m_3mps_1\R_CA44-V_CA44_cutDC';%%ÿ֡������ͼ����·��

% ADCdataPath = 'R:\·�Բ�����\ACUR100����\2023��2��\0204\ADC\ADCduikong_JL4wangfan_azi0ele0_500m_3mps';
    
%     rBin = 13;
%     frameIdxList = 1240:1:1318;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�
%     vBin = 6;

%     rBin = 21;
%     frameIdxList = 2141:1:2231;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�
%     vBin = 6;

%     rBin = 31;
%     frameIdxList = 3283;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�
% %     frameIdxList = 3261:1:3342;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�
%     vBin = 6;

%     rBin = 48;
%     frameIdxList = 5081:1:5141;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�
%     vBin = 6;

%     rBin = 7;
%     frameIdxList = 2:1:fileNum/2;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�    
%     vBin = 32;



%% ����λ
%     rBin = 11;
%     frameIdxList = 721:1:801;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�    
%     vBin = 6;

%     rBin = 15;
%     frameIdxList = 2061:1:2181;%%1:20:fileNum/2��1:20:fileNum����ȡ����֡�±귶Χ�������������������������������������������������޸�    
%     vBin = 28;
