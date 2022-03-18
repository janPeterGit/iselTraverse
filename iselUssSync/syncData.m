clc
clear all
close all

%% Dateien einlesen
% read ISEL log Datei
logISELfilename = uigetfile('*.xlsx');
iselTable = readtable(logISELfilename);
% read USS log Datei
ussTablefilename = uigetfile('*.csv');
ussTable = readtable(ussTablefilename);

%% Dateien synchronisieren und Mittelwerte berechnen
% Anzahl Messpunkte
anzahlMesspunkte = length(iselTable.position);

for i = 1:anzahlMesspunkte
    startTime = iselTable.timeStartMeasurement(i);
    endTime = iselTable.timeEndMeasurement(i);

    startID = knnsearch(datenum(ussTable.Var1),datenum(startTime));
    endID = knnsearch(datenum(ussTable.Var1),datenum(endTime));
    
    meanValue.position(i) = iselTable.position(i);
    meanValue.value(i) = mean(ussTable.Var2(startID:endID));
end

%% Daten plotten 
try 
    close all
catch ME
end

font = 'Arial';
fontSize = 15;
f_WSL = figure('Name','WSL','DefaultTextFontName', font, 'DefaultAxesFontName', font,...
    'DefaultAxesFontSize',fontSize,'DefaultTextFontSize',fontSize,...
    'Color', [1 1 1],...
    'Units','centimeters','InnerPosition',[5 5 22.5 18]);
f_WSL.WindowState = 'normal'; %fullscreen, minimize, normal, maximize

plot(meanValue.position,meanValue.value,'b-o')

ylim([0 .25])
grid on

xlabel('\slx\rm [mm]')
ylabel('\slh\rm [m]')

%% Plot abspeichern
figName = 'WSL_Test.png';
exportgraphics(f_WSL,figName,'Resolution',400)