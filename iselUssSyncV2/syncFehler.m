clc
close all
clear variables

path = 'LogISEL_LogUSS_LogLC\20220506_teilweise falscher Zeitstempel\';
folder = 'wrongTimestamp\';
filename = '20220506_1610_L474W90Q12.5H67G2_C.csv';
ussTable = readtable([path,folder,filename]);

plot(ussTable.Var1,ussTable.Var2,'.')

% daspect([1 1 1])

ylim([0 0.07])

% Zeitversatz berechnen Jahr, Monat, Tag, Stunde, Minute, Sekunde
DateVectorReal = [2022,5,6,14,52,37];

timeStampReal = datestr(DateVectorReal);

DateVectorWrong = [2015,1,1,1,14,33];

timeStampWrong = datestr(DateVectorWrong);

timeShift = datenum(timeStampReal) - datenum(timeStampWrong);

% Zeitstempel korrigieren
ussTable.Var1 = ussTable.Var1 + timeShift;

% hold on
% plot(ussTable.Var1,ussTable.Var2,'.')

% cd('corrected Time')
writetable(ussTable,[path,filename],'Delimiter',',','WriteVariableNames',false)  

% grid on