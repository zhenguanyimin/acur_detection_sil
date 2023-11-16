function [win, w_hamm] = generateWin(Rwinid,Dwinid)
global RANGE_BIN DOPPLER_BIN 

MTD_N = DOPPLER_BIN;
N = RANGE_BIN;
% Rwinid = 1;%¼Ó´°ÀàÐÍ£¬0£º¾ØÐÎ´°£»1£ºººÃ÷´°£»2£º¿­Èö´°£»3£ºÇÐ±ÈÑ©·ò´°£»4£ºº£Äþ´°£»
% Dwinid = 2;%¼Ó´°ÀàÐÍ£¬0£º¾ØÐÎ´°£»1£ºººÃ÷´°£»2£º¿­Èö´°£»3£ºÇÐ±ÈÑ©·ò´°£»4£ºº£Äþ´°£»

%% range_win
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
         else
             if(Rwinid == 4.)
                 win = hann(N);
             end
         end
      end
   end
end

%% doppler_win
if( Dwinid == 0)
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
         else
             if(Dwinid == 4.)
                 w_hamm = hann(MTD_N);
             end            
         end
      end
   end
end


% % wvtool(hamming(64),hann(64),kaiser(64,pi),chebwin(64,80));
% wvtool(ones(1,64),hamming(64),kaiser(64,pi));
% legend('hamming','hann','gausswin','chebwin');

end