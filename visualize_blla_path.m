function [outputmatrix,pointList]=visualize_blla_path(pathfilename,imgfilename,baselineWidth)

%% converts a list of paths for baselines to lines noted on a bw outputmatrix (with the width baselineWidth) and registered in the pointList

pointList=get_point_list_of_path(pathfilename);
if nargin<2
    baselineWidth=2;
    h=max(pointList(:,3))+1;
    w=max(pointList(:,2))+1;
else
    if nargin<3
        baselineWidth=2;
    end
    img=imread(imgfilename);
    [h,w,~]=size(img);
end
outputmatrix=im2bw(zeros(h,w));
nu_lines=numel(unique(pointList(:,1)));
for i=1:nu_lines
    points=pointList(pointList(:,1)==i,:);
    for j=1:numel(points(:,1))-1
        x1=points(j,2);
        y1=points(j,3);
        x2=points(j+1,2);
        y2=points(j+1,3);
        [x,y]=linePixelsOnMatrix(x1,y1,x2,y2);
        for p=1:numel(x)
            outputmatrix(min(h,max(1,y(p)-ceil(baselineWidth/2))):min(h,max(1,y(p)+floor(baselineWidth/2))),min(w,max(1,x(p))),1)=1;
        end
    end
end