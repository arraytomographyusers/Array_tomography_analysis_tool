function colocalization()

%%% Colocalization By Distance and/or overlap

 % It does:
 %   - Calculate the number of possible combinations depending on the
 %   number of channels.
 %   - Calculate the distance between all the objects (time consuming).
 %   - Save the distance of the objects that are closer than maxdistance.
 %     Output as .mat file, in case exact numbers are needed.
 %   - Save the % of objects of each channel that have objects of another 
 %     channel, or multiple channels, closer than maxdistance. 
 %     Output as .xls file.
    
    
 % To do:
 %  - Possibility to choose different distances between channels.
 %  - Less annoying GUI.
 %  - choose the overlap desired.


%% Source Files and max distances
srcPath = uigetdir('Select the sequence path'); %Images Location
mkdir(srcPath, [filesep 'Results']);
srcFiles = strcat(srcPath,[filesep '*.tif']);  % the folder in which ur images exists
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);



%% Possible combinations depending on the channels
disp(strcat ('calculating possible channel combinations and preparing excel'))

tic
% Input dialog for: 
% 1-channels. 6e10 can not be used as name. 
% 2-microscope resolution.
% 3-max distance between objects.
% 4-min overlap between objects (percent of first object area).
prompt = {'Enter space-separed channel names','Lateral resolution (X-Y) in micron/pixel', 'Axial resolution (Z) in micron/pixel', 'Which maximum distance would you like to use? in micron', 'Which minimun overlap between objects would you like to use? in percent of first object area'};
title = 'Channel names';
definput = {'abeta syph psd tmem97', '0.1', '0.07', '0.5', '10'};
answer = inputdlg(prompt,title,[1 60],definput);
channels= strsplit(answer{1});
xy= str2double(answer{2});
z= str2double(answer{3});
maxdistance= str2double(answer{4});
minoverlap= str2double(answer{5});


% Input the type of colocalization between each channel.
title = 'type of colocalization';
for i=1:length(channels)
     for j=1:length(channels)
         if j~=i
            prompt = strcat('Type of colocalization between ', {' '},channels{i},{' '},'and',{' '},channels{j});
            ColocChannel{i,j} = questdlg(prompt , title, 'overlap','distance','cancel');
         else
              ColocChannel{i,j}='-';
         end
              
     end
end


% Choose if you want to save the image of the colocalizing objects.
title = 'Save images';
prompt = 'Do you want to save the images of the colocalization?                      (all the combinations, many images)';
SaveImages = questdlg(prompt , title, 'Aye','Nae','cancel');

if contains(SaveImages, 'Aye')
    mkdir(srcPath,[filesep 'Results' filesep 'ColocImages']);
end


   
% Find how many combinations may be acording to the channels and apply
% channels name to column. The rows are the possible combinations.
Binary_Combinations = dec2bin(2^length(channels)-1:-1:0)-'0';
A=array2table(Binary_Combinations, 'VariableNames', channels);
ColocCombinations=table2struct(A);

% Crate a table of channel names instead of binary numbers
[X,Y] = size(A);
for i=1:X
    for j=1:Y
        if A{i,j}==1
            K{i,j}= A(i,j).Properties.VariableNames{1};
        else
            K{i,j}= ' ';
        end
    end      
end


% Use the table of channels names to asign a merged name for each
% combination (row names of the combinations)
[X,Y] = size(K);
for i=1:X
    list{i}=strcat (K{i,:});
end

% Prepare the table for results
list(end)=[]; % delete last combination possible (no channels colocalizind with no channels, all 0).
table (1,:) = horzcat({'Sequence_name', 'Objects'},list);
tablerow = 2;

clear A
clear K
toc

%% The Analysis


for Files=1:x
   
            tic
        if  strfind(srcFiles(Files).name, channels(1))~=0
            disp(strcat ('loading',{' '}, srcFiles(Files).name))            
            Channels{1} = read_stackTiff(strcat(srcPath,filesep,srcFiles(Files).name));
            Channels{1}= Channels{1} > 0;
            Channels{1}=bwconncomp(Channels{1},6);
            Channels{1}.cc=regionprops(Channels{1},'centroid');
            Channels{1}.name=srcFiles(Files).name;
            
                for iii=2:length(channels)
                    Channels{iii} = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, channels(1), channels(iii))))));
                    Channels{iii} = Channels{iii} > 0;
                    Channels{iii}=bwconncomp(Channels{iii},6);
                    Channels{iii}.cc=regionprops(Channels{iii},'centroid');
                    Channels{iii}.name=char(strrep(srcFiles(Files).name, channels(1), channels(iii)));
                    disp(strcat ('loading',{' '}, Channels{iii}.name)) 
                end    
        
            toc

            
                    
            
            disp('Finding distances between objects')
            tic
                for i=1:length(channels)
                    for ii=1:Channels{i}.NumObjects
                        for j=1:length(channels) 
                            Channels{i}.coloc(ii).(char(channels(j))) =0; % To start always for channel 1 (keeps columns order)
                            distanceN=1; % To store all the closest objects
                            %choose the type of colocalization between the channels
                            if ismember(ColocChannel{i,j},{'distance'})
                               for jj=1:Channels{j}.NumObjects
                                   distance = sqrt((((Channels{i}.cc(ii).Centroid(1))-(Channels{j}.cc(jj).Centroid(1)))*xy)^2 + (((Channels{i}.cc(ii).Centroid(2))-(Channels{j}.cc(jj).Centroid(2)))*xy)^2 + (((Channels{i}.cc(ii).Centroid(3))-(Channels{j}.cc(jj).Centroid(3)))*z)^2);
                                   if (distance < maxdistance)~=0
                                            Channels{i}.coloc(ii).(char(channels(j))) =1;
                                            Channels{i}.distance(ii).(char(channels(j)))(distanceN) =distance;
                                            distanceN=distanceN+1;
                                  end
                               end
                            end
                            if ismember(ColocChannel{i,j},{'overlap'})
                               for jj=1:Channels{j}.NumObjects
                                   overlap = intersect(Channels{i}.PixelIdxList{ii},Channels{j}.PixelIdxList{jj});
                                   if (length(overlap)/length(Channels{i}.PixelIdxList{ii}))*100 > minoverlap % find if the overlap is bigger than the minoverlap we choosed. Here we could do it as fixed number of pixels.
                                            Channels{i}.coloc(ii).(char(channels(j))) =1;
                                   end
                               end
                            end
                            if ismember(ColocChannel{i,j},{'-'}) % colocalization with the same channel.
                                for jj=1:Channels{j}.NumObjects
                                    Channels{i}.coloc(ii).(char(channels(j))) =1;
                                end
                               
                            end
                            
                        end
                    end
                end
            toc


            % Preparing results
            disp('Preparing and saving images')
            tic
            for i=1:length(channels)
                for j=1:length(list)
                    if (isfield (Channels{i},'coloc'))==0 %Step in case there is an image without objects 
                        Channels{i}.results.(strcat(channels{i},'_',(char (list{1,j}))))= 0;
                    end
                    Channels{i}.images.(strcat(channels{i},'_',(char (list{1,j}))))=false(Channels{i}.ImageSize);
                     for k=1:Channels{i}.NumObjects
                         if  (isequaln(ColocCombinations(j),Channels{i}.coloc(k)))~=0
                            Channels{i}.results(k).(strcat(channels{i},'_',(char (list{1,j}))))= 1;
                            Channels{i}.images.(strcat(channels{i},'_',(char (list{1,j}))))(Channels{i}.PixelIdxList{k})=true;
                         else
                            Channels{i}.results(k).(strcat(channels{i},'_',(char (list{1,j}))))= 0;
                         end
                     end
                     % Save images, if it has been selected 
                     if contains (SaveImages, 'Aye')
                         if regexp(list{1,j},channels{i})~=0 % Only images of the main channel (i).
                             for ii=1:Channels{i}.ImageSize(3)
                                outputFileName = strcat(srcPath,[filesep 'Results' filesep 'ColocImages' filesep], Channels{i}.name(1:end-4),'_',char (list{1,j}), '.tif');
                                imwrite(uint16(Channels{i}.images.(strcat(channels{i},'_',(char (list{1,j}))))(:,:,ii)),outputFileName, 'WriteMode', 'append',  'Compression','none');
                             end
                         end
                         
                         
                     end
                     
                end
            end
            toc
            
            
            % Excel export    
            disp('saving results')
            tic
            for i=1:length(channels)
                table{tablerow,1}=(Channels{i}.name);
                table{tablerow,2}=Channels{i}.NumObjects;
                for j=1:length(list)
                    table{tablerow,j+2}= (sum(cat(1,Channels{i}.results.(strcat(channels{i},'_',(char (list{1,j})))))))/(Channels{i}.NumObjects)*100;
                end
                tablerow=tablerow+1;
            end
            toc
            tic
                % Save .mat in case you want to use it later (all coloc images, full distances, centroids, ...)
                 save ((strcat(srcPath,[filesep 'Results' filesep 'Coloc_All_'],(char(Channels{1}.name)),'.mat')), 'Channels');
            toc
        end

     clear Channels
        
end

    disp('saving results')
    results = cell2table (table(2:end,:), 'VariableNames', (table(1,:)));
    writetable (results, (strcat(srcPath,[filesep 'Results' filesep 'Colocalization.xls'])));
    
disp('Done - enjoy! :)')


