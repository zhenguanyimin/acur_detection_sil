% *************************************************************************
% NXP Confidential Proprietary
% Copyright 2017-2019 NXP
% All Rights Reserved
% *************************************************************************
% THIS SOFTWARE IS PROVIDED BY NXP "AS IS" AND ANY EXPRESSED OR
% IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
% IN NO EVENT SHALL NXP OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
% INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
% HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
% STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
% IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.
% *************************************************************************

% This function computes 2D peak search kernel 
% Input param: 
%   - rdm - Range Doppler Matrix
%   - threshold - array of threshold values real
%   - nrRangeBins - number of Range Bins
%   - nrDopplerBins  - number of Doppler Bins
% Output:
%   - detected peaks matrix bitmap [nrRangeBins, nrDopplerBins]
function Out = peakSearch(rdm, threshold, nrRangeBins, nrDopplerBins)

% Global profile flag
global PROFILE_KERNEL

outMaxRange = zeros(nrDopplerBins , nrRangeBins);
outArray = zeros(nrRangeBins, nrDopplerBins );

if (PROFILE_KERNEL == 1)
    avgR0 = 0; 
    avgR1 = 0; 
end
for i = 1:(nrRangeBins)

    %% 2D Peak Search Round 1 - Max with tagging
    %Input Data Type
    in_dattyp = 'LOG2';
    %Pre-processing
    preproc = 'NO_PROCESSING'; % No preprocessing (for log2 and others)
    %Threshold Compare (valid only for local maxima)
    thld_cmp = 'THLD_ENABLED';
    %Input Tagged
    in_tag = 'NO_TAG'; % Input is not tagged
    %Local not Global maxima
    loc_n_abs = 'LOCAL_MAX'; % Local maxima to be calculated
    %Tag not bitfield (valid only for local maximum calculation)
    tag_n_bitfld = 'TAGGED_VEC'; % Output to be tagged vectors
    %Cyclic extension (valid only for local maximum calculation)
    cyc_extn = 'CYC_EXTN'; % Cyclic extension
    %MAXSN enable
    maxsn_en = 'MAXSN_DISABLED'; % MAXSN disabled
    %MAXSN operand Multiplicity select
    maxsn_sel = 'MAXS16'; % don't care
    if (PROFILE_KERNEL == 1)
        tic;
    end
    MAX_range_Out = maxs_mex(complex(threshold(i).'), complex(rdm(i,:)).', in_dattyp, preproc, thld_cmp, in_tag, loc_n_abs, tag_n_bitfld, cyc_extn, maxsn_en, maxsn_sel);               
    if (PROFILE_KERNEL == 1)
        stopTimeR0 = toc;
        avgR0 = avgR0 + stopTimeR0;
        %disp(['Round 5 - Max with tagging: ' num2str(stopTimeR4) 's']);
    end   

    outMaxRange(:,i) = MAX_range_Out;
    
end

for i = 1:nrDopplerBins 
    %% 2D Peak Search Round 2 - Max on tagged input
    %Input Data Type
    in_dattyp = 'LOG2';
    %Pre-processing
    preproc = 'NO_PROCESSING'; % No preprocessing (for log2 and others)
    %Threshold Compare (valid only for local maxima)
    thld_cmp = 'THLD_DISABLED';
    %Input Tagged
    in_tag = 'TAGGED'; % Input is tagged
    %Local not Global maxima
    loc_n_abs = 'LOCAL_MAX'; % Local maxima to be calculated
    %Tag not bitfield (valid only for local maximum calculation)
    tag_n_bitfld = 'PACKED_BITFLD'; % Output to be tagged vectors
    %Cyclic extension (valid only for local maximum calculation)
    cyc_extn = 'NO_CYC_EXTN'; % No cyclic extension
    %MAXSN enable
    maxsn_en = 'MAXSN_DISABLED'; % MAXSN disabled
    %MAXSN operand Multiplicity select
    maxsn_sel = 'MAXS16'; % don't care
    if (PROFILE_KERNEL == 1)
        tic;
    end
    MAX_final_Out = maxs_mex(complex(threshold.'), complex(outMaxRange(i,:)), in_dattyp, preproc, thld_cmp, in_tag, loc_n_abs, tag_n_bitfld, cyc_extn, maxsn_en, maxsn_sel);               
    if (PROFILE_KERNEL == 1)
        stopTimeR1 = toc;
        avgR1 = avgR1 + stopTimeR1;
        %disp(['Round 6 - Max on tagged input: ' num2str(stopTimeR5) 's']);
    end      
    outArray(:,i) = MAX_final_Out;
end

if (PROFILE_KERNEL == 1)
    disp(['Round 1 - Max with tagging: ' num2str(avgR0/(nrRangeBins)) 's']);
    disp(['Round 2 - Max on tagged input: ' num2str(avgR1/(nrDopplerBins)) 's']);
    disp(['Total time in mex: ' num2str(avgR0 + avgR1) 's']);
end

Out = outArray;

end
