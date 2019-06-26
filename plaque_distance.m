
function plaque_distance()

% Choose image location and create the results folders
srcPath = uigetdir('Select the sequence path'); 
mkdir(srcPath, [filesep 'Results']);
mkdir(srcPath,[filesep 'Results' filesep 'masked_images']);
mkdir(srcPath,[filesep 'Results' filesep 'bins_images']);
srcFiles = strcat(srcPath,[filesep '*.tif']); 
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);
tic

%%
 % From an Abeta plaques segmented image, find to contour of plaque and
 % select a radius around it to proceed with the analysis. Substract the
 % plaque region keeping only the halo from the other channels in the
 % folder.
 
 
 % It will apply the mask to all the channels in the folder with the same
 % name pattern.
 
% Input dialog for channels. 6e10 can not be used as name.
prompt = {'Enter space-separed channel names', 'Which channel is beta-amyloid?', 'Lateral resolution (X-Y) in micron/pixel', 'Axial resolution (Z) in micron/pixel', 'Maximum microns from plaque', 'Analyze objects every ... microns', 'Which channel will you use for neuropil mask?'};
title = 'Plaque distance';
definput = {'OC SYPH PSD TAU', 'OC', '0.102','0.07', '50', '10', 'SYPH'};
answer = inputdlg(prompt,title,[1 50],definput);
channels= strsplit(answer{1});
abetaname=answer{2};% Will be used to identify the plaque.
xy= str2double(answer{3});
z= str2double(answer{4});
radiusum= str2double(answer{5});
radiuspx=radiusum/xy; % Transform to pixels the limit in microns.
edges = 0:str2double(answer{6}):str2double(answer{5});% Will be used to define the histogram.
neuropilchannel = (answer{7});% Will be used to calculate the neuropil mask and area of bins.

% Choose if you want to save the image of the colocalizing objects.
title = 'Save images';
prompt = 'Do you want to save the images of all the bins?                          (all the combinations, many images)';
SaveImages = questdlg(prompt , title, 'Aye','Nae','cancel');

% Prepare the table for results
Bins=num2cell(edges (2:end));
table (1,:) = horzcat({'Sequence_name'},Bins);
tablerow = 3;

    %% Analysis

    for Files=1:x
        
        % Load all channels in the folder (Similar que a Coloc module).
        if  strfind(srcFiles(Files).name, channels(1))~=0
            disp(strcat ('loading',{' '}, srcFiles(Files).name))            
            Channels{1}.image = read_stackTiff(strcat(srcPath,filesep,srcFiles(Files).name));
            Channels{1}.image= Channels{1}.image > 0; 
            Channels{1}.name=srcFiles(Files).name;
        
            
           for iii=2:length(channels)
                Channels{iii}.image = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, channels(1), channels(iii))))));
                Channels{iii}.image = Channels{iii}.image > 0;
                Channels{iii}.name=char(strrep(srcFiles(Files).name, channels(1), channels(iii)));
                disp(strcat ('loading',{' '}, Channels{iii}.name)) 
           end    
           %% PLAQUE FINDING AND PROCESSING
            for iii=1:length(channels)
                if  strfind(Channels{iii}.name, abetaname)~=0
                    Abeta = Channels{iii}.image;
                end
            end
            
            disp('creating plaque mask')
            % Fill plaque
            se= strel('disk',10);
            bw=imclose(Abeta,se);
            for i=1:size(bw,3)
             bw(:,:,i)=imfill(bw(:,:,i),'holes'); 
            end
%             se= strel('disk',2); % VALORATE INCLUDING
%             bw=imerode(bw,se);
            [m,n,p] = size(bw);
            % Filter for the biggest size object.
            Plaques.cc=bwconncomp(bw,6);
            Plaques.cc.Plaque= regionprops(Plaques.cc,'Area','Centroid');
            [Z,ZZ]=max([Plaques.cc.Plaque.Area]);
            Plaques.cc.image = false(size (Abeta));
            if Z>10000 %random value to decide that smaller objects are not plaques and then use a centre pixel
            Plaques.cc.image(Plaques.cc.PixelIdxList{ZZ})=true;
            else
            Plaques.cc.image(round(m/2),round(n/2),round(p/2))=true;    
            end

% %             Draw a perimeter around the plaque from the max axis length. Takes into account the radius from the input.
%             for j=1:size(bw,3)
%                 Plaques.cc.imcc = regionprops(Plaques.cc.image(:,:,j),'MajorAxisLength','Centroid');          
%                 [K,KK]=(max([Plaques.cc.imcc.MajorAxisLength]));
%                 xr = K/2 + radiuspx;
%                 yr = K/2 + radiuspx;
%                 xbase = linspace(1,size(bw,1),size(bw,2)) ;
%                 [xm,ym] = ndgrid( xbase , xbase);
%                 mask(:,:,j) =(((xm-Plaques.cc.imcc(KK).Centroid(2)).^2/(xr.^2)) + ((ym-Plaques.cc.imcc(KK).Centroid(1)).^2/(yr.^2)))<=1;   
%             end

%             % Create the final mask.
%             mask=imcomplement(mask);
%             mask=Plaques.cc.image | mask;
%             mask=imcomplement(mask);
% 
%             disp('saving the mask')
%             % save mask
%             for i=1:size(bw,3)
%               outputFileName = strcat(srcPath,[filesep 'Results' filesep 'masked_images' filesep 'Mask_plaque'], srcFiles(Files).name, '.tif');
%               imwrite(uint16(mask(:,:,i)),outputFileName, 'WriteMode', 'append',  'Compression','none');
%             end
            
       %% Create neuropil mask
       
        disp('creating neuropil mask')
        for iii=1:length(channels)
            % total area
            Channels{iii}.areatotal = m*n*p;
             
                if strfind(Channels{iii}.name,neuropilchannel)>0
                    zproj = max (Channels{iii}.image,[],3);
                    zproj = zproj*100000;
                    zproj_dil = imdilate(zproj, strel('disk',19));
                    neuropilmask = imerode(zproj_dil, strel('disk',10));
                    neuropilmask= neuropilmask >0;
                    NeuropilMask=neuropilmask;
                   for j=1:p-1
                      NeuropilMask= cat (3, NeuropilMask, neuropilmask);
                   end
                  
                    % neuropil area
                    Channels{iii}.areaneuropil = Channels{iii}.areatotal - (nnz(~neuropilmask)*p);
                    neuropilarea = Channels{iii}.areaneuropil;
                    
                    % save neuropil mask image
                    seq_name = Channels{iii}.name(1:(end-4));
                 for i=1:size(bw,3)
                            outputFileName = strcat(srcPath,(strcat([ filesep 'Results' filesep 'masked_images' filesep], srcFiles(Files).name, '_NeuropilMask.tif')));
                            imwrite(uint16(NeuropilMask(:,:,i)),outputFileName, 'WriteMode', 'append',  'Compression','none');
                 end
                else
                   Channels{iii}.areaneuropil = 0;
                end 
        end    
        
%% MASK OTHER CHANNELS AND FIND DISTANCES
   
          
            % Find the perimeter of Abeta plaque.
            disp('find the perimeter of plaque')
            for i=1:size(bw,3)
                [boundarypoints,boundaryimage] = bwboundaries(Plaques.cc.image(:,:,i));
                ref_boundary{i}=vertcat (boundarypoints{:}); % merge all the diferent objects perimetres
                if ~isempty (boundarypoints)% add the z position only if there are positive pixels in that z.
                    ref_boundary{i}(:,3)=i; % save which z it is
                end
                boundary(:,:,i)=imbinarize(boundaryimage); % create the boundary image
            end
            ref_boundary=cat(1, ref_boundary{:});
            
            % Save boundary image
             for i=1:size(bw,3)
                        outputFileName = strcat(srcPath,(strcat([ filesep 'Results' filesep 'bins_images' filesep 'boundary_plaque'], srcFiles(Files).name, '.tif')));
                        imwrite(uint16(boundary(:,:,i)),outputFileName, 'WriteMode', 'append',  'Compression','none');
             end
             
            disp('applying the mask to all channels and saving masked images')
            invertedboundary = imcomplement(boundary); % image of the plaque
            
            % Apply the plaque mask and the neuropil mask to all channels
            FinalMask=(invertedboundary+NeuropilMask)>1;
            
            for iii=1:length(channels)
                Channels{iii}.masked=Channels{iii}.image.*FinalMask;% apply FinalMask (plaque and neuropil combined)
                Channels{iii}.name=regexprep(Channels{iii}.name,'.tif','');
                Channels{iii}.bw=bwconncomp(Channels{iii}.masked,6);
                Channels{iii}.cc=regionprops(Channels{iii}.bw,'centroid');
                  for i=1:size(bw,3)
                    outputFileName = strcat(srcPath, [filesep 'Results' filesep 'masked_images' filesep],Channels{iii}.name, '_masked.tif');
                    imwrite(uint16(Channels{iii}.masked(:,:,i)),outputFileName, 'WriteMode', 'append',  'Compression','none');
                  end
            end
                    
            
            disp('calculating distances and saving images of bins')
            % Calculate distances between each object and perimetre of
            % plaque and save images if selected
            for i=1:length(channels)
                for j=1:length(Channels{i}.cc)   
                        distance = sqrt((((ref_boundary(:,2))-(Channels{i}.cc(j).Centroid(1)))*xy).^2 + (((ref_boundary(:,1))-(Channels{i}.cc(j).Centroid(2)))*xy).^2 + (((ref_boundary(:,3))-(Channels{i}.cc(j).Centroid(3)))*z).^2);
                        Channels{i}.distances(j) = min(distance);
                end
                if isfield (Channels{i}, 'distances')
                    
                [Channels{i}.hist, Channels{i}.bin]=histcounts(Channels{i}.distances, edges);
                Channels{i}.Objectbin = discretize (Channels{i}.distances,edges);
                else
                    Channels{i}.bin = edges;
                    Channels{i}.hist= zeros (1,(length (edges)-1));
                    Channels{i}.Objectbin=0;
                end
                
                % save bins images if selected 
                if contains (SaveImages, 'Aye')
                    for jj=1:(length (edges)-1)
                        Channels{i}.(strcat('ImageBin_',num2str(jj)))= false (Channels{i}.bw.ImageSize);
                        for j=1:length(Channels{i}.cc) 
                            if Channels{i}.Objectbin (j)==jj
                                Channels{i}.(strcat('ImageBin_',num2str(jj)))(Channels{i}.bw.PixelIdxList{j})=true;
                            end
                        end
                        % Saving images.
                        for jjj=1:size(bw,3)
                            outputFileName = strcat(srcPath,(strcat([filesep 'Results' filesep 'bins_images' filesep],strcat('ImageBin_',num2str(jj),'_'),Channels{i}.name,'.tif')));
                            imwrite(uint16(Channels{i}.(strcat('ImageBin_',num2str(jj)))(:,:,jjj)),outputFileName, 'WriteMode', 'append',  'Compression','none');
                        end
                        if strfind(Channels{i}.name,neuropilchannel)>0 % Calculate Bin area using Bin image of neuropil channel
                                if jj==1
                                GaussianBin=imgaussfilt (double( Channels{i}.(strcat('ImageBin_',num2str(jj)))),20);
                                GaussianBin= GaussianBin>0;
                                GaussianBin=imerode(GaussianBin, strel('disk',30));
                                MaskBin= GaussianBin.*FinalMask;
                                Channels{i}.AreaBins{jj}=nnz(MaskBin);
                                Channels{i}.(strcat('MaskBin_',num2str(jj)))=MaskBin; % to save the images of MaskBins (could be removed)
                                else
                                GaussianBin=imgaussfilt (double( Channels{i}.(strcat('ImageBin_',num2str(jj)))),20);
                                GaussianBin= GaussianBin>0;
                                GaussianBin=imerode(GaussianBin, strel('disk',30));
                                MaskBin= GaussianBin.*FinalMask;
                                Channels{i}.AreaBins{jj}=nnz(MaskBin);    
                                Channels{i}.(strcat('MaskBin_',num2str(jj)))=MaskBin; % to save the images of MaskBins (could be removed)
                                end
                            
                            for jjj=1:size(bw,3)
                                outputFileName = strcat(srcPath,(strcat([filesep 'Results' filesep 'bins_images' filesep],strcat('MaskBin_',num2str(jj),'_'),Channels{i}.name,'.tif')));
                                imwrite(uint16(Channels{i}.(strcat('MaskBin_',num2str(jj)))(:,:,jjj)),outputFileName, 'WriteMode', 'append',  'Compression','none');
                            end              
                       end
                    end  
                end
            end
            
            

            
            
            disp('Saving Excel files')
            for i=1:length(channels)
              if strfind(Channels{i}.name,neuropilchannel)>0
                table(tablerow,:)=horzcat({'Area'},Channels{i}.AreaBins);
                tablerow=tablerow+1;
              end
            end
            
            for i=1:length(channels)
                Hist=num2cell(Channels{i}.hist);
                table(tablerow,:)=horzcat({Channels{i}.name},Hist);                
                tablerow=tablerow+1;
            end
            
        end
        clear Channels
        clear Plaques
        clear ref_boundary
        clear boundarypoints
        clear boundaryimage
        clear boundary
        
    end
    
    disp('saving results')
    results = cell2table (table(1:end,:));
    writetable (results, (strcat(srcPath,[filesep 'Results' filesep 'Plaque_distance.xls'])));
    
         toc
    disp('Doner! enjoy! :)')
    
    
    
    
    
    
    
    
   
    
    
    
    
    
   