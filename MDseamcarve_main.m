function [pointsAbove,pointsBelow,imgRes,errorlist]=MDseamcarve(imgname,pathname,show_result)

%% input: 
%% imgname = name of the original color or grayscale manuscript image
%% pathname = name of the path of the baselines on the manuscript image
%% show_result = boolean whether to insert the polygonresults and linelabels into the resulting image

%% output:
%% pointsAbove, pointsBelow: arrays of cells of points above each of the baselines
%% imgRes: resulting image with color overlay for each of the line polygons and labels for line numbers according to path file
%% errorlist: list of lines with a computation error

if nargin==0
   addpath('E:\MATLAB\kraken','E:\MATLAB\kraken\seamcarve_trial','E:\MATLAB\standard_code');
   id = 'images:initSize:adjustingMag'; warning('off',id); % turns off image resizing warnings.
   basedir='E:\MATLAB\kraken\seamcarve_trial\eval';
   show_result=1; 
   imgname='bge-cl0146_345.png';
   pathname='bge-cl0146_345.path';
end
img=imread(fullfile(basedir,imgname));
[bllaMask,pointList]=visualize_blla_path(fullfile(basedir,pathname),fullfile(basedir,imgname),2);
line_list=unique(pointList(:,1));
line_list=5;
errorlist=[];
imgRes=img;
for i=1:numel(line_list)
    this_line_segments=pointList(pointList(:,1)==line_list(i),2:3);
    [result_points,baseline,result_points2below,~]=getMDSeparatingLinesAroundBLLA4seamcarve(bllaMask,this_line_segments,45,3);
    try
       [imgRes,pointsAbove{i},pointsBelow{i}]=compute_MD_separating_seams(img, result_points,baseline,result_points2below,imgRes,mod(i,3)+1,show_result);
       if show_result
        imgRes = insertText(imgRes, [pointsAbove{i}(1,1),pointsAbove{i}(1,2)], num2str(line_list(i)));
       end
    catch
       errorlist=[errorlist,i];
    end
end
