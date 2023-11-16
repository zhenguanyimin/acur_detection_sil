%     figure(iFlie+200),
%     mesh(RDmap{2}-RDmap{1});title([namelist(iFlie,1).name,"ȥֱ��ǰ��RDMAP��ֵ"])
%      if(1)
%             cd(savePicsPath)
%             saveas(gcf, 'FrameID-0DC-1DC', 'fig')
%     end
    
%     figure(fileNum+100),
%     plot(frameIdxList,DClist(frameIdxList)); xlabel('֡��/FrameID','FontSize',14);ylabel('ADCֱ��ƫ��','FontSize',14);title(dataTitle,'FontSize',14);%
%     if(savePicsFlag)
%             cd(savePicsPath)
%             saveas(gcf, 'FrameID-DC', 'fig')
%     end
%    %%-1860     
        %% �����������ɸѡ
    if (choseDrone == 1)
        idx_useful = [];

%         Xw = [10974,19777];%%Զ��֡�ţ�2��Ϊ1��ֱ��
%         Yw = [66,294];%%Զ�����
%         Xf = [118473,130653];%%Զ��֡��%%����֡�ţ�2��Ϊ1��ֱ��
%         Yf = [354,18];%%��������

        %%0204
        Xw = [13317,15898];%%Զ��֡�ţ�2��Ϊ1��ֱ��
        Yw = [54,123];%%Զ�����
        Xf = [118473,130653];%%Զ��֡��%%����֡�ţ�2��Ϊ1��ֱ��
        Yf = [354,18];%%��������
        
        Kw1 = (Yw(2)-Yw(1))/(Xw(2)-Xw(1));%%Զ������1
%         Kw2 = (Yw(4)-Yw(3))/(Xw(4)-Xw(3));%%Զ������2

        bw1 = Yw(1) - Kw1 * Xw(1);
%         bw2 = Yw(4) - Kw2 * Xw(4);

        %% ���˻�Ŀ��ɸѡ
        r = find(TargetList(:,2) <= 900);
%         idx_chose = r;%%(1)
        v1 = find(TargetList(r,3) >= 3*Vres);%%2.2
        v2 = find(TargetList(r,3) <= 5*Vres);%%3.67
        v = intersect(v1,v2);
        idx_chose = r(v);%%(2)
%     idx_chose = 1:Num_tmpDetect;%%(3)

        for jj = 1:length(idx_chose)
            idx = idx_chose(jj);

            FrameID = TargetList(idx,1);
            range = TargetList(idx,2);
            tmpYw1 = Kw1 * FrameID + bw1;%%Զ������1        

            if ((tmpYw1 >= range-Rres)&&(tmpYw1 <= range+Rres))
                idx_useful = [idx_useful,idx];
            end        
        end
    end
    toc
    if (detectionPlot == 1)
        figure(fileNum+1),
        if (choseDrone)
            plot(TargetList(idx_useful,1),TargetList(idx_useful,2),'r*'),hold on;
        end
        xlabel('֡��/FrameID','FontSize',14);ylabel('����/m','FontSize',14);title(dataTitle,'FontSize',14);%
        h = legend('(1)ADC�ع�SiL�����м���','(2)ɸѡ�������˻�Ŀ�����');
%     h = legend('(1)����ʵ�����','(2)ɸѡ������ɢ����');
        set(h,'FontSize',11)
        if(savePicsFlag)
            cd(savePicsPath)
            saveas(gcf, 'FrameID-R', 'fig')
%             saveas(gcf, string(fileNum+1), 'fig')
        end
        
%         figure(fileNum+5),xlabel('֡��/FrameID');ylabel('��λ��/��');title(dataTitle);%
%         if(savePicsFlag)
%             cd(savePicsPath)
%             saveas(gcf,  'FrameID-Azimuth', 'fig')
% %             saveas(gcf, string(fileNum+5), 'fig')
%         end
%         
%         figure(fileNum+6),xlabel('֡��/FrameID');ylabel('������/��');title(dataTitle);%
%         if(savePicsFlag)
%             cd(savePicsPath)
%             saveas(gcf,  'FrameID-Elevation', 'fig')
% %             saveas(gcf, string(fileNum+6), 'fig')
%         end
        
        figure(fileNum+7),
        if (choseDrone)
            plot(TargetList(idx_useful,1),TargetList(idx_useful,4),'r*'),hold on;
        end                
        xlabel('֡��/FrameID','FontSize',14);ylabel('��ֵmag/dB','FontSize',14);title(dataTitle,'FontSize',14);%
        h = legend('(1)ADC�ع�SiL�����м���','(2)ɸѡ�������˻�Ŀ�����');
%     h = legend('(1)����ʵ�����','(2)ɸѡ������ɢ����');
        set(h,'FontSize',11)
        if(savePicsFlag)
            cd(savePicsPath)
            saveas(gcf,  'FrameID-Mag', 'fig')
%             saveas(gcf, string(fileNum+7), 'fig')
        end
        
        fprintf("ADC���ݻع�SiL��⴦���ʱ��%f\n", toc);
        
        figure(fileNum+2),hold on;
        plot(TargetList(:,2),TargetList(:,7),'ko');
        if (choseDrone)
            plot(TargetList(idx_useful,2),TargetList(idx_useful,7),'r*'),hold on;
        end
        
        plot(ones(1,45)+rangeSegment(2),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(3),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(4),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(5),1:45,'g-');hold on;
        xlabel('����/m','FontSize',14);title('����ά�����/dB','FontSize',14);%
        h = legend('(1)ADC�ع�SiL�����м���','(2)ɸѡ�������˻�Ŀ�����');
%     h = legend('(1)����ʵ�����','(2)ɸѡ������ɢ����');
        set(h,'FontSize',11)
        if(savePicsFlag)
            cd(savePicsPath)
            saveas(gcf,  'R-rSNR', 'fig')
%             saveas(gcf, string(fileNum+2), 'fig')
        end        

        figure(fileNum+3),hold on;
        plot(TargetList(:,2),TargetList(:,8),'ko');
        if (choseDrone)
            plot(TargetList(idx_useful,2),TargetList(idx_useful,8),'r*'),hold on;
        end        
        
        plot(ones(1,45)+rangeSegment(2),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(3),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(4),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(5),1:45,'g-');hold on;
        xlabel('����/m','FontSize',14);title('�ٶ�ά�����/dB','FontSize',14);%
        h = legend('(1)ADC�ع�SiL�����м���','(2)ɸѡ�������˻�Ŀ�����');
%     h = legend('(1)����ʵ�����','(2)ɸѡ������ɢ����');
        set(h,'FontSize',11)
        if(savePicsFlag)
            cd(savePicsPath)
            saveas(gcf, 'R-dSNR', 'fig')
%             saveas(gcf, string(fileNum+3), 'fig')
        end

        figure(fileNum+4),hold on;
        plot(TargetList(:,2),TargetList(:,9),'ko');
        if (choseDrone)
             plot(TargetList(idx_useful,2),TargetList(idx_useful,9),'r*'),hold on;
        end        
       
         plot(ones(1,45)+rangeSegment(2),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(3),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(4),1:45,'g-');hold on; plot(ones(1,45)+rangeSegment(5),1:45,'g-');hold on;
        xlabel('����/m','FontSize',14);title('ȫ�������/dB','FontSize',14);%
        h = legend('(1)ADC�ع�SiL�����м���','(2)ɸѡ�������˻�Ŀ�����');
%     h = legend('(1)����ʵ�����','(2)ɸѡ������ɢ����');
        set(h,'FontSize',11)
        if(savePicsFlag)
            cd(savePicsPath)
            saveas(gcf, 'R-gSNR', 'fig')
%             saveas(gcf, string(fileNum+4), 'fig')
        end 
        
        figure(fileNum+8),hold on;
        plot(TargetList(:,2),TargetList(:,4),'ko');
        if (choseDrone)
             plot(TargetList(idx_useful,2),TargetList(idx_useful,4),'r*'),hold on;
        end         
        
        plot(ones(1,80)+rangeSegment(2),1:80,'g-');hold on; plot(ones(1,80)+rangeSegment(3),1:80,'g-');hold on; plot(ones(1,80)+rangeSegment(4),1:80,'g-');hold on; plot(ones(1,80)+rangeSegment(5),1:80,'g-');hold on;
        xlabel('����/m','FontSize',14);title('��ֵmag/dB','FontSize',14);%
        h = legend('(1)ADC�ع�SiL�����м���','(2)ɸѡ�������˻�Ŀ�����');
%     h = legend('(1)����ʵ�����','(2)ɸѡ������ɢ����');
        set(h,'FontSize',11)
        if(savePicsFlag)
            cd(savePicsPath)
            saveas(gcf, 'R-mag', 'fig')
%             saveas(gcf, string(fileNum+8), 'fig')
        end 
        
        figure(fileNum+9),hold on;
        plot(TargetList(:,2),TargetList(:,4)-TargetList(:,9)+(HIST_THRESHOLD_GUARD-1)*3.0103,'ko');
        if (choseDrone)
             plot(TargetList(idx_useful,2),TargetList(idx_useful,4)-TargetList(idx_useful,9)+(HIST_THRESHOLD_GUARD-1)*3.0103,'r*'),hold on;
        end         
        
        plot(ones(1,80)+rangeSegment(2),1:80,'g-');hold on; plot(ones(1,80)+rangeSegment(3),1:80,'g-');hold on; plot(ones(1,80)+rangeSegment(4),1:80,'g-');hold on; plot(ones(1,80)+rangeSegment(5),1:80,'g-');hold on;
        xlabel('����/m','FontSize',14);title('ֱ��ͼ����/dB','FontSize',14);%
        h = legend('(1)ADC�ع�SiL�����м���','(2)ɸѡ�������˻�Ŀ�����');
%     h = legend('(1)����ʵ�����','(2)ɸѡ������ɢ����');
        set(h,'FontSize',11)
        if(savePicsFlag)
            cd(savePicsPath)
            saveas(gcf, 'R-noiseMag', 'fig')
%             saveas(gcf, string(fileNum+8), 'fig')
        end 
        
    end
    
if (choseRV == 1)
    Target_use = zeros(12,length(frameIdxList));
    for idx = 1:length(frameIdxList)
        iFlie = frameIdxList(idx);
        if (size(TargetAll{iFlie},2)>0)
            Target = TargetAll{iFlie};
            Ntar = size(Target,2);
            for ii = 1:Ntar
                R = Target(1,ii);
                V = Target(2,ii);
                if ((R > (rBin-1)*Rres) && (R < (rBin+1)*Rres) && (V > (vBin-1)*Vres) && (V < (vBin+1)*Vres))
                    Target_use(1:9,idx) = Target(:,ii);
                    Target_use(10,idx) = FrameIDall(iFlie) ;
                    Target_use(11,idx) = aziBeamList(iFlie);
                    Target_use(12,idx) = pitchBeamList(iFlie);
                end
            end
        end
    end
    
    Target_usePlot = Target_use(:,find(Target_use(1,:)~=0));
    L = size(Target_usePlot,2);
        
    R1 = Target_usePlot(1,1);%%����
    
    if (scanMode == 2)
        age_trd = -18:4:18;
        F1 = Target_usePlot(10,1);%%��1��֡��
        A1 = Target_usePlot(11,1);%%��1����λ��λ��
        E1 = Target_usePlot(12,1);%%��1����λ������       

        FL =  Target_usePlot(10,L);%%���һ��֡��

        for i_age = 1:length(age_trd)
            if (A1 == age_trd(i_age))
                if (E1 < 0)
                    frame_ge = 2*length(age_trd)-(2*(i_age-1));
                else
                    frame_ge = 2*length(age_trd)-(2*(i_age-1)+1);
                end

            end       
        end

        nn = 1;
        Idx1 = find(Target_usePlot(10,:) < F1 + frame_ge);
        Fu = find(Target_usePlot(12,Idx1) < 0);
        Zheng = find(Target_usePlot(12,Idx1) > 0);    
        Idx_kf{nn} = Idx1(Fu);
        Idx_kz{nn} = Idx1(Zheng);
        figure(nn + 200)
        plot(-18*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(-14*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(-10*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(-6*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(-2*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(2*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(6*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(10*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(14*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(18*ones(1,length(10:100)),10:100,'g-');hold on;
        plot(Target_usePlot(11,Idx1(Fu)),Target_usePlot(3,Idx1(Fu)),'b-*'); hold on;
        plot(Target_usePlot(11,Idx1(Zheng)),Target_usePlot(3,Idx1(Zheng)),'r-o');hold on; 
        xlabel('��λɨ�貨λ��/��');ylabel('��ֵmag/dB');title([num2str(R1),'m�����',num2str(nn),'��ɨ��']);% 

    %     if(savePicsFlag)
        if(1)
            cd(savePicsPath)
            saveas(gcf, string((nn + 200)), 'fig')
        end

        for kk = (F1 + frame_ge):2*length(age_trd):FL
            Idxk = [];
            for n = (length(Idx1)+1):L
                Fn =  Target_usePlot(10,n);%%��n��֡��
                if ((Fn >= kk) && (Fn < kk+2*length(age_trd)))
                    Idxk = [Idxk,n];
                end            
            end   

            nn = nn + 1;
            Fu = find(Target_usePlot(12,Idxk) < 0);
            Zheng = find(Target_usePlot(12,Idxk) > 0);
            Idx_kf{nn} = Idxk(Fu);
            Idx_kz{nn} = Idxk(Zheng);
        end

        ff = 1;
        for f = 2:length(Idx_kf)
            Idxf = Idx_kf{f};
            Idxz = Idx_kz{f};
            Nf = length(Idxf);
            Nz = length(Idxz);
            if ((Nf > 0)||(Nz > 0))
                ff = ff + 1;
                figure(ff + 200)
                plot(-18*ones(1,length(10:100)),10:100,'g-');hold on;    
                plot(-14*ones(1,length(10:100)),10:100,'g-');hold on;     
                plot(-10*ones(1,length(10:100)),10:100,'g-');hold on;      
                plot(-6*ones(1,length(10:100)),10:100,'g-');hold on;      
                plot(-2*ones(1,length(10:100)),10:100,'g-');hold on;      
                plot(2*ones(1,length(10:100)),10:100,'g-');hold on;    
                plot(6*ones(1,length(10:100)),10:100,'g-');hold on;      
                plot(10*ones(1,length(10:100)),10:100,'g-');hold on;      
                plot(14*ones(1,length(10:100)),10:100,'g-');hold on;      
                plot(18*ones(1,length(10:100)),10:100,'g-');hold on;  
                plot(Target_usePlot(11,Idxf),Target_usePlot(3,Idxf),'b-*'); hold on;
                plot(Target_usePlot(11,Idxz),Target_usePlot(3,Idxz),'r-o');hold on;       
                xlabel('��λɨ�貨λ��/��');ylabel('��ֵmag/dB');title([num2str(R1),'m�����',num2str(ff),'��ɨ��']);% 
    %             if(savePicsFlag)
                if(1)
                    cd(savePicsPath)
                    saveas(gcf, string((ff + 200)), 'fig')
                end            
            end                
        end
        
    else
        if (scanMode == 1) %%����λ
            figure(1 + 200)
            plot(Target_usePlot(10,:)-120000,Target_usePlot(3,:),'r-o'); hold on;
            xlabel('֡��/FrameID');ylabel('��ֵmag/dB');title([num2str(R1),'m���㵥��λ����ֵ�仯���']);%
%             if(savePicsFlag)
            if(1)
                cd(savePicsPath)
                saveas(gcf, string((1 + 200)), 'fig')
            end
        end
    end
    
    
%     figure(fileNum+10),hold on;
%     plot(Target_usePlot(11,:),Target_usePlot(3,:),'ko');           
%     xlabel('��λ��/��');title('��ֵmag/dB');%
%     if(savePicsFlag)
%         cd(savePicsPath)
%         saveas(gcf, string(fileNum+10), 'fig')
%     end
 
end
    

% x=[1:512]*Rres;figure,plot(x,rdmap(1:512,4)/256*3.0103);%%,x,rdmap(:,5),x,rdmap(:,6))
% x=[1:32];figure,plot(x,rdmap(143,:)/256*3.0103);%%,x,rdmap(144,:),x,rdmap(145,:))
    
    %% ============================== 3.��ͼend ================================%%
    


