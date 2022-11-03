clc;clear all;close all

koordinatenTable = readtable('Koordinaten.xlsx');
anzahlMesspunkte = length(koordinatenTable.x);

iselColumn = table;
deltaTvibr = .1;
deltaTmeas = .1;
t_pause = 0;

% Berechnet delta x je Position aus Exceltabelle
xDeltaPos = NaN(length(koordinatenTable.x)-1,1);
startPosAbsolute = koordinatenTable.x(1);
for kk = 1:length(koordinatenTable.x)-1
    xDeltaPos(kk) = koordinatenTable.x(kk+1) - koordinatenTable.x(kk);
end
% travelExtraPause = 0;
yPositionen = [65 185 305];
yVersatz = [60 300 60];
yVersatzGesamt = sum(yVersatz);
for kkk = 1:length(yVersatz)
    yPositionen(kkk+1,:) = yPositionen(kkk,:) + yVersatz(kkk);
end

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
        iselColumn.positionX(counter) = koordinatenTable.x(i);
        iselColumn.positionY1(counter) = yPositionen(ii,1);
        iselColumn.positionY2(counter) = yPositionen(ii,2);
        iselColumn.positionY3(counter) = yPositionen(ii,3);
        % schreibe Datum/Uhrzeit vor Beginn der Messung
        disp([num2str(deltaTmeas),'s Messung'])
        iselColumn.timeStartMeasurement(counter) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
        % Pause in der Messdaten erfasst werden je Position
        pause(deltaTmeas)
        % schreibe Datum/Uhrzeit nach der Messung
        iselColumn.timeEndMeasurement(counter) = datetime('now','Format','MM/dd/y HH:mm:ss.SSS');
        % schreibe festgelegte Dauer der Messung
        iselColumn.deltaTmeas(counter) = deltaTmeas;

        if ii < size(yPositionen,1)
            % ändere Position USS, ISEL für nächste Messung
            % ISEL commands
            disp('write commands')
            %         writeline(device,"@02");                  % Achsen aktivieren
            pause(t_pause);
            %         writeline(device,"@0d5000");              % Ref speed setzen
            pause(t_pause);
            %         writeline(device,"@0i");                  % #input Befehl
            pause(t_pause);
            % move relative y Achse "0WertX,SpeedX,WertY,SpeedY"
            %                 writeline(device,['00,',num2str(speed),',',num2str(steps/elev*yVersatz(ii)),',',num2str(speed)]);
            pause(t_pause);

            %         writeline(device,"9");                    % stop. Befehl
            pause(t_pause);
            %         writeline(device,"@0S");                  % #start Befehl
            disp(['commands sent for y-move (',num2str(yVersatz(ii)),' mm)'])
            %         pause(travelExtraPause)
            %         disp(['Schlitten fährt für ca. ',num2str(travelSpeed * xDeltaPos(i)),' s'])
            %         pause(travelSpeed * xDeltaPos(i))
            %         % WARTE AUF EINGABE
            %         WarnText = 'Bestätigen, wenn die Achse die Zielposition erreicht hat.';
            %         mydlg = warndlg(WarnText, 'Warning');
            %         waitfor(mydlg);

        end


    end
    

    % verfahren bis alle Messpunkte erreicht wurden
    if i < anzahlMesspunkte
        
        % zurückfahren auf y Achse
        % ISEL commands
        disp('write commands')
        %         writeline(device,"@02");                  % Achsen aktivieren
        pause(t_pause);
        %         writeline(device,"@0d5000");              % Ref speed setzen
        pause(t_pause);
        %         writeline(device,"@0i");                  % #input Befehl
        pause(t_pause);
        % move relative y Achse "0WertX,SpeedX,WertY,SpeedY"
        %                 writeline(device,['00,',num2str(speed),',',num2str(steps/elev*yVersatz(ii)),',',num2str(speed)]);
        pause(t_pause);

        %         writeline(device,"9");                    % stop. Befehl
        pause(t_pause);
        %         writeline(device,"@0S");                  % #start Befehl
        disp(['commands sent for y-move (',num2str(yVersatzGesamt*-1),' mm)'])
        %         pause(travelExtraPause)
        %         disp(['Schlitten fährt für ca. ',num2str(travelSpeed * xDeltaPos(i)),' s'])
        %         pause(travelSpeed * xDeltaPos(i))
        %         % WARTE AUF EINGABE
        %         WarnText = 'Bestätigen, wenn die Achse die Zielposition erreicht hat.';
        %         mydlg = warndlg(WarnText, 'Warning');
        %         waitfor(mydlg);

        % ändere Position USS, ISEL für nächste Messung
        % ISEL commands
        disp('write commands')
        %         writeline(device,"@02");                  % Achsen aktivieren
        pause(t_pause);
        %         writeline(device,"@0d5000");              % Ref speed setzen
        pause(t_pause);
        %         writeline(device,"@0i");                  % #input Befehl
        pause(t_pause);
        % move relative x Achse Format "0WertX,SpeedX,WertY,SpeedY"
        %                 writeline(device,['0',num2str(steps/elev*xDeltaPos(i)),',',num2str(speed),',0,',num2str(speed)]);
        pause(t_pause);

        %         writeline(device,"9");                    % stop. Befehl
        pause(t_pause);
        %         writeline(device,"@0S");                  % #start Befehl
        disp(['commands sent for x-move (',num2str(xDeltaPos(i)),' mm)'])
        %         pause(travelExtraPause)
        %         disp(['Schlitten fährt für ca. ',num2str(travelSpeed * xDeltaPos(i)),' s'])
        %         pause(travelSpeed * xDeltaPos(i))
        %         % WARTE AUF EINGABE
        %         WarnText = 'Bestätigen, wenn die Achse die Zielposition erreicht hat.';
        %         mydlg = warndlg(WarnText, 'Warning');
        %         waitfor(mydlg);

    end
end