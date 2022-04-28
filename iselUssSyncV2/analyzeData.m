clc
clear all
close all

%%
markerSet6 = ['s'
    '^'
    'o'
    'v'
    'd'
    'h'];

matlabColor = {'#EDB120',...
    '#7E2F8E',...
    '#4DBEEE',...
    '#A2142F'};

%%

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
pltRegression.Color = 'k';
pltRegression.Marker = 'none';
pltRegression.DisplayName = '1:1';

caseNums = unique(dataTable.caseNum);
caseString = {'$h_{up}, h_{down} \leq D+G$',...
    '$h_{up} > D + G, h_{down} \leq D+G$',...
    '$h_{up}, h_{down} > D+G$', ...
    '$Fr_{Down} > 1$'};

% plot calculated Force values
for j = 1:length(caseNums)-1
    pltValues = plot(dataTable.FmeasuredUncor(dataTable.caseNum == caseNums(j)),...
        dataTable.Ftotal(dataTable.caseNum == caseNums(j)));
    pltValues.LineStyle = 'none';
    pltValues.MarkerSize = 8;
    pltValues.Marker = markerSet6(j);
    pltValues.MarkerEdgeColor = 'k';
    pltValues.MarkerFaceColor = matlabColor{j};
    pltValues.DisplayName = ['case ',num2str(caseNums(j)),': ',convertStringsToChars(convertCharsToStrings(caseString(caseNums(j))))];
end

pltSpecificMomentum = plot(dataTable.FmeasuredUncor, dataTable.FspecMom);
pltSpecificMomentum.LineStyle = 'none';
pltSpecificMomentum.MarkerSize = 8;
pltSpecificMomentum.Marker = markerSet6(j+1);
pltSpecificMomentum.MarkerEdgeColor = 'k';
pltSpecificMomentum.MarkerFaceColor = matlabColor{j+1};
pltSpecificMomentum.DisplayName = ['case ',num2str(caseNums(j+1)),': $\rho g B/L (M_{up} - M_{down})$'];

% xlim([-1000 1400])
% ylim([0 150])
lgd = legend('Interpreter','latex');
lgd.Location = 'northwest';

grid on

scaleFactor = 1;
daspect([1 1/scaleFactor 1])

maxLimit = max(max(xlim,ylim));

xlim([0 maxLimit])
ylim([0 maxLimit])

xlabel('$F_{measured}$ [N]','Interpreter','latex')
ylabel('$F_{calculated}$ [N]','Interpreter','latex')

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


%%
% plot h_down - h_up

% try
%     close all
% catch ME
% end

font = 'Arial';
fontSize = 20;
f = figure('DefaultTextFontName', font, ...
    'DefaultAxesFontName', font,...
    'DefaultAxesFontSize',fontSize, ...
    'DefaultTextFontSize',fontSize);
f.Name = 'Depth';
f.Color = [1 1 1];
f.Units = 'centimeters';
f.InnerPosition = [5 5 15 12];
f.WindowState = 'maximize'; %fullscreen, minimize, normal, maximize

% calculate dimensionless values
dataTable.hUpAsterix = dataTable.hUp ./(dataTable.D + dataTable.hgr + dataTable.G);
dataTable.hDownAsterix = dataTable.hDown ./(dataTable.D + dataTable.hgr + dataTable.G);

hold on

for k = 1:length(caseNums)
    pltDepth = plot(dataTable.hDownAsterix(dataTable.caseNum == caseNums(k)),...
        dataTable.hUpAsterix(dataTable.caseNum == caseNums(k)));
    pltDepth.LineStyle = 'none';
    pltDepth.MarkerSize = 8;
    pltDepth.Marker = markerSet6(k);
    pltDepth.MarkerEdgeColor = 'k';
    pltDepth.MarkerFaceColor = matlabColor{k};
    pltDepth.DisplayName = ['case ',num2str(caseNums(k))];
end

maxLimit = max(max(xlim,ylim));

xlim([0 maxLimit])
ylim([0 maxLimit])

pltRegression02 = plot([0 maxLimit],[0 maxLimit]);
pltRegression02.LineStyle = '-';
pltRegression02.Color = 'k';
pltRegression02.Marker = 'none';
pltRegression02.DisplayName = '1:1';

% pltBorder = plot([caseBorder4],[]);

grid on

scaleFactor = 1;
daspect([1 1/scaleFactor 1])

lgd = legend('Interpreter','latex');
lgd.Location = 'northwest';

xlabel('$h_{down}^*$ [-]','Interpreter','latex')
ylabel('$h_{up}^*$ [-]','Interpreter','latex')

%%
figureName = [outputDirectory,'/hAsterix.png'];
try
    delete(figureName)
catch ME
end
exportgraphics(f,figureName,'Resolution',400)

filename = [outputDirectory,'/sumDataTable.xlsx'];
% filename = [outputDirectory,'/D',num2str(D),'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'.xlsx'];
% filename = 'testOutput.xlsx';
try
    delete(filename);
catch ME
end
writetable(dataTable,filename,'Sheet','Messdaten','WriteVariableNames',true);

% close all
