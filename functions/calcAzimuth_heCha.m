function [Target_Para_out] = calcAzimuth_heCha(Target_Para,mtd_data_sumIQ,mtd_data_subIQ,aziBeam,eleBeam)
%UNTITLED 比幅和差单脉冲测角
%% 输入：
%%% Target_Para：CFAR处理得到的目标结构体
%%% pAddData、pSubData：和、差通道IQ数据
%%% aziBeam：当前波位方位角（°）
%%% Table_Zheng、Table_Fu：和差比值正、负表
%% 输出：
%%% Target_List_temp：方位测角处理后的有效目标结构体
%%% useTarNum：方位测角处理后的有效目标总数

% aziBeam = 0;

global AgeGap TableLen_Zheng TableLen_Fu Table_Zheng Table_Fu lambda D

thetaIncrese = 0;%%给差路信号增加相位（thetaIncrese）度
Sys_Phasepole_MesureAngele = 0;%%计算测角相位极性,1
SubDeltaGainMod = 1;%%1.33

NumOutPara = size(Target_Para,1);%%检出目标输出参数总数
NumTar = size(Target_Para,2);%%检出目标数

Target_Para_out = Target_Para;

for i_tar = 1:NumTar
    
    i_range = Target_Para(1,i_tar) + 1;%%对齐PS处理，下标从0开始，matlab这里需+1
    i_doppler = Target_Para(2,i_tar);
    
    sum_i = real( mtd_data_sumIQ(i_range,i_doppler) );%%实部
    sum_q = imag( mtd_data_sumIQ(i_range,i_doppler) );%%虚部
    
    sub_i_temp = real( mtd_data_subIQ(i_range,i_doppler) );
    sub_q_temp = imag( mtd_data_subIQ(i_range,i_doppler) ); 
    
    %%差支路加相位处理
    sub_i = sub_i_temp * cosd(thetaIncrese) - sub_q_temp * sind(thetaIncrese);
    sub_q = sub_q_temp * cosd(thetaIncrese) + sub_i_temp * sind(thetaIncrese);
    
 %% (1)和差比幅测角
    %%计算和差比
    sum_i2_sum_q2 = sum_i * sum_i + sum_q * sum_q;
    sub_i2_sub_q2 = sub_i * sub_i + sub_q * sub_q;
    ratio = sqrt( sub_i2_sub_q2 / sum_i2_sum_q2 );
    
    %%偏置角补偿:主波束在法线与在其他角度需要补偿的参数
%     K_slope = cosd(aziBeam);
    K_slope = 1;
    ratio = SubDeltaGainMod * ratio / K_slope;
            
    %计算测角相位极性
    if( Sys_Phasepole_MesureAngele == 0 )    
        symbol = sub_i * sum_q - sub_q * sum_i;%%用于右偏  差相位-和相位=-90度的情况      左偏90
    else
        symbol = sub_q * sum_i - sub_i * sum_q;%%用于右偏  差相位-和相位=90度的情况      左偏-90
    end
%     symbol = cos(atan2(sum_q,sum_i) - atan2(sub_q,sub_i));
    
    
%     %查表,和差比值有正负两个表
%     if( symbol >= 0 )
%         len = TableLen_Zheng; %%表中元素总数
%         table_heChaBi = Table_Zheng;
%         symbol_ZF = 1;
%         AgeGap = 0.01;%%表的间隔是0.05度
%     else
%         len = TableLen_Fu; %%表中元素总数
%         table_heChaBi = Table_Fu;
%         symbol_ZF = -1;
%         AgeGap = -0.01;%%表的间隔是0.05度
%     end
    
%     Index = 0;
%     useful = 1;
%     if( ratio > table_heChaBi(len) )
%         Index = len;
%         useful = 0;%%该目标超出测角范围，视为无效点，打标记0输出
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

     %%查表,和差比值有正负两个表
    if( symbol >= 0 )
        symbol_ZF = 1;
        useful = 1;
        
        if( ratio > 1.6 )%%0.5425，0.6
            azi_diff = 6;%%0,2
            useful = 0;%%该目标超出测角范围，视为无效点，打标记0输出
        else
            azi_diff = 3.7638 * ratio + 0.0687;
        end
    else
        symbol_ZF = -1;
        useful = 1;
        
        if( ratio > 1.7 )%%0.5634，0.6 
            azi_diff = -6;%%0，-2
            useful = 0;%%该目标超出测角范围，视为无效点，打标记0输出
        else
            azi_diff = -3.6372 * ratio + 0.1053;
        end
    end
    
%     azi_diff = 0;
%     useful = 1;
%     if( ratio > 0.5069 )
%         azi_diff = 2;
%         useful = 0;%%该目标超出测角范围，视为无效点，打标记0输出
%     elseif ( ratio == 0.5069 )
%         azi_diff = 2;
%     else
%         azi_diff = 3.9716 * ratio + 0.0120;
%     end
    
    %%更新方位角信息及属性信息
%     Target_Para_out(NumOutPara + 4,i_tar) = aziBeam + symbol_ZF * (AgeGap * Index);%%目标方位角=波位方位角+和差测得角偏，表的间隔是0.05度,度°
    Target_Para_out(NumOutPara + 5,i_tar) = aziBeam + azi_diff;%%目标方位角=波位方位角+和差测得角偏，表的间隔是0.05度,度°
%     if ( useful )        
%         Target_Para_out(NumOutPara + 6,i_tar) = 1;%%属性
%     else
%         Target_Para_out(NumOutPara + 6,i_tar) = 0;%%属性
%     end
    
    %% (2)和差比相测角
%     sum_i2_sum_q2 = sum_i * sum_i + sum_q * sum_q;%%和路取模
%     %%差/和,sub/sum
%     tan_phase_i = (sub_i*sum_i + sub_q*sum_q) / sum_i2_sum_q2;
%     tan_phase_q = (sub_q*sum_i - sub_i*sum_q) / sum_i2_sum_q2;
%     %%tan(Phase/2),Phase = 2*pi*D/lambda*sin(deltaTheta)
%     tan_delta_abs = sqrt( tan_phase_i*tan_phase_i + tan_phase_q*tan_phase_q );
%     sin_deltaTheta = lambda*atan(tan_delta_abs)/(pi*D);
%     deltaTheta = asin(sin_deltaTheta);
%     Target_Para_out(NumOutPara + 2,i_tar) = aziBeam + symbol_ZF * (deltaTheta / pi * 180);%%目标方位角=波位方位角+和差测得角偏deltaTheta,度°
    
    %%abs(sum)/abs(sub)=abs(sum/sub),同上
    tan_delta_abs = ratio;%%和差比模值    
    sin_deltaTheta = lambda*atan(tan_delta_abs)/(pi*D*sqrt(1-cosd(eleBeam)*sind(aziBeam)*cosd(eleBeam)*sind(aziBeam)));
    deltaTheta = asin(sin_deltaTheta);
%     if (abs(deltaTheta) > 0.035) %%2* pi / 180 = 0.0349
%         deltaTheta = 0;        
%     end
    Target_Para_out(NumOutPara + 6,i_tar) = aziBeam + symbol_ZF * (deltaTheta / pi * 180);%%目标方位角=波位方位角+和差测得角偏deltaTheta,度°
    
       
    Target_Para_out(NumOutPara + 7,i_tar) = sqrt( sub_i2_sub_q2 );%%差路幅值
    Target_Para_out(NumOutPara + 8,i_tar) = sqrt( sum_i2_sum_q2 );%%和路幅值
    Target_Para_out(NumOutPara + 9,i_tar) = ratio;%%sub/sum
end


end

