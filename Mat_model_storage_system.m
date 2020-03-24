clear all; close all; clc
set(0,'defaulttextinterpreter','latex')    % LaTeX style for figures
%% Parameters
Dfill       = .145;          % inner diameter small tank
Hfill       = .420;          % height small tank
Dstor       = .295;          % inner diameter large tank
Hstor       = .230;          % height large tank
Deq         = .020;           % inner diameter equaliser pipe
Heqstorpi   = .170;          % heigth of equliser pipe in storage tank
Heqfillpi   = .250;          % height of equliser pipe in fill tank
Heqstor     = .185;          % heigth of equliser pipe in storage tank
Heqfill     = .337;          % height of equliser pipe in fill tank
e           = 0.0005;        % roughness of pipes
L           = 0.315;         % length of transfer pipes in m. Pipe connecting filler and storage and viceversa

%% Calculate the volumes
Vfilltot        = 1/4*(Dfill^2)*pi*Hfill;            % volume of the filler tank mm^3
Vstortot        = 1/4*(Dstor^2)*pi*Hstor;            % volume of the storage tank mm^3
Vfill           = 1/4*(Dfill^2)*pi*Heqfill;          % volume of the filler tank mm^3
Vstor           = 1/4*(Dstor^2)*pi*Heqstor;          % volume of the storage tank mm^3
Vtot            = (Vstor+Vfill);
Aoutflow        = ((Deq/2)^2)*pi;                        % Area of equaliser pipe mm^2

%% Read out experminental data

filename = 'storage_readings.xlsx';     % Input files in the current folder
Data = importdata(filename);

filename2 = 'filler_readings.xlsx';     % Input files in the current folder
Data2 = importdata(filename2);


%% Extract data from excel file
ExpStor     = Data.storage_readings_corrected;
Storelit    = ExpStor(:,1)';
ExpStor1    = ExpStor(:,2)';
ExpStor2    = ExpStor(:,3)';
ExpStor3    = ExpStor(:,4)';

ExpFill     = Data2.filler_readings_corrected;
Filllit     = ExpFill(:,1)';
ExpFill1    = ExpFill(:,2)';
ExpFill2    = ExpFill(:,3)';
ExpFill3    = ExpFill(:,4)';

%% Make graphs
figure('Name','Experimental data storage tank')
plot(ExpStor1,Storelit)
hold on
plot(ExpStor2,Storelit)
hold on
plot(ExpStor3,Storelit),grid on
xlabel('Time [s]')
ylabel('Volume [l]')
title('Draining of the storage tank')
legend('Experiment 1','Experiment 2','Experiment 3')
% saveas(gcf,'FigureDrainStorage','jpg')
% saveas(gcf,'FigureDrainStorage','depsc')

figure('Name','Experimental data filler tank')
plot(ExpFill1,Filllit)
hold on
plot(ExpFill2,Filllit)
hold on
plot(ExpFill3,Filllit),grid on
xlabel('Time [s]')
ylabel('Volume [l]')
title('Draining of the filler tank')
legend('Experiment 1','Experiment 2','Experiment 3')
% saveas(gcf,'FigureDrainFiller','jpg')
% saveas(gcf,'FigureDrainFiller','depsc')
%% Transient model

%Initial conditions
rho=1000; %kg/m3 density
mu=8.9*10^-4; %Pas viscosity
ReyNo=@(v,d)(rho*v*d/mu); %all inputs in SI

Vfill_initial= 0.00565; %initial volume of liquid in the filler tank
Vfill_total=Vfill_initial;
Vstor_initial= 0.0125; %initial volume of liquid in the storage tank
Vstor=Vstor_initial;
Vstor_critical=0.25*((Dstor^2)-(Deq^2))*pi*Heqstorpi;
V_dot_ship=4*10^3; %inlet volume flow rate of liquid into the filler tank in m3/s ??
VfillShipInlet=0; %initialization of volume of liquid from ship to filler
Vfill_critical=0.0055; % Maximum volume filler tank can hold considering transfer to storgae tank ??
% V_dot_out_burner=4*10^3; %outlet volume flow rate in mm3/s to burner if pump is ON ??
t_shipStatus=0; % default setting is OFF
Vfill_in_storage=0; %initialization of volume of liquid from filler to storage

delT=0.1; %time step in s
totalTime=180; % total time of system under study in s
Vfill_t=zeros(1,totalTime/delT); %volume in filler tank after every time step
Vstor_t=zeros(1,totalTime/delT); %volume in storage tank after every time step
g=9.810; % mm/s2

shipStatus=0; %status of the inlet into the filler tank ; ON=1, OFF=0

prompt='Is the inlet into the system through the ship ON? ON=1/OFF=0\n';
shipStatus=input(prompt);

if shipStatus==1
    x='Duration of inlet from ship? in seconds'
    t_shipStatus=input(x);
end

j=1;
for i=delT:delT:totalTime
  if Vfill_total>=0
    if i==t_shipStatus
        shipStatus=0; %switching OFF ship inlet into filler after time 't_shipStatus'
        VfillShipInlet=0;
    end

    if shipStatus==1
        VfillShipInlet=V_dot_ship*delT;
    end

    Vfill_total=Vfill_total+VfillShipInlet;

    if Vfill_total>Vfill_critical
        headAboveCritical=(Vfill_total-Vfill_critical)/(0.25*(Dfill^2)*pi);
        Vstor_in=sqrt(2*g*headAboveCritical)*(0.25*(Dfill^2)*pi)*delT  %for the ideal case
        %Vstor_in=(0.5*g*headAboveCritical^2)*0.25*(Dfill^2)*pi; %for the ideal case
        vel=(Vstor_in)/(pi*0.25*((Deq)^2)*delT)
        %vel=sqrt(2*g*headAboveCritical)*0.001;
        Re_FilltoStor=ReyNo(vel,Deq) %input from ideal case
        h_loss=major(Re_FilltoStor,Deq,L,vel,e);
        h_loss=0 %this is to simulate the ideal case

        Vstor_in=sqrt(2*g*(headAboveCritical-h_loss))*(0.25*(Dfill^2)*pi)*delT;
        %Vstor_in=((0.5*g*delT*delT)-h_loss)*1/4*(Dfill^2)*pi; %for the realistic case
        Vstor=Vstor+Vstor_in;
        Vfill_total=Vfill_total-Vstor_in;
    end

    if Vstor>Vstor_critical
        %Vstor=Vstor_critical;
        headAboveCritical=(Vstor-Vstor_critical)/(0.25*((Dstor^2)-(Deq^2))*pi);
        Vstor=Vstor-sqrt(2*g*headAboveCritical)*(0.25*((Dstor^2)-(Deq^2))*pi)*delT;
        %Vstor=Vstor-((0.5*g*delT*delT)*1/4*((Dstor^2)-(Deq^2))*pi);
    end

    h_Fill=Vfill_total/(0.25*pi*Dfill^2);
    h_Stor=Vstor/(0.25*pi*Dstor^2);

    hDiff=(h_Stor+0.1)-h_Fill;

    if Vstor<=0
       Vstor=0;
       hDiff=0;
       Vfill_in_storage=0;
    end

    if hDiff>0
       Vfill_in_storage= sqrt(2*g*hDiff)*(0.25*((Dstor^2)-(Deq^2))*pi)*delT; %is this the dia of the pipe from the storage to filler via valve?

       vel=(Vfill_in_storage)/(pi*0.25*Deq^2);
       Re_fill_in_storage=ReyNo(vel,Deq); %input from ideal case
       h_loss=major(Re_fill_in_storage,Deq,L+0.0795+0.175,vel,e); % L+79.5+175 is the total length
       h_loss=0 %this is to simulate the ideal case

       Vfill_in_storage= sqrt(2*g*(hDiff-h_loss))*(0.25*((Dstor^2)-(Deq^2))*pi)*delT;
       %Vfill_in_storage= sqrt(2*g*(hDiff-h_loss))*Aoutflow*delT;
       Vstor=Vstor-Vfill_in_storage;
    end


    Vfill_total=Vfill_total+Vfill_in_storage;
    h_Fill=Vfill_total/(0.25*pi*Dfill^2);

    V_dot_out_burner = sqrt(2*g*h_Fill)*(pi*0.0065^2); %what is the outlet dia of the exit? or what is the volume flow rate
    V_fill_out_burner = V_dot_out_burner*delT;

    Vfill_total=Vfill_total-V_fill_out_burner;

    Vfill_t(j)=Vfill_total;
    Vstor_t(j)=Vstor;

    j=j+1;
  end
end

% Comparison for filler tank volume
figure()
plot(ExpFill1,Filllit)
hold on
plot(delT:delT:totalTime,(Vfill_t)*10^3)

title('Comparison between predicted and measured values of filler tank volume')
xlabel('time (in  s)')
ylabel('Volume (in l)')
grid on
grid minor
ax = gca;
ax.GridAlpha = 0.7; % maximum line opacity
ax.MinorGridAlpha = 0.5;
legend('Experiment','Predicted')
saveas(gcf,'filler.jpg');


% Comparison for storage tank volume
figure()
plot(ExpStor1,Storelit)
hold on
plot(delT:delT:totalTime,(Vstor_t)*10^3)

title('Comparison between predicted and measured values of storage tank volume')
xlabel('time (in  s)')
ylabel('Volume (in l)')
grid on
grid minor
ax = gca;
ax.GridAlpha = 0.7; % maximum line opacity
ax.MinorGridAlpha = 0.5;
legend('Experiment','Predicted')
saveas(gcf,'storage.jpg');