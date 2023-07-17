clc
clear all
close all


% clearvars -except C D
dnames = ['LogISEL_LogUSS_WSLgrid\L316W45Q60'
    'LogISEL_LogUSS_WSLgrid\L316W60Q60'
    'LogISEL_LogUSS_WSLgrid\L474W45Q60'
    'LogISEL_LogUSS_WSLgrid\L474W90Q60'];
%% Dateien einlesen
% read ISEL log Datei
matlabFolder = pwd;

leereRinneAuswertung = 0;
analyzeData = 1; % interpDaten werden bei 0 abgerufen. 
% bei 1 werden die Rohdaten eingeladen und verarbeitet

% Wähle den Ordner mit den Messdaten %%%%%% STARTVERZEICHNIS ANPASSEN %%%%%
% dname = uigetdir('../../measurements/2022 Voruntersuchungen nonUniform');
% Gehe zum Verzeichnis mit den Messdaten
% cd(dname)

% dname = 'LogISEL_LogUSS_WSLgrid\leereRinne';
% dname = 'LogISEL_LogUSS_WSLgrid\leereRinnePlus';

for dirs = 1:size(dnames,1)
    dname = dnames(dirs,:);
    caseName = extractAfter(dname,'\');
    cd(dname)

    % cd(dname)

    % cd(matlabFolder)

    if analyzeData == 0
        measurements = ls('*.mat');
        load(measurements)

        lCyl = str2double(extractBetween(measurements,'L','W'))/1000;
        dCyl = 50/1000;
        gammaCyl = str2double(extractBetween(measurements,'W','Q'));
        Q = str2double(extractBetween(measurements,'Q','H'));

    else
        measurements = ls('*.xlsx');
        filenameISEL = measurements;
        filenameUSS = [filenameISEL(1:end-5),'.csv'];

        lCyl = str2double(extractBetween(filenameUSS,'L','W'))/1000;
        dCyl = 50/1000;
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
        if leereRinneAuswertung == 1
            dataTableRinne = array2table(dataMatrix);
            writetable(dataTableRinne,'leereRinnePlus.xlsx','Sheet','MyNewSheet','WriteVariableNames',true);
        end
        x = dataMatrix(:,1);
        y = dataMatrix(:,2)-395;
        meanValue = dataMatrix(:,3);
        stdValue = dataMatrix(:,4);

        meanValue(stdValue > 10) = NaN;

        %%
        % leere Rinne
        if leereRinneAuswertung == 0
            cd(matlabFolder)
            dataTableRinne = readtable('LogISEL_LogUSS_WSLgrid\leereRinneKombi\leereRinne.xlsx');
            dataRinne = table2array(dataTableRinne);
            meanValueRinne = dataRinne(:,3);

            meanValue = meanValue - meanValueRinne;
        end

        %%
        deltaXY = 30;
        xVek = min(x):deltaXY:max(x);
        yVek = min(y):deltaXY:max(y);

        % [X,Y] = meshgrid(unique(x),unique(y));
        [X,Y] = meshgrid(xVek,yVek);
        MEANvALUE = griddata(x,y,meanValue,X,Y);
        STdVALUE = griddata(x,y,stdValue,X,Y);

%         MEANvALUE(MEANvALUE > 140) = NaN;
%         [xRow,xCol] = find(X > -60 & X < 240);
%         MEANvALUE(:,unique(xCol)) = NaN;

        % mm in m
        X = X/1000;
        Y = Y/1000;
        MEANvALUE = MEANvALUE/1000;

        filenameInterpData = [dname,'\',caseName,'_interpData.mat'];
        save(filenameInterpData,'X','Y','MEANvALUE','STdVALUE')
    end
    %%
    close all
    cd(matlabFolder)

    font = 'Arial';
    fontSize = 16;
    f = figure('DefaultTextFontName', font, ...
        'DefaultAxesFontName', font,...
        'DefaultAxesFontSize',fontSize, ...
        'DefaultTextFontSize',fontSize);
    f.Name = 'wsl 3d';
    f.Color = [1 1 1];
    f.Units = 'centimeters';
    f.InnerPosition = [5 5 40 26];
    f.WindowState = 'normal'; %fullscreen, minimize, normal, maximize
    % hold on

    subplot(2,2,1:2)

    plotWSL = surf(X,Y,MEANvALUE);
    plotWSL.FaceAlpha = 0.75;
    % plotWSL.EdgeColor = 'none';


    caxis([min(min(MEANvALUE)),max(max(MEANvALUE))])
    % caxis([0.040 0.140])
    cb = colorbar;
    % cb.Layout.Tile = 'north';
    cb.Label.String = '$h$ [m]';
    cb.TickLabelInterpreter = 'latex';
    cb.Label.Interpreter = 'latex';
    cb.Location = "eastoutside";
    colormap(turbo(20))

    drawCylinder(dCyl,lCyl,64,gammaCyl);

    zFaktor = 3;
    daspect([1 1 1/zFaktor])
    view([20,20])
    zlim([0 0.15])
    grid on
    xlabel('$x$ [mm]',Interpreter='latex')
    % ylabel('$y$ [mm]',Interpreter='latex')
    zlabel('$z$ [mm]',Interpreter='latex')
    set(gca,'TickLabelInterpreter','latex')

    subplot(2,2,3)



    % pdegplot(model,FaceAlpha=0.7); hold on
    % delete(findobj(gca,'type','Quiver'))

    plotWSL = surf(X,Y,MEANvALUE);
    plotWSL.FaceAlpha = 0.75;
    % plotWSL.EdgeColor = 'none';

    % caxis([min(min(MEANvALUE)),max(max(MEANvALUE))])
    % caxis([0.040 0.140])

    drawCylinder(dCyl,lCyl,64,gammaCyl);

    zFaktor = 3;
    daspect([1 1 1/zFaktor])
    view([0,0])

    xlabel('$x$ [mm]',Interpreter='latex')
    ylabel('$y$ [mm]',Interpreter='latex')
    zlabel('$z$ [mm]',Interpreter='latex')
    set(gca,'TickLabelInterpreter','latex')




    subplot(2,2,4)

    % pdegplot(model,FaceAlpha=0.7); hold on
    % delete(findobj(gca,'type','Quiver'))

    plotWSL = surf(X,Y,MEANvALUE);
    plotWSL.FaceAlpha = 0.75;
    % plotWSL.EdgeColor = 'none';

    % caxis([min(min(MEANvALUE)),max(max(MEANvALUE))])
    % caxis([0.040 0.140])

    [vertices,sideFaces,bottomFaces] = drawCylinder(dCyl,lCyl,64,gammaCyl);

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


    png_name = ['LogISEL_LogUSS_WSLgrid\',caseName,'.png'];
    saveas(gcf,png_name)

    cd(matlabFolder)
    disp('All done')
    pause(3)

    close all

end

%%
function [vertices,sideFaces,bottomFaces] = drawCylinder(dCyl,lCyl,sideCount,gamma)

% Vertices
vertices = zeros(2*sideCount, 3);
for i = 1:sideCount
    theta = 2*pi/sideCount*(i-1);
    vertices(i,:) = [dCyl/2*cos(theta),0-lCyl/2,dCyl/2*sin(theta)+dCyl/2];
    vertices(sideCount+i,:) = [dCyl/2*cos(theta),lCyl/2, dCyl/2*sin(theta)+dCyl/2];
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
sidePatches = patch('Faces', sideFaces, 'Vertices', vertices,...
    'EdgeColor','none','FaceColor', [.4 .4 .4]);
bottomPatches = patch('Faces', bottomFaces, 'Vertices', vertices,...
    'EdgeColor','none','FaceColor', [.6 .6 .6]);
%
rotate(sidePatches, [0 0 1], gamma-90,[0 0 0])
rotate(bottomPatches, [0 0 1], gamma-90,[0 0 0])
end
