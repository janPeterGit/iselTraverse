clc
close all
clear variables


ussTable = readtable('LogISEL_LogUSS_LogLC\20220427_USS Time falsch\20220427_1303_L474W90Q40H107G2_C.csv');

plot(ussTable.Var1,ussTable.Var2,'.')

grid on