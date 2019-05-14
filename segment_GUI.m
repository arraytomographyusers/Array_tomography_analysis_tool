function [] = segment_GUI()

S.fh = figure('units','pixels',...
              'position',[800 300 150 400],...
              'menubar','none',...
              'name',' Segment',...
              'numbertitle','off',...
              'resize','off');
S.bg(1) = uibuttongroup('units','pix',...
                     'pos',[20 235 110 75]);                
S.rd(1) = uicontrol(S.bg(1),...
                    'style','rad',...
                    'unit','pix',...
                    'position',[20 40 70 25],...
                    'string','Mean');
S.rd(2) = uicontrol(S.bg(1),...
                    'style','rad',...
                    'unit','pix',...
                    'position',[20 10 70 25],...
                    'string','Median');
S.bg(2) = uibuttongroup('units','pix',...
                     'pos',[20 130 110 95]);   
                 
S.tx(5) = uicontrol(S.bg(2),...
                 'style','text',...
                 'unit','pix',...
                 'position',[5 65 90 25],...
                 'string','Filt object size');

S.tx(3) = uicontrol(S.bg(2),...
                'units','pixels',...
                 'style','text',...
                 'unit','pix',...
                 'position',[10 35 40 25],...
                 'string','From...');    
S.tx(4) = uicontrol(S.bg(2),...
                'units','pixels',...
                 'style','text',...
                 'unit','pix',...
                 'position',[10 5 40 25],...
                 'string','To...'); 
S.ed(4) = uicontrol(S.bg(2),...
                    'style','edit',...
                 'unit','pix',...
                 'position',[50 40 40 25],...
                 'string','3');    
S.ed(5) = uicontrol(S.bg(2),...
                    'style','edit',...
                 'unit','pix',...
                 'position',[50 10 40 25],...
                 'string','inf'); 
       
S.tx(1) = uicontrol('units','pixels',...
                 'style','text',...
                 'unit','pix',...
                 'position',[20 345 50 40],...
                 'string','Window size');    
S.tx(2) = uicontrol('units','pixels',...
                 'style','text',...
                 'unit','pix',...
                 'position',[20 310 50 25],...
                 'string','C factor'); 
S.ed(1) = uicontrol('style','edit',...
                 'unit','pix',...
                 'position',[80 350 50 25],...
                 'string','15');    
S.ed(2) = uicontrol('style','edit',...
                 'unit','pix',...
                 'position',[80 315 50 25],...
                 'string','1.5');
%S.ed(3) = uicontrol('style','edit',...
%                 'unit','pix',...
%                 'position',[20 100 110 30],...
%                 'string','Path unselected');             
S.pb(1) = uicontrol('style','push',...
                 'unit','pix',...
                 'position',[20 20 110 30],...
                 'string','Analyze',...
                 'callback',{@analyze,S},...
                 'enable','off');
S.pb(2) = uicontrol('style','push',...
                 'unit','pix',...
                 'position',[20 60 110 30],...
                 'string','Previsualize',...
                 'callback',{@previsualiz,S},...
                 'enable','off');
S.fm = uimenu(S.fh,...
                 'label','Select path',...
                 'callback',{@fm_call,S},...
                 'enable','on');         
% S.ch(1) = uicontrol('style','checkbox',...
%                  'unit','pix',...
%                  'position',[20 100 110 30],...
%                  'string','Intensity Norm.');
                     
S.NAME = {'No sequence selected'};

             
    function [] = analyze(varargin)
    % Callback for pushbutton.
      try
       window = get(S.ed(1),'string'); 
        factor = get(S.ed(2),'string'); 
        path = get(S.ed(3),'string');
%         norm = get(S.ch(1),'Value');
        min_size = get(S.ed(4),'string');
        max_size = get(S.ed(5),'string');
        
        min_size = str2double(min_size);
        if strcmp(max_size,'inf')
            max_size = 999999;
        else
            max_size = str2double(max_size);
        end
        
        ws = str2double(window);
        sf = str2num(factor);
       col = get(S.pb(1),'backg');  % Get the background color of the figure.
       set(S.pb(1),'str','RUNNING...','backg',[1 .6 .6]) 
       
        set(S.rd(1),{'enable'},{'off'});
        set(S.rd(2),{'enable'},{'off'});
        set(S.ed(4),{'enable'},{'off'});  
        set(S.ed(5),{'enable'},{'off'});
        set(S.ed(1),{'enable'},{'off'});  
        set(S.ed(2),{'enable'},{'off'});          
        set(S.pb(1),{'enable'},{'off'});
        set(S.pb(2),{'enable'},{'off'});
%         set(S.ch(1),{'enable'},{'off'});
        set(S.pp,{'enable'},{'off'});
        set(S.fm,{'enable'},{'off'});

        switch findobj(get(S.bg(1),'selectedobject'))
            case S.rd(1)  
                pause(.03)
                segment(path,ws,sf,'mean',min_size,max_size) 
            case S.rd(2)
                pause(.03)
                segment(path,ws,sf,'median',min_size,max_size) 
            otherwise
                set(S.ed,'string','None!') % Very unlikely I think.
        end
        pause(.01)
        set(S.pb(1),'str','Analyze','backg',col)
        set(S.rd(1),{'enable'},{'on'});
        set(S.rd(2),{'enable'},{'on'});
        set(S.ed(4),{'enable'},{'on'});  
        set(S.ed(5),{'enable'},{'on'});
        set(S.ed(1),{'enable'},{'on'});  
        set(S.ed(2),{'enable'},{'on'});          
        set(S.pb(1),{'enable'},{'on'});
        set(S.pb(2),{'enable'},{'on'});
%         set(S.ch(1),{'enable'},{'on'});
        set(S.pp,{'enable'},{'on'});
        
    catch
       try
       pause(.01)
       set(S.pb(1),'str','Analyze','backg',col)
       disp('trygui: Unable to analyze. Please check srcPath and try again')
       catch
          disp('trygui catch2: Unable to analyze. Please check srcPath and try again')
       end
    end
  % Now reset the button features.
    end



    function [] = previsualiz(varargin)
    % Callback for pushbutton.   % Get the structure.
     %   try
            window = get(S.ed(1),'string'); 
            factor = get(S.ed(2),'string'); 
            path = get(S.ed(3),'string');
%             norm = get(S.ch(1),'Value');
            
            L = get(S.pp,'Value');
            name = S.NAME{L};

            min_size = get(S.ed(4),'string');
            max_size = get(S.ed(5),'string');

            min_size = str2double(min_size);
            if strcmp(max_size,'inf')
                max_size = 999999;
            else
                max_size = str2double(max_size);
            end
            ws = str2double(window);
            sf = str2num(factor);
            fprintf('widnow size: %d \n',ws)
            fprintf('factor C: %d \n',sf)
            fprintf('min object size: %d \n',min_size)
            fprintf('max object size: %d \n',max_size)
            fprintf('srcPath: %s \n',path)
            fprintf('seqName: %s \n',name)
%             fprintf('Intensity Normalization: %d \n',norm)

            col = get(S.pb(2),'backg');  % Get the background color of the figure.
            pause(.01)
            set(S.pb(2),'str','RUNNING...','backg',[1 .6 .6]) % Change color of button. 

            switch findobj(get(S.bg(1),'selectedobject'))
                case S.rd(1)
                    segment_previsualize(path,name,ws,sf,'mean',min_size,max_size) 
            %        surface(path,name)
            %        close(S)
                case S.rd(2)
                    segment_previsualize(path,name,ws,sf,'median',min_size,max_size) 
            %        surface(path,name)
            %        close(S)
                otherwise
                    set(S.ed,'string','None!') % Very unlikely I think.
            end    
            pause(.01)
            set(S.pb(2),'str','Previsualize','backg',col)  
            % Now reset the button features.
%         catch
%              try
%                 pause(.01)
%                 set(S.pb(2),'str','Previsualize','backg',col)
%                 disp('Unable to previsualize. Please check srcPath and try again')
%              catch
%                 disp('Unable to previsualize. Please check srcPath and try again')
%              end
%         end
    end

    function [] = fm_call(varargin)     
         try
            S.fh(2) = figure('units','pixels',...
                 'position',[470 250 300 100],...
                 'name','Select sequence to previsualize',...
                 'menubar','none',...
                 'numbertitle','off');
            S.ed(3) = uicontrol('units','pixels',...
                  'style','edit',...
                  'unit','pix',...
                  'position',[20 55 260 30],...
                   'string','No path selected');
               
            set(S.fh(1),'CloseRequestFcn', @preCloseMain);
            srcPath = uigetdir('Select the sequence path'); %DIRECTORI  ON ESTAN LES IMATGES
            Files = strcat(srcPath,[filesep '*.tif']);  % the folder in which ur images exists
            srcFiles = dir(Files);
            
            for i=1:length(srcFiles)
                names{i} = srcFiles(i).name;
            end
            S.NAME = names;
            
            set(S.ed(3),'string',srcPath);
            S.pp = uicontrol(S.fh(2),...
                    'style','popupmenu',...
                    'unit','pixels',...
                    'position',[20 15 260 30],...
                    'string',S.NAME);
                set(S.pb,{'enable'},{'on'});
         catch
            disp('Unable to Load.  Check Name and Try Again.')
         end
    end

    function preCloseMain(varargin)
      try 
%        fprintf('Closing non-main figures!\n');
        close(S.fh(2));
        
        handles=findall(0,'type','figure'); % find all handles opened
        close(handles);
      end 
%      fprintf('Closing main figure!\n');     
      delete(S.fh(1));
    end

end