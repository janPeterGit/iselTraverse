clc
close all
clear variables

[filename, folder] = uigetfile('*.csv');
ussTable = readtable([folder,filename]);
%%
plot(ussTable.Var1,ussTable.Var2,'.', ...
    'DisplayName','Sensor neben Zylinder'); hold on
plot(ussTable.Var1,ussTable.Var3,'.', ...
    'DisplayName','Sensor über Zylinder')

grid on
legend

DplusG = 0.062; % m

plot([min(ussTable.Var1) max(ussTable.Var1)],[DplusG DplusG], ...
    'DisplayName','Oberkante Zylinder')

ylim([-0.004 0.004])