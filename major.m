function h_loss=major(Re,D,L,v,e)

if (Re<2000)
    f=64/Re;
end

if (Re>=2000) %this is changed !!
    f=(0.247-0.0000947*(7-log(Re))^4)/(log((e/(3.615*D))+(7.366/Re^0.9142)))^2 % !! log10
end
h_loss=f*L*v*v/(2*9.81*D);
