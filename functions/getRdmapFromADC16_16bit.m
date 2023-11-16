
function [info,adc_data_deal_A,rdmap,mtd_data_sumIQ_H,mtd_data_subIQ_H,DC1,comparePL] = getRdmapFromADC16_16bit(namelist,iFlie,cfarFlag,win,w_hamm)
global compare cutDC RANGE_BIN_ENABLE RANGE_BIN DOPPLER_BIN scanMode azimuthEnable elevationEnable WaveForm radarID calcLostFrameID comparePL_flag RDMdataPath

format long e
% beamAngle = zeros(2,1);
Ndoppler = DOPPLER_BIN;
Nrange = RANGE_BIN;

adcLeftShift = 0;
rangeWinBit = 15;
dopplerWinBit = 15;
rfftBit = 24;
dfftBit = 32;
offset1 = 2;
offset2 = 2;
mtd_data_sumIQ = zeros(Ndoppler,Nrange/2);
mtd_data_subIQ = zeros(Ndoppler,Nrange/2);

for kFile = iFlie:1:iFlie
    if(namelist(kFile).bytes ~= 2*2*Nrange*Ndoppler+128 ) %% 512k,256K+256K
        adc_data_deal_A = -1;
        rdmap = -1;
        mtd_data_sumIQ_H = -1;
        mtd_data_subIQ_H = -1;
        DC1 = -1;
        info = 0;
        comparePL = 0;
        continue;
    end 
    file_name = namelist(kFile).name; 
    
%获取文件路径
% file_name=uigetfile('*.dat');
fileID = fopen(file_name,'r');
rarray = fread(fileID);
fclose(fileID);

%%包头信息解析：128bytes
info.FrameID = rarray(4) * 2^24 + rarray(3) * 2^16 + rarray(2) * 256 + rarray(1);%%帧ID,uint32
info.waveType = rarray(8) * 2^24 + rarray(7) * 2^16 + rarray(6) * 256 + rarray(5);%%工作波形码,uint32
info.timestamp = rarray(16) * 2^56 + rarray(16) * 2^48 + rarray(14) * 2^40 + rarray(13) * 2^32 + rarray(12) * 2^24 + rarray(11) * 2^16 + rarray(10) * 256 + rarray(9);%%时间戳（ms）,uint64
info.azimuth = rarray(18) * 256 + rarray(17)-180;%%方位波束角，azimuth,int16
info.elevation = rarray(20) * 256 + rarray(19)-180;%%俯仰波束角，elevation,int16
info.aziScanCenter = rarray(21);%%方位扫描中心,int8
info.aziScanScope = rarray(22);%%方位扫描范围,int8
info.eleScanCenter = rarray(23);%%俯仰扫描中心,int8
info.eleScanScope = rarray(24);%%俯仰扫描范围,int8
info.trackTwsTasFlag = rarray(25);%%TWS和TAS波形标记：0TWS，1Tas,uint8
info.finalBeamFlag = rarray(26);%%一轮扫描最后一个波位标记,uint8
info.chirpTime=(rarray(28)*256+rarray(27))*50/1000;  % unit input:50ns, output us,uint16


%%新加
if (calcLostFrameID)
    adc_data_deal_A = zeros(Ndoppler,Nrange/2);
    rdmap = -1;
    mtd_data_sumIQ_H = -1;
    mtd_data_subIQ_H = -1;
    DC1 = -1;
    comparePL = 0;
    continue;
end

if (scanMode) 
% if (0) 
%%仅处理法线附近波位数据 —— 单波位不需要
if( abs(info.azimuth) > azimuthEnable  || abs(info.elevation) > elevationEnable )
    adc_data_deal_A = -1;
    rdmap = -1;
    mtd_data_sumIQ_H = -1;
    mtd_data_subIQ_H = -1;
    DC1 = -1;
    info = 0;
    comparePL = 0;
    return;
end
end

%数据重整:A路+B路
rarray = rarray(129:end);
LL = length(rarray);
adc_dataAB = zeros(1,LL/2);

for mm = 1:2:LL
    adc_dataAB((mm+1)/2) =  rarray(mm+1) * 256 + rarray(mm);
end
adc_data_A = adc_dataAB(2:2:end);%%AB通道输出相反
adc_data_B = adc_dataAB(1:2:end-1);

adc_data_A = reshape( adc_data_A(1:Nrange*Ndoppler),Nrange,Ndoppler  )';
adc_data_B = reshape( adc_data_B(1:Nrange*Ndoppler),Nrange,Ndoppler  )';


% %按照16进制对比数据
% adc_hex = cell(MTD_N,N);
% for ii= 1:MTD_N
%     for jj=1:N
%         data_temp=dec2hex(adc_data(ii,jj),4);
%         adc_hex{ii,jj}=data_temp;
%     end
% end 

% adc_bin = cell(MTD_N,N);
% for ii= 1:MTD_N
%     for jj=1:N
%         data_temp=dec2bin(adc_data(ii,jj),14);
%         adc_bin{ii,jj}=data_temp;
%     end
% end 

signIndex1 = find(adc_data_A >= 2^15);
adc_data_A(signIndex1) = adc_data_A(signIndex1) - 2^16;

signIndex1 = find(adc_data_B >= 2^15);
adc_data_B(signIndex1) = adc_data_B(signIndex1) - 2^16;

% adc_data_A_origin= [ zeros(Ndoppler,offset1),adc_data_A(:,offset1+1:Nrange-offset2),zeros(Ndoppler,offset2)] ;%%列对齐，ADC前10后6位为0，中间放入从第9列到倒数第N-8列的ADC数据
% adc_data_B_origin= [ zeros(Ndoppler,offset1),adc_data_B(:,offset1+1:Nrange-offset2),zeros(Ndoppler,offset2)] ;%%列对齐，ADC前10后6位为0，中间放入从第9列到倒数第N-8列的ADC数据
adc_data_A_origin= adc_data_A ;%%无调试字段时，前后无需置0
adc_data_B_origin= adc_data_B ;%%无调试字段时，前后无需置0


% %% ===================== (新加)去直流偏置 ======================%%
DC1 = mean(mean(adc_data_A_origin));
DC2 = mean(mean(adc_data_B_origin));
if (cutDC == 1)
    adc_data_deal_A = (adc_data_A_origin - DC1)*2^adcLeftShift;
    adc_data_deal_B = (adc_data_B_origin - DC2)*2^adcLeftShift;
else
    adc_data_deal_A = adc_data_A_origin*2^adcLeftShift;
    adc_data_deal_B = adc_data_B_origin*2^adcLeftShift;
end
% adc_data_deal_A = adc_data_A_origin;
% adc_data_deal_B = adc_data_B_origin;

%% ADC幅相校准(实数->复数)+和差波束合成
I = sqrt(-1);

[AmpA_JC,PhaseA_JC,AmpB_JC,PhaseB_JC] = calibrationParameter(radarID,WaveForm);

%%校准系数
DataA_JC = AmpA_JC * exp(I * PhaseA_JC);
DataB_JC = AmpB_JC * exp(I * PhaseB_JC);
DataA_JC1 = floor( DataA_JC * 2^12 );
DataB_JC1 = floor( DataB_JC * 2^12 );

%%复数相乘
adc_data_calibA1 = adc_data_deal_A * DataA_JC1;
adc_data_calibB1 = adc_data_deal_B * DataB_JC1;
adc_data_calibA = floor( adc_data_calibA1 / 2^12 );
adc_data_calibB = floor( adc_data_calibB1 / 2^12 );

%%复数相加、减——对齐PL处理
adc_data_sumIQ = floor((adc_data_calibA + adc_data_calibB)/2);
adc_data_subIQ = floor((adc_data_calibA - adc_data_calibB)/2);


% %%校准结果确认，正常流程需注释
% differA = adc_data_calibA - adc_data_calibA1;
% differB = adc_data_calibB - adc_data_calibB1;
% 
% figure,plot(real(differA));
% figure,plot(imag(differA));
% figure,plot(real(differB));
% figure,plot(imag(differB));

% figure,plot(real(adc_data_calibA(7,:)));hold on;
% plot(real(adc_data_calibB(7,:)));%%实部
% title("A、B通道实部对比——校准后",'FontSize',14);xlabel("采样点",'FontSize',14);ylabel("实部",'FontSize',14);
% 
% figure,plot(imag(adc_data_calibA(7,:)));hold on;
% plot(imag(adc_data_calibB(7,:)));%%虚部
% title("A、B通道虚部对比——校准后",'FontSize',14);xlabel("采样点",'FontSize',14);ylabel("虚部",'FontSize',14);
% 
% figure,plot(abs(adc_data_calibA(7,:)));hold on;
% plot(abs(adc_data_calibB(7,:)));%%幅度
% title("A、B通道幅度对比——校准后",'FontSize',14);xlabel("采样点",'FontSize',14);ylabel("幅度(°)",'FontSize',14);
% 
% figure,plot(angle(adc_data_calibA(7,:))*180/pi);hold on;
% plot(angle(adc_data_calibB(7,:))*180/pi);%%相位
% title("A、B通道相位对比——校准后",'FontSize',14);xlabel("采样点",'FontSize',14);ylabel("相位(°)",'FontSize',14);

%% ===================== 1D FFT ======================%%
% for k=1:MTD_N
%     fft_adc_data(k,:)=fft(adc_data_deal(k,:) .* win',N)*2/N;
% %     fft_adc_data(k,:)=fft(adc_data_deal(k,:) .* win',N);
%     % % % fft_adc_data(k,:)=fftshift(fft(adc_data_deal(k,:)));
% end

%% 1D FFT对齐FPGA
win_or = round(win/max(win)*(2^10-1));%%10bit
win_or = [win_or(1,1);win_or(1,1);win_or(1:Nrange-2,:)];
generics.C_NFFT_MAX = log2(RANGE_BIN);%%12，2^12=4096,2^10=1024
generics.C_ARCH = 3;%%generics.C_ARCH = 1;%%μ÷??++++++++++++++++++++++++++++
generics.C_HAS_NFFT = 0;
generics.C_USE_FLT_PT = 0;
generics.C_INPUT_WIDTH = 16; % Must be 32 if C_USE_FLT_PT = 1
generics.C_TWIDDLE_WIDTH = 16; % Must be 24 or 25 if C_USE_FLT_PT = 1
generics.C_HAS_SCALING = 0; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_BFP = 0; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_ROUNDING = 0; % Set to 0 if C_USE_FLT_PT = 1
samples = 2^generics.C_NFFT_MAX;
% Handle multichannel FFTs if required

%   input = input_raw;

  % Set point size for this transform
  nfft = generics.C_NFFT_MAX;
  % Set up scaling schedule: scaling_sch[1] is the scaling for the first stage
  % Scaling schedule to 1/N: 
  %    2 in each stage for Radix-4/Pipelined, Streaming I/O
  %    1 in each stage for Radix-2/Radix-2 Lite
  if generics.C_ARCH == 1 || generics.C_ARCH == 3
    scaling_sch = ones(1,floor(nfft/2)) * 2;
    if mod(nfft,2) == 1
      scaling_sch = [scaling_sch 1];
    end
  else
    scaling_sch = ones(1,nfft);
  end

  % Set FFT (1) or IFFT (0)
  direction = 1;
  
  % Run the MEX function

  %% 和路1DFFT
  rfft_data_sumIQ = zeros(Ndoppler,Nrange);
for k=1:Ndoppler
   adc_data_tmp1 = adc_data_sumIQ(k,:) .* win_or';%%16bit+10bit = 26bit
   adc_data_tmp2 = floor( adc_data_tmp1./ 2^11);%%floor( adc_data_tmp1./ 2^9),23bit,2^3,2^10,2^11,,2^10
   %% new add 1 
   ntBP = numerictype(1,16,0);
   x_BP = fi(adc_data_tmp2, 1, 23, 0) ;
   adc_data_tmp2_dec = (1.0 .* quantize(x_BP,ntBP)).';%%16bit
   Idx1 = find(adc_data_tmp2_dec >= 2^15);
   if(Idx1)
       adc_data_tmp2_dec(Idx1) = adc_data_tmp2_dec(Idx1) - 2^16;
   end
   adc_data_tmp2_end = adc_data_tmp2_dec;
   input1 = double(adc_data_tmp2_end)./double(2^15); 
%    adc_data_tmp3=floor(fft(adc_data_tmp2 ,N));

    %% output:2^(12(generics.C_NFFT_MAX)+16(generics.C_INPUT_WIDTH)+1)=2^29=[1][13][15](1Signedness+13IntegerLength+15FractionLength)
   [output, blkexp, overflow] = xfft_v9_1_bitacc_mex(generics, nfft, complex(input1), scaling_sch, direction);
   adc_data_tmp3 = output.'*2^15;%%Convert 15bit fraction to integer
   tmp1 = floor(adc_data_tmp3./2^8);%%Remove the lower 8bit fraction,2^8,2^6
% %    fft_adc_data(k,:) = floor(adc_data_tmp3./2^8);%%2^8
   %% new add 2   
   ntBP = numerictype(1,16,0);%%1st is sign￡?WordLength 16bit￡?FractionLength 0bit(EffectiveLength 15bit(last 8bit integer + front 7bit fraction))
   x_BP = fi(tmp1, 1, 16, 0) ;
   rfft_data_sumIQ(k,:) = quantize(x_BP,ntBP);
end

%% 差路1DFFT
  rfft_data_subIQ = zeros(Ndoppler,Nrange);
for k=1:Ndoppler
   adc_data_tmp1 = adc_data_subIQ(k,:) .* win_or';%%16bit+10bit = 26bit
   adc_data_tmp2 = floor( adc_data_tmp1./ 2^11);%%floor( adc_data_tmp1./ 2^9),23bit,2^3,2^10,2^11,,2^10
   %% new add 1 
   ntBP = numerictype(1,16,0);
   x_BP = fi(adc_data_tmp2, 1, 23, 0) ;
   adc_data_tmp2_dec = (1.0 .* quantize(x_BP,ntBP)).';%%16bit
   Idx1 = find(adc_data_tmp2_dec >= 2^15);
   if(Idx1)
       adc_data_tmp2_dec(Idx1) = adc_data_tmp2_dec(Idx1) - 2^16;
   end
   adc_data_tmp2_end = adc_data_tmp2_dec;
   input1 = double(adc_data_tmp2_end)./double(2^15); 
%    adc_data_tmp3=floor(fft(adc_data_tmp2 ,N));

    %% output:2^(12(generics.C_NFFT_MAX)+16(generics.C_INPUT_WIDTH)+1)=2^29=[1][13][15](1Signedness+13IntegerLength+15FractionLength)
   [output, blkexp, overflow] = xfft_v9_1_bitacc_mex(generics, nfft, complex(input1), scaling_sch, direction);
   adc_data_tmp3 = output.'*2^15;%%Convert 15bit fraction to integer
   tmp1 = floor(adc_data_tmp3./2^8);%%Remove the lower 8bit fraction,2^8,2^6
% %    fft_adc_data(k,:) = floor(adc_data_tmp3./2^8);%%2^8
   %% new add 2   
   ntBP = numerictype(1,16,0);%%1st is sign￡?WordLength 16bit￡?FractionLength 0bit(EffectiveLength 15bit(last 8bit integer + front 7bit fraction))
   x_BP = fi(tmp1, 1, 16, 0) ;
   rfft_data_subIQ(k,:) = quantize(x_BP,ntBP);
end


% if (0)
% %% 1DFFT结果相位和幅度评估
% A = abs(rfft_data_sumIQ(:,206));
% [~,Idx1] = max(A);
% [~,Idx2] = min(A);
% figure,plot(db(A));hold on;%%幅度
% xlabel("chirp",'FontSize',14);ylabel("幅度(dB)",'FontSize',14);
% if (WaveForm == 3)
%     title("1024*128波形，A、B通道幅度对比——校准后",'FontSize',14);
% else
%     title("4096*32波形，A、B通道幅度对比——校准后",'FontSize',14);
% end
% 
% P = phase(rfft_data_sumIQ(:,206))*180/pi;
% if (WaveForm == 3)
%     xi   =   1:128; % gap  
% else
%     xi   =   1:32; % gap  
% end
% yi    =   P;
% p   =   polyfit(xi, yi, 2);
% Py  =   polyval(p, xi);
% 
% figure,plot(P);hold on;plot(Py);hold on;%%相位
% xlabel("chirp",'FontSize',14);ylabel("相位(°)",'FontSize',14);
% if (WaveForm == 3)
%     title("1024*128波形，A、B通道相位对比——校准后",'FontSize',14);
% else
%     title("4096*32波形，A、B通道相位对比——校准后",'FontSize',14);
% end
% legend('实际变化曲线','拟合曲线');
% 
% figure,plot(P.'-Py);hold on;%%相位
% if (WaveForm == 3)
%     title("1024*128波形，相位实际曲线与拟合曲线残差",'FontSize',14);
% else
%     title("4096*32波形，相位实际曲线与拟合曲线残差",'FontSize',14);
% end
% 
% dBt_1 = db(abs(adc_data_sumIQ(Idx1,:)));
% dBt_2 = db(abs(adc_data_sumIQ(Idx2,:)));
% dBt_1(isinf(dBt_1)) = 0;
% dBt_2(isinf(dBt_2)) = 0;
% dBt_1 = dBt_1(dBt_1>0);
% dBt_2 = dBt_2(dBt_2>0);
% Var_t1 = var( dBt_1 );
% Var_t2 = var( dBt_2 );
% Var_t = var( dBt_1 - dBt_2 );
% figure,plot(dBt_1);hold on;plot(dBt_2);hold on;%%时域
% xlabel("采样点",'FontSize',14);ylabel("时域",'FontSize',14);
% if (WaveForm == 3)
% %     title(['1024*128波形，峰谷值时域对比，方差',num2str(Var_t)],'FontSize',14);
%     title('1024*128波形，峰谷值时域对比','FontSize',14);
% else
% %     title(['4096*32波形，峰谷值时域对比，方差',num2str(Var_t)],'FontSize',14);
%     title('4096*32波形，峰谷值时域对比','FontSize',14);
% end
% legend(['峰值点,方差',num2str(Var_t1)],['谷值点,方差',num2str(Var_t2)]);
% 
% 
% dBf_1 = db(abs(rfft_data_sumIQ(Idx1,:)));
% dBf_2 = db(abs(rfft_data_sumIQ(Idx2,:)));
% dBf_1(isinf(dBf_1)) = 0;
% dBf_2(isinf(dBf_2)) = 0;
% dBf_1 = dBf_1(dBf_1>0);
% dBf_2 = dBf_2(dBf_2>0);
% % Var_f1 = var( dBf_1 );
% % Var_f2 = var( dBf_2 );
% % Var_f = var( dBf_1 - dBf_2 );
% figure,plot(dBf_1);hold on;plot(dBf_2);hold on;%%频域
% xlabel("采样点",'FontSize',14);ylabel("频域",'FontSize',14);
% if (WaveForm == 3)
% %     title(['1024*128波形，峰谷值频域对比，方差',num2str(Var_f)],'FontSize',14);
%     title('1024*128波形，峰谷值频域对比','FontSize',14);
% else
% %     title(['4096*32波形，峰谷值频域对比，方差',num2str(Var_f)],'FontSize',14);
%     title('4096*32波形，峰谷值频域对比','FontSize',14);
% end
% legend('峰值点','谷值点');
% % legend(['峰值点,方差',num2str(Var_f1)],['谷值点,方差',num2str(Var_f2)]);
% 
% end


%% ===================== 2D FFT ======================%%
% for k=1:N/2
%     data_tmp = w_hamm.*fft_adc_data(:,k);
%     mtd_data(:,k)=fftshift(fft(data_tmp, MTD_N));
% %     mtd_data(:,k)=fft(data_tmp, MTD_N);
% end 


%% 2D FFT对齐FPGA
w_hamm_or = round(w_hamm*(2^15-1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generics for this smoke test
generics.C_NFFT_MAX = log2(DOPPLER_BIN);%%5，2^5=32,2^7=128
generics.C_ARCH = 3;
generics.C_HAS_NFFT = 0;
generics.C_USE_FLT_PT = 0;
generics.C_INPUT_WIDTH = 16; % Must be 32 if C_USE_FLT_PT = 1
generics.C_TWIDDLE_WIDTH = 16; % Must be 24 or 25 if C_USE_FLT_PT = 1
generics.C_HAS_SCALING = 0; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_BFP = 0; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_ROUNDING = 0; % Set to 0 if C_USE_FLT_PT = 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
samples = 2^generics.C_NFFT_MAX;
 nfft = generics.C_NFFT_MAX;
 direction = 1; 
 if generics.C_ARCH == 1 || generics.C_ARCH == 3
    scaling_sch = ones(1,floor(nfft/2)) * 2;
    if mod(nfft,2) == 1
      scaling_sch = [scaling_sch 1];
    end
  else
    scaling_sch = ones(1,nfft);
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 和路2DFFT
for k=1:RANGE_BIN_ENABLE    
    data_temp1 = floor(w_hamm_or .* rfft_data_sumIQ(:,k));   %% 15bit + 16bit
    data_temp2 = floor(data_temp1 / 2^16);
  
    input = data_temp2 ./ 2^15;
    [output, blkexp, overflow] = xfft_v9_1_bitacc_mex(generics, nfft, complex(input), scaling_sch, direction);
    mtd_data_sumIQ(:,k) = output.'*2^15;
end 

%% 差路2DFFT
for k=1:RANGE_BIN_ENABLE    
    data_temp1 = floor(w_hamm_or.*rfft_data_subIQ(:,k));   %% 15bit + 16bit
    data_temp2 = floor(data_temp1/2^16);
  
    input = data_temp2./2^15;
    [output, blkexp, overflow] = xfft_v9_1_bitacc_mex(generics, nfft, complex(input), scaling_sch, direction);
    mtd_data_subIQ(:,k) = output.'*2^15;
end 

%% 输出的和差通道IQ数据
mtd_data_sumIQ_H = mtd_data_sumIQ(:,1:RANGE_BIN_ENABLE).';
mtd_data_subIQ_H = mtd_data_subIQ(:,1:RANGE_BIN_ENABLE).';


%% rdmap
% mtd_data_i=floor(imag(mtd_data(:,1:2048))/2^6);
% mtd_data_r=floor(real(mtd_data(:,1:2048))/2^6);

mtd_data_i = floor(imag(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:))/2^0);
mtd_data_r = floor(real(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:))/2^0);
rdm_data = mtd_data_r + 1i * mtd_data_i;


if(cfarFlag)
    rdm_data_s2 = mtd_data_i.*mtd_data_i + mtd_data_r.*mtd_data_r + 1;%%+1确保rdm_data_s2不是0-1的小数，即log2(rdm_data_s2)不为负数
%     rdm_data_s2H_shift = fftshift(rdm_data_s2);
    rdmap = floor(log2(rdm_data_s2)*256);%%log10(*)=0.30102*log2(*)-->10log10(*)=3.0102*log2(*)-->20log10(*)=10log10(*^2)=3.0102*log2(*^2)
    rdmap = floor(rdmap/4)*4;
else
    rdmap = db(abs(rdm_data));
end

if (comparePL_flag)
    %% compare with PL
    FrameID = str2double(file_name(isstrprop(file_name,'digit')));
    % rdmap_file = fopen("D:\ACUR100_ADC\0.adc\PLvsSiL\1019\new\1019_RDMAP\3.dat");
    rdmap_file = fopen([RDMdataPath,num2str(FrameID),'.dat']);
    if (rdmap_file > 0)
        rdmap_bin_data = fread(rdmap_file);
        fclose(rdmap_file);
        rdmap_bin_data = rdmap_bin_data(129:end); 
        
        if ( size(rdmap_bin_data,1) == 2*Nrange*Ndoppler)
            rdmap_fpga = zeros(Nrange/2,Ndoppler);

            for row = 1 :Nrange/2
                for col = 1 : Ndoppler
                    rdmap_fpga(row,col) = rdmap_bin_data((row-1)*Ndoppler*4+(col-1)*4+2)*256 + rdmap_bin_data((row-1)*Ndoppler*4+(col-1)*4+1) ;
                end 
            end
            rdmap_errr = rdmap - rdmap_fpga(1:RANGE_BIN_ENABLE,:) ;
            rdmap_errr(1,1:5) = 0;
            Idx = find(rdmap_errr > 0);
            comparePL(1,1) = FrameID;
            if (~isempty(Idx))
                comparePL(2,1) = 255;%%未对齐
            else
                comparePL(2,1) = 1;%%对齐
            end
            % figure,mesh(rdmap_errr);
        else
            comparePL(1,1) = FrameID;
            comparePL(2,1) = 0;%%数据异常
        end

    else
        comparePL(1,1) = FrameID;
        comparePL(2,1) = 0;%%数据丢包
    end
else
    comparePL = 0;
end



end

end
