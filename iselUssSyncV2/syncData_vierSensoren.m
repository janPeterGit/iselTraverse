clc
clear all
close all

%% Dateien einlesen
% read ISEL log Datei
matlabFolder = pwd;
[logISELfilename,path] = uigetfile('*.xlsx');

cd(path)

iselTable = readtable(logISELfilename);

L = char(extractBetween(logISELfilename,'L','W'));
W = char(extractBetween(logISELfilename,'W','Q'));
Q = char(extractBetween(logISELfilename,'Q','H'));
h = char(extractBetween(logISELfilename,'H','_'));
Position = char(extractBetween(logISELfilename,[h,'_'],'.x'));

B = 0.79; %m
u = round(str2double(Q)/str2double(h)/B*1000/1000,3);
uChar = sprintf('%.2f',u);

% read USS log Datei
% ussTablefilename = uigetfile('*.csv');
ussTablefilename = [logISELfilename(1:end-5),'.csv'];
ussTable = readtable(ussTablefilename);
ussMatrix = table2array(ussTable(:,2:5))*1000; % *1000 m --> mm

% read Load Cell Datei
[filenameLC,path] = uigetfile('*.txt');
forceArray = importFileLC(filenameLC);

cd(matlabFolder)

%% Dateien synchronisieren und Mittelwerte berechnen
% fest verbaute Sensoren bei -2 und +2 m relativ zur Zylindermitte
hUpXposition = -2000;
hDownXposition = 2000;
% Mittelwerte USS Messung
hUp = mean(ussMatrix(:,3));
hDown = mean(ussMatrix(:,4));
hGr = ((hUp/1000 .* u).^2 ./ 9.81).^(1/3)*1000;

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
        hLoop = mean(ussMatrix(startID:endID,j));
        if hLoop > hUp + 5 || hLoop < 0
            hMatrix(i,j) = NaN;
        else
            hMatrix(i,j) = hLoop;
        end
    end
end

hUpMax = max(hMatrix(xPosition < 0));

%% Kraftberechnung

% flume
B = 0.79; %m
density = 1000; % kg/m³
gravity = 9.81; % m/s²
kinematicViscosity = 1e-6; % todo

D_Pipe = 8/1000; % mm
CD_Pipe = 1;
CD_Lmid = 1;
CD_Llong = 1;
CD_one = 1;

dataTable = table; % Tabelle erstellen, die mit Werten beschrieben wird

dataTable.D = str2double(extractBetween(filenameLC,'D','L'))/1000; % diameter cylinder
dataTable.L = str2double(extractBetween(filenameLC,'L','W'))/1000; % length cylinder
dataTable.gamma = str2double(extractBetween(filenameLC,'W','Q')); % angle
dataTable.Q = str2double(extractBetween(filenameLC,'Q','H'))/1000; % discharge
% dataTable.h = str2double(extractBetween(filenameLC,'H','Z'))/1000; % water depth

dataTable.hUp = hUp/1000;
dataTable.hUpMax = hUpMax/1000;
dataTable.hDown = hDown/1000;

dataTable.G = str2double(extractBetween(filenameLC,'Z','.txt'))/1000; % gap
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
dataTable.FmeasuredUncor = dataTable.mx *9.81 / 1000;

% dataTable.FmountCalcBR = CD_Pipe .* (1-dataTable.BR).^-2 .* dataTable.PipeRef .* dataTable.v.^2 .* 1000 .* 0.5;
% dataTable.Fmeasured = dataTable.FmeasuredUncor - dataTable.FmountCalcBR;

dataTable.CDgeneral = 2 * dataTable.FmeasuredUncor ./(1000 * dataTable.u.^2 .* dataTable.Aref);
dataTable.CDBR = 2 * dataTable.FmeasuredUncor ./(1000 * dataTable.u.^2 .* dataTable.Aref .* (1-dataTable.BR).^-2);

dataTable.hgr = ((dataTable.hUp .* dataTable.u).^2 ./ 9.81).^(1/3);
dataTable.Agr = dataTable.hgr .* B;
dataTable.FrUp = dataTable.u ./ (9.81 * dataTable.hUp).^(0.5);
dataTable.Dhy = 4 * dataTable.hUp * B ./( 2* dataTable.hUp + B );
dataTable.Re = dataTable.u .* dataTable.Dhy / kinematicViscosity;
dataTable.ReCyl = dataTable.u .* dataTable.L / kinematicViscosity;
dataTable.ReCylGroup = round(dataTable.ReCyl,-4);

% F_D = hydrodynamische Druckkraft
dataTable.Fd = CD_one * 1000 .* dataTable.Aref .* dataTable.u.^2 /2;
% F_D mit Berücksichtigung Verbaugrad (blockage ratio BR)
dataTable.FdBR = dataTable.Fd .* (1-dataTable.BR).^(-2);

hUpCalc = dataTable.hUp;
hDownCalc = dataTable.hDown;
% F_S = hydrostatische Druckkraft (Habil, Oertel (2012), Eq. 3.25)
% h_up <= D und h_down <= D 
if hUpCalc <= dataTable.D + dataTable.G && hDownCalc <= dataTable.D + dataTable.G
    caseNum = 1;
    % todo: gilt nur für 90 Grad wegen D
    dataTable.Fs = density * gravity * dataTable.L (hUpCalc^2 - hDownCalc^2);
% h_up > D und h_down <= D 
elseif hUpCalc > dataTable.D + dataTable.G && hDownCalc < dataTable.D + dataTable.G
    caseNum = 2;
    % todo: gilt nur für 90 Grad wegen L und D
    dataTable.Fs = density * gravity * dataTable.L * (dataTable.D .* (hUpCalc - 0.5 * dataTable.D) -0.5 * hDownCalc.^2);
% h_up > D und h_down > D
elseif hUpCalc > dataTable.D + dataTable.G && hDownCalc > dataTable.D + dataTable.G
    caseNum = 3;
    dataTable.Fs = density * gravity * dataTable.Aref * (hUpCalc - hDownCalc);
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
    num2str(dataTable.Ftotal/dataTable.FmeasuredUncor*100,'%.1f'),'%'])
disp('where:')
disp(['F_D = ',num2str(dataTable.Fd,'%.2f'),' N'])
disp(['F_D,BR = ',num2str(dataTable.FdBR,'%.2f'),' N'])
disp(['F_S = ',num2str(dataTable.Fs,'%.2f'),' N'])

%% Daten plotten
try
    close all
catch ME
end

font = 'Arial';
fontSize = 20;
f = figure('DefaultTextFontName', font, ...
    'DefaultAxesFontName', font,...
    'DefaultAxesFontSize',fontSize, ...
    'DefaultTextFontSize',fontSize);
f.Name = 'WSL';
f.Color = [1 1 1];
f.Units = 'centimeters';
f.InnerPosition = [5 5 15 12];
f.WindowState = 'maximize'; %fullscreen, minimize, normal, maximize

hold on
for k = 1:iselTable.countSensors(1)
    x = xPosition(:,k);
    y = hMatrix(:,k);
    xs = x(~isnan(y));
    ys = y(~isnan(y));
    yi = interp1(xs, ys, x, 'Linear');
    wslPlot = plot(xs,ys,'-o');
    wslPlot.DisplayName = ['\sly\rm = ',num2str(yPosition(1,k)),' mm'];
end

hUpPlot = plot([hUpXposition,-500],[hUp,hUp],'--');
hUpPlot.DisplayName = ['\slh_{up} (x\rm = ',num2str(hUpXposition),' mm)'];
hUpPlot.LineWidth = 2;

hDownPlot = plot([500,hDownXposition],[hDown,hDown],'--');
hDownPlot.DisplayName = ['\slh_{down} (x\rm = ',num2str(hDownXposition),' mm)'];
hDownPlot.LineWidth = 2;

hGrPlot = plot([0,500],[hGr,hGr],'--');
hGrPlot.DisplayName = '\slh_{gr}';
hGrPlot.LineWidth = 2;

% Zylinder
posCylinder = [-25 2 50 50];
cylinderplot = rectangle('Position',posCylinder,'Curvature',[1 1]);
cylinderplot.FaceColor = [136/255 0 0];
% cylinderplot.EdgeColor = 'none';

annotationDimension = [.14 .13 .3 .3];
annotationString = {['Case# ',num2str(caseNum),': \slh_{up}\rm = ',num2str(dataTable.hUp*1000,'%.1f'), ...
    ' mm, \slh_{down}\rm = ',num2str(dataTable.hDown*1000,'%.1f'),' mm'];
    ['\slh_{up,max}\rm = ',num2str(dataTable.hUpMax*1000,'%.1f'),' mm']
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

%% Daten in Tabelle schreiben und Bild exportieren
outputDirectory = 'OutputWSL';
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

figureName = [outputDirectory,'/L',L,'W',W,'Q',Q,'U',uChar,'H',h,'_',Position,'_WSL.png'];
try
    delete(figureName)
catch ME
end
exportgraphics(f,figureName,'Resolution',400)
% close all

exportTable = table;
exportTable.xPosition = xPosition;
exportTable.yPosition = yPosition;
exportTable.h = hMatrix;

filename = [outputDirectory,'/L',L,'W',W,'Q',Q,'U',uChar,'H',h,'_',Position,'_WSL.xlsx'];
% filename = 'testOutput.xlsx';
try
    delete(filename);
catch ME
end
writetable(exportTable,filename,'Sheet','Messdaten','WriteVariableNames',true);

close all

%% Funktionen
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
