function [avg_bout] = boutavg(matrix,tone_bout)
%calculate average time of duration bout for every 3 tones
%loops through matrix that has tone # and duration on platform per bout and
%pulls out 1-3,4-6,etc. Calculates average

count = 1;
for ppp = 1:3:length(tone_bout)
  
    idx1 = find(matrix(:,3) == ppp);
    idx2 = find(matrix(:,3) == ppp+1);
    idx3 = find(matrix(:,3) == ppp+2);
    dur_avg_idx = [idx1;idx2;idx3];
   
    avg_bout(count) = mean(matrix(dur_avg_idx,4));
    count = count+1;
end
end


