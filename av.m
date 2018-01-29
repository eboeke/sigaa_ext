function av(subjectcode,eyetrack,screenStuff)
% runs avoidance phase of experiment for subjects in master condition.
%args:
%   subjectcode, a string
%   eyetrack, a bool indicating whether eyetracking data is being collected
%   screenStuff, a struct with info necessary to use Psychtoolbox's screen
%functions
try
    window = screenStuff.winPtr;
    windowRect = screenStuff.winRect;
    screenNumber = screenStuff.number;

    %determine version etc based on subject code. 
    components = regexp(subjectcode,regexptranslate('escape','_'),'split'); %split up subjectcode into components

    sub_num = components{1};
    task_version = components{2};
    condition =components{3};
    if strcmp(condition(1),'m')
        if length(condition)==2
            if strcmp(condition(2),'i')
                instruction_type = 2;
            elseif strcmp(condition(2),'n')
                instruction_type = 1;
            end
        end
    end

    task_version = str2double(task_version);
    if(ceil(task_version/4)==1) %if task version 1:4, order 1
        order = 1;
        face_version = task_version;
    else
        order = 2;
        face_version = task_version-4;
    end



    %task parameters
    nTrials = 48; %number of trials
    initial_ITI_dur = 10;
    trial_dur = 6; %duration of trial
    grid_cols = 10; %number of columns in the grid 
    grid_rows = 5; %number of rows in the grid
    shock_duration = .2;
    fix_height = .25;
    grid_scale = 1.5; %amount to scale the grid by, sizewise
    cs_scale = 1.5;
    goal_reached = 0; % this will mark, on a given trial, whether the "goal" n position was reached
    goal = 1; % set this up and save for later, to mark what the "goal" n position is on a given trial
    move_number = 0; % this will track # moves made
    fix_string = ['+']; %string to present during fixation
    %order/response matrix
    av.av_mtx = nan(nTrials,11);
    %column indices for av mtx:
    trial_idx = 1; % lists trial number
    cstype_idx = 2;
    cs_offset_idx = 3;
    iti_offset_idx = 4;
    cs_onset_act_idx = 5;
    cs_offset_act_idx = 6;
    iti_onset_act_idx = 7;
    iti_offset_act_idx = 8;
    num_moves_idx = 9;
    shocked_idx = 10;
    shock_onset_idx = 11;

    %the moves made, with a row for each move (not a row for each trial, as
    %above. 
    av.allmoves = nan(nTrials*40,5); % this part of the struct lists all 
    AM_trial_idx = 1;
    AM_time = 2; %time of button press
    AM_key = 3;% button pressed
    AM_m = 4; %m position
    AM_n = 5;%n position

    KbName('UnifyKeyNames'); %Unify key names--makes mapping betw mac and pc easier
    left = KbName('leftArrow');   %left arrow key code
    right = KbName('rightArrow');   %right arrow key code
    up = KbName('upArrow'); % up arrow key code
    down = KbName('downArrow'); %down arrow key code
    quit_key = KbName('q'); % definte a quit key
    space = KbName('space');
    expkey = KbName('`~');
    end_text = ['You have completed this part of the experiment.\n'...
        'Please let the experimenter know.'];

    %CS values (numeric representation of variables)
    csp_val = 1;
    csm_val = 2;
    CSmap = {'CSp','CSm'};

    %set orders
    if order==1
        %set iti durations
        ITI_durs = [10 10 8 10 12 8 8 12 8 12 12 10 8 10 8 10 10 8 8 10 8 12 8 ...
            12 10 12 10 10 12 8 12 12 8 12 12 10 12 8 8 10 8 10 12 8 12 10 12 10];
        %set stim order
         av.av_mtx(:,cstype_idx) = [1 2 1 2 1 1 1 2 2 1 2 2 1 1 2 1 1 2 2 2 1 1 2 2 1 1 2 1 1 1 2 1 2 1 2 2 2 1 2 2 1 2 1 1 2 2 1 2];
    elseif order==2
        ITI_durs = [12 8 12 8 12 10 10 12 10 8 12 12 10 10 12 12 10 10 8 10 12 ...
            10 8 10 8 10 8 8 10 8 10 12 10 8 8 12 8 8 10 12 8 12 8 12 12 8 10 12]
        av.av_mtx(:,cstype_idx) = [2 1 2 1 2 2 2 1 2 1 1 2 2 1 1 1 2 1 1 2 2 1 1 2 2 1 2 1 1 2 2 2 1 2 1 2 1 2 2 1 1 1 2 1 1 2 2 1];

    end
    av.av_mtx(1,iti_offset_idx) = initial_ITI_dur + trial_dur + ITI_durs(1);%calculate time after first trial + ITI afterwards elapses
    av.av_mtx(1,cs_offset_idx) =initial_ITI_dur+trial_dur; %calculate time after first trial elapses 

    %set trial timing
    for x = 2:nTrials %makes a vectors of times that trials and ITIs should end, with respect to the start of the first ITI.
        av.av_mtx(x,cs_offset_idx) = av.av_mtx(x-1,cs_offset_idx)+ ITI_durs(x-1)+ trial_dur ;
        av.av_mtx(x,iti_offset_idx) = av.av_mtx(x-1,iti_offset_idx) + trial_dur + ITI_durs(x);
    end

    %file naming stuff
    root = pwd; %name the parent folder
    stim_folder = 'stims/';
    results_dir =  fullfile(root,'task_results'); %name the folder where data will go
    results_mat_file = fullfile(results_dir,sprintf('%s_av_task.mat',subjectcode)); %name matlab file
    results_txt_file = fullfile(results_dir,sprintf('%s_av_task.txt',subjectcode)); %name text file
    if exist(results_txt_file,'file') ==2 %if the file exists
        disp('the specified file exists already. Please enter a different subject code.');
        return;
    end

    black = BlackIndex(screenNumber);

    grids = zeros(grid_rows,grid_cols);
    % Set up textures. 
    for m = 1:grid_rows
        for n = 1:grid_cols
            if (n == 5) | (n == 6) %if 5th/6th column, only want to make version with circle in row 3
                if m ==3
                    img = imread([[stim_folder,'g'] num2str(n) '_' num2str(m) '.jpg']); %set "img" to the grid image.
                    tex = Screen('MakeTexture',window,img); %make a texture with the image
                    eval(['grid_' num2str(n) '_' num2str(m) '= tex;']); %save texture to the correct name.
                    grids(m,n) = tex; %store grid texture pointers 
                end
            else
                img = imread([[stim_folder,'g'] num2str(n) '_' num2str(m) '.jpg']); %set "img" to the grid image
                tex = Screen('MakeTexture',window,img); %make a texture with the image
                eval(['grid_' num2str(n) '_' num2str(m) '= tex;']); %save texture to the correct name.
                grids(m,n) = tex; 
            end
        end
    end


    %assign CS images
    switch face_version
        case 1
            CSp_img =  imread([stim_folder,'CS1.jpg']);
            CSm_img =  imread([stim_folder,'CS2.jpg']);
        case 2
            CSp_img =  imread([stim_folder,'CS2.jpg']);
            CSm_img =  imread([stim_folder,'CS1.jpg']); 
        case 3
            CSp_img =  imread([stim_folder,'CS3.jpg']);
            CSm_img =  imread([stim_folder,'CS4.jpg']);
        case 4
            CSp_img =  imread([stim_folder,'CS4.jpg']);
            CSm_img =  imread([stim_folder,'/CS3.jpg']);
    end

    %make texture for CSs
    CSp = Screen('MakeTexture',window,CSp_img); %make a texture with the image
    CSm = Screen('MakeTexture',window,CSm_img); %make a texture with the image

    %get size of grid
    grid_n_pixels = size(img,2); % number of pixels in grid in n direction
    grid_m_pixels = size(img,1) ;% number of pixels in grid in m direction

    %get size of CSs
    cs_n_pixels = size(CSp_img,2); 
    cs_m_pixels = size(CSp_img,1);

     %figure out where edges of images go
     %cs:
     cs_height = .2;
     left_edge_cs = (windowRect(3) - cs_n_pixels*cs_scale)/2; %left edge
     top_edge_cs = (windowRect(4) - cs_m_pixels*cs_scale)*cs_height; % top edge
     right_edge_cs = left_edge_cs + cs_n_pixels*cs_scale;
     bottom_edge_cs = top_edge_cs + cs_m_pixels*cs_scale;
     position_cs = [left_edge_cs top_edge_cs right_edge_cs bottom_edge_cs];
     position_cs_left = [left_edge_cs-250 top_edge_cs+150 right_edge_cs-250 bottom_edge_cs+150];
     position_cs_right = [left_edge_cs+250 top_edge_cs+150 right_edge_cs+250 bottom_edge_cs+150];

     %grid:
     grid_height_task = .7;
     left_edge_grid = (windowRect(3) - grid_n_pixels*grid_scale)/2; %left edge where grid will appear in instructions
     right_edge_grid = left_edge_grid + grid_n_pixels*grid_scale;
     top_edge_grid = (windowRect(4) - grid_m_pixels)*grid_height_task; % top edge
     bottom_edge_grid = (top_edge_grid + grid_m_pixels*grid_scale);
     position_grid = [left_edge_grid top_edge_grid right_edge_grid bottom_edge_grid];


     %open text file
     fid = fopen(results_txt_file,'a');

     %put time stamp in text file
     fprintf(fid,'\n%d\t%d\t%d\t%d\t%d\t%2.3f\n\n',clock);

     %list the parent directory
     fprintf(fid, '%s\n\n',root);

     %delineate name of tabs in text file
     % write a header row to the text file describing what's in each of the columns
     fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'Trial_number', ...
     'CS_type','CS_offset_scheduled', 'ITI_offset_scheduled','CS_onset_actual', 'CS_offset_actual', ...
     'ITI_onset_actual', 'ITI_offset_actual', 'Num_moves', 'Shocked?','Shock_onset');

     HideCursor; % hide the cursor

     %initialize KB tools,etc
     [~,~,keyCode]=KbCheck; % set up Keycode vector before any buttons have been pressed

     GetSecs;
     WaitSecs(.1);
     KbReleaseWait();
     KbReleaseWait(-1); %this solved the issue of the circle moving too fast in the first trial

     %***************************

     %initialize shock stuff
     object = io64;
     status = io64(object);
     if status~=0
         error('cannot access parallel port.')
     end
     address = hex2dec('C020');
     io64(object,address,0);

     % lptwrite(888,0);
     %***************************
     inst_start = GetSecs(); 
     av.checkcorrect = av_instructions(instruction_type,window,windowRect,grids,position_grid,CSp,CSm,position_cs_left,position_cs_right);
     av.instruction_duration = GetSecs-inst_start;
     % ----------------------------INITIAL FIXATION----------------------------

     %eye tracker code
     if(eyetrack)
        Eyelink('StartRecording');
     end

     % put fixation cross up
     DrawFormattedText(window, fix_string, 'center', windowRect(3)*fix_height, black);
     [~,exp_onset]=  Screen('Flip', window);  %flip the screen, record experiment onset


     %while loop for initial ITI
     while (GetSecs < exp_onset + initial_ITI_dur) %while ITI time (minus anticipation time) has not elapsed
        [~,~,keyCode]=KbCheck; %check for a key press
        keyCodeNum = find(keyCode==1);
        if (keyCodeNum == quit_key) %check for quit key, quit if pressed
            Screen('closeall');
            Priority(0);
            ShowCursor;
            disp('... The program was terminated manually.');
            RestrictKeysForKbCheck([]);
             fclose(fid);
            return;
        end
    end

    keyCode = zeros(size(keyCode)); %***this line seems to have solved first trial jumping problem.
    % ----------------------------BEGIN TRIALS----------------------------

    RestrictKeysForKbCheck([left, right, up, down, quit_key]); % make it so only arrow keys can be read in
    %set initial [position
    m = 2; n = 1;
    % for loop--goes through all trials
    for x = 1:nTrials 
        av.av_mtx(x,trial_idx) = x; % set the trial number
        av.av_mtx(x,num_moves_idx) = 0;
        % set up "goal" n position
        if n<6 % if we're on the left
            goal = 7; % the goal is the rightmost column
        else
            goal = 4; % otherwise, the goal is the leftmost column
        end
        
        
        Screen('DrawTexture', window,eval(CSmap{av.av_mtx(x,cstype_idx)}),[], position_cs, 0);%display cs picture
        Screen('DrawTexture', window, eval(['grid_' num2str(n) '_' num2str(m)]), [], position_grid, 0); % put the grid(starting position) on the screen 
        Screen(window, 'Flip');
        %***************************
        io64(object,address,1); %send marker to acqknowledge
        %***************************
        av.av_mtx(x,cs_onset_act_idx) = GetSecs - exp_onset; % record the onset time of this grid trial
        %send event marker to eyelink
        if eyetrack
            Eyelink('Message', [CSmap{av.av_mtx(x,cstype_idx)} '_on']);
        end

        %below is a while loop that goes as long as it has been less than 6
        %seconds. if there is an arrow key press, the appropriate move is made
        %and recorded.

        while (GetSecs - exp_onset)<=av.av_mtx(x,cs_offset_idx)-shock_duration % while it's been less than 6 secs

            if sum(keyCode)>1 %if 2 buttons pressed at once, act like nothing has been pressed.
                keyCode = keyCode*0; %did this do something weird? sometimes slow or something
            end

            keyCodeNum = find(keyCode==1); %figure out which key has been pressed.
            if(keyCodeNum) % if something has been pressed, update m and n pos and flip the screen. no need to update screen if nothing has been pressed   
               if(av.av_mtx(x,cstype_idx)==csp_val) % if CS+ trial
                   switch keyCodeNum
                   case  left
                        if n > 1
                            if (n ~=7 | (n == 7 & m ==3))%only proceed if not against middle wall
                                n = n - 1;
                                move_number = move_number+1;
                                av.av_mtx(x,num_moves_idx) = av.av_mtx(x,num_moves_idx) + 1;%increment the move number for this trial
                                av.allmoves(move_number,AM_trial_idx) = x; %increment the overall move number and record details of move.
                                av.allmoves(move_number,AM_time) = GetSecs - exp_onset;
                                av.allmoves(move_number,AM_key) = keyCodeNum;
                                av.allmoves(move_number,AM_m) = m;
                                av.allmoves(move_number,AM_n) = n;
                            end
                        end

                    case right
                        if  n < grid_cols
                            if (n ~=4 | (n == 4 & m ==3))%only proceed if not against middle wall
                                n = n + 1;
                                move_number = move_number+1;
                                av.av_mtx(x,num_moves_idx) = av.av_mtx(x,num_moves_idx) + 1;
                                av.allmoves(move_number,AM_trial_idx) = x; %increment the overall move number and record details of move.
                                av.allmoves(move_number,AM_time) = GetSecs - exp_onset;
                                av.allmoves(move_number,AM_key) = keyCodeNum;
                                av.allmoves(move_number,AM_m) = m;
                                av.allmoves(move_number,AM_n) = n;
                            end
                        end
                    case up
                        if m > 1
                            if (n ~= 5 & n ~= 6) %don't go up if in tunnel
                                m = m - 1;
                                move_number = move_number+1;
                                av.av_mtx(x,num_moves_idx) = av.av_mtx(x,num_moves_idx) + 1;
                                av.allmoves(move_number,AM_trial_idx) = x; %increment the overall move number and record details of move.
                                av.allmoves(move_number,AM_time) = GetSecs - exp_onset;
                                av.allmoves(move_number,AM_key) = keyCodeNum;
                                av.allmoves(move_number,AM_m) = m;
                                av.allmoves(move_number,AM_n) = n;
                            end
                        end
                    case down
                        if m < grid_rows 
                            if (n ~= 5 & n ~= 6) %don't go down if in tunnel
                                m = m + 1;
                                move_number = move_number+1;
                                av.av_mtx(x,num_moves_idx) = av.av_mtx(x,num_moves_idx) + 1;
                                av.allmoves(move_number,AM_trial_idx) = x; %increment the overall move number and record details of move.
                                av.allmoves(move_number,AM_time) = GetSecs - exp_onset;
                                av.allmoves(move_number,AM_key) = keyCodeNum;
                                av.allmoves(move_number,AM_m) = m;
                                av.allmoves(move_number,AM_n) = n;
                            end
                        end
                    case quit_key %if user quits, end program
                        Screen('closeall');
                        Priority(0);
                        ShowCursor;
                        disp('... The program was terminated manually.');
                        RestrictKeysForKbCheck([]);
                        return;
                   end
                   
                   if n == goal
                       goal_reached = 1; %flag if subject reached goal state
                   end
                   Screen('DrawTexture', window,eval(CSmap{av.av_mtx(x,cstype_idx)}),[], position_cs, 0); %load the cs
                   Screen('DrawTexture', window, eval(['grid_' num2str(n) '_' num2str(m)]), [], [position_grid], 0); %load the new grid
                   % Flip to the screen
                   Screen('Flip', window);

                   KbReleaseWait(-1,exp_onset+av.av_mtx(x,cs_offset_idx)-shock_duration);
               else
                   move_number = move_number+1;
                   av.av_mtx(x,num_moves_idx) = av.av_mtx(x,num_moves_idx) + 1;
                   av.allmoves(move_number,AM_trial_idx) = x; %increment the overall move number and record details of move.
                   av.allmoves(move_number,AM_time) = GetSecs - exp_onset;
                   av.allmoves(move_number,AM_key) = keyCodeNum;
                   KbReleaseWait(-1,exp_onset+av.av_mtx(x,cs_offset_idx));
               end
            end

            %check if need to make AllMoves matrix bigger (if 3/4 of length
            %used up)
            if (av.allmoves(ceil(length(av.allmoves)*3/4),1)>1)
               av.allmoves = vertcat(av.allmoves,nan(nTrials*20,5));
               disp('Extended AllMoves mtx')
            end   
            [~,~,keyCode]=KbCheck; % this is where it actually checks for what key is being pressed.
            WaitSecs(0.001); % avoid CPU hogging

        end

        %GRID OVER
        % SHOCK:
        if(av.av_mtx(x,cstype_idx)==csp_val)
            if ~goal_reached %if goal not reached, shock.
                %***************************

                io64(object,address,100); %send shock
                io64(object,address,1);

                 %***************************
                av.av_mtx(x,shocked_idx) = 1; %record info ab shock
                av.av_mtx(x,shock_onset_idx) = GetSecs-exp_onset;
            end
        end
        while(GetSecs-exp_onset < av.av_mtx(x,cs_offset_idx))
           WaitSecs(.001);
        end
        av.av_mtx(x,cs_offset_act_idx) = GetSecs - exp_onset; %record cs offset time
        %clear port
        %***************************
        io64(object,address,0); %clear port
        %***************************
        %----------------------------ITI AFTER TRIAL----------------------------
        Screen('DrawTexture', window, eval(['grid_' num2str(n) '_' num2str(m)]), [], position_grid, 0); %load the new picture
        DrawFormattedText(window, fix_string, 'center',windowRect(3)*fix_height, black);% draw ITI and record time of onset
        [~,ITI_onset]=  Screen('Flip', window);  
        av.av_mtx(x,iti_onset_act_idx) = ITI_onset - exp_onset;
        %send event marker to eyelink
        if eyetrack
            Eyelink('Message', [CSmap{av.av_mtx(x,cstype_idx)} '_off']);
        end

        while (GetSecs < exp_onset + av.av_mtx(x,iti_offset_idx)) %while ITI time (minus anticipation time) has not elapsed
            [~,~,keyCode]=KbCheck;
            keyCodeNum = find(keyCode==1);
            if (keyCodeNum == quit_key) %check for quit key, quit if pressed
                Screen('closeall');
                Priority(0);
                ShowCursor;
                fclose(fid);
                disp('... The program was terminated manually.');
                RestrictKeysForKbCheck([]);
                return;
            end
        end


        av.av_mtx(x,iti_offset_act_idx) = GetSecs - exp_onset; %record ITI offset time

        %print tab delimited results from this trial to text file
        fprintf(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ...
                av.av_mtx(x,:));

        save(results_mat_file, '-struct', 'av'); %save mat file
        goal_reached = 0; % reset goal reached variable
        keyCode = keyCode*0; %refresh keyCode before next trial

    end
    if(eyetrack)
        Eyelink('StopRecording');
    end

    inst_text(window,end_text,0,0,quit_key,expkey);

catch
    % Clear the screen.
    Screen('CloseAll'); 
    %switch Matlab/Octave back to priority 0 -- normal priority:
    Priority(0);
    rethrow(lasterror)
end
%allow kbcheck to look for all keys again
RestrictKeysForKbCheck([]);

%close connection to text file
fclose(fid);

end


