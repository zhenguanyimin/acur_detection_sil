dirpath=uigetdir;
namelist = dir('*.dat');
for iFlie=1:500 
    [adc_data_deal,rdmap]=getRdmapFromADC(iFlie,dirpath);
    figure(1)
    mesh(rdmap(1:512,:));title([namelist(iFlie,1).name,"RDMAP"])
end
