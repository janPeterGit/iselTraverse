clc
clear all
close all


% clearvars -except C D

%% Dateien einlesen
% read ISEL log Datei
matlabFolder = pwd;

% Wähle den Ordner mit den Messdaten %%%%%% STARTVERZEICHNIS ANPASSEN %%%%%
% dname = uigetdir('../../measurements/2022 Voruntersuchungen nonUniform');
% Gehe zum Verzeichnis mit den Messdaten
% cd(dname)
dname = 'LogISEL_LogUSS_WSLgrid\L474W90Q60';
% dname = 'LogISEL_LogUSS_WSLgrid\leereRinne';
cd(dname)

% cd(dname)
measurements = ls('*.xlsx');
% cd(matlabFolder)

filenameISEL = measurements;
filenameUSS = [filenameISEL(1:end-5),'.csv'];

lCyl = str2double(extractBetween(filenameUSS,'L','W'));
dCyl = 50;
gammaCyl = str2double(extractBetween(filenameUSS,'W','Q'));
Q = str2double(extractBetween(filenameUSS,'Q','H'));

% später in function übersetzen

% read ISEL Datei
iselTable = readtable(filenameISEL);
% read USS log Datei
% ussTablefilename = uigetfile('*.csv');
ussTable = readtable(filenameUSS);
ussTable = renamevars(ussTable,["Var1","Var2","Var3","Var4"],...
    ["ussTimeStamp","sensor01","sensor02","sensor03"]);
% ussMatrix = table2array(ussTable(:,2:5))*1000; % *1000 m --> mm

% Anzahl Messpunkte X
anzahlMesspunkteX = length(iselTable.positionX);

for i = 1:anzahlMesspunkteX
    startTime = iselTable.timeStartMeasurement(i);
    endTime = iselTable.timeEndMeasurement(i);

    startID = knnsearch(datenum(ussTable.ussTimeStamp),datenum(startTime));
    endID = knnsearch(datenum(ussTable.ussTimeStamp),datenum(endTime));

    iselTable.meanValueSensor01(i) = mean(ussTable.sensor01(startID:endID)*1000);
    iselTable.stdValueSensor01(i) = std(ussTable.sensor01(startID:endID)*1000);

    iselTable.meanValueSensor02(i) = mean(ussTable.sensor02(startID:endID)*1000);
    iselTable.stdValueSensor02(i) = std(ussTable.sensor02(startID:endID)*1000);

    iselTable.meanValueSensor03(i) = mean(ussTable.sensor03(startID:endID)*1000);
    iselTable.stdValueSensor03(i) = std(ussTable.sensor03(startID:endID)*1000);
end

%%

dataTable01 = iselTable(:,{'positionX','positionY1','meanValueSensor01','stdValueSensor01'});
dataTable02 = iselTable(:,{'positionX','positionY2','meanValueSensor02','stdValueSensor02'});
dataTable03 = iselTable(:,{'positionX','positionY3','meanValueSensor03','stdValueSensor03'});

dataMatrix = table2array(dataTable01);
dataMatrix = [dataMatrix;table2array(dataTable02)];
dataMatrix = [dataMatrix;table2array(dataTable03)];
% dataTableRinne = array2table(dataMatrix);
% writetable(dataTableRinne,'leereRinne.xlsx','Sheet','MyNewSheet','WriteVariableNames',true);

x = dataMatrix(:,1);
y = dataMatrix(:,2)-395;
meanValue = dataMatrix(:,3);
stdValue = dataMatrix(:,4);

%%
% leere Rinne
dataTableRinne = readtable('C:\Users\JB\Documents\GitHub\iselTraverse\iselUssSyncV2\LogISEL_LogUSS_WSLgrid\leereRinne\leereRinne.xlsx');
dataRinne = table2array(dataTableRinne);
meanValueRinne = dataRinne(:,3);

meanValue = meanValue - meanValueRinne;

%%
deltaXY = 30;
xVek = min(x):deltaXY:max(x);
yVek = min(y):deltaXY:max(y);

% [X,Y] = meshgrid(unique(x),unique(y));
[X,Y] = meshgrid(xVek,yVek);
MEANvALUE = griddata(x,y,meanValue,X,Y);

MEANvALUE(MEANvALUE > 140) = NaN;
[xRow,xCol] = find(X > -60 & X < 240);
MEANvALUE(:,unique(xCol)) = NaN;


%%
close all

font = 'Arial';
fontSize = 16;
f = figure('DefaultTextFontName', font, ...
    'DefaultAxesFontName', font,...
    'DefaultAxesFontSize',fontSize, ...
    'DefaultTextFontSize',fontSize);
f.Name = 'wsl 3d';
f.Color = [1 1 1];
f.Units = 'centimeters';
f.InnerPosition = [5 5 18 30];
f.WindowState = 'normal'; %fullscreen, minimize, normal, maximize
% hold on

tlayout = tiledlayout(3,1);

nexttile(1)
plotWSL = surf(X,Y,MEANvALUE); hold on
plotWSL.FaceAlpha = 0.75;
% plotWSL.EdgeColor = 'none';

cb = colorbar;
cb.Layout.Tile = 'north';
cb.Label.String = '$h$ [mm]';
cb.TickLabelInterpreter = 'latex';
cb.Label.Interpreter = 'latex';
colormap(turbo(20))
% caxis([min(min(MEANvALUE)),max(max(MEANvALUE))])
caxis([40 140])
% caxis([-1 1.5])

% rCyl = 25;
% [Xcyl,Zcyl,Ycyl] = cylinder(rCyl);
% plotCylinder = surf(Xcyl,(Ycyl*Lcyl)-Lcyl/2,Zcyl+Dcyl/2);
% plotCylinder.FaceColor = [0.7 0.7 0.7];
% plotCylinder.EdgeColor = 'none';

drawCylinder(dCyl/2,lCyl,64);

zFaktor = 3;
daspect([1 1 1/zFaktor])
view([20,20])

xlabel('$x$ [mm]',Interpreter='latex')
% ylabel('$y$ [mm]',Interpreter='latex')
zlabel('$z$ [mm]',Interpreter='latex')
set(gca,'TickLabelInterpreter','latex')

nexttile
plotWSL = surf(X,Y,MEANvALUE); hold on
plotWSL.FaceAlpha = 0.75;
% plotWSL.EdgeColor = 'none';

% caxis([min(min(MEANvALUE)),max(max(MEANvALUE))])
caxis([40 140])

drawCylinder(dCyl/2,lCyl,64);

zFaktor = 3;
daspect([1 1 1/zFaktor])
view([0,0])

xlabel('$x$ [mm]',Interpreter='latex')
ylabel('$y$ [mm]',Interpreter='latex')
zlabel('$z$ [mm]',Interpreter='latex')
set(gca,'TickLabelInterpreter','latex')

nexttile
plotWSL = surf(X,Y,MEANvALUE); hold on
plotWSL.FaceAlpha = 0.75;
% plotWSL.EdgeColor = 'none';

% caxis([min(min(MEANvALUE)),max(max(MEANvALUE))])
caxis([40 140])

[vertices,sideFaces,bottomFaces] = drawCylinder(dCyl/2,lCyl,64);

zFaktor = 3;
daspect([1 1 1/zFaktor])
view([0,90])

xlabel('$x$ [mm]',Interpreter='latex')
ylabel('$y$ [mm]',Interpreter='latex')
zlabel('$z$ [mm]',Interpreter='latex')
set(gca,'TickLabelInterpreter','latex')

% function syncData
% syncData(dname,filenameISEL,filenameUSS,matlabFolder)

% title(tlayout,['$L_{cyl}$ = ',num2str(lCyl),' mm,',...
%     ' $\gamma$ = ',num2str(gammaCyl),'$^\circ$,',...
%     ' $Q$ = ',num2str(Q),' l/s',...
%     ' (',num2str(zFaktor),'-fach \"uberh\"oht)'],...
%     Interpreter='latex')
% title(tlayout,'test')

cd(matlabFolder)
disp('All done')




%%
function [vertices,sideFaces,bottomFaces] = drawCylinder(rCyl,lCyl,sideCount)

% Vertices
vertices = zeros(2*sideCount, 3);
for i = 1:sideCount
    theta = 2*pi/sideCount*(i-1);
    vertices(i,:) = [rCyl*cos(theta),0-lCyl/2,rCyl*sin(theta)+rCyl];
    vertices(sideCount+i,:) = [rCyl*cos(theta),lCyl/2, rCyl*sin(theta)+rCyl];
end

% Side faces
sideFaces = zeros(sideCount, 4);
for i = 1:(sideCount-1)
    sideFaces(i,:) = [i, i+1, sideCount+i+1, sideCount+i];
end
sideFaces(sideCount,:) = [sideCount, 1, sideCount+1, 2*sideCount];

% Bottom faces
bottomFaces = [
    1:sideCount;
    (sideCount+1):2*sideCount];

% Draw patches
patch('Faces', sideFaces, 'Vertices', vertices,...
    'EdgeColor','none','FaceColor', [.4 .4 .4]);
patch('Faces', bottomFaces, 'Vertices', vertices,...
    'EdgeColor','none','FaceColor', [.6 .6 .6]);
end