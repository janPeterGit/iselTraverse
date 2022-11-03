clc
clear all
close all
%%
% Einlesen Excel Dstei Koordinaten
koordinatenTable = readtable('Koordinaten.xlsx');
disp('Excel-Koordinaten eingeladen...')

%%
% Abfrage Setup
prompt = {'L_cyl [mm]',...
    'Rotation [°]',...
    'Q [l/s]','h_up (mit Lineal gemessen) [mm]',...
    'Position S (Side) oder C (Center)?'};
dlgtitle = 'Einstellungen Messprogramm 1/3';
dims = [1 60];
definput = {'474','90','60','80','C'};
answer_0 = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer_0)
    disp('Keine Eingabe erfolgt. Abbruch durch Anwender.')
    return
end

prompt = {'x0 (Abstand Referenzpunkt zum Zylindermittelpunkt) [mm]',...
    'Versatz des Zylinders durch Strömungskraft [mm]', ...
    'y0 (Abstand 1. Sensor von rechts zur Rinnenmitte) [mm]',...
    'Anzahl Sensoren',...
    'Abstand Sensoren [mm]',...
    'Gap (Zylinderunterkante zu Sohle) [mm]'};
dlgtitle = 'Einstellungen Messprogramm 2/3';
dims = [1 60];
definput = {'1238','0','65','3','120','0'};
answer_1 = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer_1)
    disp('Keine Eingabe erfolgt. Abbruch durch Anwender.')
    return
end

% answer_0
L = char(answer_0(1));
W = char(answer_0(2));
Q = char(answer_0(3));
h = char(answer_0(4));
Position = char(answer_0(5));

% answer_1
x0ohneLast = str2double(answer_1(1));
xDeltaLast = str2double(answer_1(2));
y0 = str2double(answer_1(3));
anzahlSensoren = str2double(answer_1(4));
abstandSensoren = str2double(answer_1(5));
G = char(answer_1(6));

x0 = -(x0ohneLast + xDeltaLast); % Berechnet Abstand zwischen 
% Referenzpunkt Lineareinheit und Zylindermittelpunkt unter Last

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'Messdauer [s]','Pause (Fahren/Virbration) [s]'};
dlgtitle = 'Einstellungen Messprogramm 3/3';
dims = [1 60];
definput = {'5','5'};
answer_3 = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer_3)
    disp('Keine Eingabe erfolgt. Abbruch durch Anwender.')
    return
end

% Berechnet delta x je Position aus Exceltabelle
xDeltaPos = NaN(length(koordinatenTable.x)-1,1);
startPosAbsolute = koordinatenTable.x(1);
for kk = 1:length(koordinatenTable.x)-1
    xDeltaPos(kk) = koordinatenTable.x(kk+1) - koordinatenTable.x(kk);
end

% startPosAbsolute = str2double(answer_3(1));
startPosRelative = abs(startPosAbsolute - x0);
% totalDist = str2double(answer_3(2));
endPosRelative = koordinatenTable.x(end) - x0;
% deltaXpos = str2double(answer_3(3));

deltaTmeas = str2double(answer_3(1));
deltaTvibr = str2double(answer_3(2));

travelSpeed = 35/500; % s/mm
travelExtraPause = 3;

% startPos = 500; % Startposition in mm
% endPos = 550; % Endposition in mm
% moveRelX = 10; % bewege x Achse in mm
% deltaTmeas = 2; % Messzeit in Sekunden
% deltaTvibr = 5; % Pause wegen Vibration am USS nach ISEL Bewegung

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Prüfen, ob Bedingungen eingehalten werden...
anzahlMesspunkte = length(koordinatenTable.x);
if floor(anzahlMesspunkte) ~= anzahlMesspunkte
    msg = ['Die Messstrecke ',num2str(totalDist),' mm ist kein Vielfaches des Messintervalls ',num2str(deltaXpos),' mm.'];
    errordlg(msg)
    return
end
if startPosRelative > 2000
    msg = 'Der eingegebene Wert für die Startposition überschreitet das Limit von 2000 mm.';
    errordlg(msg)
    return
    % elseif endPosRelative < startPosRelative + deltaXpos
    %     msg = 'Der eingegebene Wert für die Endposition ist niedriger als der Wert der Startposition.';
    %     errordlg(msg)
    %     return
elseif endPosRelative > 2800
    msg = 'Der eingegebene Wert für die Endposition überschreitet das Limit von 2800 mm.';
    errordlg(msg)
    return
elseif startPosAbsolute < x0
    msg = 'Der eingegebene Wert für die Startposition unterschreitet das Limit x0.';
    errordlg(msg)
    return
end

% DurationSum = round(((deltaTmeas+deltaTvibr+travelExtraPause)*anzahlMesspunkte + sum(xDeltaPos)*travelSpeed),1);

% Info und Abfrage der Messpunkte
qstMsg = sprintf(['Anzahl Messpunkte: ',num2str(anzahlMesspunkte),...
    '\nStartposition: ',num2str(startPosAbsolute),' mm',...
    '\nMessdauer: ',num2str(deltaTmeas),' s']);
%     '\nGesamtdauer: ca. ',num2str(DurationSum),' s']);
answer_1 = questdlg(qstMsg, ...
    'Messprogramm', ...
    'Start','Abbrechen','Start');
% Handle response
switch answer_1
    case 'Start'
    case 'Abbrechen'
        disp('Abbruch durch Anwender.')
        return
end

%% Connect Device UltraLab
% COM settings
COM_port = 'COM4';
baudrate = 19200;

t_pause = 0.5; % seconds, wozu ist die Pause? Funktioniert auch ohne

% Lineareinheit settings
elev = 2.5;
steps = 800;
speed = 5000;


% % connect serial port
% device = serialport(COM_port,baudrate);
% configureTerminator(device,"CR/LF") % unbedingt notwendig, für ECHO Antwort
% pause(t_pause);
% device.Timeout = 10; % default 10
% pause(t_pause);

%% Achse referenzieren und an Startposition fahren
% ISEL commands
disp('write commands')
writeline(device,"@02");                  % Achsen aktivieren
pause(t_pause);
writeline(device,"@0d5000");              % Ref speed setzen
pause(t_pause);
writeline(device,"@0i");                  % #input Befehl
pause(t_pause);
writeline(device,"71");                   % Achse 1 referenzieren
pause(t_pause);
% move relative x Achse
writeline(device,['0',num2str(steps/elev*startPosRelative),',',num2str(speed),',0,',num2str(speed)]);
pause(t_pause);
writeline(device,"9");                    % stop. Befehl
pause(t_pause);
writeline(device,"@0S");                  % #start Befehl
disp('commands sent')

% WARTE AUF EINGABE
WarnText = 'Bestätigen, wenn die Achse referenziert und die Startposition erreicht wurde.';
mydlg = warndlg(WarnText, 'Warning');
waitfor(mydlg);

%% für y Versatz
% hier erster Sensor Abstand 65 mm zu Wand
% 3 Sensoren mit jeweils 120 mm Abstand zueinander
yPositionen = [65 185 305];
yVersatz = [60 300 60];
yVersatzGesamt = sum(yVersatz);
for kkk = 1:length(yVersatz)
    yPositionen(kkk+1,:) = yPositionen(kkk,:) + yVersatz(kkk);
end

iselTable = table;

%% Achse für Intervall Messung verfahren und Position und Zeiten loggen
counter = 0;
for i = 1:anzahlMesspunkte
    for ii = 1:size(yPositionen,1)
        counter = counter + 1;
        % Pause, um Vibrationen am USS abzuwarten nachdem ISEL verfahren ist
        disp([num2str(deltaTvibr),'s Pause (Vibration)'])
        pause(deltaTvibr)
        disp(['### Messpunkt ',num2str(i),'-',num2str(ii),', Fortschritt: ',...
            num2str(counter),'/',num2str(anzahlMesspunkte*size(yPositionen,1))])
        disp(['Position x = ',num2str(koordinatenTable.x(i)),...
            ' und y = ',num2str(yPositionen(ii,1)),...
            ', ',num2str(yPositionen(ii,2)),...
            ', ',num2str(yPositionen(ii,3))])
        % schreibe Position USS, ISEL vor Beginn der Messung
        iselTable.positionX(counter) = koordinatenTable.x(i);
        iselTable.positionY1(counter) = yPositionen(ii,1);
        iselTable.positionY2(counter) = yPositionen(ii,2);
        iselTable.positionY3(counter) = yPositionen(ii,3);
        % schreibe Datum/Uhrzeit vor Beginn der Messung
        disp([num2str(deltaTmeas),'s Messung'])
        iselTable.timeStartMeasurement(counter) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
        % Pause in der Messdaten erfasst werden je Position
        pause(deltaTmeas)
        % schreibe Datum/Uhrzeit nach der Messung
        iselTable.timeEndMeasurement(counter) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
        % schreibe festgelegte Dauer der Messung
        iselTable.deltaTmeas(counter) = deltaTmeas;

        if ii < size(yPositionen,1)
            % ändere Position USS, ISEL für nächste Messung
            % ISEL commands
            disp('write commands')
            writeline(device,"@02");                  % Achsen aktivieren
            pause(t_pause);
            writeline(device,"@0d5000");              % Ref speed setzen
            pause(t_pause);
            writeline(device,"@0i");                  % #input Befehl
            pause(t_pause);
            % move relative y Achse "0WertX,SpeedX,WertY,SpeedY"
            writeline(device,['00,',num2str(speed),',',num2str(steps/elev*yVersatz(ii)),',',num2str(speed)]);
            pause(t_pause);
            writeline(device,"9");                    % stop. Befehl
            pause(t_pause);
            writeline(device,"@0S");                  % #start Befehl
            disp(['commands sent for y-move (',num2str(yVersatz(ii)),' mm)'])
            pause(travelExtraPause)
            disp(['Schlitten fährt für ca. ',num2str(travelSpeed * yVersatz(ii)),' s'])
            pause(travelSpeed * yVersatz(ii))

        end

    end
    % verfahren bis alle Messpunkte erreicht wurden
    if i < anzahlMesspunkte

        % zurückfahren auf y Achse zu y0
        % ISEL commands
        disp('write commands')
        writeline(device,"@02");                  % Achsen aktivieren
        pause(t_pause);
        writeline(device,"@0d5000");              % Ref speed setzen
        pause(t_pause);
        writeline(device,"@0i");                  % #input Befehl
        pause(t_pause);
        % move relative y Achse "0WertX,SpeedX,WertY,SpeedY"
        writeline(device,['00,',num2str(speed),',',num2str(steps/elev*yVersatzGesamt*-1),',',num2str(speed)]);
        pause(t_pause);
        writeline(device,"9");                    % stop. Befehl
        pause(t_pause);
        writeline(device,"@0S");                  % #start Befehl
        disp(['commands sent for y-move (',num2str(yVersatzGesamt*-1),' mm)'])
        pause(travelExtraPause)
        disp(['Schlitten fährt für ca. ',num2str(travelSpeed * yVersatzGesamt*-1),' s'])
        pause(travelSpeed * yVersatzGesamt*-1)

        % ändere x-Position USS, ISEL für nächste Messung
        % ISEL commands
        disp('write commands')
        writeline(device,"@02");                  % Achsen aktivieren
        pause(t_pause);
        writeline(device,"@0d5000");              % Ref speed setzen
        pause(t_pause);
        writeline(device,"@0i");                  % #input Befehl
        pause(t_pause);
        % move relative x Achse "0WertX,SpeedX,WertY,SpeedY"
        writeline(device,['0',num2str(steps/elev*xDeltaPos(i)),',',num2str(speed),',0,',num2str(speed)]);
        pause(t_pause);

        writeline(device,"9");                    % stop. Befehl
        pause(t_pause);
        writeline(device,"@0S");                  % #start Befehl
        disp('commands sent')
        pause(travelExtraPause)
        disp(['Schlitten fährt für ca. ',num2str(travelSpeed * xDeltaPos(i)),' s'])
        pause(travelSpeed * xDeltaPos(i))
    end
end

% ReferenceX(device)
% Achse referenzieren und an Startposition fahren
% ISEL commands
disp('write commands')
writeline(device,"@02");                  % Achsen aktivieren
pause(t_pause);
writeline(device,"@0d5000");              % Ref speed setzen
pause(t_pause);
writeline(device,"@0i");                  % #input Befehl
pause(t_pause);
writeline(device,"71");                   % Achse 1 referenzieren
pause(t_pause);
writeline(device,"9");                    % stop. Befehl
pause(t_pause);
writeline(device,"@0S");                  % #start Befehl
disp('commands sent')

% close serial port
delete(device);

%% write file

iselTable.x0(:) = x0;
iselTable.y0(:) = y0;
iselTable.countSensors(:) = anzahlSensoren;
iselTable.deltaYSensors(:) = abstandSensoren;

formatOut = 'yyyymmdd_HHMM';
dateString = datestr(now,formatOut);
outputDirectory = ['LogISEL_LogUSS_LogLC/',dateString(1:8),'/'];
if not(isfolder(outputDirectory))
    mkdir(outputDirectory) % Ordner für Export im Ordner mit den Messdaten erstellen
end

filename = [dateString,'_L',L,'W',W,'Q',Q,'H',h,'G',G,'_',Position,'.xlsx'];
pathFilename = [outputDirectory,filename];
writetable(iselTable,pathFilename,'Sheet','Messdaten','WriteVariableNames',true);

infoMsg = sprintf(['Die Datei "',filename,'" abgespeichert. \n\nReferenzfahrt wird durchgeführt und das Gerät getrennt.']);
msgbox(infoMsg)

%% funcions
% function ReferenceX(device,t_pause)
% % Achse referenzieren und an Startposition fahren
% % ISEL commands
% disp('write commands')
% writeline(device,"@01");                  % 1 Achsen aktivieren
% pause(t_pause);
% writeline(device,"@0d5000");              % Ref speed setzen
% pause(t_pause);
% writeline(device,"@0i");                  % #input Befehl
% pause(t_pause);
% writeline(device,"71");                   % Achse 1 referenzieren
% pause(t_pause);
% writeline(device,"9");                    % stop. Befehl
% pause(t_pause);
% writeline(device,"@0S");                  % #start Befehl
% disp('commands sent')
% end
