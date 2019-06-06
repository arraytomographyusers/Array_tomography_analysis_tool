function segment_previsualize(srcPath,name,ws,sf,method,min,max) 

srcFiles = strcat(srcPath,[filesep '*.tif']);  % the folder in which ur images exists
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);

I = read_stackTiff(strcat(srcPath,filesep,name)); % read tiff stack
[f,c,p]=size(I);

Imat = mat2gray(I);

%% BW thresholding with mean or median local filter

meanI2=zeros(size(Imat));
medianI2=meanI2;
sI2=meanI2;
bwI2=meanI2;
join1D = false([f c]);
join2D =false(size(bwI2));

switch method
    % Local mean filter  (a triar entre aquest i el median filter)
    case 'mean'
        for i=1:p
        %     stret = stretchlim(I2(:,:,i));
            C=-mean(mean(Imat(:,:,i)))/sf; %%%modificable value(median, bins,...)
            meanI2(:,:,i)=imfilter(Imat(:,:,i),fspecial('average',ws),'replicate');

            sI2(:,:,i)=meanI2(:,:,i)-Imat(:,:,i)-C;
            bwI2(:,:,i)=im2bw(sI2(:,:,i),0);
            bwI2(:,:,i)=imcomplement(bwI2(:,:,i));
            
                    %remove small dots in 2D
                    CCbwImat(i).CC=bwconncomp(bwI2(:,:,i),4);
                    for ii=1:CCbwImat(i).CC.NumObjects
                            pixId=CCbwImat(i).CC.PixelIdxList{ii};
                                if (length(pixId)>2) 
                                    join1D(CCbwImat(i).CC.PixelIdxList{ii})=true;
                                end
                     end   
                     join2D(:,:,i)=join1D;
                     join1D = false([f c]);
        end

        % Local median filter 
    case 'median'
        for i=1:p
        %     stret = stretchlim(I2(:,:,i));
            C=-median(median(Imat(:,:,i)))/sf; %%% modificable value (median, bins,...)
            medianI2(:,:,i)=medfilt2(Imat(:,:,i),[ws ws]);

            sI2(:,:,i)=medianI2(:,:,i)-Imat(:,:,i)-C;
            bwI2(:,:,i)=im2bw(sI2(:,:,i),0);
            bwI2(:,:,i)=imcomplement(bwI2(:,:,i));
            
                    %remove small dots in 2D
                    CCbwImat(i).CC=bwconncomp(bwI2(:,:,i),4);
                    for ii=1:CCbwImat(i).CC.NumObjects
                            pixId=CCbwImat(i).CC.PixelIdxList{ii};
                                if (length(pixId)>2) 
                                    join1D(CCbwImat(i).CC.PixelIdxList{ii})=true;
                                end
                     end   
                     join2D(:,:,i)=join1D;
                     join1D = false([f c]);
        end 

    otherwise 
        fprintf('\n The method %s is not implemented yet...\n', method);
end
    
    %% Extract connectivity and size information of each object

        CC = bwconncomp(join2D,6);
        props=regionprops(CC, 'PixelList');
        join3D =false(size(join2D));    
      
    for i=1:CC.NumObjects
        object=diff(props(i).PixelList);
        if (sum(object(:,3))>0 && length(object(:,1))+1>min && length(object(:,1))+1<max) % Check the dimensions of this label
                    join3D(CC.PixelIdxList{i})=true;     
        end
    end

implay(join3D)
implay(Imat*5)

end
