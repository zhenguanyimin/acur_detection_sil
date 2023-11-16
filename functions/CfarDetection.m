%V0.0  初始版本
function [Target_Para, target_num, PeakTarget_Para] = CfarDetection(rdmapData, peakBitmap, threshold, noiseMag)

global HIST_THRESHOLD_GUARD  RDM_MAG_PER_HIST_BIN_EXP 

rCFARmode = 2;%%距离维CFAR类型：1:CA，2：GO，3：CMLD，4：OS
dCFARmode = 2;%%速度维CFAR类型：1:CA，2：GO，3：CMLD
RemoveMin_Flag = 0;%%CA、GO是否去除幅值最小单元：1:是，0：否
removeMax_r = 2;%%CMLD需去除的最大单元数
removeMin_r = 1;%%CMLD需去除的最小单元数

CfarParameter.Guard_Range       =   2;                                     %%距离维 保护单元2/3,[26][28][36][24][25][27][35]
CfarParameter.Win_Range         =   6;                                     %%距离维 参考单元6/5

CfarParameter.Guard_Doppler     =   4;                                     %%速度维 保护单元4/5,[46][36][44][45][37][35][34]
CfarParameter.Win_Doppler       =   6;                                     %%速度维 参考单元6/6

%%%%%%%%%%%%%%%CFAR Params%%%%%%%%%%%%%%%
%%1700/256*3.0103,18*256/3.0103
%%2211(25.9991dB，26),2126(24.9996dB,25),2048(24.0824dB,24),1956(23.0006dB,23),1871(22.0011dB,22),1785(20.9898dB,21),1700(19.9903dB,20)
%%1615(18.9908dB,19),1530(17.9912dB,18),1445(16.9917dB,17)，1360(15.9922dB,16)，1275(14.9927dB,15),1190(13.9932dB,14)
%%1105(12.9937dB,13),1020(11.9942dB,12),935(10.9947dB,11),850(9.9951dB,10),765(8.9956dB,9),681(8.0079dB,8)

%% =========== CFAR下限 =====================%%
% %% 9dB-CFAR
% rangeSnrTh_ST =  ceil( [22,16,9,9,9,90] * 256 / 3.01 );
% dopplerSnrTh_ST =  ceil( [19,15,9,9,9,100] * 256 / 3.01 );
% globalSnrTh_ST =  ceil( [15,13,9,9,9,90] * 256 / 3.01 );

%% 0320-CFAR, using
% rangeSnrTh_ST = ceil( [22,16,13,12,12.5,90] * 256 / 3.01 );
% dopplerSnrTh_ST = ceil( [19,15,13,13,13,100] * 256 / 3.01 );
% globalSnrTh_ST = ceil( [15,13,11,11,11,90] * 256 / 3.01 );

% %% 0420CFAR-rCA,VGO, 基础版本newUsing
% rangeSnrTh_ST = ceil( [22,16,13,12,12.5,90] * 256 / 3.01 );
% dopplerSnrTh_ST = ceil( [19,15,13,12,13,100] * 256 / 3.01 );
% globalSnrTh_ST = ceil( [15,13,12,12,11,90] * 256 / 3.01 );

% % 0426CFAR——rCA,VGO-dopplerWindow is kaiser -1
% rangeSnrTh_ST = ceil( [22,16,13,13,12.5,90] * 256 / 3.01 );
% dopplerSnrTh_ST = ceil( [19,15,13,11,13,100] * 256 / 3.01 );
% globalSnrTh_ST = ceil( [15,13,12,12,11,90] * 256 / 3.01 );

% %% 0704CFAR-rGO,VGO, 4代雷达基础版本test，501-801m:rCAvGO,ok
% rangeSnrTh_ST = ceil( [22,16,13,12,12,90] * 256 / 3.01 );
% dopplerSnrTh_ST = ceil( [19,15,13,12,12,100] * 256 / 3.01 );
% globalSnrTh_ST = ceil( [15,13,12,12,11,90] * 256 / 3.01 );

% %% 0704CFAR-rGO,VGO, 4代雷达基础版本test，501-801m:rCAvGO
% rangeSnrTh_ST = ceil( [22,16,9,12,12,90] * 256 / 3.01 );
% dopplerSnrTh_ST = ceil( [19,15,9,12,12,100] * 256 / 3.01 );
% globalSnrTh_ST = ceil( [15,13,9,12,11,90] * 256 / 3.01 );

%% 0804CFAR:210-501m:rCMLD,CA;501-801m:rCA,cGOO;801-1200m:rCMLD,vGO,其余GO
rangeSnrTh_ST = ceil( [22,16,16,12,15,90] * 256 / 3.01 );
dopplerSnrTh_ST = ceil( [19,15,14,12,12,100] * 256 / 3.01 );
globalSnrTh_ST = ceil( [15,13,12,12,11,90] * 256 / 3.01 );


%% =========== CFAR上限 =====================%%
%% 0607CFAR—3rd Gen Radar
rangeSnrTh_ED = ceil( [80,80,80,80,80,90] * 256 / 3.01 );
dopplerSnrTh_ED = ceil( [80,80,80,80,80,90] * 256 / 3.01 );
globalSnrTh_ED = ceil( [80,80,80,80,80,90] * 256 / 3.01 );

% %% 0320CFAR
% rangeSnrTh_ED = [60,60,45,26,26,90] * 256 / 3.01;
% dopplerSnrTh_ED = [50,35,42,26,26,90] * 256 / 3.01;
% globalSnrTh_ED = [50,43,42,30,30,90] * 256 / 3.01;

% %% 0420CFAR—rCA,VGO-2,newUsing
% rangeSnrTh_ED = ceil( [60,50,35,26,24,90] * 256 / 3.01 );
% dopplerSnrTh_ED = ceil( [52,45,38,30,24,90] * 256 / 3.01 );
% globalSnrTh_ED = ceil( [55,48,36,28,24,90] * 256 / 3.01 );

%% 0418CFAR
% rangeSnrTh_ED = ceil( [60,60,45,28,26,90] * 256 / 3.01 );
% dopplerSnrTh_ED = ceil( [50,50,42,28,26,90] * 256 / 3.01 );
% globalSnrTh_ED = ceil( [55,50,40,30,28,90] * 256 / 3.01 );


%%%%第二版硬件，中频2023320优化版本，SNR(*)/3.01*256，GO26,GO46
%% start thershold
CFAR_RANGE_THRESHOLD_SEG_ST_1ST = rangeSnrTh_ST(1);    %/* cfar range threshold segment 1st, 22 */
CFAR_RANGE_THRESHOLD_SEG_ST_2ND = rangeSnrTh_ST(2);    %/* cfar range threshold segment 2nd, 16 */ 
CFAR_RANGE_THRESHOLD_SEG_ST_3RD = rangeSnrTh_ST(3);    %/* cfar range threshold segment 3rd, 13(1106) */
CFAR_RANGE_THRESHOLD_SEG_ST_4TH = rangeSnrTh_ST(4);    %/* cfar range threshold segment 4th, 12(1021),12.5(1064) */
CFAR_RANGE_THRESHOLD_SEG_ST_5TH = rangeSnrTh_ST(5);    %/* cfar range threshold segment 5th, 90 */
CFAR_RANGE_THRESHOLD_SEG_ST_6TH = rangeSnrTh_ST(6);    %/* cfar range threshold segment 5th, 90 */

CFAR_DOPPLER_THRESHOLD_SEG_ST_1ST = dopplerSnrTh_ST(1);  %/* cfar doppler threshold segment 1st, 19 */
CFAR_DOPPLER_THRESHOLD_SEG_ST_2ND = dopplerSnrTh_ST(2);  %/* cfar doppler threshold segment 2nd, 15 */
CFAR_DOPPLER_THRESHOLD_SEG_ST_3RD = dopplerSnrTh_ST(3);  %/* cfar doppler threshold segment 3rd, 13 */
CFAR_DOPPLER_THRESHOLD_SEG_ST_4TH = dopplerSnrTh_ST(4);  %/* cfar doppler threshold segment 4th, 13(1106),12(1021) */
CFAR_DOPPLER_THRESHOLD_SEG_ST_5TH = dopplerSnrTh_ST(5);  %/* cfar doppler threshold segment 5yh, 100 */
CFAR_DOPPLER_THRESHOLD_SEG_ST_6TH = dopplerSnrTh_ST(6);  %/* cfar doppler threshold segment 5yh, 100 */

CFAR_GLOBAL_THRESHOLD_SEG_ST_1ST = globalSnrTh_ST(1);        %/* cfar global threshold segment 1st, 14 */
CFAR_GLOBAL_THRESHOLD_SEG_ST_2ND = globalSnrTh_ST(2);        %/* cfar global threshold segment 2nd, 11(936),12(1021) */
CFAR_GLOBAL_THRESHOLD_SEG_ST_3RD = globalSnrTh_ST(3);        %/* cfar global threshold segment 3rd, 11(936),12(1021),10(851) */
CFAR_GLOBAL_THRESHOLD_SEG_ST_4TH = globalSnrTh_ST(4);        %/* cfar global threshold segment 4th, 11(936),12(1021),10(851) */
CFAR_GLOBAL_THRESHOLD_SEG_ST_5TH = globalSnrTh_ST(5);        %/* cfar global threshold segment 5th, 90 */
CFAR_GLOBAL_THRESHOLD_SEG_ST_6TH = globalSnrTh_ST(6);        %/* cfar global threshold segment 6th, 90 */

%% end thershold
CFAR_RANGE_THRESHOLD_SEG_ED_1ST = rangeSnrTh_ED(1);    %/* cfar range threshold segment 1st, 22 */
CFAR_RANGE_THRESHOLD_SEG_ED_2ND = rangeSnrTh_ED(2);    %/* cfar range threshold segment 2nd, 16 */ 
CFAR_RANGE_THRESHOLD_SEG_ED_3RD = rangeSnrTh_ED(3);    %/* cfar range threshold segment 3rd, 13(1106) */
CFAR_RANGE_THRESHOLD_SEG_ED_4TH = rangeSnrTh_ED(4);    %/* cfar range threshold segment 4th, 12(1021),12.5(1064) */
CFAR_RANGE_THRESHOLD_SEG_ED_5TH = rangeSnrTh_ED(5);    %/* cfar range threshold segment 5th, 90 */
CFAR_RANGE_THRESHOLD_SEG_ED_6TH = rangeSnrTh_ED(6);    %/* cfar range threshold segment 5th, 90 */

CFAR_DOPPLER_THRESHOLD_SEG_ED_1ST = dopplerSnrTh_ED(1);  %/* cfar doppler threshold segment 1st, 19 */
CFAR_DOPPLER_THRESHOLD_SEG_ED_2ND = dopplerSnrTh_ED(2);  %/* cfar doppler threshold segment 2nd, 15 */
CFAR_DOPPLER_THRESHOLD_SEG_ED_3RD = dopplerSnrTh_ED(3);  %/* cfar doppler threshold segment 3rd, 13 */
CFAR_DOPPLER_THRESHOLD_SEG_ED_4TH = dopplerSnrTh_ED(4);  %/* cfar doppler threshold segment 4th, 13(1106),12(1021) */
CFAR_DOPPLER_THRESHOLD_SEG_ED_5TH = dopplerSnrTh_ED(5);  %/* cfar doppler threshold segment 5yh, 100 */
CFAR_DOPPLER_THRESHOLD_SEG_ED_6TH = dopplerSnrTh_ED(6);  %/* cfar doppler threshold segment 5yh, 100 */

CFAR_GLOBAL_THRESHOLD_SEG_ED_1ST = globalSnrTh_ED(1);        %/* cfar global threshold segment 1st, 14 */
CFAR_GLOBAL_THRESHOLD_SEG_ED_2ND = globalSnrTh_ED(2);        %/* cfar global threshold segment 2nd, 11(936),12(1021) */
CFAR_GLOBAL_THRESHOLD_SEG_ED_3RD = globalSnrTh_ED(3);        %/* cfar global threshold segment 3rd, 11(936),12(1021),10(851) */
CFAR_GLOBAL_THRESHOLD_SEG_ED_4TH = globalSnrTh_ED(4);        %/* cfar global threshold segment 4th, 11(936),12(1021),10(851) */
CFAR_GLOBAL_THRESHOLD_SEG_ED_5TH = globalSnrTh_ED(5);        %/* cfar global threshold segment 5th, 90 */
CFAR_GLOBAL_THRESHOLD_SEG_ED_6TH = globalSnrTh_ED(6);        %/* cfar global threshold segment 6th, 90 */

RANGE_CUT_INDEX_1ST          = 3;                %/* rangeBin cut index 1st 2(6m) */
RANGE_CUT_INDEX_2ND          = 18;                %/* rangeBin cut index 2nd 10(30m),17(51m) */
RANGE_CUT_INDEX_3RD          = 71;                %/* rangeBin cut index 3rd 100(300m),63(189m),70(210) */
RANGE_CUT_INDEX_4TH          = 168;                %/* rangeBin cut index 4th 167(501m),121(363m),109(327m),134(402m),167(501m) */
RANGE_CUT_INDEX_5TH          = 268;                %/* rangeBin cut index 5th 267(801m),234(702m),212(636m),300(900m),210(630),267(801m) */
RANGE_CUT_INDEX_6TH          = 401;                %/* rangeBin cut index 6th 430(1290m),350(1050m) */

% RANGE_CUT_INDEX_1ST          = 2;                %/* rangeBin cut index 1st 2(6m) */
% RANGE_CUT_INDEX_2ND          = 17;                %/* rangeBin cut index 2nd 10(30m),17(51m) */
% RANGE_CUT_INDEX_3RD          = 70;                %/* rangeBin cut index 3rd 100(300m),63(189m),70(210) */
% RANGE_CUT_INDEX_4TH          = 167;                %/* rangeBin cut index 4th 167(501m),121(363m),109(327m),134(402m),167(501m) */
% RANGE_CUT_INDEX_5TH          = 267;                %/* rangeBin cut index 5th 267(801m),234(702m),212(636m),300(900m),210(630),267(801m) */
% RANGE_CUT_INDEX_6TH          = 400;                %/* rangeBin cut index 6th 430(1290m),350(1050m) */


CfarParameter.Range_Len         =   size(rdmapData,1);                                   %%距离维阈值长度
% CfarParameter.Range_LenEnable         =   RANGE_BIN_ENABLE;                                   %%距离维阈值长度，只对前512bin做底噪计算及CFAR
CfarParameter.Doppler_Len       =   size(rdmapData,2);                                   %%速度维阈值长度
CfarParameter.OS_RANGE          =   150;                                   %%距离维使用OS CFAR的格数

Os_K                            =   0.5;
CfarParameter.osRangeK          =   floor(Os_K*CfarParameter.Win_Range*2); %%OS CFAR选取估计底噪单元格 %%%%%第K大


% 目标 Range velocity 阈值
gRangeCfarThreshold    = [ CFAR_RANGE_THRESHOLD_SEG_ST_1ST, CFAR_RANGE_THRESHOLD_SEG_ST_2ND, CFAR_RANGE_THRESHOLD_SEG_ST_3RD, CFAR_RANGE_THRESHOLD_SEG_ST_4TH, CFAR_RANGE_THRESHOLD_SEG_ST_5TH, CFAR_RANGE_THRESHOLD_SEG_ST_6TH ];
gDopplerCfarThreshold =  [ CFAR_DOPPLER_THRESHOLD_SEG_ST_1ST, CFAR_DOPPLER_THRESHOLD_SEG_ST_2ND, CFAR_DOPPLER_THRESHOLD_SEG_ST_3RD, CFAR_DOPPLER_THRESHOLD_SEG_ST_4TH, CFAR_DOPPLER_THRESHOLD_SEG_ST_5TH, CFAR_DOPPLER_THRESHOLD_SEG_ST_6TH ];
gGlobalCfarThreshold =  [ CFAR_GLOBAL_THRESHOLD_SEG_ST_1ST, CFAR_GLOBAL_THRESHOLD_SEG_ST_2ND, CFAR_GLOBAL_THRESHOLD_SEG_ST_3RD, CFAR_GLOBAL_THRESHOLD_SEG_ST_4TH, CFAR_GLOBAL_THRESHOLD_SEG_ST_5TH, CFAR_GLOBAL_THRESHOLD_SEG_ST_6TH ];


gRangeCfarThreshold_end    = [ CFAR_RANGE_THRESHOLD_SEG_ED_1ST, CFAR_RANGE_THRESHOLD_SEG_ED_2ND, CFAR_RANGE_THRESHOLD_SEG_ED_3RD, CFAR_RANGE_THRESHOLD_SEG_ED_4TH, CFAR_RANGE_THRESHOLD_SEG_ED_5TH, CFAR_RANGE_THRESHOLD_SEG_ED_6TH ];
gDopplerCfarThreshold_end =  [ CFAR_DOPPLER_THRESHOLD_SEG_ED_1ST, CFAR_DOPPLER_THRESHOLD_SEG_ED_2ND, CFAR_DOPPLER_THRESHOLD_SEG_ED_3RD, CFAR_DOPPLER_THRESHOLD_SEG_ED_4TH, CFAR_DOPPLER_THRESHOLD_SEG_ED_5TH, CFAR_DOPPLER_THRESHOLD_SEG_ED_6TH ];
gGlobalCfarThreshold_end =  [ CFAR_GLOBAL_THRESHOLD_SEG_ED_1ST, CFAR_GLOBAL_THRESHOLD_SEG_ED_2ND, CFAR_GLOBAL_THRESHOLD_SEG_ED_3RD, CFAR_GLOBAL_THRESHOLD_SEG_ED_4TH, CFAR_GLOBAL_THRESHOLD_SEG_ED_5TH, CFAR_GLOBAL_THRESHOLD_SEG_ED_6TH ];


gRangeBinCutIdx = [ RANGE_CUT_INDEX_1ST, RANGE_CUT_INDEX_2ND, RANGE_CUT_INDEX_3RD, RANGE_CUT_INDEX_4TH, RANGE_CUT_INDEX_5TH, RANGE_CUT_INDEX_6TH ];


nrRangeBins=size(rdmapData,1);
nrDopplerBins=size(rdmapData,2);

ROW_range           =   nrRangeBins;
COL_doppler         =   nrDopplerBins;
target_num          =   0;
Peaktarget_num      =   0;
Target_Para=zeros(5,target_num);
PeakTarget_Para=zeros(4,Peaktarget_num);
% TODO: name of nrRangeBins(not the numbers of range bins)
% BitmapOut_peaksearch=uint32(zeros(nrRangeBins,1));
% matResahpe=reshape(peakBitmap,32,nrRangeBins);  %32*512
% for iCol=1:nrRangeBins 
%     for jRow=1:32
%         if(matResahpe(jRow,iCol)==1)
%             BitmapOut_peaksearch(iCol)= bitset( BitmapOut_peaksearch(iCol),jRow);
%         end
%     end
% end
% BitmapOut_peaksearch_resharp    =   reshape(BitmapOut_peaksearch,1,[]);               %嵌入式不需要  给512*1 转换成1*512行
% inputDetectBitmapSize           =   length(BitmapOut_peaksearch_resharp)/32;          %循环总次数，下面区分动静    16=512/32

%% 每个bitmap包的长度为32bit
BitmapOut_peaksearch_resharp    =   reshape(peakBitmap,1,[]);               %嵌入式不需要  转换成1行*(512*32)列
inputDetectBitmapSize           =   length(BitmapOut_peaksearch_resharp)/32;          %循环总次数，下面区分动静    16=512/32

%%
%%
for  i_BitmapNum=1:inputDetectBitmapSize
    
    i_index     =   i_BitmapNum;
    aux         =   BitmapOut_peaksearch_resharp(32*(i_index-1)+1:32*i_index);
    j_index     =   1;
    aux         =   fliplr(aux);             %高低位互换
    aux_str     =   bin2dec(num2str(aux));   %数组转二进制
    
    
    while (aux_str)
        if (bitget(aux_str,1) && 1)
            
            peakIndex           =   (i_index-1)*32+j_index;
            j_doppler           =   peakIndex / CfarParameter.Range_Len;       
            j_doppler           =   ceil(j_doppler);                            %嵌入式法 0-63
            startIndex_Doppler  =   (j_doppler-1) * CfarParameter.Range_Len;
            i_range             =   peakIndex-startIndex_Doppler;            
            
            Range_NoiseFloor = 0;
            Doppler_NoiseFloor = 0;

            RangeCfarThreshold = 0;
            DopplerCfarThreshold = 0;
            GlobalCfarThreshold = 0;

            RangeCfarThreshold_end = 0;
            DopplerCfarThreshold_end = 0;
            GlobalCfarThreshold_end = 0;
                                   
            %% get CFAR thresholds for each range
%             if ( i_range > gRangeBinCutIdx(1) && i_range <= gRangeBinCutIdx(2) ) %%[2,10]bin
            if ( i_range >= gRangeBinCutIdx(1) && i_range <= gRangeBinCutIdx(2) ) %%[2,10]bin
                RangeCfarThreshold      =   gRangeCfarThreshold(1);
                DopplerCfarThreshold    =   gDopplerCfarThreshold(1);%%CfarParameter.Range_LenEnable
                GlobalCfarThreshold    =   gGlobalCfarThreshold(1);
                
                RangeCfarThreshold_end = gRangeCfarThreshold_end(1);
                DopplerCfarThreshold_end = gDopplerCfarThreshold_end(1);
                GlobalCfarThreshold_end = gGlobalCfarThreshold_end(1);

%             elseif ( i_range >= gRangeBinCutIdx(6) && i_range < CfarParameter.Range_Len ) %%[430,end]bin    
            elseif ( i_range > gRangeBinCutIdx(6) && i_range < CfarParameter.Range_Len ) %%[430,end]bin
                RangeCfarThreshold      =   gRangeCfarThreshold(6);
                DopplerCfarThreshold    =   gDopplerCfarThreshold(6);
                GlobalCfarThreshold    =   gGlobalCfarThreshold(6);
                
                RangeCfarThreshold_end = gRangeCfarThreshold_end(6);
                DopplerCfarThreshold_end = gDopplerCfarThreshold_end(6);
                GlobalCfarThreshold_end = gGlobalCfarThreshold_end(6);

            elseif ( i_range > gRangeBinCutIdx(2) && i_range <= gRangeBinCutIdx(3) ) %%(10, 32]bin
                RangeCfarThreshold      =   gRangeCfarThreshold(2);
                DopplerCfarThreshold    =   gDopplerCfarThreshold(2);
                GlobalCfarThreshold    =   gGlobalCfarThreshold(2);
                
                RangeCfarThreshold_end = gRangeCfarThreshold_end(2);
                DopplerCfarThreshold_end = gDopplerCfarThreshold_end(2);
                GlobalCfarThreshold_end = gGlobalCfarThreshold_end(2);
               
            elseif ( i_range > gRangeBinCutIdx(3) && i_range <= gRangeBinCutIdx(4) ) %%(32, 54]bin
                RangeCfarThreshold      =   gRangeCfarThreshold(3);
                DopplerCfarThreshold    =   gDopplerCfarThreshold(3);
                GlobalCfarThreshold    =   gGlobalCfarThreshold(3);
                
                RangeCfarThreshold_end = gRangeCfarThreshold_end(3);
                DopplerCfarThreshold_end = gDopplerCfarThreshold_end(3);
                GlobalCfarThreshold_end = gGlobalCfarThreshold_end(3);
                
            elseif ( i_range > gRangeBinCutIdx(4) && i_range <= gRangeBinCutIdx(5) ) %%(54, 72]bin
                RangeCfarThreshold      =   gRangeCfarThreshold(4);
                DopplerCfarThreshold    =   gDopplerCfarThreshold(4);
                GlobalCfarThreshold    =   gGlobalCfarThreshold(4);
                
                RangeCfarThreshold_end = gRangeCfarThreshold_end(4);
                DopplerCfarThreshold_end = gDopplerCfarThreshold_end(4);
                GlobalCfarThreshold_end = gGlobalCfarThreshold_end(4);
                
            elseif (i_range > gRangeBinCutIdx(5) && i_range <= gRangeBinCutIdx(6) )  %%(72, 430]bin
                RangeCfarThreshold      =   gRangeCfarThreshold(5);
                DopplerCfarThreshold    =   gDopplerCfarThreshold(5);
                GlobalCfarThreshold    =   gGlobalCfarThreshold(5);
                
                RangeCfarThreshold_end = gRangeCfarThreshold_end(5);
                DopplerCfarThreshold_end = gDopplerCfarThreshold_end(5);
                GlobalCfarThreshold_end = gGlobalCfarThreshold_end(5);
                
            else	  %%[1, 2]bin
                RangeCfarThreshold      =   gRangeCfarThreshold(3);
                DopplerCfarThreshold    =   gDopplerCfarThreshold(3);
                GlobalCfarThreshold    =   gGlobalCfarThreshold(3);
                
                RangeCfarThreshold_end = gRangeCfarThreshold_end(3);
                DopplerCfarThreshold_end = gDopplerCfarThreshold_end(3);
                GlobalCfarThreshold_end = gGlobalCfarThreshold_end(3);
                    
            end
            
            %% get noise floor
            if ( i_range > gRangeBinCutIdx(3) && i_range <= gRangeBinCutIdx(4) )   %%210-501m ,r-CMLD,v-CA             
                Range_NoiseFloor     =   Range_CMLD_CFAR(i_range,CfarParameter.Range_Len,6,2,rdmapData(:,j_doppler),removeMax_r,removeMin_r);%%2、6最优
                Doppler_NoiseFloor   =   Doppler_CACFAR_NEW(j_doppler,COL_doppler,CfarParameter.Win_Doppler,CfarParameter.Guard_Doppler,rdmapData(i_range,:),1,RemoveMin_Flag);
%                 fprintf("mode,i_range,j_doppler,mag,rNoise,dNoise：%d,%d,%d,%d,%d,%d\n", 1,i_range,j_doppler,rdmapData(i_range,j_doppler),Range_NoiseFloor,Doppler_NoiseFloor);

            elseif ( i_range > gRangeBinCutIdx(4) && i_range <= gRangeBinCutIdx(5) )  %%501-801m ,r-CA,v-GOI 
                Range_NoiseFloor     =   Range_CACFAR_new(i_range,CfarParameter.Range_Len,5,3,rdmapData(:,j_doppler),1);%% remove the min value
                Doppler_NoiseFloor   =   Doppler_GOCFAR_NEW(j_doppler,COL_doppler,CfarParameter.Win_Doppler,CfarParameter.Guard_Doppler,rdmapData(i_range,:),1,RemoveMin_Flag);
%                 fprintf("mode,i_range,j_doppler,mag,rNoise,dNoise：%d,%d,%d,%d,%d,%d\n", 2,i_range,j_doppler,rdmapData(i_range,j_doppler),Range_NoiseFloor,Doppler_NoiseFloor);

            elseif ( i_range > gRangeBinCutIdx(5) && i_range <= gRangeBinCutIdx(6) )   %%801-1200m ,r-CMLD,v-GO 
                Range_NoiseFloor     =   Range_CMLD_CFAR(i_range,CfarParameter.Range_Len,6,2,rdmapData(:,j_doppler),removeMax_r,removeMin_r);%%2、6最优
                Doppler_NoiseFloor   =   Doppler_GOCFAR_NEW(j_doppler,COL_doppler,CfarParameter.Win_Doppler,CfarParameter.Guard_Doppler,rdmapData(i_range,:),1,RemoveMin_Flag);
%                 fprintf("mode,i_range,j_doppler,mag,rNoise,dNoise：%d,%d,%d,%d,%d,%d\n", 3,i_range,j_doppler,rdmapData(i_range,j_doppler),Range_NoiseFloor,Doppler_NoiseFloor);

            else      %% r-GO,v-GO       
                %%range
                if (rCFARmode == 4)
                    Range_NoiseFloor     =   Range_OSCFAR(i_range,CfarParameter.Range_Len,CfarParameter.Win_Range,CfarParameter.Guard_Range,rdmapData(:,j_doppler),CfarParameter.osRangeK);
                elseif (rCFARmode == 3)
                    Range_NoiseFloor     =   Range_CMLD_CFAR(i_range,CfarParameter.Range_Len,CfarParameter.Win_Range,CfarParameter.Guard_Range,rdmapData(:,j_doppler),removeMax_r,removeMin_r);                   
                elseif (rCFARmode == 2)
    %                 Range_NoiseFloor     =   Range_GOCFAR(i_range,CfarParameter.Range_Len,CfarParameter.Win_Range,CfarParameter.Guard_Range,rdmapData(:,j_doppler));
                    Range_NoiseFloor     =   Range_GOCFAR_new(i_range,CfarParameter.Range_Len,CfarParameter.Win_Range,CfarParameter.Guard_Range,rdmapData(:,j_doppler),RemoveMin_Flag);
                else
    %                 Range_NoiseFloor     =   Range_CACFAR(i_range,CfarParameter.Range_Len,CfarParameter.Win_Range,CfarParameter.Guard_Range,rdmapData(:,j_doppler));
                    Range_NoiseFloor     =   Range_CACFAR_new(i_range,CfarParameter.Range_Len,CfarParameter.Win_Range,CfarParameter.Guard_Range,rdmapData(:,j_doppler),RemoveMin_Flag);%% remove the min value
                end

                %%doppler
                if (dCFARmode == 3)
                    Doppler_NoiseFloor   =   Doppler_CMLD_CFAR(j_doppler,COL_doppler,CfarParameter.Win_Doppler,CfarParameter.Guard_Doppler,rdmapData(i_range,:),removeMax_r,removeMin_r);
                elseif (dCFARmode == 2)   
                    Doppler_NoiseFloor   =   Doppler_GOCFAR_NEW(j_doppler,COL_doppler,CfarParameter.Win_Doppler,CfarParameter.Guard_Doppler,rdmapData(i_range,:),1,RemoveMin_Flag);
                else
    %                 Doppler_NoiseFloor    =   Doppler_CACFAR(j_doppler,COL_doppler,CfarParameter.Win_Doppler,CfarParameter.Guard_Doppler,rdmapData(i,:));
                    Doppler_NoiseFloor   =   Doppler_CACFAR_NEW(j_doppler,COL_doppler,CfarParameter.Win_Doppler,CfarParameter.Guard_Doppler,rdmapData(i_range,:),1,RemoveMin_Flag);
                end
%                 fprintf("mode,i_range,j_doppler,mag,rNoise,dNoise：%d,%d,%d,%d,%d,%d\n", 4,i_range,j_doppler,rdmapData(i_range,j_doppler),Range_NoiseFloor,Doppler_NoiseFloor);
            end
            
            %% 3.noise output exception handling = global noise
            %%Range
            if (Range_NoiseFloor == 0)
                Range_NoiseFloor = ( threshold(i_range) - ((HIST_THRESHOLD_GUARD) * RDM_MAG_PER_HIST_BIN_EXP) );
            end
            %%doppler
            if (Doppler_NoiseFloor == 0)
                Doppler_NoiseFloor = ( threshold(i_range) - ((HIST_THRESHOLD_GUARD) * RDM_MAG_PER_HIST_BIN_EXP) );
            end

            
             %----------------------------------------------------嵌入式不要-------------------------------------------------------------------
            Peaktarget_num=Peaktarget_num+1;
            PeakTarget_Para(1,Peaktarget_num)   =   i_range - 1;%%对齐PS处理，下标从0开始
            PeakTarget_Para(2,Peaktarget_num)   =   j_doppler;
            PeakTarget_Para(3,Peaktarget_num)   =   rdmapData(i_range,j_doppler)/256*3.0103;%%幅值 
            PeakTarget_Para(4,Peaktarget_num)   =   (RangeCfarThreshold+Range_NoiseFloor)/256*3.0103;%%距离维幅值阈值
            PeakTarget_Para(5,Peaktarget_num)   =   (DopplerCfarThreshold+Doppler_NoiseFloor)/256*3.0103;%%速度维幅值阈值 
            PeakTarget_Para(6,Peaktarget_num)   =   (rdmapData(i_range,j_doppler)-Range_NoiseFloor)/256*3.0103;%%距离维信噪比  
            PeakTarget_Para(7,Peaktarget_num)   =   (rdmapData(i_range,j_doppler)-Doppler_NoiseFloor)/256*3.0103;%%速度维信噪比                   
            PeakTarget_Para(8,Peaktarget_num)   =   (rdmapData(i_range,j_doppler)-threshold(i_range)+(HIST_THRESHOLD_GUARD)*RDM_MAG_PER_HIST_BIN_EXP)/256*3.0103;%%全局信噪比-直方图底噪               
            PeakTarget_Para(9,Peaktarget_num)   =   (rdmapData(i_range,j_doppler)-noiseMag(i_range))/256*3.0103;%%全局信噪比-均值底噪                  
            %-------------------------------------------------------------------------------------------------------------------------------------------------

            %% 筛选过CFAR阈值的峰值点（距离维+速度维+全局）
%             if ((rdmapData(i_range,j_doppler) > (MagThreshold)) && (rdmapData(i_range,j_doppler) > (RangeCfarThreshold+Range_NoiseFloor)) && ((rdmapData(i_range,j_doppler)  > (DopplerCfarThreshold+Doppler_NoiseFloor))))
            if ( ( rdmapData(i_range,j_doppler) > floor(RangeCfarThreshold + Range_NoiseFloor) ) && ( rdmapData(i_range,j_doppler) < floor(RangeCfarThreshold_end + Range_NoiseFloor) ) && ...
                    (( rdmapData(i_range,j_doppler) > floor(DopplerCfarThreshold + Doppler_NoiseFloor) )) && (( rdmapData(i_range,j_doppler) < floor(DopplerCfarThreshold_end + Doppler_NoiseFloor) )) && ...
                    (( rdmapData(i_range,j_doppler) > floor(GlobalCfarThreshold + (threshold(i_range)-(HIST_THRESHOLD_GUARD)*RDM_MAG_PER_HIST_BIN_EXP)) )) && ...
                    (( rdmapData(i_range,j_doppler) < floor(GlobalCfarThreshold_end + (threshold(i_range)-(HIST_THRESHOLD_GUARD)*RDM_MAG_PER_HIST_BIN_EXP)) ))  )

%                 fprintf("i_range,j_doppler,mag,rThod,rNoise,dThod,dNoise,gThod,gNoise：%d,%d,%d,%d,%d,%d,%d,%d,%d\n", i_range,j_doppler,rdmapData(i_range,j_doppler),RangeCfarThreshold,Range_NoiseFloor,DopplerCfarThreshold,Doppler_NoiseFloor,GlobalCfarThreshold,(threshold(i_range)-(HIST_THRESHOLD_GUARD)*RDM_MAG_PER_HIST_BIN_EXP)); 
                target_num=target_num+1;
                Target_Para(1,target_num)   =   i_range - 1;%%对齐PS处理，下标从0开始
                Target_Para(2,target_num)   =   j_doppler;
                Target_Para(3,target_num)   =   rdmapData(i_range,j_doppler)/256*3.0103;%%幅值                 
                Target_Para(4,target_num)   =   (RangeCfarThreshold+Range_NoiseFloor)/256*3.0103;%%距离维幅值阈值
                Target_Para(5,target_num)   =   (DopplerCfarThreshold+Doppler_NoiseFloor)/256*3.0103;%%速度维幅值阈值 
                Target_Para(6,target_num)   =   (rdmapData(i_range,j_doppler)-Range_NoiseFloor)/256*3.0103;%%距离维信噪比  
                Target_Para(7,target_num)   =   (rdmapData(i_range,j_doppler)-Doppler_NoiseFloor)/256*3.0103;%%速度维信噪比   
                Target_Para(8,target_num)   =   (rdmapData(i_range,j_doppler)- (threshold(i_range)-(HIST_THRESHOLD_GUARD)*RDM_MAG_PER_HIST_BIN_EXP) )/256*3.0103;%%全局信噪比-直方图底噪                
                Target_Para(9,target_num)   =   (rdmapData(i_range,j_doppler)-noiseMag(i_range))/256*3.0103;%%全局信噪比-均值底噪 
                                
%                         Indices(i,j)=1;
%                         SNR_Range_Matrix(i,j)=(rdmapData(i,j)-cfarThreshold_Range)*0.0039*3.0103;  
%                         SNR_Doppler_Matrix(i,j)=(rdmapData(i,j)-cfarThreshold_Doppler)*0.0039*3.0103;                 
            end
        end
        j_index=j_index+1;
        aux_str=bitshift(aux_str, -1);
    end 
end

end


%% ==================================== 子函数 ============================================%%
%%%%%%%%%%%%%%%% Bubble Sort:descending order %%%%%%%%%%%%%%%%%%
function [Idx_final] = Bubble_Sort(Idx_start,Num_win,RangeData)

Idx_final = Idx_start;

for i_win = 1:Num_win-1
    for j_win = 1:Num_win-i_win
        tmpMag_j = RangeData( Idx_final(j_win) );
        tmpMag_j1 = RangeData( Idx_final(j_win + 1) );        
        if (tmpMag_j < tmpMag_j1)            
            tmpIdx = Idx_final(j_win + 1);
            Idx_final(j_win + 1) = Idx_final(j_win);
            Idx_final(j_win) = tmpIdx;
        end
    end
end

end

%%%%%%%%%%%%%%%% Range CFAR %%%%%%%%%%%%%%%%%%
%%--------- remove the min value win ------------------%
function    Range_NoiseFloor_CA = Range_CACFAR_new(idx,ROW,CFAR_WINDOW,CFAR_GUARD,RangeData,RemoveMin_Flag)    
    Range_NoiseFloor_CA = 0;
    data_zero = 0;
    winsize = CFAR_WINDOW*2;
    i_temp = 0;
    index_R = 0;index_L = 0;
    data_sum = 0;
    value_min = 65536;
    
  %% 右边
  for i_R = 1:CFAR_WINDOW                                                    %这个可以一个for循环里面存2个点数据，并且比较
      index_R = idx+CFAR_GUARD+i_R;
      if ( index_R <= ROW )
          if RangeData(index_R)~=0
              data_sum = data_sum + RangeData(index_R);
              i_temp = i_temp+1;
              index_num(i_temp) = index_R;              
             %% find the min value
              if ( (RemoveMin_Flag) && ( RangeData(index_R) < value_min ) )
                  value_min = RangeData(index_R);
              end
          end
      else %%右边不够，向左取，跳过左窗覆盖范围，且>左边界，差几个连着取几个
          index_R = idx-CFAR_GUARD-CFAR_WINDOW-(CFAR_WINDOW-i_R+1);
          if ( (index_R > 0) && (index_R <= ROW) )
              if RangeData(index_R)~=0
                  data_sum = data_sum + RangeData(index_R);
                  i_temp = i_temp+1;
                  index_num(i_temp) = index_R;
                  %% find the min value
                  if ( (RemoveMin_Flag) && ( RangeData(index_R) < value_min ) )
                      value_min = RangeData(index_R);
                  end
              end
          end
      end     
  end
   
   %% 左边                                                                               %非边缘距离点
  for i_L = 1:CFAR_WINDOW                                                    %这个可以一个for循环里面存2个点数据，并且比较
      index_L = idx-CFAR_GUARD-i_L;
      if ( index_L > 0 )
          if RangeData(index_L)~=0
              data_sum = data_sum + RangeData(index_L);
              i_temp = i_temp+1;
              index_num(i_temp) = index_L;              
             %% find the min value
              if ( (RemoveMin_Flag) && ( RangeData(index_L) < value_min ) )
                  value_min = RangeData(index_L);
              end
          end
      else %%左边不够，向右取，跳过右窗覆盖范围，且<右边界，差几个连着取几个
          index_L = idx+CFAR_GUARD+CFAR_WINDOW+(CFAR_WINDOW-i_L+1);
          if ( (index_L > 0) && (index_L <= ROW) )
              if RangeData( index_L )~=0
                  data_sum = data_sum + RangeData( index_L );
                  i_temp = i_temp+1;
                  index_num(i_temp) = index_L;
                 %% find the min value
                  if ( (RemoveMin_Flag) && ( RangeData( index_L ) < value_min ) )
                      value_min = RangeData( index_L );
                  end
              end
          end
      end     
  end
 
            
   %% 取平均
   if (i_temp >= 1)
        if ( (RemoveMin_Flag) && (value_min ~= 0) && (i_temp > 2) )
            data_sum = data_sum - value_min;
            i_temp = i_temp - 1;
        end
        Range_NoiseFloor_CA = floor(data_sum / i_temp);
   else
        Range_NoiseFloor_CA = 0;
   end
    
end

function    Range_NoiseFloor_GO = Range_GOCFAR_new(idx,ROW,CFAR_WINDOW,CFAR_GUARD,RangeData,RemoveMin_Flag)    
    Range_NoiseFloor_GO = 0;
    iR_temp = 0;
    iL_temp = 0;
    dataRight_sum = 0;
    dataLift_sum = 0;
    valueR_min = 65536;
    valueL_min = 65536;
  %% （1）距离维前边缘保护，左窗参考单元不足，只取右窗
    if(idx <= CFAR_WINDOW + CFAR_GUARD)                                     %距离维前边缘保护，左窗参考单元不足，只取右窗
        for i = 1:CFAR_WINDOW                                                   %这个可以一个for循环里面存2个点数据，并且比较
            IdxR = idx + CFAR_GUARD + i;  
            if RangeData(IdxR) ~= 0
                dataRight_sum = dataRight_sum + RangeData(IdxR);
                iR_temp = iR_temp + 1;
                indexR_num(iR_temp) = IdxR;                                 %记录左窗选取bin格的index
               %% find the min right value
                if ( (RemoveMin_Flag) && ( RangeData(IdxR) < valueR_min ) )
                    valueR_min = RangeData(IdxR);
                end
            end
        end  
  %% （2）距离维后边缘保护，右窗参考单元不足，只取左窗         
    elseif((idx > ROW-CFAR_WINDOW-CFAR_GUARD) && (idx <= ROW))              %距离维后边缘保护，右窗参考单元不足，只取左窗                                      
        for i = 1:CFAR_WINDOW                                               %这个可以一个for循环里面存2个点数据，并且比较
             IdxL = idx - CFAR_GUARD - CFAR_WINDOW - 1 + i;
            if RangeData(IdxL)~=0
                dataLift_sum = dataLift_sum + RangeData(IdxL);
                iL_temp = iL_temp+1;
                indexL_num(iL_temp) = IdxL;                                 %记录左窗选取bin格的index   
               %% find the min lift value
                if ( (RemoveMin_Flag) && ( RangeData(IdxL) < valueL_min ) )
                    valueL_min = RangeData(IdxL);
                end
            end
        end
  %% （3）非边缘距离点，左窗+右窗     
    else                                                                                          %非边缘距离点，左窗+右窗
        for i = 1:CFAR_WINDOW                                                   %这个可以一个for循环里面存2个点数据，并且比较
            IdxR = idx + CFAR_GUARD + i;  
            if (RangeData(IdxR) ~= 0)
                dataRight_sum = dataRight_sum + RangeData(IdxR);
                iR_temp = iR_temp + 1;
                indexR_num(iR_temp) = IdxR;                                 %记录左窗选取bin格的index      
               %% find the min right value
                if ( (RemoveMin_Flag) && ( RangeData(IdxR) < valueR_min ) )
                    valueR_min = RangeData(IdxR);
                end
            end
            
            IdxL = idx - CFAR_GUARD - CFAR_WINDOW - 1 + i;
            if (RangeData(IdxL)~=0)
                dataLift_sum = dataLift_sum + RangeData(IdxL);
                iL_temp = iL_temp+1;
                indexL_num(iL_temp) = IdxL;                                 %记录左窗选取bin格的index   
               %% find the min lift value
                if ( (RemoveMin_Flag) && ( RangeData(IdxL) < valueL_min ) )
                    valueL_min = RangeData(IdxL);
                end
            end
            
        end              
    end
    
   %% （4）取平均，选大       
   if ( (iL_temp < 1) && (iR_temp >= 1) )
       if ( (RemoveMin_Flag) && (valueR_min ~= 0)  && (iR_temp > 2) )
           dataRight_sum = dataRight_sum - valueR_min;
           iR_temp = iR_temp - 1;
       end       
       Range_NoiseFloor_GO = floor(dataRight_sum / iR_temp);
       
   elseif ( (iL_temp >= 1) && (iR_temp < 1) )
       if ( (RemoveMin_Flag) && (valueL_min ~= 0) && (iL_temp > 2) )
           dataLift_sum = dataLift_sum - valueL_min;
           iL_temp = iL_temp - 1;
       end
       Range_NoiseFloor_GO = floor(dataLift_sum / iL_temp);
       
   elseif ( (iL_temp >= 1) && (iR_temp >= 1) )
       if ( (RemoveMin_Flag) && (valueR_min ~= 0) && (iR_temp > 2) )
           dataRight_sum = dataRight_sum - valueR_min;
           iR_temp = iR_temp - 1;
       end
       if ( (RemoveMin_Flag) && (valueL_min ~= 0) && (iL_temp > 2) )
           dataLift_sum = dataLift_sum - valueL_min;
           iL_temp = iL_temp - 1;
       end
       
       tmpR = dataRight_sum / iR_temp;
       tmpL = dataLift_sum / iL_temp;
       
       if (tmpR > tmpL)
           Range_NoiseFloor_GO = floor(tmpR);
       else
           Range_NoiseFloor_GO = floor(tmpL);
       end
       
   end
   
   
end

function    Range_NoiseFloor_OS = Range_OSCFAR(idx,ROW,CFAR_WINDOW,CFAR_GUARD,RangeData,osRangeK)        
    Range_NoiseFloor_OS=0;
    data_zero=0;
    winsize=CFAR_WINDOW*2;
    value_max = 0;
    max_index=0;
    value_min = 65536;
    min_index=0;
    i_temp=1;
    
  %%  
    if(idx<=CFAR_WINDOW+CFAR_GUARD)                                  %距离维前边缘保护
        if(idx<=CFAR_GUARD+1)                                            %  参考单元不足
            for i=1:winsize                                              %这个可以一个for循环里面存2个点数据，并且比较
                needSortsz(i) = RangeData(idx+CFAR_GUARD+i);
                index_num(i_temp)=idx+CFAR_GUARD+i;                      %记录选取bin格的index
                i_temp=i_temp+1;
                if     needSortsz(i)>value_max                            %比较大小
                        value_max=needSortsz(i);
                        max_index=i;
                elseif needSortsz(i)<value_min
                        value_min=needSortsz(i);
                        min_index=i;
                end
            end
          
        else                                                             %    
            for i=1:winsize                                                                 %这个可以一个for循环里面存2个点数据，并且比较 似乎可以优化，少个判断，有空看
                if     i<=CFAR_GUARD+CFAR_WINDOW+1-idx
                        needSortsz(i) = RangeData(idx+CFAR_GUARD+CFAR_WINDOW+i);
                        index_num(i_temp)=idx+CFAR_GUARD+CFAR_WINDOW+i;                      %记录选取bin格的index
                        i_temp=i_temp+1;
                elseif i<=CFAR_WINDOW
                        needSortsz(i) = RangeData(idx-CFAR_GUARD-CFAR_WINDOW-1+i);
                        index_num(i_temp)=idx-CFAR_GUARD-CFAR_WINDOW-1+i;                    %记录选取bin格的index
                        i_temp=i_temp+1;
                else
                        needSortsz(i) = RangeData(idx+CFAR_GUARD+i-CFAR_WINDOW);
                        index_num(i_temp)=idx+CFAR_GUARD+i-CFAR_WINDOW;                      %记录选取bin格的index
                        i_temp=i_temp+1;
                end    
                if needSortsz(i)>value_max
                    value_max=needSortsz(i);
                    max_index=i;
                elseif needSortsz(i)<value_min
                    value_min=needSortsz(i);
                    min_index=i;
                end
            end
        
        end
        
  %%
    elseif(idx<=ROW && idx>ROW-CFAR_WINDOW-CFAR_GUARD)                     %距离维后边缘保护
       
        if(idx>=ROW-CFAR_GUARD)                                            %  参考单元不足
            for i=1:winsize                                                %这个可以一个for循环里面存2个点数据，并且比较
                needSortsz(i)       = RangeData(idx-CFAR_GUARD-winsize-1+i);
                index_num(i_temp)   = idx-CFAR_GUARD-winsize-1+i;                      %记录选取bin格的index
                i_temp              = i_temp+1;
                if needSortsz(i)>value_max
                    value_max       = needSortsz(i);
                    max_index       = i;
                elseif needSortsz(i)<value_min
                    value_min       = needSortsz(i);
                    min_index       = i;
                end
            end
              
        else                                                             %    
            for i=1:winsize                                                                  %这个可以一个for循环里面存2个点数据，并且比较
                if     i<=ROW-idx-CFAR_GUARD
                        needSortsz(i) = RangeData(idx+CFAR_GUARD+i);
                        index_num(i_temp)=idx+CFAR_GUARD+i;                      %记录选取bin格的index
                        i_temp=i_temp+1;
                else
                        needSortsz(i) = RangeData(idx-CFAR_GUARD-winsize-1+i);
                        index_num(i_temp)=idx-CFAR_GUARD-winsize-1+i;                    %记录选取bin格的index
                        i_temp=i_temp+1;
                end    
                
                if     needSortsz(i)>value_max
                        value_max=needSortsz(i);
                    	max_index=i;
                elseif needSortsz(i)<value_min
                        value_min=needSortsz(i);
                        min_index=i;
                end
            end
            
        end
  %%      
    else                                                                   %非边缘距离点
            for i=1:CFAR_WINDOW                                                %这个可以一个for循环里面存2个点数据，并且比较
                needSortsz(i)              = RangeData(idx-CFAR_GUARD-CFAR_WINDOW-1+i);
                index_num(i)               = idx-CFAR_GUARD-CFAR_WINDOW-1+i;
                needSortsz(i+CFAR_WINDOW)  = RangeData(idx+CFAR_GUARD+i); %记录选取bin格的index
                index_num(i+CFAR_WINDOW)   = idx+CFAR_GUARD+i;                      %记录选取bin格的index
                if needSortsz(i)<=needSortsz(i+CFAR_WINDOW)                
                    if needSortsz(i+CFAR_WINDOW)>value_max
                        value_max=needSortsz(i+CFAR_WINDOW);
                        max_index=i+CFAR_WINDOW;
                    end
                    if needSortsz(i)<value_min
                        value_min=needSortsz(i);
                        min_index=i;
                    end
                else
                    if needSortsz(i)>value_max
                        value_max=needSortsz(i);
                        max_index=i;
                    end
                    if needSortsz(i+CFAR_WINDOW)<value_min
                        value_min=needSortsz(i+CFAR_WINDOW);
                        min_index=i+CFAR_WINDOW;
                    end
                end
            end
            
   %%  
    end
   %% OS排序
% min_index
% max_index
index_num;
needSortsz;        
% ——————————— %嵌入式排序—————————————————————————————         
% %           Range_sort1=needSortsz;
% %            for i=1:winsize-osRangeK+1
% %                for j=i+1:winsize
% %                    if Range_sort1(i)<Range_sort1(j)
% %                     min_temp=Range_sort1(i);
% %                     Range_sort1(i)=Range_sort1(j);
% %                     Range_sort1(j)=min_temp;
% %                    end
% % 
% %                end
% %             end
% %             Range_NoiseFloor_OS1 = Range_sort1(winsize-osRangeK+1)
%————————————————————————————————————————————       
%*****************************************************************************
%————————————————————部分排序————————————————————
        max_temp=needSortsz(1);
        needSortsz(1)=needSortsz(max_index);
        needSortsz(max_index)=max_temp;
        if winsize == 2
            Range_NoiseFloor_OS=needSortsz(winsize);
        else
            if min_index == 1
                min_temp=needSortsz(winsize);
                needSortsz(winsize)=needSortsz(max_index);
                needSortsz(max_index)=min_temp; 
            else
                min_temp=needSortsz(winsize);
                needSortsz(winsize)=needSortsz(min_index);
                needSortsz(min_index)=min_temp; 
            end
            for i=2:winsize-osRangeK+1
               for j=i+1:winsize-1
                   if needSortsz(i)<needSortsz(j)
                    min_temp=needSortsz(i);
                    needSortsz(i)=needSortsz(j);
                    needSortsz(j)=min_temp;
                   end

               end
            end
            Range_NoiseFloor_OS = needSortsz(winsize-osRangeK+1);
        end
%————————————————————————————————————————
end

function    Range_NoiseFloor_CMLD = Range_CMLD_CFAR(idx,ROW,CFAR_WINDOW,CFAR_GUARD,RangeData,removeMax_r,removeMin_r)    
    Range_NoiseFloor_CMLD = 0;
    iR_temp = 0;iL_temp = 0;i_temp = 0;
    indexR = 0;indexL = 0;
    data_sum = 0;
    
    indexList_R = zeros(1,CFAR_WINDOW);
    indexList_L = zeros(1,CFAR_WINDOW);
    
  %% 右边参考单元下标
  for i_R = 1:(CFAR_WINDOW + removeMax_r + removeMin_r)                                                    %这个可以一个for循环里面存2个点数据，并且比较
      if (iR_temp >= CFAR_WINDOW) 
          break;
      end
        
      if ( idx+CFAR_GUARD+i_R <= ROW )
          iR_temp = iR_temp + 1;
          indexList_R(iR_temp) = idx+CFAR_GUARD+i_R; 
      else %%右边不够，向左取，跳过左窗覆盖范围，且>左边界，差几个连着取几个
          if ( (idx-CFAR_GUARD-CFAR_WINDOW-(CFAR_WINDOW-i_R+1) > 0) && (idx-CFAR_GUARD-CFAR_WINDOW-(CFAR_WINDOW-i_R+1) <= ROW) )
              iR_temp = iR_temp + 1;
              indexList_R(iR_temp) = idx-CFAR_GUARD-CFAR_WINDOW-(CFAR_WINDOW-i_R+1);
          end
      end     
  end
   
   %% 左边参考单元下标                                                 %非边缘距离点
  for i_L = 1:(CFAR_WINDOW + removeMax_r+ removeMin_r)                                                    %这个可以一个for循环里面存2个点数据，并且比较
      if (iL_temp >= CFAR_WINDOW)
          break;
      end
        
      if ( idx-CFAR_GUARD-i_L > 0 )
          iL_temp = iL_temp + 1;
          indexList_L(iL_temp) = idx-CFAR_GUARD-i_L;           
      else %%左边不够，向右取，跳过右窗覆盖范围，且<右边界，差几个连着取几个
          if ( (idx+CFAR_GUARD+CFAR_WINDOW+(CFAR_WINDOW-i_L+1) > 0) && (idx+CFAR_GUARD+CFAR_WINDOW+(CFAR_WINDOW-i_L+1) <= ROW) )
              iL_temp = iL_temp + 1;
              indexList_L(iL_temp) = idx+CFAR_GUARD+CFAR_WINDOW+(CFAR_WINDOW-i_L+1);
          end
      end     
  end
 
%   if (idx==388 || idx==336 || idx==340||idx==325 || idx==339 || idx==250|| idx==225 || idx==231)
%       for i_R = 1:iR_temp
%           fprintf("555555-r1-CMLD-555555 i_range,i_R,iR_mag：%d,%d,%d,%d,%d,%d \n", idx,i_R,indexList_R(i_R),RangeData(indexList_R(i_R))); 
%       end
%       for i_L = 1:iL_temp
%           fprintf("555555-r1-CMLD-555555 i_range,i_R,iR_mag：%d,%d,%d,%d,%d,%d \n", idx,i_L,indexList_L(i_L),RangeData(indexList_L(i_L))); 
%       end
%   end
  
  %% 冒泡降序排序
  [indexList_endR] = Bubble_Sort(indexList_R,iR_temp,RangeData);
  [indexList_endL] = Bubble_Sort(indexList_L,iL_temp,RangeData);
  
%   if (idx==388 || idx==336 || idx==340||idx==325 || idx==339 || idx==250|| idx==225 || idx==231)
%       for i_R = 1:iR_temp
%           fprintf("555555-r2-CMLD-555555 i_range,i_R,iR_mag：%d,%d,%d,%d,%d,%d \n", idx,i_R,indexList_R(i_R),RangeData(indexList_R(i_R)));
%       end
%       for i_L = 1:iL_temp
%           fprintf("555555-r2-CMLD-555555 i_range,i_R,iR_mag：%d,%d,%d,%d,%d,%d \n", idx,i_L,indexList_L(i_L),RangeData(indexList_L(i_L)));
%       end
%   end
  
  %% 左右求和:分别去除removeMax_r个最大值，removeMin_r个最小值
  for i_R = (1+removeMax_r):(iR_temp-removeMin_r)   
      indexR = indexList_endR(i_R);
      if ( RangeData(indexR) ~= 0 )
          i_temp = i_temp + 1;
          data_sum = data_sum +  RangeData(indexR);
      end          
  end
  
  for i_L = (1+removeMax_r):(iL_temp-removeMin_r)     
      indexL = indexList_endL(i_L);
      if ( RangeData(indexL) ~= 0 )
          i_temp = i_temp + 1;
          data_sum = data_sum +  RangeData(indexL);
      end          
  end
            
   %% 取平均
    Range_NoiseFloor_CMLD = floor(data_sum / i_temp);
    
%     fprintf("555555-r3-CMLD-555555 data_sum,i_temp,R_Noise_CMLD,removeMax_r,removeMin_r：%d,%d,%d,%d,%d \n", data_sum, i_temp, Range_NoiseFloor_CMLD,removeMax_r,removeMin_r);
end
%%--------- remove the min value win ------------------%

function    Range_NoiseFloor_CA = Range_CACFAR(idx,ROW,CFAR_WINDOW,CFAR_GUARD,RangeData)    
    Range_NoiseFloor_CA=0;
    data_zero=0;
    winsize=CFAR_WINDOW*2;
    i_temp=1;
    data_sum=0;
  %%  
    if(idx<=CFAR_WINDOW+CFAR_GUARD)                                        %距离维前边缘保护
        if(idx<=CFAR_GUARD+1)                                              %  左边缘参考单元不足
            for i=1:winsize                                                %这个可以一个for循环里面存2个点数据，并且比较
                if RangeData(idx+CFAR_GUARD+i) ~= 0
                    data_sum = data_sum+RangeData(idx+CFAR_GUARD+i);       %%只取右边
                    index_num(i_temp)=idx+CFAR_GUARD+i;                        %记录选取bin格的index
                    i_temp=i_temp+1;
                end
            end
          
        else                                                               %    
            for i=1:winsize                                                                 %这个可以一个for循环里面存2个点数据，并且比较 似乎可以优化，少个判断，有空看
                if     i<=CFAR_GUARD+CFAR_WINDOW+1-idx
                    if RangeData(idx+CFAR_GUARD+CFAR_WINDOW+i) ~= 0
                        data_sum = data_sum+RangeData(idx+CFAR_GUARD+CFAR_WINDOW+i);
                        index_num(i_temp)=idx+CFAR_GUARD+CFAR_WINDOW+i;                      %记录选取bin格的index
                        i_temp=i_temp+1;
                    end
                elseif i<=CFAR_WINDOW
                    if RangeData(idx-CFAR_GUARD-CFAR_WINDOW-1+i)~=0
                        data_sum =  data_sum+RangeData(idx-CFAR_GUARD-CFAR_WINDOW-1+i);
                        index_num(i_temp)=idx-CFAR_GUARD-CFAR_WINDOW-1+i;                    %记录选取bin格的index
                        i_temp=i_temp+1;
                    end
                else
                    if RangeData(idx+CFAR_GUARD-CFAR_WINDOW+i)~=0
                        data_sum = data_sum+RangeData(idx+CFAR_GUARD-CFAR_WINDOW+i);
                        index_num(i_temp)=idx+CFAR_GUARD-CFAR_WINDOW+i;                      %记录选取bin格的index
                        i_temp=i_temp+1;
                    end
                end    
                
            end
        
        end
        
  %%
    elseif(idx<=ROW && idx>ROW-CFAR_WINDOW-CFAR_GUARD)                     %距离维后边缘保护
        if(idx>=ROW-CFAR_GUARD)                                            %  参考单元不足
            for i=1:winsize                                                %这个可以一个for循环里面存2个点数据，并且比较
                if RangeData(idx-CFAR_GUARD-winsize-1+i)~=0
                    data_sum            = data_sum+RangeData(idx-CFAR_GUARD-winsize-1+i);
                    index_num(i_temp)   = idx-CFAR_GUARD-winsize-1+i;                      %记录选取bin格的index
                    i_temp              = i_temp+1;
                end
            end
              
        else                                                             %    
            for i=1:winsize                                                                  %这个可以一个for循环里面存2个点数据，并且比较
                if     i<=ROW-idx-CFAR_GUARD
                    if RangeData(idx+CFAR_GUARD+i)~=0
                        data_sum            =  data_sum+RangeData(idx+CFAR_GUARD+i);
                        index_num(i_temp)   = idx+CFAR_GUARD+i;                              %记录选取bin格的index
                        i_temp=i_temp+1;
                    end
                else
                    if RangeData(idx-CFAR_GUARD-winsize-1+i)~=0
                        data_sum            = data_sum+ RangeData(idx-CFAR_GUARD-winsize-1+i);
                        index_num(i_temp)   =idx-CFAR_GUARD-winsize-1+i;                    %记录选取bin格的index
                        i_temp=i_temp+1;
                    end
                end    
                
                
            end
            
        end
  %%      
    else                                                                           %非边缘距离点
            for i=1:CFAR_WINDOW                                                    %这个可以一个for循环里面存2个点数据，并且比较
                if RangeData(idx-CFAR_GUARD-CFAR_WINDOW-1+i)~=0
                    data_sum                  = data_sum+RangeData(idx-CFAR_GUARD-CFAR_WINDOW-1+i);
                    index_num(i_temp)              = idx-CFAR_GUARD-CFAR_WINDOW-1+i;
                    i_temp=i_temp+1;
                end
                if RangeData(idx+CFAR_GUARD+i)~=0
                    data_sum                  = data_sum+RangeData(idx+CFAR_GUARD+i); %记录选取bin格的index
                    index_num(i_temp)  = idx+CFAR_GUARD+i;                      %记录选取bin格的index
                    i_temp=i_temp+1;
                end
            end
            
   %%  
    end
    index_num;
    Range_NoiseFloor_CA = floor(data_sum/(i_temp-1));
end

function    Range_NoiseFloor_GO = Range_GOCFAR(idx,ROW,CFAR_WINDOW,CFAR_GUARD,RangeData)    
    Range_NoiseFloor_GO = 0;
    iR_temp = 1;
    iL_temp = 1;
    dataRight_sum = 0;
    dataLift_sum = 0;
  %% （1）距离维前边缘保护，左窗参考单元不足，只取右窗
    if(idx <= CFAR_WINDOW + CFAR_GUARD)                                     %距离维前边缘保护，左窗参考单元不足，只取右窗
        for i = 1:CFAR_WINDOW                                                   %这个可以一个for循环里面存2个点数据，并且比较
            IdxR = idx + CFAR_GUARD + i;  
            if RangeData(IdxR) ~= 0
                dataRight_sum = dataRight_sum + RangeData(IdxR);
                indexR_num(iR_temp) = IdxR;                                 %记录左窗选取bin格的index
                iR_temp = iR_temp + 1;
            end
        end  
  %% （2）距离维后边缘保护，右窗参考单元不足，只取左窗         
    elseif((idx > ROW-CFAR_WINDOW-CFAR_GUARD) && (idx <= ROW))              %距离维后边缘保护，右窗参考单元不足，只取左窗                                      
        for i = 1:CFAR_WINDOW                                               %这个可以一个for循环里面存2个点数据，并且比较
             IdxL = idx - CFAR_GUARD - CFAR_WINDOW - 1 + i;
            if RangeData(IdxL)~=0
                dataLift_sum = dataLift_sum + RangeData(IdxL);
                indexL_num(iL_temp) = IdxL;                                 %记录左窗选取bin格的index
                iL_temp = iL_temp+1;
            end
        end
  %% （3）非边缘距离点，左窗+右窗     
    else                                                                                          %非边缘距离点，左窗+右窗
        for i = 1:CFAR_WINDOW                                                   %这个可以一个for循环里面存2个点数据，并且比较
            IdxR = idx + CFAR_GUARD + i;  
            if (RangeData(IdxR) ~= 0)
                dataRight_sum = dataRight_sum + RangeData(IdxR);
                indexR_num(iR_temp) = IdxR;                                 %记录左窗选取bin格的index
                iR_temp = iR_temp + 1;
            end
            
            IdxL = idx - CFAR_GUARD - CFAR_WINDOW - 1 + i;
            if (RangeData(IdxL)~=0)
                dataLift_sum = dataLift_sum + RangeData(IdxL);
                indexL_num(iL_temp) = IdxL;                                 %记录左窗选取bin格的index
                iL_temp = iL_temp+1;
            end
            
        end              
    end
    
   %% （4）取平均，选大
   if ((iL_temp < 2) && (iR_temp >= 2))
       
       Range_NoiseFloor_GO = floor(dataRight_sum / (iR_temp-1));
       
   elseif ((iL_temp >= 2) && (iR_temp < 2))
       
       Range_NoiseFloor_GO = floor(dataLift_sum / (iL_temp-1));
       
   elseif ((iL_temp >= 2) && (iR_temp >= 2))
       
       tmpR = dataRight_sum / (iR_temp-1);
       tmpL = dataLift_sum / (iL_temp-1);
       if (tmpR > tmpL)
           Range_NoiseFloor_GO = floor(tmpR);
       else
           Range_NoiseFloor_GO = floor(tmpL);
       end
       
   end
   
   
end

function    Range_NoiseFloor_GO = Range_newGOCFAR(idx,ROW,CFAR_WINDOW,CFAR_GUARD,RangeData)    
    Range_NoiseFloor_GO = 0;
    iR_temp = 1;
    iL_temp = 1;
    dataRight_sum = 0;
    dataLift_sum = 0;
  %% （1）距离维前边缘保护，左窗参考单元不足，只取右窗
    if(idx <= CFAR_WINDOW + CFAR_GUARD)                                     %距离维前边缘保护，左窗参考单元不足，只取右窗
        for i = 1:CFAR_WINDOW                                                   %这个可以一个for循环里面存2个点数据，并且比较
            IdxR = idx + CFAR_GUARD + i;  
            if RangeData(IdxR) ~= 0
                dataRight_sum = dataRight_sum + RangeData(IdxR);
                indexR_num(iR_temp) = IdxR;                                 %记录左窗选取bin格的index
                iR_temp = iR_temp + 1;
            end
        end  
  %% （2）距离维后边缘保护，右窗参考单元不足，只取左窗         
    elseif((idx > ROW-CFAR_WINDOW-CFAR_GUARD) && (idx <= ROW))              %距离维后边缘保护，右窗参考单元不足，只取左窗                                      
        for i = 1:CFAR_WINDOW                                               %这个可以一个for循环里面存2个点数据，并且比较
             IdxL = idx - CFAR_GUARD - CFAR_WINDOW - 1 + i;
            if RangeData(IdxL)~=0
                dataLift_sum = dataLift_sum + RangeData(IdxL);
                indexL_num(iL_temp) = IdxL;                                 %记录左窗选取bin格的index
                iL_temp = iL_temp+1;
            end
        end
  %% （3）非边缘距离点，左窗+右窗     
    else                                                                                          %非边缘距离点，左窗+右窗
        for i = 1:CFAR_WINDOW                                                   %这个可以一个for循环里面存2个点数据，并且比较
            IdxR = idx + CFAR_GUARD + i;  
            if (RangeData(IdxR) ~= 0)
                dataRight_sum = dataRight_sum + RangeData(IdxR);
                indexR_num(iR_temp) = IdxR;                                 %记录左窗选取bin格的index
                iR_temp = iR_temp + 1;
            end
            
            IdxL = idx - CFAR_GUARD - CFAR_WINDOW - 1 + i;
            if (RangeData(IdxL)~=0)
                dataLift_sum = dataLift_sum + RangeData(IdxL);
                indexL_num(iL_temp) = IdxL;                                 %记录左窗选取bin格的index
                iL_temp = iL_temp+1;
            end
            
        end              
    end
    
   %% （4）取平均，选大
   if ((iL_temp < 2) && (iR_temp >= 2))
       
       Range_NoiseFloor_GO = floor(dataRight_sum / (iR_temp-1));
       
   elseif ((iL_temp >= 2) && (iR_temp < 2))
       
       Range_NoiseFloor_GO = floor(dataLift_sum / (iL_temp-1));
       
   elseif ((iL_temp >= 2) && (iR_temp >= 2))
       
       tmpR = dataRight_sum / (iR_temp-1);
       tmpL = dataLift_sum / (iL_temp-1);
       if (tmpR > tmpL)
           Range_NoiseFloor_GO = floor(tmpR);
       else
           Range_NoiseFloor_GO = floor(tmpL);
       end
       
   end
   
   
end



%%%%%%%%%%%%%%%% Doppler CFAR %%%%%%%%%%%%%%%%%%
%%--------- remove the min+max value win ------------------%
function Doppler_NoiseFloor_CA = Doppler_CACFAR_NEW(idx,COL,CFAR_WINDOW,CFAR_GUARD,DopplerData,RemoveMax_Flag,RemoveMin_Flag)
    Doppler_NoiseFloor_CA   =   0;
    data_zero               =   0;
    winsize                 =   CFAR_WINDOW*2;
    i_temp                  =   1;
    data_sum                =   0;
    value_max               =   0;
    value_min               =   65536;
    
    iL_temp = 0; iR_temp = 0;
    use_L = 0;use_R = 0;

%     %%test
%     indexList_left =[1:CFAR_WINDOW+3];
%     indexList_right =[COL:-1:COL-CFAR_WINDOW-3];

       for i = 1:(CFAR_WINDOW+3)
           
           if ( (iL_temp >= CFAR_WINDOW) && (iR_temp >= CFAR_WINDOW) )
               break;
           end
           
           use_L = 0;use_R = 0;
           
%            index_left = idx-CFAR_GUARD-CFAR_WINDOW-1-i;
           index_left = idx - CFAR_GUARD - i;
           index_right = idx + CFAR_GUARD + i;
 %-------------------------------------------------------------------------           
            if( index_left <= 0 )
                index_left = index_left + COL;
            end
            
            if( index_right > COL )
                index_right = index_right - COL;
            end                
 %-------------------------------------------------------------------------    
            if (iL_temp < CFAR_WINDOW)
                if DopplerData(index_left)~=0
                    if (index_left ~= 1 && index_left ~= 2 && index_left ~= COL)
                        use_L = 1;  %%记录左窗当前参考单元有效的标记
                        data_sum = data_sum+ DopplerData(index_left);
                        iL_temp = iL_temp + 1;
                        index_num(iL_temp)   = index_left;      %记录选取bin格的index
                    end
                end 
            end
            
            if (iR_temp < CFAR_WINDOW)
                if DopplerData(index_right)~=0
                    if (index_right ~= 1 && index_right ~= 2 && index_right ~= COL)
                        use_R = 1;%%记录右窗当前参考单元有效的标记
                        data_sum = data_sum+ DopplerData(index_right);
                        iR_temp = iR_temp + 1;
                        index_num(CFAR_WINDOW+iR_temp)   = index_right;                    %记录选取bin格的index

                    end
                end
            end
                       
%-----------------------------------------------------------------------   
           %% the max value
            if ( (use_L == 1) && ( DopplerData(index_left) > value_max) )
                value_max   =   DopplerData(index_left);
            end
            if ( (use_R == 1) && ( DopplerData(index_right) > value_max) )
                value_max   =   DopplerData(index_right);
            end
           %% the min value
            if ( (use_L == 1) && ( DopplerData(index_left) < value_min) )
                value_min   =   DopplerData(index_left);
            end
            if ( (use_R == 1) && ( DopplerData(index_right) < value_min) )
                value_min   =   DopplerData(index_right);
            end
    
       end
%-----------------------------------------------------------------------   
    i_temp = iL_temp + iR_temp;
    
    if (i_temp >= 1)
        if ( (i_temp > 3) )
           if ( (RemoveMax_Flag) && (value_max ~= 0) )
               data_sum = data_sum - value_max;
               i_temp = i_temp - 1;
           end
           if ( (RemoveMin_Flag) && (value_min ~= 0) )
               data_sum = data_sum - value_min;
               i_temp = i_temp - 1;
           end
        end
       Doppler_NoiseFloor_CA = floor((data_sum) / (i_temp));        
    else
        Doppler_NoiseFloor_CA = 0;
    end      
 
    index_num;
end

%%--------- remove the min+max value win ------------------%
function Doppler_NoiseFloor_GO = Doppler_GOCFAR_NEW(idx,COL,CFAR_WINDOW,CFAR_GUARD,DopplerData,RemoveMax_Flag,RemoveMin_Flag)
    Doppler_NoiseFloor_CA   =   0;
    iR_temp = 0;
    iL_temp = 0;
    dataR_sum = 0;
    dataL_sum = 0;
    valueR_max = 0;
    valueL_max = 0;
    valueR_min = 65536;
    valueL_min = 65536;
    
    use_L = 0;use_R = 0;
        
  %%  （1）（翻转）左窗+右窗   
  for i = 1:(CFAR_WINDOW+3)
      
      if ( (iL_temp >= CFAR_WINDOW) && (iR_temp >= CFAR_WINDOW) )
          break;
      end
      
      use_L = 0;use_R = 0;
      
%       index_left = idx - CFAR_GUARD - CFAR_WINDOW - 1 - i;
      index_left = idx - CFAR_GUARD - i;
      index_right = idx + CFAR_GUARD + i;
%-------------------------------------------------------------------------           
        if (index_left <= 0)
            index_left = index_left + COL;
        end

        if(index_right > COL)
            index_right = index_right - COL;
        end
%-------------------------------------------------------------------------   
        if ( iL_temp < CFAR_WINDOW )
            if (DopplerData(index_left) ~= 0)
                if (index_left ~= 1 && index_left ~= 2 && index_left ~= COL)
                    use_L = 1;  %%记录左窗当前参考单元有效的标记
                    dataL_sum = dataL_sum + DopplerData(index_left);
                    iL_temp = iL_temp + 1;
                    indexL_num(iL_temp) = index_left;                    %记录选取bin格的index
                end
            end 
        end
        
        if ( iR_temp < CFAR_WINDOW )
            if (DopplerData(index_right) ~= 0)
                if (index_right ~= 1 && index_right ~= 2 && index_right ~= COL)
                    use_R = 1;%%记录右窗当前参考单元有效的标记
                    dataR_sum = dataR_sum + DopplerData(index_right);
                    iR_temp = iR_temp + 1;
                    indexR_num(iR_temp) = index_right;                    %记录选取bin格的index                    
                end
            end
        end
%-----------------------------------------------------------------------   
        %% the max value
        if ( (use_L == 1) && (DopplerData(index_left) > valueL_max) )
            valueL_max = DopplerData(index_left);
        end            

        if ( (use_R == 1) && (DopplerData(index_right) > valueR_max) )
            valueR_max = DopplerData(index_right);
        end    
        
        %% the min value
        if ( (use_L == 1) && (DopplerData(index_left) < valueL_min) )
            valueL_min = DopplerData(index_left);
        end            

        if ( (use_R == 1) && (DopplerData(index_right) < valueR_min) )
            valueR_min = DopplerData(index_right);
        end 

   end
%-----------------------------------------------------------------------          
       
   %% （2）取平均，选大   
   %% mean(meanR,meanL) 
   if ( (iL_temp >= 1) && (iR_temp >= 1) )
       %% the left part
       if ( (iL_temp > 3) )
           if ( (RemoveMax_Flag) && (valueL_max ~= 0) )
               dataL_sum = dataL_sum - valueL_max;
               iL_temp = iL_temp - 1;
           end
           if ( (RemoveMin_Flag) && (valueL_min ~= 0) )
               dataL_sum = dataL_sum - valueL_min;
               iL_temp = iL_temp - 1;
           end
       end
       mean_L = (dataL_sum) / (iL_temp);
       %% the right part
       if ( (iR_temp > 3) )
           if ( (RemoveMax_Flag) && (valueR_max ~= 0) )
               dataR_sum = dataR_sum - valueR_max;
               iR_temp = iR_temp - 1;
           end
           if ( (RemoveMin_Flag) && (valueR_min ~= 0) )
               dataR_sum = dataR_sum - valueR_min;
               iR_temp = iR_temp - 1;
           end
       end
       mean_R = (dataR_sum) / (iR_temp);
       
       %% chose the max part
       if (mean_R > mean_L)
           Doppler_NoiseFloor_GO = floor(mean_R);
       else
           Doppler_NoiseFloor_GO = floor(mean_L);
       end
       
   elseif ((iL_temp >= 1) && (iR_temp < 1))
       %% only the left part
       if ( (iL_temp > 3) )
           if ( (RemoveMax_Flag) && (valueL_max ~= 0) )
               dataL_sum = dataL_sum - valueL_max;
               iL_temp = iL_temp - 1;
           end
           if ( (RemoveMin_Flag) && (valueL_min ~= 0) )
               dataL_sum = dataL_sum - valueL_min;
               iL_temp = iL_temp - 1;
           end
       end
       Doppler_NoiseFloor_GO = floor((dataL_sum) / (iL_temp));
              
   elseif ((iL_temp < 1) && (iR_temp >= 1))
       %% only the right part
       if ( (iR_temp > 3) )
           if ( (RemoveMax_Flag) && (valueR_max ~= 0) )
               dataR_sum = dataR_sum - valueR_max;
               iR_temp = iR_temp - 1;
           end
           if ( (RemoveMin_Flag) && (valueR_min ~= 0) )
               dataR_sum = dataR_sum - valueR_min;
               iR_temp = iR_temp - 1;
           end
       end
       Doppler_NoiseFloor_GO = floor((dataR_sum) / (iR_temp));
       
   else
       Doppler_NoiseFloor_GO = 0;
   end        
       
end

%%--------- remove the min+max value win ------------------%
function Doppler_NoiseFloor_CMLD = Doppler_CMLD_CFAR(idx,COL,CFAR_WINDOW,CFAR_GUARD,DopplerData,removeMax_r)
    Doppler_NoiseFloor_CMLD = 0;
    iR_temp = 0;iL_temp = 0;i_temp = 0;
    indexR = 0;indexL = 0;
    data_sum = 0;
    
    indexList_R = zeros(1,CFAR_WINDOW);
    indexList_L = zeros(1,CFAR_WINDOW);

%     %%test
%     indexList_left =[1:CFAR_WINDOW+3];
%     indexList_right =[COL:-1:COL-CFAR_WINDOW-3];

    for i = 1:(CFAR_WINDOW + removeMax_r)

        if ( (iL_temp >= CFAR_WINDOW) && (iR_temp >= CFAR_WINDOW) )
            break;
        end

        index_left = idx - CFAR_GUARD - CFAR_WINDOW + (i-1);
        index_right = idx + CFAR_GUARD + i;
        %-------------------------------------------------------------------------
        if( index_left <= 0 )
            index_left = index_left + COL;
        end

        if( index_right > COL )
            index_right = index_right - COL;
        end
        %-------------------------------------------------------------------------
        if (iL_temp < CFAR_WINDOW)
            iL_temp = iL_temp + 1;
            indexList_L(iL_temp) = index_left;
        end

        if (iR_temp < CFAR_WINDOW)
            iR_temp = iR_temp + 1;
            indexList_R(iR_temp) = index_right;
        end
    end
%-----------------------------------------------------------------------   
    %% 冒泡降序排序
    [indexList_endR] = Bubble_Sort(indexList_R,iR_temp,DopplerData);
    [indexList_endL] = Bubble_Sort(indexList_L,iL_temp,DopplerData);
    
    %% 左右求和
    for i_R = (1+removeMax_r):iR_temp
        indexR = indexList_endR(i_R);
        if ( DopplerData(indexR) ~= 0 )
            i_temp = i_temp + 1;
            data_sum = data_sum +  DopplerData(indexR);
        end
    end
    
    for i_L = (1+removeMax_r):iL_temp
        indexL = indexList_endL(i_L);
        if ( DopplerData(indexL) ~= 0 )
            i_temp = i_temp + 1;
            data_sum = data_sum +  DopplerData(indexL);
        end
    end
    
    %% 取平均
    Doppler_NoiseFloor_CMLD = floor(data_sum / i_temp);
    
end

function Doppler_NoiseFloor = Doppler_CACFAR(idx,COL,CFAR_WINDOW,CFAR_GUARD,DopplerData)
    result=0;
    Doppler_NoiseFloor=0;
    for i=1:round(CFAR_WINDOW)
        index_left=idx-CFAR_GUARD-CFAR_WINDOW+i-1;
		index_right=idx+CFAR_GUARD+i;
        if(index_left<=0)
            index_left=index_left+COL;
        end
        if(index_right>COL)
            index_right=index_right-COL;
        end
        result=result+DopplerData(index_left);
		result=result+DopplerData(index_right);
    end
    Doppler_NoiseFloor=result/(CFAR_WINDOW*2);
end

