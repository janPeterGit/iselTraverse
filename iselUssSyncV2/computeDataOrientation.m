clc
clear all
close all


% clearvars -except C D

%% Dateien einlesen
matlabFolder = pwd;

% alle oder nur ausgewählter measurementDay?
allDays = 0;

measurementDirectory = uigetdir('measurementRotation/');
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
    measurements = ls('*.csv');
    cd(matlabFolder)



    for i = 1:size(measurements,1)
        disp('#################################################')
        disp(['Measurement ',num2str(i),'/',num2str(size(measurements,1))])

        filenameUSS = strtrim(measurements(i,:));
        filenameLC = [filenameUSS(1:end-4),'.txt'];

        % function syncData
        syncData(selectedDay,filenameUSS,filenameLC,...
            matlabFolder)
    end
end
disp('All done')




%%
function syncData(folder,filenameUSS,filenameLC,matlabFolder)
%
% plotting = 1;
plotting = 1;

cd(folder)
% pwd
% ls
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



% Variablen aus Dateinamen extrahieren
TimeString = char(extractBefore(filenameUSS,'_D'));
D = char(extractBetween(filenameUSS,'D','L'));
L = char(extractBetween(filenameUSS,'L','W'));
W = char(extractBetween(filenameUSS,'W','Q'));
Q = char(extractBetween(filenameUSS,'Q','H'));
h = char(extractBetween(filenameUSS,'H','G'));
G = char(extractBetween(filenameUSS,'G','_'));
PositionCase = char(extractBetween(filenameUSS,['G',G,'_'],'.c'));

% Fließgeschwindigkeit berechnen
u = round(str2double(Q)/str2double(h)/B*1000/1000,3);
uChar = sprintf('%.2f',u);

% Dateien synchronisieren und Mittelwerte berechnen
% fest verbaute Sensoren bei -2 und +2 m relativ zur Zylindermitte
hUpXposition = -2000;
hDownXposition = 2000;
% Mittelwerte USS Messung
hUp = mean(ussMatrix(:,1));
hDown = mean(ussMatrix(:,2));


% Kraftberechnung %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataTable = table; % Tabelle erstellen, die mit Werten beschrieben wird

% dataTable.D = str2double(extractBetween(filenameLC,'D','L'))/1000; % diameter cylinder
dataTable.D = str2double(D)/1000; % todo
dataTable.L = str2double(L)/1000; % length cylinder
dataTable.gamma = str2double(W); % angle
dataTable.Position = PositionCase(1);
dataTable.Q = str2double(Q)/1000; % discharge

dataTable.hUp = hUp/1000;
dataTable.hDown = hDown/1000;

% dataTable.G = str2double(extractBetween(filenameLC,'G','.txt'))/1000; % gap
dataTable.G = str2double(G)/1000;
dataTable.z = dataTable.G + dataTable.D./2; % center Cylinder to bed lvl
dataTable.u = dataTable.Q/(B*dataTable.hUp); % velocity

dataTable.GdivD = dataTable.G/dataTable.D; % G/D

dataTable.hDivD = dataTable.hUp/dataTable.D;
dataTable.LdivB = dataTable.L/B;

hUpMinusG = dataTable.hUp - dataTable.G;
hDownMinusG = dataTable.hDown - dataTable.G;
%%%% Hier muss berechnet werden, dass der Zylinder teilweise unter Wasser
%%%% ist und zudem gedreht wird % todo
% dataTable.Aref = sind(dataTable.gamma)*dataTable.L*dataTable.D + cosd(dataTable.gamma)*pi()/4*dataTable.D^2;
% todo: hier muss nicht hUpMinusG genutzt werden sondern hUpMaxMinusG
if hUpMinusG > dataTable.D
    dataTable.Aref = sind(dataTable.gamma)*dataTable.L*dataTable.D + cosd(dataTable.gamma)*pi()/4*dataTable.D^2;
elseif hUpMinusG <= dataTable.D
    dataTable.Aref = dataTable.L *sind(dataTable.gamma) * hUpMinusG; % todo: hier wird die Ellipse nicht bedacht
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
% dataTable.FrDownMax = (dataTable.Q / (dataTable.hDownMin / B)) ./ (gravity * dataTable.hDownMin).^(0.5);
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
if PositionCase(2) == '1'
    caseNum = 10;
    caseStr = PositionCase(2);
    % todo: gilt nur für 90 Grad wegen D
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;
    dataTable.Fs = density * gravity * dataTable.L * sind(dataTable.gamma) * (hUpMinusG.^2 - hDownMinusG.^2);

    % F_total = F_D + F_S
    dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;
    % h_up > D und h_down <= D
elseif PositionCase(2) == '2'
    caseNum = 20;
    caseStr = PositionCase(2);
    % todo: gilt nur für 90 Grad wegen L und D
    dataTable.caseNum = caseNum;
    dataTable.caseStr = caseStr;
    dataTable.Fs = density * gravity * dataTable.L * sind(dataTable.gamma) * ...
        (dataTable.D .* (hUpMinusG - 0.5 * dataTable.D) -0.5 * hDownMinusG.^2);

    % F_total = F_D + F_S
    dataTable.Ftotal = dataTable.FdBR + dataTable.Fs;
    % h_up > D und h_down > D
elseif PositionCase(2) == '3'
    caseNum = 30;
    caseStr = PositionCase(2);
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
dataTable.FspecMom = density * gravity * dataTable.L * sind(dataTable.gamma)...
    /B *(((dataTable.Q/B)^2 / (gravity *dataTable.hUp) + (dataTable.hUp^2 /2)) ...
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
outputDirectory = 'OutputWSLorientation';
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

filename = [outputDirectory,'/',TimeString,'_D',D,'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',PositionCase,'_DATA.xlsx'];
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
