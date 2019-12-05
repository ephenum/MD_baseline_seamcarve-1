function [imgRes,pointsAbove,pointsBelow]=compute_MD_separating_seams(img, result_points,baseline,result_points2below,imgRes,color,show_result)

%% computes the separating seams for a baseline in any direction
%% still need to test whether there is a need to add for oblique angles between 22.5 to 67.5 degrees. danidanbreak

[h,w,c]=size(img);
baseline_mask=im2bw(zeros(h,w));
for i=1:length(baseline(:,1));baseline_mask(baseline(i,2),baseline(i,1))=1;end
baseline_mask=imdilate(baseline_mask,strel('disk',3));
if c>1
    img_gray=rgb2gray(img);
else img_gray=img;
end


if isempty(result_points)
    result_points=ones(w,2);
    result_points(:,1)=[1:w];
end
if isempty(result_points2below)
    result_points2below=ones(w,2);
    result_points2below(:,1)=[1:w];
    result_points2below(:,2)=result_points2below(:,2)*h;
end
%% get quadrant of baseline
angle_this_line=getAngleLine(baseline(1,1),baseline(1,2),baseline(end,1),baseline(end,2));
% angle 0 is horizontal right or left, 90 is straight down; -90 is straight up
% -45 is right upwards, 45 is right downwards
% -88 is right steep upwards, 88 is right steep downwards
%(angle_this_line >=-22.5) & (angle_this_line <=22.5) --> 1 and again for 180 later etc
% (angle_this_line >=22.5) & (angle_this_line <=67.5) --> 2
% (angle_this_line >=67.5) & (angle_this_line <=112.5) --> 3
% (angle_this_line >=112.5) & (angle_this_line <=157.5) --> 4
quadrant=mod(ceil((angle_this_line-22.5)/45),4)+1;


%% compute the energy map
[Ix,Iy] = gradient(double(img_gray));
energy_map = abs(Ix) + abs(Iy);
%energy_map=edge(imgaussfilt(img_gray, 0.5));
%figure;imagesc(energy_map);waitforbuttonpress;
mask_energy=im2bw(zeros(h,w));
line_energy=100000;
for i=1:length(baseline)
    mask_energy(baseline(i,2),baseline(i,1))=1;
end
for i=1:length(result_points)
    mask_energy(result_points(i,2),result_points(i,1))=1;
end
for i=1:length(result_points2below)
    mask_energy(result_points2below(i,2),result_points2below(i,1))=1;
end
mask_energy=imdilate(mask_energy,strel('square',2));
%figure;imshow(mask_energy);
%waitforbuttonpress
energy_map(mask_energy)=line_energy;
%figure;
%subplot(1,2,1);imagesc(energy_map);
%m=distance_mask_point2line([baseline(1,1),baseline(1,2)],[baseline(end,1),baseline(end,2)],h,w);
%m=round(m/30,0);
m=round(bwdist(baseline_mask)/30,0);
%figure;imagesc(m);waitforbuttonpress;
energy_map=energy_map+m;
%subplot(1,2,2);imagesc(m);
%waitforbuttonpress;
%figure;

switch quadrant
    case 1
        left=min(baseline(:,1));    right=max(baseline(:,1));
        top=min(result_points((result_points(:,1)>=min(baseline(:,1)) & (result_points(:,1)<=max(baseline(:,1)))),2));
        if isempty(top)    top=max(1,mean(baseline(:,2))-100); end
        bottom=max(result_points2below((result_points2below(:,1)>=min(baseline(:,1)) & (result_points2below(:,1)<=max(baseline(:,1)))),2));
        if isempty(bottom)    bottom=min(h,mean(baseline(:,2))+100); end
        baseline_end=baseline(end,2)-top+1;
        energy_map_cutout=energy_map(top:bottom,left:right);
        
        output_cutout=img(top:bottom,left:right,:);
    case {2,4}
        danidanbreak;
    case 3
        left=min(baseline(:,2)); right=max(baseline(:,2)); % turned by 90 degrees
        bottom=max(result_points((result_points(:,2)>=left & (result_points(:,2)<=right)),1));
        top=min(result_points2below((result_points2below(:,2)>=left & (result_points2below(:,2)<=right)),1));
        if isempty(bottom)    bottom=min(w,mean(baseline(:,1))+100); end
        if isempty(top)    top=max(1,mean(baseline(:,1))-100); end
        %             b=baseline'
        %             ab=result_points'
        %             bel=result_points2below'
        if top>bottom
            swap_var=top;
            top=bottom;
            bottom=swap_var;
        end
        baseline_end=baseline(end,1)-top+1;
        energy_map_cutout=energy_map(left:right,top:bottom);
        energy_map_cutout=energy_map_cutout';
        output_cutout=img(left:right,top:bottom,:);
end
height=bottom-top;
energy_map_cutout(1,:)=100000;
energy_map_cutout(end,:)=100000;
[h_cutout,w_cutout] = size(energy_map_cutout);
%if show_result subplot(1,3,1);imshow(output_cutout);subplot(1,3    ,2);imagesc(energy_map_cutout); end;

%% compute minimum energy separating seam using dynamic programming
for x = 2:w_cutout
    for y = 2:h_cutout-1
        %% find previous row's neighbors for the cumulative matrix computation and take care not to overstep the boundaries of the image
        switch quadrant
            case {1,3}
                min_left_energy=min(energy_map_cutout(y-1:y+1,x-1));
            case 2
                min_left_energy=min([energy_map_cutout(y:y+1,x-1);energy_map_cutout(y-1,x)]);
                %             case 3
                %             min_left_energy=min(energy_map_cutout(y,x-1:x+1));
            case 4
                min_left_energy=min([energy_map_cutout(y-1:y,x-1);energy_map_cutout(y+1,x)]);
        end
        energy_map_cutout(y,x) = min_left_energy+energy_map_cutout(y,x);
    end
end
%% trace the path backwards  for both TOP and BOTTOM SEAM   % find the minimum energy path at the bottom, the index of the minimum energy is the starting point
min_index_top=zeros(1,w_cutout);
[~,min_index_top(w_cutout)]=min(energy_map_cutout(1:min(h_cutout,baseline_end),w_cutout));
min_index_bottom=zeros(1,w_cutout);
%baseline_end
%size(energy_map_cutout)
[~,min_index_bottom(w_cutout)]=min(energy_map_cutout(baseline_end+1:end,w_cutout));
min_index_bottom(w_cutout)=min_index_bottom(w_cutout)+baseline_end+1;
for x=w_cutout-1:-1:1
    switch quadrant
        case {1,3}
            %               max(1,min_index_top(x+1)-1)
            %               min(h_cutout,min_index_top(x+1)+1)
%             display(x);
%             display(length(min(energy_map_cutout(max(1,min_index_top(x+1)-1):min(h_cutout,min_index_top(x+1)+1),x))));
%             display(length(min(energy_map_cutout(max(1,min_index_bottom(x+1)-1):min(h_cutout,min_index_bottom(x+1)+1),x))));
            [~, min_index_top(x)] = min(energy_map_cutout(max(1,min_index_top(x+1)-1):min(h_cutout,min_index_top(x+1)+1),x));
            min_index_top(x)=min_index_top(x)+min_index_top(x+1)-2;
            [~, min_index_bottom(x)] = min(energy_map_cutout(max(1,min_index_bottom(x+1)-1):min(h_cutout,min_index_bottom(x+1)+1),x));
            min_index_bottom(x)=min_index_bottom(x)+min_index_bottom(x+1)-2;
        case {2,4}
          danidanbreak;
    end;
end

if show_result
    switch quadrant
        case 1
            %    output_cutout=img(top:bottom,left:right,:);
            for x=1:w_cutout-1
                output_cutout(min_index_top(x),x,1)=255;
                output_cutout(min_index_bottom(x),x,2)=255;
            end
            min_index_top=min_index_top+top-1;
            min_index_bottom=min_index_bottom+top-1;
        case {2,4}
            danidanbreak
        case 3
            %            output_cutout=img(left:right,top:bottom,:);
            for x=1:w_cutout-1
                output_cutout(x,min_index_top(x),1)=255;
                output_cutout(x,min_index_bottom(x),2)=255;
            end
            min_index_top=min_index_top+top-1;
            min_index_bottom=min_index_bottom+top-1;
    end 
end
if show_result
    random_color1=randi([0,255]);
    random_color2=randi([100,150]);
    for x=1:w_cutout-1
        switch quadrant
            case 1
                imgRes(max(1,min_index_top(x)):min(h,min_index_bottom(x)),min(w,max(1,x+left-1)),color)=random_color1;
                %imgRes(max(1,min_index_top(x)):min(h,min_index_bottom(x)),min(w,max(1,x+left-1)),mod(color+1,3)+1)=random_color2;
            case {2,4}
                danidanbreak;
                beep(1);
            case 3
                imgRes(min(h,max(1,x+left-1)),max(1,min_index_top(x)):min(w,min_index_bottom(x)),color)=random_color1;
        end
    end
    %subplot(1,3,3);imshow(output_cutout);%waitforbuttonpress
end

%% convert into 2 lists of points
pointsAbove=[];pointsBelow=[];
for x=1:w_cutout-1
    switch quadrant
        case 1 %% horizontal lines
            pointsAbove=[pointsAbove;x+left-1,min_index_top(x),quadrant];
            pointsBelow=[pointsBelow;x+left-1,min_index_bottom(x),quadrant];
        case {2,4}
            danidanbreak;
        case 3 %% vertical lines
            pointsAbove=[pointsAbove;min_index_top(x),x+left-1,quadrant];
            pointsBelow=[pointsBelow;min_index_bottom(x),x+left-1,quadrant];
    end
end