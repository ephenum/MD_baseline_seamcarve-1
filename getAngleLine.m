function angle=getAngleLine(x1,y1,x2,y2)
%% gives the angle of a line defined by two points (x1, y1, x2, y2)
%% angle 0 is horizontal right or left, 90 is straight down; -90 is straight up
%% -45 is right upwards, 45 is right downwards
%% -88 is right steep upwards, 88 is right steep downwards 

if x1<x2
    swap=x1;
    x1=x2;
    x2=swap;
    swap=y1;
    y1=y2;
    y2=swap;
end

delta_x=x2-x1;
delta_y=y2-y1;

angle=rad2deg(atan(delta_y/delta_x));