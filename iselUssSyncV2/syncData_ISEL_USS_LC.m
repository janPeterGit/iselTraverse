clc
clear all
close all


% clearvars -except C D

%% Dateien einlesen
% read ISEL log Datei
matlabFolder = pwd;

measurementDirectory = uigetdir('Measurements/');
cd(measurementDirectory)
measurements = ls('*.xlsx');
cd(matlabFolder) 

for i = 1:size(measurements,1)
    disp('#################################################')
    disp(['Measurement ',num2str(i),'/',num2str(size(measurements,1))])

    filenameISEL = convertStringsToChars(strtrim(convertCharsToStrings(measurements(i,:))));
    filenameUSS = [filenameISEL(1:end-5),'.csv'];
    filenameLC = [filenameISEL(1:end-5),'.txt'];
    
    % function syncData
    syncData(measurementDirectory,filenameISEL,filenameUSS,filenameLC,...
        matlabFolder)
end

disp('All done')







%%
function syncData(folder,filenameISEL,filenameUSS,filenameLC,matlabFolder)
%
cd(folder)
% read ISEL Datei
iselTable = readtable(filenameISEL);

% read USS log Datei
% ussTablefilename = uigetfile('*.csv');
ussTable = readtable(filenameUSS);
ussMatrix = table2array(ussTable(:,2:5))*1000; % *1000 m --> mm

% read Load Cell Datei
% [filenameLC,path] = uigetfile('*.txt');
forceArray = importFileLC(filenameLC);

cd(matlabFolder)

% Konstanten
B = 0.79; %m
density = 1000; % kg/m³
gravity = 9.81; % m/s²
kinematicViscosity = 1e-6; % todo

% D_Pipe = 8/1000; % mm
% CD_Pipe = 1;
% CD_Lmid = 1;
% CD_Llong = 1;
CD_one = 1;

D = 50; % todo

% Variablen aus Dateinamen extrahieren
L = char(extractBetween(filenameISEL,'L','W'));
W = char(extractBetween(filenameISEL,'W','Q'));
Q = char(extractBetween(filenameISEL,'Q','H'));
h = char(extractBetween(filenameISEL,'H','G'));
G = char(extractBetween(filenameISEL,'G','_'));
Position = char(extractBetween(filenameISEL,['G',G,'_'],'.x'));

% Fließgeschwindigkeit berechnen
u = round(str2double(Q)/str2double(h)/B*1000/1000,3);
uChar = sprintf('%.2f',u);

% Dateien synchronisieren und Mittelwerte berechnen
% fest verbaute Sensoren bei -2 und +2 m relativ zur Zylindermitte
hUpXposition = -2000;
hDownXposition = 2000;
% Mittelwerte USS Messung
hUp = mean(ussMatrix(:,3));
hDown = mean(ussMatrix(:,4));

% Anzahl Messpunkte
anzahlMesspunkteX = length(iselTable.xPosition);

hMatrixMean = NaN(anzahlMesspunkteX,iselTable.countSensors(1));
hMatrixStdDev = hMatrixMean;
xPosition = hMatrixMean;
yPosition = hMatrixMean;

for i = 1:anzahlMesspunkteX
    startTime = iselTable.timeStartMeasurement(i);
    endTime = iselTable.timeEndMeasurement(i);

    startID = knnsearch(datenum(ussTable.Var1),datenum(startTime));
    endID = knnsearch(datenum(ussTable.Var1),datenum(endTime));

    for j = 1:iselTable.countSensors(1)
        xPosition(i,:) = iselTable.xPosition(i);
        yPosition(:,j) = iselTable.y0(1) - (j-1) * iselTable.deltaYSensors(1);
        hLoopMean = mean(ussMatrix(startID:endID,j));
        hLoopStdDev = std(ussMatrix(startID:endID,j));
        if hLoopMean > hUp + 5 || hLoopMean < 0 || hLoopStdDev > 5
            hMatrixMean(i,j) = NaN;
            hMatrixStdDev(i,j) = NaN;
        else
            hMatrixMean(i,j) = hLoopMean;
            hMatrixStdDev(i,j) = hLoopStdDev;
        end
    end
end

SensorID = 2; % Sensor entlang +5cm Zylindermitte

hSensor2 = hMatrixMean(:,SensorID);
hDownMin = min(hSensor2(xPosition(:,SensorID) > 0));
hUpMax = max(hSensor2(xPosition(:,SensorID) < 0));
hCyl = hSensor2(xPosition(:,SensorID) == 0) - D - str2double(G);

% Kraftberechnung %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataTable = table; % Tabelle erstellen, die mit Werten beschrieben wird

% dataTable.D = str2double(extractBetween(filenameLC,'D','L'))/1000; % diameter cylinder
dataTable.D = D/1000; % todo
dataTable.L = str2double(L)/1000; % length cylinder
dataTable.gamma = str2double(W); % angle
dataTable.Q = str2double(Q)/1000; % discharge

dataTable.hUp = hUp/1000;
dataTable.hUpMax = hUpMax/1000;
dataTable.hCyl = hCyl/1000;
dataTable.hDown = hDown/1000;
dataTable.hDownMin = hDownMin/1000;

% dataTable.G = str2double(extractBetween(filenameLC,'G','.txt'))/1000; % gap
dataTable.G = str2double(G)/1000;
dataTable.z = dataTable.G + dataTable.D./2; % center Cylinder to bed lvl
dataTable.u = dataTable.Q/(B*dataTable.hUp); % velocity

dataTable.GdivD = dataTable.G/dataTable.D; % G/D

dataTable.hDivD = dataTable.hUp/dataTable.D;
dataTable.LdivB = dataTable.L/B;

dataTable.Aref = sind(dataTable.gamma)*dataTable.L*dataTable.D + cosd(dataTable.gamma)*pi()/4*dataTable.D^2;
% dataTable.PipeRef = D_Pipe .* (dataTable.h - dataTable.D - dataTable.G);

dataTable.BR = dataTable.Aref / (B * dataTable.hUp);
% dataTable.BR = (dataTable.Aref + dataTable.PipeRef) / (B * dataTable.h);

% korrekte Spalte in eingeladener .txt auswählen (in den Spalten ohne
% Messwerte ist der Wert immer -1000000
for j = 2:5
    if forceArray(1,j) == -1000000
    else
        % mx = Masse in gramm
        dataTable.mx = mean(forceArray(:,j));
    end
end

% weitere Daten berechnen
dataTable.FmeasuredUncor = dataTable.mx * gravity / 1000;

% dataTable.FmountCalcBR = CD_Pipe .* (1-dataTable.BR).^-2 .* dataTable.PipeRef .* dataTable.v.^2 .* 1000 .* 0.5;
% dataTable.Fmeasured = dataTable.FmeasuredUncor - dataTable.FmountCalcBR;

dataTable.CDgeneral = 2 * dataTable.FmeasuredUncor ./(density * dataTable.u.^2 .* dataTable.Aref);
dataTable.CDBR = 2 * dataTable.FmeasuredUncor ./(density * dataTable.u.^2 .* dataTable.Aref .* (1-dataTable.BR).^-2);

dataTable.hgr = ((dataTable.hUp .* dataTable.u).^2 ./ gravity).^(1/3);
dataTable.Agr = dataTable.hgr .* B;
dataTable.FrUp = dataTable.u ./ (gravity * dataTable.hUp).^(0.5);
dataTable.FrDownMax = (dataTable.Q / (dataTable.hDownMin / B)) ./ (gravity * dataTable.hDownMin).^(0.5);
dataTable.Dhy = 4 * dataTable.hUp * B ./( 2* dataTable.hUp + B );
dataTable.Re = dataTable.u .* dataTable.Dhy / kinematicViscosity;
dataTable.ReCyl = dataTable.u .* dataTable.L / kinematicViscosity;
dataTable.ReCylGroup = round(dataTable.ReCyl,-4);

% F_D = hydrodynamische Druckkraft
dataTable.Fd = CD_one * density .* dataTable.Aref .* dataTable.u.^2 /2;
% F_D mit Berücksichtigung Verbaugrad (blockage ratio BR)
dataTable.FdBR = dataTable.Fd .* (1-dataTable.BR).^(-2);

dataTable.Fs = NaN;
dataTable.FspecMom = NaN;


hUpCalc = dataTable.hUp - dataTable.G;
hDownCalc = dataTable.hDown - dataTable.G;
% F_S = hydrostatische Druckkraft (Habil, Oertel (2012), Eq. 3.25)
% h_up <= D und h_down <= D
if hUpCalc <= dataTable.D && hDownCalc <= dataTable.D
    caseNum = 1;
    % todo: gilt nur für 90 Grad wegen D
    dataTable.caseNum = caseNum;
    dataTable.Fs = density * gravity * dataTable.L (hUpCalc^2 - hDownCalc^2);
    % h_up > D und h_down <= D
elseif hUpCalc > dataTable.D && hDownCalc < dataTable.D
    caseNum = 2;
    % todo: gilt nur für 90 Grad wegen L und D
    dataTable.caseNum = caseNum;
    dataTable.Fs = density * gravity * dataTable.L * (dataTable.D .* (hUpCalc - 0.5 * dataTable.D) -0.5 * hDownCalc.^2);
    % h_up > D und h_down > D
elseif hUpCalc > dataTable.D && hDownCalc > dataTable.D && dataTable.hDownMin - dataTable.hgr > 0
    caseNum = 3;
    dataTable.caseNum = caseNum;
    dataTable.Fs = density * gravity * dataTable.Aref * (hUpCalc - hDownCalc);
elseif hUpCalc > dataTable.D && hDownCalc > dataTable.D && dataTable.hDownMin - dataTable.hgr < 0
    caseNum = 4;
    dataTable.caseNum = caseNum;
    % specific momentum Turcotte, 2016
    dataTable.FspecMom = density * gravity * dataTable.L /B *(((dataTable.Q/B)^2 / (gravity *dataTable.hUp) + (dataTable.hUp^2 /2)) ...
        - ((dataTable.Q/B)^2 /(gravity *dataTable.hDown) + (dataTable.hDown^2 /2)));
end
% F_total = F_D + F_S
dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;



% Ausgabe im Command Window
disp('---')
disp(['Case# ',num2str(caseNum),': h_up = ',num2str(dataTable.hUp*1000,'%.1f'), ...
    ' mm, h_down = ',num2str(dataTable.hDown*1000,'%.1f'),' mm'])
disp(['F_measured = ',num2str(dataTable.FmeasuredUncor,'%.2f'),' N'])
disp(['F_calculated (Oertel, 2012) = ',num2str(dataTable.Ftotal,'%.2f'),' N'])
disp(['Deviation = ', ...
    num2str((dataTable.Ftotal/dataTable.FmeasuredUncor-1)*100,'%.1f'),'%'])
disp('where:')
disp(['F_D = ',num2str(dataTable.Fd,'%.2f'),' N'])
disp(['F_D,BR = ',num2str(dataTable.FdBR,'%.2f'),' N'])
disp(['F_S = ',num2str(dataTable.Fs,'%.2f'),' N'])
disp(' ')

% Daten plotten %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    close all
catch ME
end

font = 'Arial';
fontSize = 12;
f = figure('DefaultTextFontName', font, ...
    'DefaultAxesFontName', font,...
    'DefaultAxesFontSize',fontSize, ...
    'DefaultTextFontSize',fontSize);
f.Name = 'WSL';
f.Color = [1 1 1];
f.Units = 'centimeters';    
f.InnerPosition = [5 5 30 24];
f.WindowState = 'normal'; %fullscreen, minimize, normal, maximize

hold on
for k = 1:iselTable.countSensors(1)
    x = xPosition(:,k);
    y = hMatrixMean(:,k);
    errSdt = hMatrixStdDev(:,k);
    xs = x(~isnan(y));
    ys = y(~isnan(y));
    errSdts = errSdt(~isnan(y));
    %     yi = interp1(xs, ys, x, 'Linear');
    wslPlot = errorbar(xs,ys,errSdts,'-');
    wslPlot.DisplayName = ['\sly\rm = ',num2str(yPosition(1,k)),' mm'];
end

hUpPlot = plot([hUpXposition,-500],[hUp,hUp],'--');
hUpPlot.DisplayName = ['\slh_{up} (x\rm = ',num2str(hUpXposition),' mm)'];
hUpPlot.LineWidth = 2;

hDownPlot = plot([500,hDownXposition],[hDown,hDown],'--');
hDownPlot.DisplayName = ['\slh_{down} (x\rm = ',num2str(hDownXposition),' mm)'];
hDownPlot.LineWidth = 2;

hGrPlot = plot([0,500],[dataTable.hgr*1000,dataTable.hgr*1000],'--');
hGrPlot.DisplayName = '\slh_{gr}';
hGrPlot.LineWidth = 2;

% Zylinder
posCylinder = [-25 2 50 50];
cylinderplot = rectangle('Position',posCylinder,'Curvature',[1 1]);
cylinderplot.FaceColor = [136/255 0 0];
% cylinderplot.EdgeColor = 'none';

annotationDimension = [.15 .13 .3 .3];
annotationString = {['Case# ',num2str(caseNum)];
    ['\slh_{up}\rm = ',num2str(dataTable.hUp*1000,'%.1f'), ...
    ' mm, \slh_{down}\rm = ',num2str(dataTable.hDown*1000,'%.1f'),' mm'];
    ['\slh_{up,max}\rm = ',num2str(dataTable.hUpMax*1000,'%.1f'),' mm', ...
    ', \slh_{down,min}\rm = ',num2str(dataTable.hDownMin*1000,'%.1f'),' mm'];
    ['\slh_{gr}\rm = ',num2str(dataTable.hgr*1000,'%.1f'),' mm'];
    ['\slF_{measured}\rm = ',num2str(dataTable.FmeasuredUncor,'%.2f'),' N'];
    ['\slF_{calculated}\rm = ',num2str(dataTable.Ftotal,'%.2f'),' N', ...
    ', \sl\DeltaF\rm = ',num2str(dataTable.Ftotal-dataTable.FmeasuredUncor,'%.2f'), ...
    ' N (',num2str(((dataTable.Ftotal/dataTable.FmeasuredUncor)-1)*100,'%.1f'),'%)'];
    ['\slF_{D,BR}\rm = ',num2str(dataTable.FdBR,'%.2f'),' N', ...
    ', \slF_S\rm = ',num2str(dataTable.Fs,'%.2f'),' N']};
AnnottationBox = annotation('textbox',annotationDimension,'String',annotationString);
AnnottationBox.FontName = font;
AnnottationBox.FontSize = fontSize*0.75;
AnnottationBox.FitBoxToText = 'on';
AnnottationBox.BackgroundColor = [.95 .95 .95];

xlim([-1000 1400])
ylim([0 150])
legend(Location="northeast")

grid on

scaleFactor = 5;
daspect([1 1/scaleFactor 1])

xlabel('\slx\rm [mm]')
ylabel('\slh\rm [mm]')
titleString = ['\rm\slu\rm = ',num2str(dataTable.u,'%.2f'),' m/s, \slL\rm = ',L,' mm, \sl\gamma\rm = ',W,'°, \slh\rm-scalefactor = ',num2str(scaleFactor)];
title(titleString)

pause(1)

% Daten in Tabelle schreiben und Bild exportieren %%%%%%%%%%%%%%%%%%%%%%%%%
outputDirectory = 'OutputWSL';
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

figureName = [outputDirectory,'/D',num2str(D),'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'_WSL.png'];
try
    delete(figureName)
catch ME
end
exportgraphics(f,figureName,'Resolution',400)
% close all

exportTable = table;
exportTable.xPosition = xPosition;
exportTable.yPosition = yPosition;
exportTable.h = hMatrixMean;

filename = [outputDirectory,'/D',num2str(D),'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'_WSL.xlsx'];
% filename = 'testOutput.xlsx';
try
    delete(filename);
catch ME
end
writetable(exportTable,filename,'Sheet','Messdaten','WriteVariableNames',true);

filename = [outputDirectory,'/D',num2str(D),'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'_DATA.xlsx'];
% filename = 'testOutput.xlsx';
try
    delete(filename);
catch ME
end
writetable(dataTable,filename,'Sheet','Messdaten','WriteVariableNames',true);

close all

end

%%
function loadCellArray = importFileLC(filenameLC)
% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 6);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["Zeit1Standardmessrates", "PW2DC3MRg", "PW2DC3MR_1kg", "MX440B_CH3V", "MX440B_CH4V", "VarName6"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "VarName6", "TrimNonNumeric", true);
opts = setvaropts(opts, ["Zeit1Standardmessrates", "PW2DC3MRg", "PW2DC3MR_1kg", "MX440B_CH3V", "MX440B_CH4V", "VarName6"], "DecimalSeparator", ",");
opts = setvaropts(opts, "VarName6", "ThousandsSeparator", ".");

% Import the data
loadCellTab = readtable(filenameLC, opts);

loadCellArray = table2array(loadCellTab);

% Clear temporary variables
clear opts

end
