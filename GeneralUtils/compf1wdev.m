function [f1, f1s, dc, dcs,f2,f2s] = compf1wdev(data)
%  function [f1, f1s, dc, dcs,f2,f2s] = compf1wdev(data)
% data contains rows of single cycle data.

[n,m] = size(data);

if n==1
  ff = fft((data));
else
  ff = fft(nanmean(data));
end

dc = ff(1)/m;
f1 = 2*abs(ff(2)/m);
f2 = 2*abs(ff(3)/m);

angf1 = angle(ff(2));
angf2 = angle(ff(3));

if n==1
  f1s = 0;
  f2s = 0;
  dcs = 0;
  return;
end

%OK, now we need ot get the vector of the angle that points in that direction:
for j=1:n
    
  ff = fft(data(j,:));
  singleangle = angle(ff(2));
  indf1amp(j) = cos(singleangle - angf1) * abs(ff(2) *2 / m);
  inddcamp(j) = ff(1)/m;

  singleangle = angle(ff(3));
  indf2amp(j) = cos(singleangle - angf2) * abs(ff(3) *2 / m);


  
end

%indf1amp
%inddcamp

f1s = (indf1amp);
f2s = (indf2amp);
dcs = (inddcamp);

