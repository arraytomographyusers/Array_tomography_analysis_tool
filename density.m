function density()

% Choose image location and create the results folders
srcPath = uigetdir('Select the sequence path'); 
mkdir(srcPath, [filesep 'Density_Results']);
mkdir(srcPath, [filesep 'Density_Results' filesep 'Neuropilmask']);
srcFiles = strcat(srcPath,[filesep '*.tif']);  % the folder in which ur images exists
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);

% Input dialog for channels. 6e10 can not be used as name.
prompt = {'Enter space-separed channel names', 'Which channel will be used for neuropil mask?','Lateral resolution (X-Y) in micron/pixel', 'Axial resolution (Z) in micron/pixel'};
title = 'Channel names';
definput = {'OC PSD SYPH TAU', 'SYPH', '0.102', '0.07'};
answer = inputdlg(prompt,title,[1 40],definput);
channels = strsplit(answer{1});
neuropilchannel = answer{2};% Will be used to create a neuropil mask.
xy= str2double(answer{3});
z= str2double(answer{4});

% Prepare the table for results
table (1,:) = {'Sequence_name', 'Objects', 'Total_area_vx', 'Neuropil_area_vx', 'Density_in_neuropil_mm3'};
tablerow = 2;


%%
%find positions of channels in srcFiles
for Files=1:x
        
      % Load all channels in the folder (Similar que a Coloc module).
      if  strfind(srcFiles(Files).name, channels(1))~=0
            disp(strcat ('loading',{' '}, srcFiles(Files).name))            
            Channels{1}.image = read_stackTiff(strcat(srcPath,filesep,srcFiles(Files).name));
            Channels{1}.image = logical (Channels{1}.image); 
            Channels{1}.CC = bwconncomp (Channels{1}.image, 6);
            Channels{1}.name=srcFiles(Files).name;
        
            
          for iii=2:length(channels)
                    Channels{iii}.image = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, channels(1), channels(iii))))));
                    Channels{iii}.image = logical (Channels{iii}.image); 
                    Channels{iii}.CC = bwconncomp (Channels{iii}.image, 6);
                    Channels{iii}.name=char(strrep(srcFiles(Files).name, channels(1), channels(iii)));
                    disp(strcat ('loading',{' '}, Channels{iii}.name)) 
          end    

        disp('creating neuropil mask')
        for iii=1:length(channels)
            % total area
            [m,n,p] = size(Channels{iii}.image);
            Channels{iii}.areatotal = m*n*p;
             
                if strfind(Channels{iii}.name,neuropilchannel)>0
                    zproj = max (Channels{iii}.image,[],3);
                    zproj = zproj*100000;
                    zproj_dil = imdilate(zproj, strel('disk',19));
                    neuropilmask = imerode(zproj_dil, strel('disk',10));
                    neuropilmask= neuropilmask >0;
                    % neuropil area
                    Channels{iii}.areaneuropil = Channels{iii}.areatotal - (nnz(~neuropilmask)*p);  
                    % save neuropil mask image
                    seq_name = Channels{iii}.name(1:(end-4));
                    outputFileName = strcat(srcPath,[filesep 'Density_Results' filesep 'Neuropilmask' filesep],seq_name,'_neuropilMask.tif');
                    imwrite(uint16(neuropilmask),outputFileName, 'WriteMode', 'append',  'Compression','none');
                    neuropilarea = Channels{iii}.areaneuropil;
                else
                   Channels{iii}.areaneuropil = 0;
                end 
        end
        
        for iii=1:length(channels)     
            
            Channels{iii}.density= ((Channels{iii}.CC.NumObjects/neuropilarea)/(xy*xy*z))*10^9;
            
            % save results into a table
            table (tablerow,:)= {Channels{iii}.name (Channels{iii}.CC.NumObjects) Channels{iii}.areatotal (Channels{iii}.areaneuropil) Channels{iii}.density};
            tablerow=tablerow+1;
        end
     end
end
    disp('saving results')
    results = cell2table (table(2:end,:), 'VariableNames', (table(1,:)));
    writetable (results, (strcat(srcPath,[filesep 'Density_Results' filesep 'Densities.xls'])));
    
    
fprintf('\n Done - enjoy! \n')