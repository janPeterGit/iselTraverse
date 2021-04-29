%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% isel communication via serial port %%%%%%%%%%%%%%%
%%% (c) 2021 Univ.-Prof. Dr.-Ing. Mario Oertel %%%%%%%
%%% only for internal use %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Test Kommunikation isel Schrittmotor
clc
clear all
close all


COM_port = 'COM1';
t_pause = 0.5; % seconds

% Terminal output
% @03              2 Achsen setzen
% @0d1000,1000     ref speed setzen
% @0R3             xy referenzieren
% @0i              #input Befehl
% m0,3000,0,5000   absolutfahrt posx,Geschw1, posy,Geschw2
% 9                stop. befehl
% @0S              #start Befehle



% open serial port
serial_COM = serial(COM_port,'Baudrate',38400,'Parity','none','Databits',8,'StopBits',1);
fopen(serial_COM);
status_COM = get(serial_COM, 'Status');     % fragt den Status ab
display(status_COM);
set(serial_COM,'Terminator','CR/LF');       % unbedingt notwendig, für ECHO Antwort
pause(t_pause);

% send commands
fprintf(serial_COM,'@03');                  % 2 Achsen aktivieren
pause(t_pause);
fprintf(serial_COM,'@0d1000,1000');         % Ref speed setzen
pause(t_pause);
fprintf(serial_COM,'@0R3');                 % 2 Achsen referenzieren
pause(t_pause);
fprintf(serial_COM,'@0i');                  % #input Befehl
pause(t_pause);
fprintf(serial_COM,'m0,3000,0,3000');       % fahre an abs Pos 0,0 mit Geschw. 3000
pause(t_pause);
fprintf(serial_COM,'9');                    % stop. Befehl
pause(t_pause);
fprintf(serial_COM,'@0S');                  % #start Befehl
pause(5);
 
% close serial port
fclose(serial_COM);
status_COM = get(serial_COM, 'Status');
display(status_COM);
delete(serial_COM);
clear serial_COM;




