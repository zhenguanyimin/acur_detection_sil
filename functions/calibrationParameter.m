function [AmpA_JC,PhaseA_JC,AmpB_JC,PhaseB_JC] = calibrationParameter(radarID,WaveForm)
%CALIBRATIONPARA 获取AB双通道幅相一致性校准参数
%   此处显示详细说明

switch radarID
   %% =================== 1、4代雷达校准参数 ================================ %%
    case 401
        %%0720校准——4代1#雷达：换信号源板+中频放大，AB通道顺序正常(4096*32)
        %%校准A,-30dbm,0°——OK
        AmpA_JC = 0.4666;
        PhaseA_JC = 0.9607;%%弧度
        AmpB_JC = 1;%%0626校准幅度
        PhaseB_JC = 0;%%相位，弧度
        
     case 402   
         if (WaveForm == 3)
            %%0830校准——4代2#雷达改中频滤波1.5M+天线罩，AB通道顺序正常(1024*128)
            %%校准B,-30dbm,4MHz,0°,eb23F7,800K,电荷泵320-70us——OK
            AmpA_JC = 1;
            PhaseA_JC = 0;%%弧度
            AmpB_JC = 1/1.2385;%%B通道校准幅度
            PhaseB_JC = 2.2537;%%B通道校准相位，弧度
        else
            %%0808校准——4代2#雷达，-30dbm,0°，AB通道顺序正常(4096*32)
            %%校准A，OK
            AmpA_JC = 0.8757;
            PhaseA_JC = 2.7428;%%弧度
            AmpB_JC = 1;%%0626校准幅度
            PhaseB_JC = 0;%%相位，弧度
         end
    
    case 403
        if (WaveForm == 3)  
            %0823校准——4代3#雷达+天线罩,AB通道顺序正常(1024*128)
            %校准A,-30dbm,4MHz,0°,800K,电荷泵320-70us——OK
            AmpA_JC = 1.1233;%%A通道校准幅度
            PhaseA_JC = -1.4115;%%弧度
            AmpB_JC = 1;%%A通道校准幅度
            PhaseB_JC = 0;%%A通道校准相位，弧度
        else
            %0817校准——4代3#雷达,AB通道顺序正常(4096*32)
            %校准A,-30dbm,0°,电荷泵304-315us——OK
            AmpA_JC = 1.0985;%%A通道校准幅度
            PhaseA_JC = -1.3906;%%弧度
            AmpB_JC = 1;%%A通道校准幅度
            PhaseB_JC = 0;%%A通道校准相位，弧度
        end
     
    case 405
        %0819校准——4代5#雷达,AB通道顺序正常
        %校准A,-30dbm,1MHz，0°，eb23f7+U8全5,电荷泵314-315us——OK
        AmpA_JC = 0.7602;%%A通道校准幅度
        PhaseA_JC = 1.1479;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 407
        %0811校准——4代7#雷达,AB通道顺序正常(4096*32)
        %校准A,-50dbm,0°，电荷泵14-315us——OK
        AmpA_JC = 0.8585;%%A通道校准幅度
        PhaseA_JC = 0.6033;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 408
        %0924校准——4代8#雷达（11#源板）,AB通道顺序正常(4096*32)
        %校准A,-30dbm,0°，电荷泵14-315us——OK
        AmpA_JC = 0.8907;%%A通道校准幅度
        PhaseA_JC = 1.6862;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 409
        %0905校准——4代9#雷达,AB通道顺序正常(4096*32)
        %校准A,-30dbm,0°，电荷泵14-315us——OK
        AmpA_JC = 0.6895;%%A通道校准幅度
        PhaseA_JC = 0.8712;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 410
        %0830校准——4代10#雷达,AB通道顺序正常(4096*32)
        %校准A,-30dbm,0°，电荷泵314-315us——OK
        AmpA_JC = 0.7513;%%A通道校准幅度
        PhaseA_JC = 1.7091;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 411
        %0926校准——4代11#雷达(15#源板),AB通道顺序正常(4096*32)
        %校准A,-30dbm,0°，电荷泵314-315us——OK
        AmpA_JC =1;%%A通道校准幅度
        PhaseA_JC = 0;%%A通道校准相位，弧度
        AmpB_JC = 0.9951;%%B通道校准幅度
        PhaseB_JC = -0.9136;%%B通道校准相位，弧度
   
  %% =================== 2、5代PVT雷达校准参数 ================================ %% 
    case 502
        %,1016校准——5代2#雷达重装,AB通道顺序正常
        %校准A,-30dbm,0°，电荷泵314-315us——OK
        AmpA_JC =0.6304;%%A通道校准幅度
        PhaseA_JC = 0.5639;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 503
        %,1012校准——5代3#雷达,AB通道顺序正常
        %校准A,-30dbm,0°，电荷泵314-315us——OK
        AmpA_JC =0.5991;%%A通道校准幅度
        PhaseA_JC = 1.2105;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 505
        %,1013校准——5代5#雷达,AB通道顺序正常
        %校准A,-30dbm,0°，电荷泵314-315us——OK
        AmpA_JC =0.8176;%%A通道校准幅度
        PhaseA_JC = 0.8588;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
    case 506    
        %,1016校准——5代6#雷达,AB通道顺序正常
        %校准A,-30dbm,0°，电荷泵314-315us——OK
        AmpA_JC =0.6854;%%A通道校准幅度
        PhaseA_JC = 0.8219;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
        
    otherwise
        %,1012校准——5代3#雷达,AB通道顺序正常
        %校准A,-30dbm,0°，电荷泵314-315us——OK
        AmpA_JC =0.5991;%%A通道校准幅度
        PhaseA_JC = 1.2105;%%A通道校准相位，弧度
        AmpB_JC = 1;%%B通道校准幅度
        PhaseB_JC = 0;%%B通道校准相位，弧度
        
end






end

