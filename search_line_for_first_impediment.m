function [result_points,img]=search_line_for_first_impediment(start_x,start_y,segment_angle,safety_distance,bllaMask,img,result_points,color);
%% calculates the nearest points of other baselines in 
%% start_x,start_y = starting point on baseline
%% segment_angle = angle of line segment
%% safety_distance = distance from which to begin the calculation 
%% bllaMask = mask with all other baselines
%% img = manuscript image
%% result_points = already existing result_points
%% color = color with which to mark 

show_process=0; %% set to 1 if you want to observe the process
[h,w]=size(bllaMask);
[perpendicular_x,perpendicular_y]=linePixelsAngleLength(start_x,start_y,segment_angle-90,max(h,w)*1.5); %the maximal length that can be attained is sqrt of 2 multiplied by the larger value of (height,width) of the mask
perpendicular_points=zeros(numel(perpendicular_x),2);
perpendicular_points(:,1)=perpendicular_x;
perpendicular_points(:,2)=perpendicular_y;
perpendicular_points((perpendicular_x<1)|(perpendicular_y<1)|(perpendicular_x>w)|(perpendicular_y>h),:)=[]; % delete all points outside of mask
if show_process
    perpenmask=uint8(zeros(h,w,1));
    for k=1:numel(perpendicular_points(:,1));
        perpenmask(perpendicular_points(k,2),perpendicular_points(k,1))=255;
    end;
    img(:,:,3)=perpenmask;
    imshow(img);
end;
nu_perpendicular_points=numel(perpendicular_points(:,1));
noWhiteFound=1;
k=safety_distance;
while noWhiteFound && (k<nu_perpendicular_points)
    k=k+1;
    if ~((perpendicular_points(k,1)==start_x) & (perpendicular_points(k,2)==start_y))
        if bllaMask(perpendicular_points(k,2),perpendicular_points(k,1))==1
            result_points=[result_points;perpendicular_points(k,1:2)];
            img(perpendicular_points(k,2)-1:perpendicular_points(k,2)+1,perpendicular_points(k,1)-1:perpendicular_points(k,1)+1,2)=color;
            if show_process
               lineMask(perpendicular_points(k,2),perpendicular_points(k,1))=1;
               img(:,:,2)=lineMask*255;
               imshow(imdilate(lineMask,strel('disk',5)));
            end;
            noWhiteFound=0;
        end
    end
end
%imshow(img);