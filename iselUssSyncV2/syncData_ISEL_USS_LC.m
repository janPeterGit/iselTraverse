clc
clear all
close all


% clearvars -except C D

%% Dateien einlesen
% read ISEL log Datei
matlabFolder = pwd;

% alle oder nur ausgewählter measurementDay?
allDays = 0;

measurementDirectory = uigetdir('LogISEL_LogUSS_LogLC/');
if allDays == 1
    measurementDays = dir(measurementDirectory);
else
    measurementDays = NaN(3,1);
end

for j = 3:size(measurementDays,1) % 3 wegen . und ..

    if allDays == 1
    selectedDay = [measurementDays(j).folder,'\',measurementDays(j).name];
    else
        selectedDay = measurementDirectory;
    end
    cd(selectedDay)
    measurements = ls('*.xlsx');
    cd(matlabFolder)



    for i = 1:size(measurements,1)
        disp('#################################################')
        disp(['Measurement ',num2str(i),'/',num2str(size(measurements,1))])

        filenameISEL = strtrim(measurements(i,:));
        filenameUSS = [filenameISEL(1:end-5),'.csv'];
        filenameLC = [filenameISEL(1:end-5),'.txt'];

        % function syncData
        syncData(selectedDay,filenameISEL,filenameUSS,filenameLC,...
            matlabFolder)
    end
end
disp('All done')




%%
function syncData(folder,filenameISEL,filenameUSS,filenameLC,matlabFolder)
%
% plotting = 1;
plotting = 1;

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

% korrektur Durchbiegung bis einschl. 6.5.2022
correctionFolder = 'correctDeflection';
if exist(correctionFolder, 'dir')
    deflectionCorrection = 1;
    correctionTable =  readtable([correctionFolder,'/correctDeflection.xlsx']);
else
    deflectionCorrection = 0;
end

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



% Variablen aus Dateinamen extrahieren
TimeString = char(extractBefore(filenameISEL,'_D'));
D = char(extractBetween(filenameISEL,'D','L'));
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

% Korrektur durch Unebene Sohle für case S(!)
if Position == 'S'
    bedLevelCorrection = 1;
    correctBedLevel = table2array(readtable('emptyFlume\bedLevelCaseS.xlsx'));
end

% einladen der Messdaten aus Ultraschallmessung für Sensoren 1 und 2
% (x-Traverse)
for i = 1:anzahlMesspunkteX
    startTime = iselTable.timeStartMeasurement(i);
    endTime = iselTable.timeEndMeasurement(i);

    %     shiftTime = minutes(119)+seconds(59);
    shiftTime = 0;

    startID = knnsearch(datenum(ussTable.Var1+shiftTime),datenum(startTime));
    endID = knnsearch(datenum(ussTable.Var1+shiftTime),datenum(endTime));

    for j = 1:iselTable.countSensors(1)
        xPosition(i,:) = iselTable.xPosition(i);
        yPosition(:,j) = iselTable.y0(1) - (j-1) * iselTable.deltaYSensors(1);
        % korrektur Durchbiegung bis einschl. 6.5.2022
        if deflectionCorrection == 1
            hLoopMean = mean(ussMatrix(startID:endID,j)...
                +correctionTable.correctDeflection(i,1));
            hLoopStdDev = std(ussMatrix(startID:endID,j)...
                +correctionTable.correctDeflection(i,1));
        elseif bedLevelCorrection == 1
            hLoopMean = mean(ussMatrix(startID:endID,j))...
                -correctBedLevel(i,j);
            hLoopStdDev = std(ussMatrix(startID:endID,j))...
                -correctBedLevel(i,j);
        else
            hLoopMean = mean(ussMatrix(startID:endID,j));
            hLoopStdDev = std(ussMatrix(startID:endID,j));
        end

%         if hLoopMean > hUp + 5 || hLoopMean < 0 || hLoopStdDev > 5
%             hMatrixMean(i,j) = NaN;
%             hMatrixStdDev(i,j) = NaN;
%         else
            hMatrixMean(i,j) = hLoopMean;
            hMatrixStdDev(i,j) = hLoopStdDev;
%         end
    end
end

SensorID = 2; % Sensor entlang +5cm Zylindermitte

hSensor2 = hMatrixMean(:,SensorID);
hDownMin = min(hSensor2(xPosition(:,SensorID) > 0));
hUpMax = max(hSensor2(xPosition(:,SensorID) < str2double(D)/1000/2));
hCyl = hSensor2(xPosition(:,SensorID) == 0) - str2double(D) - str2double(G);

% Kraftberechnung %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataTable = table; % Tabelle erstellen, die mit Werten beschrieben wird

% dataTable.D = str2double(extractBetween(filenameLC,'D','L'))/1000; % diameter cylinder
dataTable.D = str2double(D)/1000; % todo
dataTable.L = str2double(L)/1000; % length cylinder
dataTable.gamma = str2double(W); % angle
dataTable.Position = Position;
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

hUpMinusG = dataTable.hUp - dataTable.G;
hUpMaxMinusG = dataTable.hUpMax - dataTable.G;
hDownMinusG = dataTable.hDown - dataTable.G;
%%%% Hier muss berechnet werden, dass der Zylinder teilweise unter Wasser
%%%% ist und zudem gedreht wird % todo
% dataTable.Aref = sind(dataTable.gamma)*dataTable.L*dataTable.D + cosd(dataTable.gamma)*pi()/4*dataTable.D^2;
% todo: hier muss nicht hUpMinusG genutzt werden sondern hUpMaxMinusG
if hUpMinusG > dataTable.D
    dataTable.Aref = dataTable.L * dataTable.D;
elseif hUpMinusG <= dataTable.D
    dataTable.Aref = dataTable.L * hUpMinusG;
end
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

extraMargin = 2/1000;
DplusMargin = dataTable.D + extraMargin;
% F_S = hydrostatische Druckkraft (Habil, Oertel (2012), Eq. 3.25)
% h_up <= D und h_down <= D
if hUpMaxMinusG <= DplusMargin &&...
        hUpMinusG <= DplusMargin &&...
        hDownMinusG <= DplusMargin
    caseNum = 11;
    caseStr = '1';
    % todo: gilt nur für 90 Grad wegen D
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;
    dataTable.Fs = density * gravity * dataTable.L * (hUpMinusG.^2 - hDownMinusG.^2);

    % F_total = F_D + F_S
    dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;
    % h_up > D und h_down <= D
elseif hUpMinusG > DplusMargin && hDownMinusG < DplusMargin && ...
        round(dataTable.hDownMin - dataTable.hgr,3) >= 0
    caseNum = 21;
    caseStr = '2A';
    % todo: gilt nur für 90 Grad wegen L und D
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;
    dataTable.Fs = density * gravity * dataTable.L * ...
        (dataTable.D .* (hUpMinusG - 0.5 * dataTable.D) -0.5 * hDownMinusG.^2);

    % F_total = F_D + F_S
    dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;
    % h_up > D und h_down > D
elseif hUpMinusG > DplusMargin && hDownMinusG < DplusMargin && ...
        round(dataTable.hDownMin - dataTable.hgr,3) < 0
    caseNum = 22;
    caseStr = '2B';
    % todo: gilt nur für 90 Grad wegen L und D
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;
    dataTable.Fs = density * gravity * dataTable.L * ...
        (dataTable.D .* (hUpMinusG - 0.5 * dataTable.D) -0.5 * hDownMinusG.^2);

    % F_total = F_D + F_S
    dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;
    % h_up > D und h_down > D
elseif hUpMinusG > DplusMargin && hDownMinusG > DplusMargin && ...
        round(dataTable.hDownMin - dataTable.hgr,3) >= 0
    caseNum = 31;
    caseStr = '3A';
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;
    dataTable.Fs = density * gravity * dataTable.Aref * (hUpMinusG - hDownMinusG);

    % F_total = F_D + F_S
    dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;
elseif hUpMinusG > DplusMargin && hDownMinusG > DplusMargin && ...
        round(dataTable.hDownMin - dataTable.hgr,3) < 0
    caseNum = 32;
    caseStr = '3B';
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;



    dataTable.Fs = density * gravity * dataTable.Aref * (hUpMinusG - hDownMinusG);

    % F_total = F_D + F_S
    dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;

else
    disp(['Keine Zuordnung möglich für die Messung vom ',TimeString])
    caseNum = 99;
    caseStr = 'kA';
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;



    dataTable.Fs = NaN;

    % F_total = F_D + F_S
    dataTable.Ftotal = NaN;
end

% specific momentum Turcotte, 2016
dataTable.FspecMom = density * gravity * dataTable.L /B *(((dataTable.Q/B)^2 / (gravity *dataTable.hUp) + (dataTable.hUp^2 /2)) ...
    - ((dataTable.Q/B)^2 /(gravity *dataTable.hDown) + (dataTable.hDown^2 /2)));


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

% Output directory
outputDirectory = 'OutputWSL';
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

% Daten plotten %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if plotting == 1

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

    hDecision = plot([-100,0],[(DplusMargin+dataTable.G)*1000,(DplusMargin+dataTable.G)*1000],':');
    hDecision.DisplayName = '\slG + D + \rmmargin';
    hDecision.LineWidth = 1;

    % Zylinder
    posCylinder = [-str2double(D)/2 str2double(G) str2double(D) str2double(D)];
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


    % Daten in Tabelle schreiben und Bild exportieren %%%%%%%%%%%%%%%%%%%%%%%%%

    figureName = [outputDirectory,'/',TimeString,'_D',D,'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'_WSL.png'];
    try
        delete(figureName)
    catch ME
    end
    exportgraphics(f,figureName,'Resolution',400)
    % close all

end

exportTable = table;
exportTable.xPosition = xPosition;
exportTable.yPosition = yPosition;
exportTable.h = hMatrixMean;

filename = [outputDirectory,'/',TimeString,'_D',D,'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'_WSL.xlsx'];
% filename = 'testOutput.xlsx';
try
    delete(filename);
catch ME
end
writetable(exportTable,filename,'Sheet','Messdaten','WriteVariableNames',true);

filename = [outputDirectory,'/',TimeString,'_D',D,'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'_DATA.xlsx'];
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