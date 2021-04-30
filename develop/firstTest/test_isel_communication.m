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

% pal pc input
% #axis X;
% #steps 800; % nicht im terminal output
% #elev 2.5 % nicht im terminal output
% #ref_speed 5000
% #units mm; % nicht im terminal output
% #input
% reference x;
% moverel 10(5000),0(3000),0(3000);
% stop.
% #start

% pal pc terminal output
% @01              1 Achsen setzen
% @0d5000          ref speed setzen
% @0i              #input Befehl
% 71             reference x
% 03200,5000      moverel
% 9                stop. befehl
% @0S              #start Befehle

% COM settings
COM_port = 'COM3';
baudrate = 19200;

t_pause = 0.5; % seconds @Mario wozu ist die Pause? Funktioniert auch ohne

elev = 2.5;
steps = 800;
speed = 6000;

moverelX = 100;
moverelY = 100;

moverel = 0;

% connect serial port
device = serialport(COM_port,baudrate);
configureTerminator(device,"CR/LF")      % unbedingt notwendig, für ECHO Antwort
pause(t_pause);
device.Timeout = 10; % default 10
pause(t_pause);

% send commands
disp('send commands')
writeline(device,"@02");                  % 1 Achsen aktivieren
pause(t_pause);
writeline(device,"@0d5000");              % Ref speed setzen
pause(t_pause);
writeline(device,"@0i");                  % #input Befehl
pause(t_pause);
writeline(device,"72");                   % 1 Achsen referenzieren
pause(t_pause);
if moverel == 1
    writeline(device,['0',num2str(steps/elev*moverelX),',',num2str(speed),',0,',num2str(speed)]);        % move relative x
    pause(t_pause);
    writeline(device,['0','0,',num2str(speed),',',num2str(steps/elev*moverelY),',',num2str(speed)]);        % move relative y
    pause(t_pause);
end
writeline(device,"9");                    % stop. Befehl
pause(t_pause);
writeline(device,"@0S");                  % #start Befehl
disp('commands sent')
disp('5s pause')
pause(5);

% close serial port
delete(device);
clear variables




