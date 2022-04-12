clc
clear all
close all
%%
% Abfrage Setup
prompt = {'L_cyl [mm]','Rotation [°]','Q [l/s]','h_up [mm]',...
    'Position S oder C?','x0 (-Abstand zum Zylinder) [mm]','y0 (Abstand 1. Sensor von rechts zur Rinnenmitte) [mm]','Anzahl Sensoren','Abstand Sensoren [mm]'};
dlgtitle = 'Einstellungen Messprogramm';
dims = [1 30];
definput = {'474','90','31.6','100','C','-1000','100','2','100'};
answer_0 = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer_0)
    disp('Keine Eingabe erfolgt. Abbruch durch Anwender.')
    return
end

L = char(answer_0(1));
W = char(answer_0(2));
Q = char(answer_0(3));
h = char(answer_0(4));
Position = char(answer_0(5));
x0 = str2double(answer_0(6));
y0 = str2double(answer_0(7));
anzahlSensoren = str2double(answer_0(8));
abstandSensoren = str2double(answer_0(9));

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Abfrage der Parameter
prompt = {'Startposition [mm]','Messstrecke [mm]', 'Messintervall [mm]','Messdauer [s]','Pause (Fahren/Virbration) [s]'};
dlgtitle = 'Einstellungen Messprogramm';
dims = [1 30];
definput = {'-800','40','20','5','5'};
answer_1 = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer_1)
    disp('Keine Eingabe erfolgt. Abbruch durch Anwender.')
    return
end

startPosAbsolute = str2double(answer_1(1));
startPos = abs(startPosAbsolute - x0);
totalDist = str2double(answer_1(2));
endPos = startPos + totalDist;
deltaXpos = str2double(answer_1(3));
deltaTmeas = str2double(answer_1(4));
deltaTvibr = str2double(answer_1(5));

% startPos = 500; % Startposition in mm
% endPos = 550; % Endposition in mm
% moveRelX = 10; % bewege x Achse in mm
% deltaTmeas = 2; % Messzeit in Sekunden
% deltaTvibr = 5; % Pause wegen Vibration am USS nach ISEL Bewegung

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Prüfen, ob Bedingungen eingehalten werden...
anzahlMesspunkte = (endPos-startPos)/deltaXpos+1;
if floor(anzahlMesspunkte) ~= anzahlMesspunkte
    msg = ['Die Messstrecke ',num2str(totalDist),' mm ist kein Vielfaches des Messintervalls ',num2str(deltaXpos),' mm.'];
    errordlg(msg)
    return
end
if startPos > 2000
    msg = 'Der eingegebene Wert für die Startposition überschreitet das Limit von 2000 mm.';
    errordlg(msg)
    return
elseif endPos < startPos + deltaXpos
    msg = 'Der eingegebene Wert für die Endposition ist niedriger als der Wert der Startposition.';
    errordlg(msg)
    return
elseif endPos > 2800
    msg = 'Der eingegebene Wert für die Endposition überschreitet das Limit von 2800 mm.';
    errordlg(msg)
    return
elseif startPosAbsolute < x0
    msg = 'Der eingegebene Wert für die Startposition unterschreitet das Limit x0.';
    errordlg(msg)
    return
end

DurationSum = round(((deltaTmeas+deltaTvibr)*anzahlMesspunkte),1);

% Info und Abfrage der Messpunkte
qstMsg = sprintf(['Anzahl Messpunkte: ',num2str(anzahlMesspunkte),...
    '\nStartposition: ',num2str(startPosAbsolute),' mm',...
    '\nEndposition: ',num2str(startPosAbsolute + totalDist),' mm',...
    '\nMessintervall: ',num2str(deltaXpos),' mm',...
    '\nMessdauer: ',num2str(deltaTmeas),' s',...
    '\nGesamtdauer: ca. ',num2str(DurationSum),' s']);
answer_2 = questdlg(qstMsg, ...
    'Messprogramm', ...
    'Start','Abbrechen','Start');
% Handle response
switch answer_2
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
% 
% %% Achse referenzieren und an Startposition fahren
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
% % move relative x Achse
% writeline(device,['0',num2str(steps/elev*startPos),',',num2str(speed)]);
% pause(t_pause);
% writeline(device,"9");                    % stop. Befehl
% pause(t_pause);
% writeline(device,"@0S");                  % #start Befehl
% disp('commands sent')

% WARTE AUF EINGABE
WarnText = 'Bestätigen, wenn die Achse referenziert und die Startposition erreicht wurde.';
mydlg = warndlg(WarnText, 'Warning');
waitfor(mydlg);

tic
%% Achse für Intervall Messung verfahren und Position und Zeiten loggen
for i = 1:anzahlMesspunkte % +1, um nach der letzten Positionsänderung noch zu messen
    % Pause, um Vibrationen am USS abzuwarten nachdem ISEL verfahren ist
    disp([num2str(deltaTvibr),'s Pause (Vibration)'])
    pause(deltaTvibr)
    disp(['--- Messpunkt ',num2str(i),'/',num2str(anzahlMesspunkte),', Position x = ',num2str(startPosAbsolute + (i-1)*deltaXpos)])
    % schreibe Position USS, ISEL vor Beginn der Messung
    iselColumn.position(i) = startPosAbsolute + (i-1)*deltaXpos; % (i-1), da beim ersten Wert die Startposition gilt
    % schreibe Datum/Uhrzeit vor Beginn der Messung
    disp([num2str(deltaTmeas),'s Messung'])
    iselColumn.timeStartMeasurement(i) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
    % Pause in der Messdaten erfasst werden je Position
    pause(deltaTmeas)
    % schreibe Datum/Uhrzeit nach der Messung
    iselColumn.timeEndMeasurement(i) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
    % schreibe festgelegte Dauer der Messung
    iselColumn.deltaTmeas(i) = deltaTmeas;
    
%     % verfahren bis alle Messpunkte erreicht wurden
%     if i < anzahlMesspunkte
%         % ändere Position USS, ISEL für nächste Messung
%         % ISEL commands
%         disp('write commands')
%         writeline(device,"@01");                  % 1 Achsen aktivieren
%         pause(t_pause);
%         writeline(device,"@0d5000");              % Ref speed setzen
%         pause(t_pause);
%         writeline(device,"@0i");                  % #input Befehl
%         pause(t_pause);
%         % move relative x Achse
%         writeline(device,['0',num2str(steps/elev*deltaXpos),',',num2str(speed)]);
%         pause(t_pause);
% 
%         writeline(device,"9");                    % stop. Befehl
%         pause(t_pause);
%         writeline(device,"@0S");                  % #start Befehl
%         disp('commands sent')
%         disp('Schlitten fährt...')
%         pause(2) % 2s für Fahrtzeit
%     end
    duration = toc;
    disp(['Gesamtdauer = ',num2str(round(duration,1)),...
        ' s, Restzeit = ',num2str(DurationSum - round(duration,1)),' s'])
end

% % ReferenceX(device)
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
% 
% % close serial port
% delete(device);

%% write file
iselTable = table;
iselTable.xPosition = iselColumn.position';
iselTable.x0(:) = x0;
iselTable.y0(:) = y0;
iselTable.countSensors(:) = anzahlSensoren;
iselTable.deltaYSensors(:) = abstandSensoren;
iselTable.timeStartMeasurement = iselColumn.timeStartMeasurement';
iselTable.timeEndMeasurement = iselColumn.timeEndMeasurement';
iselTable.deltaTmeas = iselColumn.deltaTmeas';

formatOut = 'yyyymmdd_HHMM';
dateString = datestr(now,formatOut);
filename = [dateString,'_L',L,'W',W,'Q',Q,'H',h,'_',Position,'.xlsx'];
writetable(iselTable,filename,'Sheet','Messdaten','WriteVariableNames',true);

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
