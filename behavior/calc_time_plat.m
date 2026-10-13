function [first_plat_sec, frames_on_plat] = calc_time_plat(on_plat,iti_bout, sample_rate)
% determines the frames in which the animal was on the platform 
% labels each with the tone bout that platform stay occurred in 
% says how long it is in seconds
%   Detailed explanation goes here
first_plat=[];first_plat_time=[]; plat_dur=[]; %% there is a bug right now where if they are on the platform 
%for the first frame and immediately leave the first line in the output is all zeros

frames_on_plat=[]; count = 1;

for jjj = 1:length(iti_bout);
    first_plat_temp = find(on_plat(iti_bout(jjj,1):iti_bout(jjj,2)), 1)-1;
    plat_dur_temp = find(on_plat(iti_bout(jjj,1):iti_bout(jjj,2)));
    if isempty(first_plat_temp)
        first_plat(jjj) = NaN;
    else
        first_plat(jjj) = first_plat_temp;
        if jjj==1
        frames_on_plat(count,1) = plat_dur_temp(1)+iti_bout(jjj,1)-1;
        frames_on_plat(count,3)=jjj;
        else
            count=count+1;
            frames_on_plat(count,1) = plat_dur_temp(1)+iti_bout(jjj,1)-1;
            frames_on_plat(count,3)=jjj;
        end
        for hhh = 2:length(plat_dur_temp);
            if plat_dur_temp(hhh) - plat_dur_temp(hhh-1) == 1
                frames_on_plat(count,2) = plat_dur_temp(hhh)+iti_bout(jjj,1)-1;
                frames_on_plat(count,3) = jjj;
            else
                if frames_on_plat(count,2)==0
                    frames_on_plat(count,2)=frames_on_plat(count,1)+1;
                end
                count = count + 1;
                frames_on_plat(count,1) = plat_dur_temp(hhh)+iti_bout(jjj,1)-1;
                frames_on_plat(count,3)=jjj;
                if plat_dur_temp(hhh) == plat_dur_temp(end)
                    frames_on_plat(count, 2) = plat_dur_temp(hhh)+iti_bout(jjj,1)-1;
                    frames_on_plat(count,3)=jjj;
                end
            end
        end
    end
end

for jjj = 1:size(frames_on_plat,1)
    duration_temp = frames_on_plat(jjj,2)-frames_on_plat(jjj,1);
    frames_on_plat(jjj,4) = duration_temp/sample_rate;
end

first_plat_sec = first_plat/sample_rate;
