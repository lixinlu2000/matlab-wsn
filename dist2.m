function distance = dist2(x1,y1,x2,y2)
%DIST2 Calculate the distance between two point
% Function DIST2 calculates the distance between two points
% in a cartesian coordinate system.
%
% Calling sequence:
% res = dist2(x1,y1,x2,y2)
distance = sqrt((x2-x1).^2 + (y2-y1).^2);