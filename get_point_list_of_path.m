function pointList=get_point_list_of_path(pathfilename)
%% converts the json in a pathfilename to a list of points [linenumber,x,y]
fid=fopen(pathfilename);
pathfile = fscanf(fid,'%c');
fclose(fid);

lines=strsplit(pathfile,']], [[');
lines{1}(1:3)=[];
lines{end}(end-2:end)=[];
nu_lines=numel(lines);
nu_points=sum(count(lines,'], ['));
pointList=zeros(nu_points,3);
counter=0;
for i=1:nu_lines
    points=strsplit(lines{i},'], [');
    for j=1:numel(points)
        coordinates=strsplit(points{j},', ');
        x=str2double(coordinates{1});
        y=str2double(coordinates{2});
        counter=counter+1;
        pointList(counter,:)=[i,x,y];
    end
end