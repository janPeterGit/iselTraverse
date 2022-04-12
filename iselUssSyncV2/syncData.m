clc
clear all
close all

%% Dateien einlesen
% read ISEL log Datei
logISELfilename = uigetfile('*.xlsx');
iselTable = readtable(logISELfilename);

L = char(extractBetween(logISELfilename,'L','W'));
W = char(extractBetween(logISELfilename,'W','Q'));
Q = char(extractBetween(logISELfilename,'Q','H'));
h = char(extractBetween(logISELfilename,'H','_'));
Position = char(extractBetween(logISELfilename,[h,'_'],'.x'));

% read USS log Datei
% ussTablefilename = uigetfile('*.csv');
ussTablefilename = [logISELfilename(1:end-5),'.csv'];
ussTable = readtable(ussTablefilename);
ussMatrix = table2array(ussTable(:,2:5));

%% Dateien synchronisieren und Mittelwerte berechnen
% Anzahl Messpunkte
anzahlMesspunkteX = length(iselTable.xPosition);

hMatrix = NaN(anzahlMesspunkteX,iselTable.countSensors(1));
xPosition = hMatrix;
yPosition = hMatrix;

for i = 1:anzahlMesspunkteX
    startTime = iselTable.timeStartMeasurement(i);
    endTime = iselTable.timeEndMeasurement(i);

    startID = knnsearch(datenum(ussTable.Var1),datenum(startTime));
    endID = knnsearch(datenum(ussTable.Var1),datenum(endTime));
    
    for j = 1:iselTable.countSensors(1)
        xPosition(i,:) = iselTable.xPosition(i);
        yPosition(:,j) = iselTable.y0(1) - (j-1) * iselTable.deltaYSensors(1);
        hMatrix(i,j) = mean(ussMatrix(startID:endID,j));
    end
end



%% Daten plotten
try
    close all
catch ME
end

figureTitle = 'WSL';
font = 'Arial';
fontSize = 15;
f = figure('Name',figureTitle,'DefaultTextFontName', font, 'DefaultAxesFontName', font,...
    'DefaultAxesFontSize',fontSize,'DefaultTextFontSize',fontSize,...
    'Color', [1 1 1],...
    'Units','centimeters','InnerPosition',[5 5 22.5 18]);
f.WindowState = 'normal'; %fullscreen, minimize, normal, maximize

hold on
for k = 1:iselTable.countSensors(1)
    wslPlot = plot(xPosition(:,k),hMatrix(:,k)*100,'-o');
    wslPlot.DisplayName = ['\sly\rm = ',num2str(yPosition(1,k)),' mm'];
end

ylim([0 25])
legend(Location="southeast")
grid on

xlabel('\slx\rm [mm]')
ylabel('\slh\rm [cm]')

%% Daten in Tabelle schreiben und Bild exportieren
outputDirectory = 'Output';
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

figureName = ['Output/L',L,'W',W,'Q',Q,'H',h,'_',Position,'_WSL.png'];
delete(figureName)
exportgraphics(f,figureName,'Resolution',400)
% close all

dataTable = table;
dataTable.xPosition = xPosition;
dataTable.yPosition = yPosition;
dataTable.h = hMatrix;

filename = ['Output/L',L,'W',W,'Q',Q,'H',h,'_',Position,'_WSL.xlsx'];
% filename = 'testOutput.xlsx';
delete(filename);
writetable(dataTable,filename,'Sheet','Messdaten','WriteVariableNames',true);