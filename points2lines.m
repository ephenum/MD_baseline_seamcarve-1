function [result_points,img]=points2lines(points,img);

%% gives all points for a line between two points and notes them on an image
result_points=[];
if ~isempty(points)
if numel(points(:,1))>2
    for i=1:numel(points(:,1))-1
        [whole_line_x,whole_line_y]=linePixelsOnMatrix(points(i,1),points(i,2),points(i+1,1),points(i+1,2));
        whole_line=zeros(numel(whole_line_x),2);
        whole_line(:,1)=whole_line_x;
        whole_line(:,2)=whole_line_y;
        result_points=[result_points;whole_line];
    end
    for i=1:numel(result_points(:,2))
        img(result_points(i,2),result_points(i,1),3)=255;
    end
end
end