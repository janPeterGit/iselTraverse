clc
clear all
close all

%% Connect Device UltraLab
% COM settings
COM_port = 'COM4';
baudrate = 19200;

t_pause = 0.5; % seconds, wozu ist die Pause? Funktioniert auch ohne

% Lineareinheit settings
elev = 2.5;
steps = 800;
speed = 5000;

% connect serial port
device = serialport(COM_port,baudrate);
configureTerminator(device,"CR/LF") % unbedingt notwendig, für ECHO Antwort
pause(t_pause);
device.Timeout = 10; % default 10
pause(t_pause);

%% Achse referenzieren und an Startposition fahren
% ISEL commands
disp('write commands')
writeline(device,"@01");                  % 1 Achsen aktivieren
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

delete(device)