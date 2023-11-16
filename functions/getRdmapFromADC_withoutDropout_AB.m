
function [info,adc_data_deal_A,rdmap,rdmapAB,mtd_data_sumIQ_H,mtd_data_subIQ_H,mtd_data_ABIQ_H,DC1] = getRdmapFromADC_withoutDropout_AB(namelist,iFlie,cfarFlag,rWin,dWin)
global compare cutDC RANGE_BIN_ENABLE RANGE_BIN DOPPLER_BIN scanMode azimuthEnable elevationEnable radarID WaveForm

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
% mtd_data_sumIQ = zeros(Ndoppler,Nrange/2);
% mtd_data_subIQ = zeros(Ndoppler,Nrange/2);

for kFile = iFlie:1:iFlie
    if(namelist(kFile).bytes ~= 2*2*Nrange*Ndoppler+128 ) %% 512k,256K+256K
        adc_data_deal_A = -1;
        rdmap = -1;
        rdmapAB = -1;
        mtd_data_sumIQ_H = -1;
        mtd_data_subIQ_H = -1;
        mtd_data_ABIQ_H = -1;
        DC1 = -1;
        info = 0;
        continue;
    end
    file_name = namelist(kFile).name;
    
%��ȡ�ļ�·��
% file_name=uigetfile('*.dat');
fileID = fopen(file_name,'r');
rarray = fread(fileID);
fclose(fileID);

%%��ͷ��Ϣ������128bytes
info.FrameID = rarray(4) * 2^24 + rarray(3) * 2^16 + rarray(2) * 256 + rarray(1);%%֡ID,uint32
info.waveType = rarray(8) * 2^24 + rarray(7) * 2^16 + rarray(6) * 256 + rarray(5);%%����������,uint32
info.timestamp = rarray(16) * 2^56 + rarray(16) * 2^48 + rarray(14) * 2^40 + rarray(13) * 2^32 + rarray(12) * 2^24 + rarray(11) * 2^16 + rarray(10) * 256 + rarray(9);%%ʱ�����ms��,uint64
info.azimuth = rarray(18) * 256 + rarray(17)-180;%%��λ�����ǣ�azimuth,int16
info.elevation = rarray(20) * 256 + rarray(19)-180;%%���������ǣ�elevation,int16
info.aziScanCenter = rarray(21);%%��λɨ������,int8
info.aziScanScope = rarray(22);%%��λɨ�跶Χ,int8
info.eleScanCenter = rarray(23);%%����ɨ������,int8
info.eleScanScope = rarray(24);%%����ɨ�跶Χ,int8
info.trackTwsTasFlag = rarray(25);%%TWS��TAS���α�ǣ�0TWS��1Tas,uint8
info.finalBeamFlag = rarray(26);%%һ��ɨ�����һ����λ���,uint8
info.chirpTime=(rarray(28)*256+rarray(27))*50/1000;  % unit input:50ns, output us,uint16

if (scanMode) 
% if (0) 
%%�������߸�����λ���� ���� ����λ����Ҫ
if( abs(info.azimuth) > azimuthEnable  || abs(info.elevation) > elevationEnable )
    adc_data_deal_A = -1;
    rdmap = -1;
    rdmapAB = -1;
    mtd_data_sumIQ_H = -1;
    mtd_data_subIQ_H = -1;
    mtd_data_ABIQ_H = -1;
    DC1 = -1;
    info = 0;
    return;
end
end

%��������:A·+B·
rarray = rarray(129:end);
LL = length(rarray);
adc_dataAB = zeros(1,LL/2);

for mm = 1:2:LL
    adc_dataAB((mm+1)/2) =  rarray(mm+1) * 256 + rarray(mm);
end
adc_data_A = adc_dataAB(2:2:end);%%ABͨ������෴
adc_data_B = adc_dataAB(1:2:end-1);


adc_data_A = reshape( adc_data_A(1:Nrange*Ndoppler),Nrange,Ndoppler  )';
adc_data_B = reshape( adc_data_B(1:Nrange*Ndoppler),Nrange,Ndoppler  )';


signIndex1 = find(adc_data_A >= 2^15);
adc_data_A(signIndex1) = adc_data_A(signIndex1) - 2^16;

signIndex1 = find(adc_data_B >= 2^15);
adc_data_B(signIndex1) = adc_data_B(signIndex1) - 2^16;

% adc_data_A_origin= [ zeros(Ndoppler,offset1),adc_data_A(:,offset1+1:Nrange-offset2),zeros(Ndoppler,offset2)] ;%%�ж��룬ADCǰ10��6λΪ0���м����ӵ�9�е�������N-8�е�ADC����
% adc_data_B_origin= [ zeros(Ndoppler,offset1),adc_data_B(:,offset1+1:Nrange-offset2),zeros(Ndoppler,offset2)] ;%%�ж��룬ADCǰ10��6λΪ0���м����ӵ�9�е�������N-8�е�ADC����
adc_data_A_origin= adc_data_A ;%%�޵����ֶ�ʱ��ǰ��������0
adc_data_B_origin= adc_data_B ;%%�޵����ֶ�ʱ��ǰ��������0


%% ===================== (�¼�)ȥֱ��ƫ�� ======================%%
DC1 = mean(mean(adc_data_A_origin));
DC2 = mean(mean(adc_data_B_origin));
if (cutDC == 1)
    adc_data_deal_A = (adc_data_A_origin - DC1)*2^adcLeftShift;
    adc_data_deal_B = (adc_data_B_origin - DC2)*2^adcLeftShift;
else
    adc_data_deal_A = adc_data_A_origin*2^adcLeftShift;
    adc_data_deal_B = adc_data_B_origin*2^adcLeftShift;
end

%% ADC����У׼(ʵ��->����)+�Ͳ���ϳ�
I = sqrt(-1);

[AmpA_JC,PhaseA_JC,AmpB_JC,PhaseB_JC] = calibrationParameter(radarID,WaveForm);

%%У׼ϵ��
DataA_JC = AmpA_JC * exp(I * PhaseA_JC);
DataB_JC = AmpB_JC * exp(I * PhaseB_JC);
% DataA_JC1 = floor( DataA_JC * 2^12 );
% DataB_JC1 = floor( DataB_JC * 2^12 );

% %%�������
% adc_data_calibA1 = adc_data_deal_A * DataA_JC1;
% adc_data_calibB1 = adc_data_deal_B * DataB_JC1;
% adc_data_calibA = floor( adc_data_calibA1 / 2^12 );
% adc_data_calibB = floor( adc_data_calibB1 / 2^12 );
% 
% %%������ӡ�����������PL����
% adc_data_sumIQ = floor((adc_data_calibA + adc_data_calibB)/2);
% adc_data_subIQ = floor((adc_data_calibA - adc_data_calibB)/2);


% %%У׼���ȷ��
% figure,plot(real(adc_data_calibA(1,:)));hold on;
% plot(real(adc_data_calibB(1,:)));
% 
% figure,plot(imag(adc_data_calibA(1,:)));hold on;
% plot(imag(adc_data_calibB(1,:)));


%% ===================== 1D FFT ======================%%
%% A·1DFFT
rfft_data_AIQ = zeros(Ndoppler,Nrange);
for irfft = 1:Ndoppler
    rfft_tmp = adc_data_deal_A(irfft,:) .* rWin';
    rfft_data_AIQ(irfft,:) = fft(rfft_tmp,Nrange);
end

%% B·1DFFT
  rfft_data_BIQ = zeros(Ndoppler,Nrange);
for irfft = 1:Ndoppler
    rfft_tmp = adc_data_deal_B(irfft,:) .* rWin';
    rfft_data_BIQ(irfft,:) = fft(rfft_tmp,Nrange);
end


%% ABͨ������У׼+�Ͳ�ͨ���ϳ�
% %%�������
% rfft_data_calibA1 = rfft_data_AIQ * DataA_JC1;
% rfft_data_calibB1 = rfft_data_BIQ * DataB_JC1;
% rfft_data_calibA = floor( rfft_data_calibA1 / 2^14 );
% rfft_data_calibB = floor( rfft_data_calibB1 / 2^14 );
% 
% %%������ӡ�����������PL����
% rfft_data_sumIQ = floor((rfft_data_calibA + rfft_data_calibB)/2);
% rfft_data_subIQ = floor((rfft_data_calibA - rfft_data_calibB)/2);

%%�������
rfft_data_calibA = rfft_data_AIQ * DataA_JC;
rfft_data_calibB = rfft_data_BIQ * DataB_JC;

%%������ӡ�����������PL����
rfft_data_sumIQ = (rfft_data_calibA + rfft_data_calibB)/2;
rfft_data_subIQ = (rfft_data_calibA - rfft_data_calibB)/2;

%% ===================== 2D FFT ======================%%
mtd_data_sumIQ = zeros(Ndoppler,Nrange/2);
mtd_data_subIQ = zeros(Ndoppler,Nrange/2);
%% ��·2DFFT
for idfft = 1:RANGE_BIN_ENABLE
    dfft_tmp =  dWin .* rfft_data_sumIQ(:,idfft);
    mtd_data_sumIQ(:,idfft) = fft(dfft_tmp,Ndoppler);
end

%% ��·2DFFT
for idfft = 1:RANGE_BIN_ENABLE
    dfft_tmp = dWin .* rfft_data_subIQ(:,idfft);
    mtd_data_subIQ(:,idfft) = fft(dfft_tmp,Ndoppler);
end

%% =========== A��B·2DFFT =====================%%
mtd_data_AIQ = zeros(Ndoppler,Nrange/2);
mtd_data_BIQ = zeros(Ndoppler,Nrange/2);
%% A·2DFFT
for idfft = 1:RANGE_BIN_ENABLE
    dfft_tmp =  dWin .* rfft_data_calibA(:,idfft);
    mtd_data_AIQ(:,idfft) = fft(dfft_tmp,Ndoppler);
end

%% B·2DFFT
for idfft = 1:RANGE_BIN_ENABLE
    dfft_tmp = dWin .* rfft_data_calibB(:,idfft);
    mtd_data_BIQ(:,idfft) = fft(dfft_tmp,Ndoppler);
end

mtd_data_ABIQ_H{1} = mtd_data_AIQ(:,1:RANGE_BIN_ENABLE).';
mtd_data_ABIQ_H{2} = mtd_data_BIQ(:,1:RANGE_BIN_ENABLE).';

%%ABͨ������
mtd_data_Ai = imag(mtd_data_ABIQ_H{1})/2^0;
mtd_data_Ar = real(mtd_data_ABIQ_H{1})/2^0;
rdm_dataA = mtd_data_Ai + 1i * mtd_data_Ar;

mtd_data_Bi = imag(mtd_data_ABIQ_H{2})/2^0;
mtd_data_Br = real(mtd_data_ABIQ_H{2})/2^0;
rdm_dataB = mtd_data_Bi + 1i * mtd_data_Br;

%% ����ĺͲ�ͨ��IQ����
mtd_data_sumIQ_H = mtd_data_sumIQ(:,1:RANGE_BIN_ENABLE).';
mtd_data_subIQ_H = mtd_data_subIQ(:,1:RANGE_BIN_ENABLE).';

%% rdmap
mtd_data_i = imag(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:));
mtd_data_r = real(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:));
rdm_data = mtd_data_r + 1i * mtd_data_i;



if(cfarFlag)
    rdm_data_s2 = mtd_data_i.*mtd_data_i + mtd_data_r.*mtd_data_r;%%+1ȷ��rdm_data_s2����0-1��С������log2(rdm_data_s2)��Ϊ����
    rdmap = (log2(rdm_data_s2)*256);%%log10(*)=0.30102*log2(*)-->10log10(*)=3.0102*log2(*)-->20log10(*)=10log10(*^2)=3.0102*log2(*^2)
%     rdmap = floor(rdmap/4)*4;

    %%ABͨ��rdmap
    rdm_data_As2 = mtd_data_Ai.*mtd_data_Ai + mtd_data_Ar.*mtd_data_Ar + 1;%%+1ȷ��rdm_data_s2����0-1��С������log2(rdm_data_s2)��Ϊ����
    rdmapAB{1} = floor(log2(rdm_data_As2)*256);%%log10(*)=0.30102*log2(*)-->10log10(*)=3.0102*log2(*)-->20log10(*)=10log10(*^2)=3.0102*log2(*^2)
    
    rdm_data_Bs2 = mtd_data_Bi.*mtd_data_Bi + mtd_data_Br.*mtd_data_Br + 1;%%+1ȷ��rdm_data_s2����0-1��С������log2(rdm_data_s2)��Ϊ����
    rdmapAB{2} = floor(log2(rdm_data_Bs2)*256);%%log10(*)=0.30102*log2(*)-->10log10(*)=3.0102*log2(*)-->20log10(*)=10log10(*^2)=3.0102*log2(*^2)
else
    rdmap = db(abs(rdm_data));
    rdmapAB{1} = db(abs(rdm_dataA));
    rdmapAB{2} = db(abs(rdm_dataB));
end

% %% ����ĺͲ�ͨ��IQ����
% mtd_data_sumIQ_H = mtd_data_sumIQ(:,1:RANGE_BIN_ENABLE).';
% mtd_data_subIQ_H = mtd_data_subIQ(:,1:RANGE_BIN_ENABLE).';
% 
% 
% %% rdmap
% % mtd_data_i = floor(imag(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:))/2^0);
% % mtd_data_r = floor(real(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:))/2^0);
% mtd_data_i = imag(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:));
% mtd_data_r = real(mtd_data_sumIQ_H(1:RANGE_BIN_ENABLE,:));
% rdm_data = mtd_data_r + 1i * mtd_data_i;
% 
% if(cfarFlag)
%     rdm_data_s2 = mtd_data_i.*mtd_data_i + mtd_data_r.*mtd_data_r + 1;%%+1ȷ��rdm_data_s2����0-1��С������log2(rdm_data_s2)��Ϊ����
% %     rdm_data_s2H_shift = fftshift(rdm_data_s2);
%     rdmap = floor(log2(rdm_data_s2)*256);%%log10(*)=0.30102*log2(*)-->10log10(*)=3.0102*log2(*)-->20log10(*)=10log10(*^2)=3.0102*log2(*^2)
%     rdmap = floor(rdmap/4)*4;
% else
%     rdmap = db(abs(rdm_data));
% end

end

end

