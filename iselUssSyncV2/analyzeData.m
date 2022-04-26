clc
clear all
close all

matlabDirectory = pwd;
dataDirectory = 'OutputWSL';

cd(dataDirectory)

cases = ls('*DATA.xlsx');

dataTable = table;

for i = 1:size(cases,1)
    disp(['case ',num2str(i),'/',num2str(size(cases,1))])
        
        filename = strtrim(convertCharsToStrings(cases(i,:)));
        clear dataTableImport
        dataTableImport = readtable(filename);

        dataTable(i,:) = dataTableImport;
end

%%
% plot data

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
f.Name = 'Forces';
f.Color = [1 1 1];
f.Units = 'centimeters';
f.InnerPosition = [5 5 15 12];
f.WindowState = 'maximize'; %fullscreen, minimize, normal, maximize

hold on
% plot regressionen 1:1 line
pltRegression = plot(dataTable.FmeasuredUncor,dataTable.FmeasuredUncor);
pltRegression.LineStyle = '-';
pltRegression.Marker = 'none';
pltRegression.DisplayName = '1:1';

% plot calculated Force values
pltValues = plot(dataTable.FmeasuredUncor,dataTable.Ftotal);
pltValues.LineStyle = 'none';
pltValues.Marker = 'o';
pltValues.DisplayName = 'Calculated Values';

% xlim([-1000 1400])
% ylim([0 150])
lgd = legend();
lgd.Location = 'northwest';

grid on

scaleFactor = 1;
daspect([1 1/scaleFactor 1])

xlabel('\slF_{measured}\rm [N]')
ylabel('\slF_{calculated}\rm [N]')

%%
% save dataTable and plot
cd(matlabDirectory) % go to matlab folder

outputDirectory = 'OutputForces';
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

% figureName = [outputDirectory,'/D',num2str(D),'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'.png'];
figureName = [outputDirectory,'/1to1-Forces.png'];
try
    delete(figureName)
catch ME
end
exportgraphics(f,figureName,'Resolution',400)
% close all

filename = [outputDirectory,'/sumDataTable.xlsx'];
% filename = [outputDirectory,'/D',num2str(D),'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'.xlsx'];
% filename = 'testOutput.xlsx';
try
    delete(filename);
catch ME
end
writetable(dataTable,filename,'Sheet','Messdaten','WriteVariableNames',true);

close all





