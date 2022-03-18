clc
clear all
close all

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Abfrage der Parameter
prompt = {'Startposition [mm]','Endposition [mm]', 'Messintervall [mm]','Messdauer [s]'};
dlgtitle = 'Einstellungen Messprogramm';
dims = [1 30];
definput = {'500','550','10','5'};
answer_1 = inputdlg(prompt,dlgtitle,dims,definput);

if isempty(answer_1)
    disp('Keine Eingabe erfolgt. Abbruch durch Anwender.')
    return
end

startPos = str2double(answer_1(1)); 
endPos = str2double(answer_1(2));
moveRelX = str2double(answer_1(3)); 
deltaTmeas = str2double(answer_1(4)); 

% startPos = 500; % Startposition in mm
% endPos = 550; % Endposition in mm
% moveRelX = 10; % bewege x Achse in mm
% deltaTmeas = 2; % Messzeit in Sekunden
deltaTvibr = 5; % Pause wegen Vibration am USS nach ISEL Bewegung

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if startPos > 2000
    msg = 'Der eingegebene Wert für die Startposition überschreitet das Limit von 2000 mm.';
    errordlg(msg)
    return
elseif endPos < startPos + moveRelX
    msg = 'Der eingegebene Wert für die Endposition ist niedriger als der Wert der Startposition.';
    errordlg(msg)
    return
elseif endPos > 2800
    msg = 'Der eingegebene Wert für die Endposition überschreitet das Limit von 2800 mm.';
    errordlg(msg)
    return
end

% Info und Abfrage der Messpunkte
anzahlMesspunkte = (endPos-startPos)/moveRelX;
qstMsg = sprintf(['Anzahl Messpunkte: ',num2str(anzahlMesspunkte),...
    '\nStartposition: ',num2str(startPos),' mm',...
    '\nEndposition: ',num2str(endPos),' mm',...
    '\nMessintervall: ',num2str(moveRelX),' mm',...
    '\nMessdauer: ',num2str(deltaTmeas),' s',...
    '\nGesamtdauer: ca. ',num2str((deltaTmeas+deltaTvibr)*anzahlMesspunkte),' s']);
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
COM_port = 'COM3';
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
mydlg = warndlg('Bestätigen, wenn die Achse referenziert und die Startposition erreicht wurde.', 'Warning');
waitfor(mydlg);

%% Achse für Intervall Messung verfahren und Position und Zeiten loggen
iselTable = table; % log table
for i = 1:anzahlMesspunkte
    % schreibe Position USS, ISEL vor Beginn der Messung
    iselTable.position(i) = startPos + (i-1)*moveRelX; % (i-1), da beim ersten Wert die Startposition gilt
    % schreibe Datum/Uhrzeit vor Beginn der Messung
    disp([num2str(deltaTmeas),'s, measures...'])
    iselTable.timeStartMeasurement(i) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
    % Pause in der Messdaten erfasst werden je Position
    pause(deltaTmeas)
    % schreibe Datum/Uhrzeit nach der Messung
    iselTable.timeEndMeasurement(i) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
    % schreibe festgelegte Dauer der Messung
    iselTable.deltaTmeas(i) = deltaTmeas;


%     % ändere Position USS, ISEL für nächste Messung
%     % ISEL commands
%     disp('write commands')
%     writeline(device,"@01");                  % 1 Achsen aktivieren
%     pause(t_pause);
%     writeline(device,"@0d5000");              % Ref speed setzen
%     pause(t_pause);
%     writeline(device,"@0i");                  % #input Befehl
%     pause(t_pause);
%     % move relative x Achse
%     writeline(device,['0',num2str(steps/elev*moveRelX),',',num2str(speed)]);
%     pause(t_pause);
% 
%     writeline(device,"9");                    % stop. Befehl
%     pause(t_pause);
%     writeline(device,"@0S");                  % #start Befehl
%     disp('commands sent')
%     % Pause, um Vibrationen am USS abzuwarten nachdem ISEL verfahren ist
%     disp([num2str(deltaTvibr),'s pause'])
%     pause(deltaTvibr)
end


% % close serial port
% delete(device);
