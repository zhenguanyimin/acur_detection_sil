function [Target_Para_out] = calcAzimuth_heCha_AB(Target_Para,mtd_data_sumIQ,mtd_data_subIQ,mtd_data_ABIQ,aziBeam,eleBeam)
%UNTITLED �ȷ��Ͳ������
%% ���룺
%%% Target_Para��CFAR����õ���Ŀ��ṹ��
%%% pAddData��pSubData���͡���ͨ��IQ����
%%% aziBeam����ǰ��λ��λ�ǣ��㣩
%%% Table_Zheng��Table_Fu���Ͳ��ֵ��������
%% �����
%%% Target_List_temp����λ��Ǵ�������ЧĿ��ṹ��
%%% useTarNum����λ��Ǵ�������ЧĿ������

% aziBeam = 0;

global AgeGap TableLen_Zheng TableLen_Fu Table_Zheng Table_Fu lambda D

thetaIncrese = 0;%%����·�ź�������λ��thetaIncrese����
Sys_Phasepole_MesureAngele = 0;%%��������λ����,0
SubDeltaGainMod = 1;%%1.33

NumOutPara = size(Target_Para,1);%%���Ŀ�������������
NumTar = size(Target_Para,2);%%���Ŀ����

Target_Para_out = Target_Para;

mtd_data_AIQ = mtd_data_ABIQ{1};
mtd_data_BIQ = mtd_data_ABIQ{2};

for i_tar = 1:NumTar
    
    i_range = Target_Para(1,i_tar) + 1;%%����PS�����±��0��ʼ��matlab������+1
    i_doppler = Target_Para(2,i_tar);
    
    sum_i = real( mtd_data_sumIQ(i_range,i_doppler) );%%ʵ��
    sum_q = imag( mtd_data_sumIQ(i_range,i_doppler) );%%�鲿
    
    sub_i_temp = real( mtd_data_subIQ(i_range,i_doppler) );
    sub_q_temp = imag( mtd_data_subIQ(i_range,i_doppler) ); 
    
    %%��֧·����λ����
    sub_i = sub_i_temp * cosd(thetaIncrese) - sub_q_temp * sind(thetaIncrese);
    sub_q = sub_q_temp * cosd(thetaIncrese) + sub_i_temp * sind(thetaIncrese);
    
    %%A/Bͨ��IQ��ȡ
    A_i = real( mtd_data_AIQ(i_range,i_doppler) );%%ʵ��
    A_q = imag( mtd_data_AIQ(i_range,i_doppler) );%%�鲿
    
    B_i = real( mtd_data_BIQ(i_range,i_doppler) );
    B_q = imag( mtd_data_BIQ(i_range,i_doppler) ); 
    
    %% (1)�Ͳ�ȷ����
    %%����Ͳ��
    sum_i2_sum_q2 = sum_i * sum_i + sum_q * sum_q;
    sub_i2_sub_q2 = sub_i * sub_i + sub_q * sub_q;
    ratio = sqrt( sub_i2_sub_q2 / sum_i2_sum_q2 );
    
    %%ƫ�ýǲ���:�������ڷ������������Ƕ���Ҫ�����Ĳ���
%     K_slope = cosd(aziBeam);
    K_slope = 1;
    ratio = SubDeltaGainMod * ratio / K_slope;
            
    %��������λ����
    if( Sys_Phasepole_MesureAngele == 0 )    
        symbol = sub_i * sum_q - sub_q * sum_i;%%������ƫ  ����λ-����λ=-90�ȵ����      ��ƫ90
    else
        symbol = sub_q * sum_i - sub_i * sum_q;%%������ƫ  ����λ-����λ=90�ȵ����      ��ƫ-90
    end
%     symbol = cos(atan2(sum_q,sum_i) - atan2(sub_q,sub_i));
    
    
%     %���,�Ͳ��ֵ������������
%     if( symbol >= 0 )
%         len = TableLen_Zheng; %%����Ԫ������
%         table_heChaBi = Table_Zheng;
%         symbol_ZF = 1;
%         AgeGap = 0.01;%%��ļ����0.05��
%     else
%         len = TableLen_Fu; %%����Ԫ������
%         table_heChaBi = Table_Fu;
%         symbol_ZF = -1;
%         AgeGap = -0.01;%%��ļ����0.05��
%     end
    
%     Index = 0;
%     useful = 1;
%     if( ratio > table_heChaBi(len) )
%         Index = len;
%         useful = 0;%%��Ŀ�곬����Ƿ�Χ����Ϊ��Ч�㣬����0���
%     elseif ( ratio == table_heChaBi(len) )
%         Index = len;
%     else
%         for ii = 1:len-1
%             if( (ratio >= table_heChaBi(ii)) && (ratio < table_heChaBi(ii+1)) )
%                 Index = ii;
%                 continue;
%             end
%         end
%     end

     %%���,�Ͳ��ֵ������������
    if( symbol >= 0 )
        symbol_ZF = 1;
        useful = 1;
        
        if( ratio > 1.6 )%%0.5425��0.6
            azi_diff = 6;%%0,2
            useful = 0;%%��Ŀ�곬����Ƿ�Χ����Ϊ��Ч�㣬����0���
        else
            azi_diff = 3.7638 * ratio + 0.0687;
        end
    else
        symbol_ZF = -1;
        useful = 1;
        
        if( ratio > 1.7 )%%0.5634��0.6 
            azi_diff = -6;%%0��-2
            useful = 0;%%��Ŀ�곬����Ƿ�Χ����Ϊ��Ч�㣬����0���
        else
            azi_diff = -3.6372 * ratio + 0.1053;
        end
    end
    
%     azi_diff = 0;
%     useful = 1;
%     if( ratio > 0.5069 )
%         azi_diff = 2;
%         useful = 0;%%��Ŀ�곬����Ƿ�Χ����Ϊ��Ч�㣬����0���
%     elseif ( ratio == 0.5069 )
%         azi_diff = 2;
%     else
%         azi_diff = 3.9716 * ratio + 0.0120;
%     end
    
    %%���·�λ����Ϣ��������Ϣ
%     Target_Para_out(NumOutPara + 5,i_tar) = aziBeam + symbol_ZF * (AgeGap * Index);%%Ŀ�귽λ��=��λ��λ��+�Ͳ��ý�ƫ����ļ����0.05��,�ȡ�
    Target_Para_out(NumOutPara + 5,i_tar) = aziBeam + azi_diff;%%Ŀ�귽λ��=��λ��λ��+�Ͳ��ý�ƫ����ļ����0.05��,�ȡ�
%     if ( useful )        
%         Target_Para_out(NumOutPara + 6,i_tar) = 1;%%����
%     else
%         Target_Para_out(NumOutPara + 6,i_tar) = 0;%%����
%     end
    
    %% (2)�Ͳ������
%     sum_i2_sum_q2 = sum_i * sum_i + sum_q * sum_q;%%��·ȡģ
%     %%��/��,sub/sum
%     tan_phase_i = (sub_i*sum_i + sub_q*sum_q) / sum_i2_sum_q2;
%     tan_phase_q = (sub_q*sum_i - sub_i*sum_q) / sum_i2_sum_q2;
%     %%tan(Phase/2),Phase = 2*pi*D/lambda*sin(deltaTheta)
%     tan_delta_abs = sqrt( tan_phase_i*tan_phase_i + tan_phase_q*tan_phase_q );
%     sin_deltaTheta = lambda*atan(tan_delta_abs)/(pi*D);
%     deltaTheta = asin(sin_deltaTheta);
%     Target_Para_out(NumOutPara + 2,i_tar) = aziBeam + symbol_ZF * (deltaTheta / pi * 180);%%Ŀ�귽λ��=��λ��λ��+�Ͳ��ý�ƫdeltaTheta,�ȡ�
    
    %%abs(sum)/abs(sub)=abs(sum/sub),ͬ��
    tan_delta_abs = ratio;%%�Ͳ��ģֵ    
    sin_deltaTheta = lambda*atan(tan_delta_abs)/(pi*D*sqrt(1-cosd(eleBeam)*sind(aziBeam)*cosd(eleBeam)*sind(aziBeam)));
    deltaTheta = asin(sin_deltaTheta);
%     if (abs(deltaTheta) > 0.035) %%2* pi / 180 = 0.0349
%         deltaTheta = 0;        
%     end
    Target_Para_out(NumOutPara + 6,i_tar) = aziBeam + symbol_ZF * (deltaTheta / pi * 180);%%Ŀ�귽λ��=��λ��λ��+�Ͳ��ý�ƫdeltaTheta,�ȡ�
    
    
     %% (3)��ͨ��������   
    %%----����ratio = peak1*conj(peak2) ------%
    ratio_Re = A_i * B_i + A_q * B_q;
    ratio_Im = A_q * B_i - A_i * B_q;
    Wz = atan2(ratio_Im, ratio_Re);
    sin_deltaTheta = lambda*(-Wz)/(2*pi*D*sqrt(1-cosd(eleBeam)*sind(aziBeam)*cosd(eleBeam)*sind(aziBeam)));%%d = D * sqrt(1-(cosd(eleBeam)*sind(aziBeam))^2)
    deltaTheta = asin(sin_deltaTheta);
%     if (abs(deltaTheta) > 0.035) %%2* pi / 180 = 0.0349
%         deltaTheta = 0;        
%     end
    Target_Para_out(NumOutPara + 7,i_tar) = aziBeam + (deltaTheta / pi * 180);%%Ŀ�귽λ��=��λ��λ��+�Ͳ��ý�ƫdeltaTheta,�ȡ�
%     Target_Para_out(NumOutPara + 5,i_tar) = aziBeam + symbol_ZF * (deltaTheta / pi * 180);%%Ŀ�귽λ��=��λ��λ��+�Ͳ��ý�ƫdeltaTheta,�ȡ�
    
       
    Target_Para_out(NumOutPara + 8,i_tar) = sqrt( sub_i2_sub_q2 );%%��·��ֵ
    Target_Para_out(NumOutPara + 9,i_tar) = sqrt( sum_i2_sum_q2 );%%��·��ֵ
    Target_Para_out(NumOutPara + 10,i_tar) = ratio;%%sub/sum
    
end


end


