clc
clear all
close all

data = table;
% data.time(1:1000) = NaN;
data.value(1:1000) = NaN;

for i = 1:10000
    data.time(i) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
    data.value(i) = randi([10 15],1,1);
    pause(1/100)
end

filename = 'Test.csv';
delete(filename);
writetable(data,filename,'Sheet','Messdaten','WriteVariableNames',true);