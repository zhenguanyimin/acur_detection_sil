function rdmap=rdmapBinRead()
% close all
MTD_N = 32;
N=4096/8;
NN=N*MTD_N;
offset=6;

Rwinid = 0;%�Ӵ����ͣ�0�����δ���1����������2����������3���б�ѩ�򴰣�
Dwinid = 0;%�Ӵ����ͣ�0�����δ���1����������2����������3���б�ѩ�򴰣�

if( Rwinid == 0.)
   win(1:N) = 1.;
   win =win';
else
   if(Rwinid == 1.)
      win = hamming(N);
   else
      if( Rwinid == 2.)
         win = kaiser(N,pi);
      else
         if(Rwinid == 3.)
            win = chebwin(N,60);
         end
      end
   end
end


if( Dwinid == 0.)
   w_hamm(1:MTD_N) = 1.;
   w_hamm =w_hamm';
else
   if(Dwinid == 1.)
      w_hamm = hamming(MTD_N);
   else
      if( Dwinid == 2.)
         w_hamm = kaiser(MTD_N,pi);
      else
         if(Dwinid == 3.)
            w_hamm = chebwin(MTD_N,80);
         end
      end
   end
end


namelist = dir('*.dat');

% len = length(namelist);
% for kk = 1:5%:1162
%     file_name=namelist(kk).name;
%     x= load(file_name{ii});

% filename =  file_name{kk};
%��ȡ�ļ�·��
file_name=uigetfile('*.bin');
fileID = fopen(file_name,'r');
rarray = fread(fileID);
 fclose(fileID);
%��������
LL=length(rarray);

for mm=1:4:LL
adc_data((mm+3)/4)=rarray(mm+3)*2^24+rarray(mm+2)*2^16+rarray(mm+1)*2^8+rarray(mm);
end 
adc_data=reshape( adc_data(1:N*MTD_N),MTD_N,N  )';
%����16���ƶԱ�����
adc_hex = cell(N,MTD_N);
for ii= 1:N
    for jj=1:MTD_N
        data_temp=dec2hex(adc_data(ii,jj),8);
        adc_hex{ii,jj}=data_temp;
    end
end 
adc_data_1=2.^(adc_data/256);
rdmap=adc_data;
% adc_bin = cell(MTD_N,N);
% for ii= 1:MTD_N
%     for jj=1:N
%         data_temp=dec2bin(adc_data(ii,jj),14);
%         adc_bin{ii,jj}=data_temp;
%     end
% end 
figure;mesh(adc_data_1(4:end,:));
axis([1 32 1 512 1 1e2])

figure;mesh(adc_data(4:end,:));
% axis([1 32 1 512 1 1e4])
% for mm=1:2:LL
% if(adc_data((mm+1)/2) >2^13)
%     adc_data((mm+1)/2) = adc_data((mm+1)/2)-2^14;    
% end 
%  adc_data((mm+1)/2) = adc_data((mm+1)/2);
% end 
% adc_avg= mean(mean(adc_data(:,offset+1:N-offset)));
% adc_avg = 0;
%   adc_data = adc_data -  adc_avg;
%   
% adc_data_deal= [ zeros(MTD_N,offset),adc_data(:,offset+1:N-offset),zeros(MTD_N,offset)] ;
%���ݷ���
% figure;
% mesh(adc_data_deal);
% ylabel('�������');
% xlabel('���뵥Ԫ');
% title('ADC����');
% adc_max = max(max(adc_data_deal))
% adc_min= min(min(adc_data_deal))
% adc_avg= mean(mean(adc_data_deal))
% figure;plot(adc_data_deal);title('ADC����');
% figure;plot(db(abs(fftshift(fft(adc_data_deal)))));
% title('FFT�����dB��');
% figure;plot(db(abs((fft(adc_data_deal,2048)))));
% title('FFT�����dB��');




% for k=1:MTD_N
% fft_adc_data(k,:)=fft(adc_data_deal(k,:) .* win',N);
% % fft_adc_data(k,:)=fftshift(fft(adc_data_deal(k,:)));
% end
% figure;plot(abs(fft_adc_data(16,:)),'DisplayName','fft_adc_data');
% title('FFT���');
% for k=1:N
% data_tmp = w_hamm.*fft_adc_data(:,k);
% mtd_data(:,k)=fft(data_tmp, MTD_N);
% % mtd_data(:,k)=fftshift(fft(fft_adc_data(:,k)));
% end 
% mtd_data(1:2,1:2)=0;
% figure;mesh((abs(mtd_data(:,1:128))),'DisplayName','mtd_data');
% title('MTD���');
% pause(0.5)

% data_f=round(log2(data_e+1)*256);
% 
% 
% for ii =  1:n-1
%         fprintf(fid,'%d,\n',data_f(ii));
%  end
%    ii =  ii +1; 
%     fprintf(fid,'%d\n',data_f(ii));
   
% end
end