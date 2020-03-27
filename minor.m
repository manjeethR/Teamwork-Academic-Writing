function h_loss=minor(Re,D,L,v,e)

% Head loss part 
% R/D gives and indication about the kind of bend you are dealing with
% ??(??)^2 Dimensionless number as an indication of the type of bend
% Y^2(??)^1/2 Dimensionless number as an indication of the type of bend
% Y^3e^Y=??(?/?)^1/2 Relation between the two dimensionless numbers

R = 100;                % radius of the bend
r = 10;                 % radius of the pipe
erough = 0.0002;        % relative roughness 
Rr = R/r;               % R/r 
L = 10;                 % Length of the pipe in m 

theta = 45;             % bend angle
Re = 2e4;               % Reynolds number
Ycub = Re*sqrt(Rr);     % Relation between two dimensionless numbers 
u_avg = 0.5;            % Average flow speed m/s
gravity = 9.81;         % Gravitational accaleration. 


fc = (0.2479-0.0000947*(7-log(Re))^4)/(log((erough/3.615*r)+(7.366/Re^(0.9142))));

if theta == 45 
    alpha = 0.95 + 14.2*(R/r)^(-1.47);
elseif theta == 90 & Rr <= 19.7
    alpha = 0.95 + 17.2*(Rr)^(-1.96); 
elseif theta == 90 & Rr >= 19.7
    alpha = 1; 
elseif theta == 180 
    alpha = 1 + 116*Rr^(-4.52); 
end

if Re*Rr^2 <= 91 & (Re >= 2e4 & Re <= 4e5)
    kt = 0.000873*alpha*fc*theta*R/r; 
elseif Re*Rr^2 >= 91 & (Re >= 2e4 & Re <= 4e5)
    kt = 0.0024*alpha*theta*Re^(-0.17)*(R/r)^(0.84);
end 

if Re >= 2e4 & Re <= 4e5 else disp('This Reynolds number not within the appropriate range');
    kt = 0.0024*alpha*theta*Re^(-0.17)*(R/r)^(0.84);
end

deltahf_dw =  fc*(L/r)*(u_avg^2/2*gravity)