clc
clear all
close all

%%
markerSet6 = ['o'
    '^'
    's'
    'v'
    'd'
    'h'];

matlabColor = {'#0072BD',...
    '#D95319',...
    '#EDB120',...
    '#7E2F8E',...
    '#77AC30',...
    '#4DBEEE',...
    '#D95319',...
    '#4DBEEE',...
    '#77AC30',...
    '#7E2F8E',...
    '#EDB120'
    };

dateIndexPlot = 0;

B = 0.79;

%%

matlabDirectory = pwd;
dataDirectory = 'OutputWSL';
% dataDirectory = 'OutputWSLorientation';

cd(dataDirectory)

cases = ls('*DATA.xlsx');

dataTable = table;

for i = 1:size(cases,1)
    disp(['case ',num2str(i),'/',num2str(size(cases,1))])

    filename = convertStringsToChars(strtrim(convertCharsToStrings(cases(i,:))));
    clear dataTableImport
    dataTableImport = readtable(filename);
    dataTableImport.measurementDay = str2double(filename(1:8));
    dataTable(i,:) = dataTableImport;
end

dataTable = dataTable(dataTable.D == 0.05,:); % alle D=60mm Messungen aussortieren

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

maxLimit = max(max(dataTable.FmeasuredUncor,...
    dataTable.Ftotal));
% plot each Length
uniqueLength = unique(dataTable.L);
for kk = 1:length(uniqueLength)
    dataTableLengthSelected = dataTable(dataTable.L == uniqueLength(kk),:);

    caseNums = unique(dataTableLengthSelected.caseNum);
    caseStr = unique(dataTableLengthSelected.caseStr);
    positions = unique(cell2mat(dataTableLengthSelected.Position));
    % plot calculated Force values
    % each case
    subplot(1,2,kk); hold on
    addOneToOneLine(dataTable.FmeasuredUncor)
%     addTrendline(1,dataTableLengthSelected.FmeasuredUncor,...
%         dataTableLengthSelected.Ftotal)
    for ll = 1:length(positions)
        
        positionIndex = strcmp(dataTableLengthSelected.Position, positions(ll,:));
        [idR,idC] = find(positionIndex == 1);
        dataTablePositionSelected = dataTableLengthSelected(min(idR):max(idR),:);
    
        for j = 1:length(caseNums)%-1


            dataTableCaseSelected = dataTablePositionSelected(dataTablePositionSelected.caseNum == caseNums(j),:);
            if size(dataTableCaseSelected,1) > 0
                pltValues = plot(dataTableCaseSelected.FmeasuredUncor,...
                    dataTableCaseSelected.Ftotal);

                pltValues.LineStyle = 'none';
                pltValues.MarkerSize = 8;
                pltValues.Marker = markerSet6(ll);
                pltValues.MarkerEdgeColor = 'k';
                pltValues.MarkerFaceColor = matlabColor{j};
                pltValues.DisplayName = [num2str(size(dataTableCaseSelected,1)),...
                    'x case ',caseStr{j},', ',positions(ll,:)];

            end

            lgd = legend('Interpreter','latex');
            lgd.Location = 'northwest';

            grid on

            scaleFactor = 1;
            daspect([1 1/scaleFactor 1])



            xlim([0 maxLimit])
            ylim([0 maxLimit])

            xlabel('$F_{measured}$ [N]','Interpreter','latex')
            ylabel('$F_{calculated}$ [N]','Interpreter','latex')

            title(['$L/B = ',num2str(uniqueLength(kk)/B),'$'], ...
                'Interpreter','latex')
        end
    end

end

sgtitle('$F_{calculated}=F_{total}=F_D+F_S$', ...
    'Interpreter','latex','FontSize',fontSize*1.2)

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
% plot data

font = 'Arial';
fontSize = 24;
f = figure('DefaultTextFontName', font, ...
    'DefaultAxesFontName', font,...
    'DefaultAxesFontSize',fontSize, ...
    'DefaultTextFontSize',fontSize);
f.Name = 'Forces Specific Momentum';
f.Color = [1 1 1];
f.Units = 'centimeters';
f.InnerPosition = [5 5 15 12];
f.WindowState = 'maximize'; %fullscreen, minimize, normal, maximize


maxLimit = max(max(dataTable.FmeasuredUncor,...
    dataTable.FspecMom));
% plot each Length
uniqueLength = unique(dataTable.L);
for kk = 1:length(uniqueLength)
    dataTableLengthSelected = dataTable(dataTable.L == uniqueLength(kk),:);

    caseNums = unique(dataTableLengthSelected.caseNum);
    caseStr = unique(dataTableLengthSelected.caseStr);
    positions = unique(cell2mat(dataTableLengthSelected.Position));
    % plot calculated Force values
    % each case
    subplot(1,2,kk); hold on
    addOneToOneLine(dataTable.FmeasuredUncor)
    addTrendline(1,dataTableLengthSelected.FmeasuredUncor,...
        dataTableLengthSelected.FspecMom)
    for ll = 1:length(positions)
        
        positionIndex = strcmp(dataTableLengthSelected.Position, positions(ll,:));
        [idR,idC] = find(positionIndex == 1);
        dataTablePositionSelected = dataTableLengthSelected(min(idR):max(idR),:);
    
        for j = 1:length(caseNums)%-1


            dataTableCaseSelected = dataTablePositionSelected(dataTablePositionSelected.caseNum == caseNums(j),:);
            if size(dataTableCaseSelected,1) > 0
                pltValues = plot(dataTableCaseSelected.FmeasuredUncor,...
                    dataTableCaseSelected.FspecMom);

                pltValues.LineStyle = 'none';
                pltValues.MarkerSize = 8;
                pltValues.Marker = markerSet6(ll);
                pltValues.MarkerEdgeColor = 'k';
                pltValues.MarkerFaceColor = matlabColor{j};
                pltValues.DisplayName = [num2str(size(dataTableCaseSelected,1)),...
                    'x case ',caseStr{j},', ',positions(ll,:)];

            end

            lgd = legend('Interpreter','latex');
            lgd.Location = 'northwest';

            grid on

            scaleFactor = 1;
            daspect([1 1/scaleFactor 1])



            xlim([0 maxLimit])
            ylim([0 maxLimit])

            xlabel('$F_{measured}$ [N]','Interpreter','latex')
            ylabel('$F_{calculated}$ [N]','Interpreter','latex')

            title(['$L/B = ',num2str(uniqueLength(kk)/B),'$'], ...
                'Interpreter','latex')
        end
    end

end

sgtitle('Specific Momentum Eq. (see Turcotte, 2016)', ...
    'Interpreter','latex','FontSize',fontSize*1.2)

%%
% save dataTable and plot
cd(matlabDirectory) % go to matlab folder

outputDirectory = 'OutputForces';
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

% figureName = [outputDirectory,'/D',num2str(D),'L',L,'W',W,'Q',Q,'U',uChar,'H',h,'G',G,'_',Position,'.png'];
figureName = [outputDirectory,'/1to1-Forces_SpecMom.png'];
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

% calculate dimensionless values, what about dataTable.G ??? todo
dataTable.hUpAsterix = (dataTable.hUp) ./(dataTable.D + dataTable.hgr);
dataTable.hDownAsterix = (dataTable.hDown) ./(dataTable.D + dataTable.hgr);

hold on

% DatumsIndex plotten
% for jj = 1:length(measurementDays)
%     dateText01 = text(dataTable.hDownAsterix(dataTable.measurementDay == measurementDays(jj))+0.005, ...
%         dataTable.hUpAsterix(dataTable.measurementDay == measurementDays(jj)),num2str(jj),'FontSize',fontSize/2);
% end

for k = 1:length(caseNums)
    pltDepth = plot(dataTable.hDownAsterix(dataTable.caseNum == caseNums(k)),...
        dataTable.hUpAsterix(dataTable.caseNum == caseNums(k)));
    pltDepth.LineStyle = 'none';
    pltDepth.MarkerSize = 8;
    pltDepth.Marker = markerSet6(k);
    pltDepth.MarkerEdgeColor = 'k';
    pltDepth.MarkerFaceColor = matlabColor{k};
    pltDepth.DisplayName = ['case ',caseStr{k}];
end

maxLimit = max(max(xlim,ylim));

xlim([0 2])
ylim([0 2])

pltRegression02 = plot([0 2],[0 2]);
pltRegression02.LineStyle = '-';
pltRegression02.Color = 'k';
pltRegression02.Marker = 'none';
pltRegression02.DisplayName = '1:1';

% pltBorder = plot([caseBorder4],[]);

grid on

scaleFactor = 1;
daspect([1 1/scaleFactor 1])

lgd = legend('Interpreter','latex');
lgd.Location = 'NorthWestOutside';

xlabel('$h_{down}^* = \frac{h_{down}}{D_{cyl} + h_{gr}}$ [-]','Interpreter','latex')
ylabel('$h_{up}^* = \frac{h_{up}}{D_{cyl} + h_{gr}}$ [-]','Interpreter','latex')

%%
figureName = [outputDirectory,'/hAsterix.png'];
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
f.Name = 'Delta Depth';
f.Color = [1 1 1];
f.Units = 'centimeters';
f.InnerPosition = [5 5 15 12];
f.WindowState = 'maximize'; %fullscreen, minimize, normal, maximize

hold on

% calculate Delta H
dataTable.deltaH = (dataTable.hUp - dataTable.hDown) * 1000; % m -> mm

% plot each Length
uniqueLength = unique(dataTable.L);
for kk = 1:length(uniqueLength)
    dataTableLengthSelected = dataTable(dataTable.L == uniqueLength(kk),:);

    caseNums = unique(dataTableLengthSelected.caseNum);
    caseStr = unique(dataTableLengthSelected.caseStr);
    positions = unique(cell2mat(dataTableLengthSelected.Position));
    % plot calculated Force values
    % each case
    subplot(1,2,kk); hold on
%     addOneToOneLine(dataTable.FmeasuredUncor)
%     addTrendline(1,dataTableLengthSelected.FmeasuredUncor,...
%         dataTableLengthSelected.Ftotal)
    for ll = 1:length(positions)
        
        positionIndex = strcmp(dataTableLengthSelected.Position, positions(ll,:));
        [idR,idC] = find(positionIndex == 1);
        dataTablePositionSelected = dataTableLengthSelected(min(idR):max(idR),:);
    
        for j = 1:length(caseNums)%-1


            dataTableCaseSelected = dataTablePositionSelected(dataTablePositionSelected.caseNum == caseNums(j),:);
            if size(dataTableCaseSelected,1) > 0
                pltValues = plot(dataTableCaseSelected.deltaH,...
                    dataTableCaseSelected.FmeasuredUncor);

                pltValues.LineStyle = 'none';
                pltValues.MarkerSize = 8;
                pltValues.Marker = markerSet6(ll);
                pltValues.MarkerEdgeColor = 'k';
                pltValues.MarkerFaceColor = matlabColor{j};
                pltValues.DisplayName = [num2str(size(dataTableCaseSelected,1)),...
                    'x case ',caseStr{j},', ',positions(ll,:)];

            end

            lgd = legend('Interpreter','latex');
            lgd.Location = 'northwest';

            grid on

            scaleFactor = 1;
%             daspect([1 1/scaleFactor 1])



            xlim([0 max(dataTable.deltaH)])
            ylim([0 max(dataTable.FmeasuredUncor)])

            xlabel('$\Delta h$ [mm]','Interpreter','latex')
            ylabel('$F_{measured}$ [N]','Interpreter','latex')

            title(['$L/B = ',num2str(uniqueLength(kk)/B),'$'], ...
                'Interpreter','latex')
        end
    end

end

sgtitle('$\Delta h/F_{measured}$', ...
    'Interpreter','latex','FontSize',fontSize*1.2)


%%
figureName = [outputDirectory,'/deltaH-F.png'];
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

pause(2)
% close all

disp('All done')

%% functions

function addTrendline(polyGrad,xValues,yValues)
poly = polyfit(xValues,yValues,polyGrad);
xPoly = linspace(min(xValues),max(xValues));
yPoly = polyval(poly,xPoly);

trendline = plot(xPoly,yPoly);
trendline.LineStyle = '--';
trendline.Color = 'k';
% trendline.DisplayName = ['fitted polynom ',num2str(polyGrad),'. grade'];
trendline.DisplayName = 'trendline';
end

function addOneToOneLine(inputValues)
% plot regressionen 1:1 line
pltRegression = plot(inputValues,inputValues);
pltRegression.LineStyle = '-';
pltRegression.Color = 'k';
pltRegression.Marker = 'none';
pltRegression.DisplayName = '1:1';
end
