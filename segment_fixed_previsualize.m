function segment_fixed_previsualize(srcPath,name,Thresholdvalue,min,max) 

srcFiles = strcat(srcPath,[filesep '*.tif']);  % the folder in which ur images exists
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);

I = read_stackTiff(strcat(srcPath,filesep,name)); % read tiff stack
[f,c,p]=size(I);

Imat = mat2gray(I);

 %% BW thresholding with fixed threshold value
    Ibw = I>Thresholdvalue;

     join1D = false([f c]);
     join2D =false(size(Ibw));
                %remove small dots in 2D
                for i=1:p
                    CCbwImat(i).CC=bwconncomp(Ibw(:,:,i),4);
                    for ii=1:CCbwImat(i).CC.NumObjects
                            pixId=CCbwImat(i).CC.PixelIdxList{ii};
                                if (length(pixId)>2) 
                                    join1D(CCbwImat(i).CC.PixelIdxList{ii})=true;
                                end
                     end   
                     join2D(:,:,i)=join1D;
                     join1D = false([f c]);
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
