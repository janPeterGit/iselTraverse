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
% 
% #steps 800; % not used in terminal
% #elev 2.5 % not used in terminal
% #ref_speed 5000
% #units mm; % not used in terminal
% 
% #input
% 
% reference x;
% moverel 100(5000),0(3000),0(3000);
% 
% 
% stop.
% 
% #start

% Terminal output
% @01              1 Achsen setzen
% @0d5000          ref speed setzen
% @0i              #input Befehl
% 71             reference x
% 032000,5000      moverel 
% 9                stop. befehl
% @0S              #start Befehle

% COM settings
COM_port = 'COM3';
baudrate = 19200;

t_pause = 0.1; % seconds

% open serial port
device = serialport(COM_port,baudrate);
configureTerminator(device,"CR/LF")      % unbedingt notwendig, für ECHO Antwort
pause(t_pause);
device.Timeout = 10; % default 10
pause(t_pause);
% resp = writeread(device,"*IDN?")
pause(t_pause);

% send commands
disp('send commands')
writeline(device,"@01");                  % 1 Achsen aktivieren
pause(t_pause);
writeline(device,"@0d5000");              % Ref speed setzen
pause(t_pause);
writeline(device,"@0i");                  % #input Befehl
pause(t_pause);
writeline(device,"71");                   % 1 Achsen referenzieren
pause(t_pause);
% writeline(device,'032000,5000');        % fahre an abs Pos 0,0 mit Geschw. 3000
% pause(t_pause);
writeline(device,"9");                    % stop. Befehl
pause(t_pause);
writeline(device,"@0S");                  % #start Befehl
disp('commands sent')
disp('5s pause')
pause(5);
 
% close serial port
% delete(device);
clear device;




