     % 5.out ——by hxj 
%             dopplerBinList = fftshift(1:sp.nrDopplerBins);
             dopplerBinList = 1:sp.nrDopplerBins;
            for ii = 1:sp.nrDopplerBins
                tmpDopplerBin = dopplerBinList(ii)-1;%%MATLAB下标从1开始
                if (tmpDopplerBin >= sp.nrDopplerBins/2) %%-15~16
                    tmpDopplerBin = tmpDopplerBin - sp.nrDopplerBins;%% + 1
                end
                dopplerBinList(ii) = tmpDopplerBin;%% + 1
            end

            Num = size(Target_Para,2);
            Target = Target_Para;
            Target(1,:) = Target(1,:)*Rres;%%range
            for ii = 1:Num
                dopplerBinIdx = Target(2,ii);
                dopplerBin = dopplerBinList(dopplerBinIdx);
                Target(2,ii) = dopplerBin * Vres;
            end
            TargetAll{iFlie} = Target;
            TargetList(Nts:Nts+Num-1,2:size(Target,1)+1) = Target.';

            Num1 = size(PeakTarget_Para,2);
            PeakTarget = PeakTarget_Para;
            PeakTarget(1,:) = PeakTarget(1,:)*Rres;%%range
            for ii = 1:Num1
                dopplerBinIdx = PeakTarget(2,ii);
                dopplerBin = dopplerBinList(dopplerBinIdx);
                PeakTarget(2,ii) = dopplerBin * Vres;    
            end
            PeakTargetAll{iFlie} = PeakTarget;
            PeakTargetList(Nps:Nps+Num1-1,2:size(PeakTarget,1)+1) = PeakTarget.';
            
           %% ============================== 3.画图 ===================================%%           
           %% (1)RDmap
            if (RDmapPlot == 1)
                hold on
                % plot targets
                detNum = size(Target_Para,2);
                for iRow = 1:detNum
                    ragneBin = Target_Para(1,iRow)+1;dopplerBin = Target_Para(2,iRow);
                    scatter3(dopplerBin,ragneBin,rdmap(ragneBin,dopplerBin),'o','r');
                end
                % plot peaks
                for iRow = 1:size(PeakTarget_Para,2)
                    ragneBin = PeakTarget_Para(1,iRow)+1;dopplerBin = PeakTarget_Para(2,iRow);
                    scatter3(dopplerBin,ragneBin,rdmap(ragneBin,dopplerBin),'x','k');
                end
                title({[namelist(iFlie,1).name,'  RDMAP ','detNum = ',num2str(detNum)];['azimuth = ', num2str(aziBeam), ' pitch = ',num2str(eleBeam)]});
%                axis([0 32 0 256])
                if(pickSpecificBeam == 1)
                    if(aziBeam == -23)
                        frameIDarray{uniqueFrameNum,1} = namelist(iFlie,1).name;
                        frameIDarray{uniqueFrameNum,2} = detNum;
                        uniqueFrameNum = uniqueFrameNum+1;
                    end
                end
                view([10,30])
                if(RDmapSave)
%                     cd('D:\work\ACUR100\test data\20221013zhiyuanlouxia\pic')
                    cd(savePicsPath)
                    saveas(gcf, namelist(iFlie,1).name(1:end-4), 'fig')
%                     if (K == 1)
%                         saveas(gcf, namelist(iFlie,1).name(1:end-4), 'fig')
%                     end
%                     if (K == 2)
%                         saveas(gcf, [namelist(iFlie,1).name(1:end-4),'_cutDC'], 'fig')
%                     end
                end
    %             view(2)
            end
            
            %% (2)noise
            if (noisePlot == 1)
                figure(iFlie+fileNum+7),                
                x=[1:RANGE_BIN_ENABLE]*Rres;plot(x,rdmap(1:RANGE_BIN_ENABLE,4)/256*3.0103,'k-',x,rdmap(1:RANGE_BIN_ENABLE,5)/256*3.0103,'b-',x,rdmap(1:RANGE_BIN_ENABLE,6)/256*3.0103,'g-');hold on;
                plot(Rres.*(1:length(detectObjData.noiseMag)),detectObjData.noiseMag./256.*3.0103,'r-');
                xlabel('距离/m','FontSize',14);ylabel('底噪/dB','FontSize',14);title([dataTitle,'——',namelist(iFlie,1).name(1:end-4),'.dat'],'FontSize',14);%
                h = legend(['(1)V=',num2str(roundn(3*Vres,-2)),'m/s的rdmap幅值曲线'],['(2)V=',num2str(roundn(4*Vres,-2)),'m/s的rdmap幅值曲线'],['(3)V=',num2str(roundn(5*Vres,-2)),'m/s的rdmap幅值曲线'],'(4)直方图底噪');
                set(h,'FontSize',11)
                cd(savePicsPath)
                saveas(gcf, ['noise_',namelist(iFlie,1).name(1:end-4)], 'fig')
                
%                 x=[1:512]*Rres;figure,plot(x,rdmap(1:512,4)/256*3.0103);%%,x,rdmap(:,5),x,rdmap(:,6))
                figure,x=[1:32];plot(x,rdmap(143,:)/256*3.0103);%%,x,rdmap(144,:),x,rdmap(145,:))
                 xlabel('dopplerBin','FontSize',14);ylabel('rdmap幅值曲线/dB','FontSize',14);title([dataTitle,'——',namelist(iFlie,1).name(1:end-4),'.dat'],'FontSize',14);%
                h = legend(['(1)V=',num2str(roundn(143*Rres,-2)),'m的rdmap幅值曲线'],['(2)V=',num2str(roundn(4*Vres,-2)),'m/s的rdmap幅值曲线'],['(3)V=',num2str(roundn(5*Vres,-2)),'m/s的rdmap幅值曲线'],'(4)直方图底噪');
                set(h,'FontSize',11)
                cd(savePicsPath)
                saveas(gcf, ['dopplerMag_',namelist(iFlie,1).name(1:end-4)], 'fig')
            end
            
            %% (3)detection output
             if (detectionPlot == 1)
                str = namelist(iFlie,1).name;
                A = isstrprop(str,'digit');
                B = str(A);
                FrameID = str2num(B);
                FrameIDall(iFlie) = FrameID;
                
                TargetList(Nts:Nts+Num-1,1) = FrameID * ones(Num,1);
                PeakTargetList(Nps:Nps+Num1-1,1) = FrameID * ones(Num1,1);
                Nts = Nts + Num; 
                Nps = Nps + Num1;
                
                figure(fileNum+1),plot(FrameID*ones(1,Num),Target(1,:),'ko'),hold on;
%                 figure(fileNum+5),plot(FrameID,aziBeam,'ko'),hold on;
%                 figure(fileNum+6),plot(FrameID,eleBeam,'ko'),hold on;
                figure(fileNum+7),plot(FrameID*ones(1,Num),Target(3,:),'ko'),hold on;              
            end