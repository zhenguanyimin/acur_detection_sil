% function [adc_hex,adc_data_deal,rdmap,DC]=getRdmapFromADC(iFlie,dirpath,cfarFlag,K)
function [beamAngle,adc_data_origin,rdmap,DC]=getRdmapFromADC(namelist,iFlie,dirpath,cfarFlag,win,w_hamm)
global compare cutDC RANGE_BIN_ENABLE

format long e
beamAngle=zeros(2,1);
MTD_N = 32;
N = 4096;
adcLeftShift=8;
rangeWinBit=16;
dopplerWinBit=16;
rfftBit=24;
dfftBit=32;
offset1 = 10;
offset2 = 10;
mtd_data = zeros(MTD_N,N/2);
% N_Flies = length(namelist);
% listfilename=[dirpath,'\target_list.txt'];
% fid = fopen('target_list.txt','w');%±£´æ²¨ÐÎÊý¾Ý
for kFile =iFlie:1:iFlie
    if(namelist(kFile).bytes ~= 262144 )
        continue;
    end 
    file_name=namelist(kFile).name; 
    
%»ñÈ¡ÎÄ¼þÂ·¾¶
% file_name=uigetfile('*.dat');
fileID = fopen(file_name,'r');
rarray = fread(fileID);
fclose(fileID);
%Êý¾ÝÖØÕû
LL=length(rarray);
adc_data=zeros(LL/2,1);
for mm=1:2:LL
adc_data((mm+1)/2)=rarray(mm+1)*256+rarray(mm);
end 

adc_data=reshape( adc_data(1:N*MTD_N),N,MTD_N  )';
% 
adc_data1 = zeros(size(adc_data)); %%奇偶列互�?
adc_data1(:,1:2:end) = adc_data(:,2:2:end); %%奇偶列互�?
adc_data1(:,2:2:end) = adc_data(:,1:2:end); %%奇偶列互�?
adc_data = adc_data1;
beamAngle(1)=adc_data(1,1)-180;
beamAngle(2)=adc_data(1,2)-180;
% if(abs(beamAngle(1))>10)
%     adc_data_deal=-1;
%     rdmap=-1;
% DC=-1;
%     return;
% end
%°´ÕÕ16½øÖÆ¶Ô±ÈÊý¾Ý
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

signIndex=find(adc_data>2^15);
adc_data(signIndex)=adc_data(signIndex)-2^16;

% for mm=1:2:LL
% if(adc_data((mm+1)/2) >2^15) %%£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡   
%     adc_data((mm+1)/2) = adc_data((mm+1)/2)-2^16; %%£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡£¡   
% end 
% end 

% adc_data(1,7)=mean(adc_data(1,:));
% adc_data(1,8)=mean(adc_data(1,:));
% adc_avg= mean(mean(adc_data(:,offset+1:N-offset)));
% % adc_avg = 0;
% % adc_data = adc_data -  adc_avg;
 
adc_data_origin= [ zeros(MTD_N,offset1),adc_data(:,offset1-1:N-offset2+2),zeros(MTD_N,offset2-4)] ;%%ÁÐ¶ÔÆë£¬ADCÇ°10ºó6Î»Îª0£¬ÖÐ¼ä·ÅÈë´ÓµÚ9ÁÐµ½µ¹ÊýµÚN-8ÁÐµÄADCÊý¾Ý

%% ===================== (ÐÂ¼Ó)È¥Ö±Á÷Æ«ÖÃ  ======================%%
DC = mean(mean(adc_data_origin));
if (cutDC == 1)
    adc_data_deal = (adc_data_origin - DC);
else
    adc_data_deal=adc_data_origin;
end

% DC = -1870;
% adc_data_deal = DC*ones(size(adc_data_deal));%%Ö±Á÷·ÖÁ¿

%% ===================== 1D FFT ======================%%
% for k=1:MTD_N
%     fft_adc_data(k,:)=fft(adc_data_deal(k,:) .* win',N)*2/N;
% %     fft_adc_data(k,:)=fft(adc_data_deal(k,:) .* win',N);
%     % % % fft_adc_data(k,:)=fftshift(fft(adc_data_deal(k,:)));
% end

%% 1D FFT¶ÔÆëFPGA
win_or = round(win/max(win)*(2^rangeWinBit-1));
win_or = [win_or(1,1);win_or(1,1);win_or(1:N-2,:)];
generics.C_NFFT_MAX = 12;
generics.C_ARCH = 3;%%generics.C_ARCH = 1;%%µ÷Õû++++++++++++++++++++++++++++
generics.C_HAS_NFFT = 0;
generics.C_USE_FLT_PT = 0;
generics.C_INPUT_WIDTH = rfftBit; % Must be 32 if C_USE_FLT_PT = 1
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

fft_adc_data = zeros(MTD_N,N);
ntBP = numerictype(1,rfftBit,0);
for k=1:MTD_N
   adc_data_tmp1 = adc_data_deal(k,:) .* win_or';%%16bit+16bit = 32bit
   adc_data_tmp2 = floor( adc_data_tmp1./ 2^(rangeWinBit-adcLeftShift));%%32-8=24bit
   %% new add 1 
   x_BP = fi(adc_data_tmp2, 1, rfftBit, 0) ;
   adcTruncation = (1.0 .* quantize(x_BP,ntBP)).';%%16bit
%    Idx1 = find(adc_data_tmp2_dec >= 2^15);
%    if(Idx1)
%        adc_data_tmp2_dec(Idx1) = adc_data_tmp2_dec(Idx1) - 2^16;
%    end
   input1 = double(adcTruncation)./double(2^(generics.C_INPUT_WIDTH-1)); 
%    adc_data_tmp3=floor(fft(adc_data_tmp2 ,N));

    %% output:2^(12(generics.C_NFFT_MAX)+16(generics.C_INPUT_WIDTH)+1)=2^29=[1][13][15](1Signedness+13IntegerLength+15FractionLength)
   [output, blkexp, overflow] = xfft_v9_1_bitacc_mex(generics, nfft, complex(input1), scaling_sch, direction);
   fft_adc_data(k,:) = output.'*2^(generics.C_INPUT_WIDTH-1);%%Convert 15bit fraction to integer   
    % fft_adc_data_im_tmp1 =imag(output);
    % fft_adc_data_re_tmp1 =real(output);
    % 
    % fft_adc_data_im_tmp2 =imag(fft_adc_data);
    % fft_adc_data_re_tmp2 =real(fft_adc_data);


end
fft_adc_data = floor(fft_adc_data/2)*2;
% for ii=1:MTD_N
%     for jj=1:N
%         if(real(fft_adc_data(ii,jj))>32767)
%         fft_adc_data_r(ii,jj)=real(fft_adc_data(ii,jj))-65536;
%         elseif(real(fft_adc_data(ii,jj))<-32768)
%         fft_adc_data_r(ii,jj)=real(fft_adc_data(ii,jj))+65536;    
%           else 
%         fft_adc_data_r(ii,jj)=real(fft_adc_data(ii,jj));     
%             end 
%        
%         if(imag(fft_adc_data(ii,jj))>32767)
%         fft_adc_data_i(ii,jj)=imag(fft_adc_data(ii,jj))-65536;
%         elseif(imag(fft_adc_data(ii,jj))<-32768)
%         fft_adc_data_i(ii,jj)=imag(fft_adc_data(ii,jj))+65536;    
%          else 
%         fft_adc_data_i(ii,jj)=imag(fft_adc_data(ii,jj));     
%         end 
%         fft_adc_data(ii,jj)=  fft_adc_data_r(ii,jj) + 1i*fft_adc_data_i(ii,jj);
%     end
% end 

% figure;mesh(abs(fft_adc_data(:,:)),'DisplayName','fft_adc_data');
% xlabel('²ÉÑùµãÊý');ylabel('chirpÊý');title('1D FFT½á¹û');


%% ===================== 2D FFT ======================%%
% for k=1:N/2
%     data_tmp = w_hamm.*fft_adc_data(:,k);
%     mtd_data(:,k)=fftshift(fft(data_tmp, MTD_N));
% %     mtd_data(:,k)=fft(data_tmp, MTD_N);
% end 

%% 2D FFT¶ÔÆëFPGA
w_hamm_or = round(w_hamm*(2^dopplerWinBit-1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generics for this smoke test
generics.C_NFFT_MAX = 5;
generics.C_ARCH = 3;
generics.C_HAS_NFFT = 0;
generics.C_USE_FLT_PT = 0;
generics.C_INPUT_WIDTH = dfftBit; % Must be 32 if C_USE_FLT_PT = 1
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
ntBP = numerictype(1,dfftBit,0);   
for k=1:RANGE_BIN_ENABLE
    data_temp1 = floor(w_hamm_or.*fft_adc_data(:,k));   %% 37bit + 16bit = 53bit
    data_temp2 = floor( data_temp1./ 2^(rfftBit + log2(N) + 1 + dopplerWinBit - dfftBit)); % 53bit-21bit = 32bit
    x_BP = fi(data_temp2, 1, dfftBit, 0) ;
    rfftTruncation = double((1.0 .* quantize(x_BP,ntBP)).');%%32bit
    input = rfftTruncation./double(2^(generics.C_INPUT_WIDTH-1));
    [output, ~, ~] = xfft_v9_1_bitacc_mex(generics, nfft, complex(input), scaling_sch, direction);
    mtd_data(:,k)= output.'*2^(generics.C_INPUT_WIDTH-1);
%     mtd_data(:,k)=floor(fft(data_temp2, MTD_N));
end 
% if (compare == 1)
%     fullpath = mfilename('fullpath');
%     [path,name] = fileparts(fullpath);
%     cd(path);
%     load data_c.mat
%     mtd_data(:,1:2048) = data_c;
% end

% mtd_data_i=floor(imag(mtd_data(:,1:2048))/2^6);
% mtd_data_r=floor(real(mtd_data(:,1:2048))/2^6);

mtd_data_i=floor(imag(mtd_data(:,1:2048))/2^0);
mtd_data_r=floor(real(mtd_data(:,1:2048))/2^0);
rdm_data = mtd_data_r + 1i*mtd_data_i;

if(cfarFlag)
    rdm_data_s2 = mtd_data_i.*mtd_data_i + mtd_data_r.*mtd_data_r + 1;%%+1È·±£rdm_data_s2²»ÊÇ0-1µÄÐ¡Êý£¬¼´log2(rdm_data_s2)²»Îª¸ºÊý
    rdm_data_s2H = rdm_data_s2.';
    rdm_data_s2H = floor(rdm_data_s2H/2^13);
%     rdm_data_s2H_shift = fftshift(rdm_data_s2H);
    rdmap = floor(log2(rdm_data_s2H)*256);%%log10(*)=0.30102*log2(*)-->10log10(*)=3.0102*log2(*)-->20log10(*)=10log10(*^2)=3.0102*log2(*^2)
    rdmap = floor(rdmap/4)*4;%%ÐÂ¼Ó++++++++++++++++++++++++++++
else
    rdm_dataH = rdm_data.';
    rdmap = db(abs(rdm_dataH));
end
end

end