function [result_points_above,baseline,result_points_below,img]=getMDSeparatingLinesAroundBLLA4seamcarve(bllaMask, linePoints, maxAngle,step)
%% gives all points of baselines directly above and below a given baseline

result_points=[];baseline=[];result_points_below=[];
[h,w]=size(bllaMask);
nu_segments=numel(linePoints(:,1))-1;
lineMask=im2bw(zeros(h,w));
img=uint8(zeros(h,w,3));
img(:,:,1)=bllaMask*255;
%% get basic angle of line in order to reorder points from left to right or from top to bottom
angle_this_line=getAngleLine(linePoints(1,1),linePoints(1,2),linePoints(end,1),linePoints(end,2));
% angle 0 is horizontal right or left, 90 is straight down; -90 is straight up
% -45 is right upwards, 45 is right downwards
% -88 is right steep upwards, 88 is right steep downwards 
% (angle_this_line >=-22.5) & (angle_this_line <=22.5) --> 1 and again for 180 later etc
% (angle_this_line >=22.5) & (angle_this_line <=67.5) --> 2
% (angle_this_line >=67.5) & (angle_this_line <=112.5) --> 3
% (angle_this_line >=112.5) & (angle_this_line <=157.5) --> 4
quadrant=mod(ceil((angle_this_line-22.5)/45),4)+1;
switch quadrant
    case 1
        if linePoints(1,1)>linePoints(end,1);linePoints=flipud(linePoints);end
    case {2,4}
        danidanbreak; %% needs to be written
    case 3
        if linePoints(1,2)>linePoints(end,2);linePoints=flipud(linePoints);end
end

for line_segment_nu=1:nu_segments
    x1=linePoints(line_segment_nu,1);
    y1=linePoints(line_segment_nu,2);
    x2=linePoints(line_segment_nu+1,1);
    y2=linePoints(line_segment_nu+1,2);
    
    %% draw segment
    segment_points=[];
    
    [segment_points(:,1),segment_points(:,2)]=linePixelsOnMatrix(x1,y1,x2,y2);
    segment_angle=getAngleLine(x1,y1,x2,y2);
%    if abs(segment_angle)>80
        segment_angle=abs(segment_angle);
%    end;
    if line_segment_nu==1
        segment_angle_first=segment_angle;
    end
    if line_segment_nu==nu_segments
        segment_angle_last=segment_angle;
    end
    % angle 0 is horizontal right or left;     % positive values if line descends rightwards up to 90 straight down     % negative values if line ascends rightwards up to -90 straight up
    for j=1:numel(segment_points(:,1))
        lineMask(segment_points(j,2),segment_points(j,1))=1;
    end
    baseline=[baseline;segment_points];
    img(:,:,2)=img(:,:,2)+uint8(imdilate(lineMask,strel('disk',5))*255);
 
    %% take each point of each segment and find first white pixel (if extant) on a perpendicular line
    for j=1:step:numel(segment_points(:,1))
        [result_points,img]=search_line_for_first_impediment(segment_points(j,1),segment_points(j,2),segment_angle,3,bllaMask,img,result_points,255);
    end
    for j=1:step:numel(segment_points(:,1))
        [result_points_below,img]=search_line_for_first_impediment(segment_points(j,1),segment_points(j,2),segment_angle-180,3,bllaMask,img,result_points_below,120);
    end
end
%% look for further impediments before the first point or after the last point in a max angle given by user
points_before=[];points_after=[];
for j=1:step:maxAngle
    [points_before,img]=search_line_for_first_impediment(linePoints(1,1),linePoints(1,2),segment_angle_first-j,3,bllaMask,img,points_before,255);
    [points_after,img]=search_line_for_first_impediment(linePoints(end,1),linePoints(end,2),segment_angle_last+j,3,bllaMask,img,points_after,255);
end

points_below_before=[];points_below_after=[];
for j=1:step:maxAngle
    [points_below_before,img]=search_line_for_first_impediment(linePoints(1,1),linePoints(1,2),segment_angle_first-180+j,3,bllaMask,img,points_below_before,120);
    [points_below_after,img]=search_line_for_first_impediment(linePoints(end,1),linePoints(end,2),segment_angle_last-180-j,3,bllaMask,img,points_below_after,120);
end

result_points=[points_before;result_points;points_after];
result_points_below=[points_below_before;result_points_below;points_below_after];
[result_points_above,img]=points2lines(result_points,img);
[result_points_below,img]=points2lines(result_points_below,img);
img(:,:,3)=imdilate(img(:,:,3),strel('disk',5));