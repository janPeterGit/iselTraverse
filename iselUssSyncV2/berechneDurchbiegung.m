clc
clear all
close all

% berechne durchbiegung

x = [-1.25, 0.225, 1.7];
y = [0, -3/1000, 0];

hold on
plot(x,y)

messpunkte = readtable("LogISEL_LogUSS_LogLC\20220426_Zylinder 1 cm Versatz\20220426_1020_L474W90Q30.0H94G2_C.xlsx");
korrekturWert = NaN(length(messpunkte.xPosition),1);

messpunkte.xPosition = messpunkte.xPosition./1000;

for i = 1:length(messpunkte.xPosition)
korrekturWert(i) = 0.00137891410514220 * messpunkte.xPosition(i)^2 ...
    -0.000620511347313991 * messpunkte.xPosition(i)	...
    -0.00293019247342718;
end

plot(messpunkte.xPosition,korrekturWert)

korrekturTabelle = table;
korrekturTabelle.correctDeflection = korrekturWert;

writetable(korrekturTabelle,'korrekturTabelle.xlsx')