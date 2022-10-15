function genvec = fitpow(lambda,xdat)

thresh = lambda(1);
gain = lambda(2);
power = lambda(3);
genvec = gain * max((xdat-thresh),0).^power;

%plot(xdat,genvec)
%drawnow
