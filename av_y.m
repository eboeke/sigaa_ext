function av_y(subjectcode,eyetrack,screenStuff)
% runs avoidance phase of experiment for subjects in yoke condition.
%args:
%   subjectcode, a string
%   eyetrack, a bool indicating whether eyetracking data is being collected
%   screenStuff, a struct with info necessary to use Psychtoolbox's screen
%functions
try
    window = screenStuff.winPtr;
    windowRect = screenStuff.winRect
    screenNumber = screenStuff.number

    %determine version etc based on subject code. 
    components = regexp(subjectcode,regexptranslate('escape','_'),'split'); %split up subjectcode into components

    sub_num = components{1};
    task_version = components{2};
    condition =components{3};

    task_version = str2double(task_version);

    if(ceil(task_version/4)==1) %if task version 1:4, order 1
        order = 1;
        face_version = task_version;
    else
        order = 2;
        face_version = task_version-4;
    end


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
    master_file = dir(['task_results/',sub_num,'_',num2str(task_version),'_m*_av_task.mat']);


    master_file = load(['task_results/',master_file.name]);
    %task parameters
    nTrials = 48; %number of trials
    initial_ITI_dur = 10;
    trial_dur = 6; %duration of trial
    shock_duration = .2;
    fix_height = .25;
    grid_scale = 1.5; %amount to scale the grid by, sizewise
    cs_scale = 1.5;
    move_number = 0; % this will track # moves made
    fix_string = ['+']; %string to present during fixation
    av.inst_duration = 0; %will record duration of instructions/practice
    pre_inst = 0; %will record  onset of instructions.
    num_cells = 42; %num cells in the grid
    num_gridvers = 3; %number of configurations of each grid
    num_circles = 1; %will state the number of circles on each trial.
    %order/response matrix
    av.av_mtx = nan(nTrials,13);
    %column indices for av mtx:
    trial_idx = 1; % lists trial number
    cstype_idx = 2;
    cs_offset_idx = 3;
    iti_offset_idx = 4;
    cs_onset_act_idx = 5;
    cs_offset_act_idx = 6;
    iti_onset_act_idx = 7;
    iti_offset_act_idx = 8;
    num_moves_masters_idx = 9;
    num_circles_idx = 9;
    shocked_idx = 10;
    shock_onset_idx = 11;
    grid_version_idx = 12;
    num_moves_yoke_idx = 13;



    %get task info from master file
    av.av_mtx(:,cstype_idx) = master_file.av_mtx(:,cstype_idx);
    av.av_mtx(:,iti_offset_idx) = master_file.av_mtx(:,iti_offset_idx);
    av.av_mtx(:,cs_offset_idx) = master_file.av_mtx(:,cs_offset_idx);
    av.av_mtx(:,num_circles_idx) = master_file.av_mtx(:,num_moves_masters_idx);
    av.av_mtx((av.av_mtx(:,num_circles_idx)>42),num_circles_idx) = 42;  %on trials where master made more than 42 trials, put 42 circles (can't do more)
    av.av_mtx(:,shocked_idx) = master_file.av_mtx(:,shocked_idx);


    %set versions of grids
    %there are 3 versions.
    %find out which # circles they will see, and how many times of each.
    rand('state',sum(100*clock)); %reseed the random number generator

    circlenums = unique(av.av_mtx(:,num_circles_idx)); %get a vector of unique values with # circles
    for i = 1:length(circlenums)
        %for each # circles, divide by the # of versions (round down and get remainder)
        copies_idx = av.av_mtx(:,num_circles_idx)==circlenums(i);
        copies = sum(copies_idx);
        copies_per_version = floor(copies/num_gridvers);
        copies_remainder = rem(copies,num_gridvers);
        %make a list with an even (rounded down) number of each version
        version_list = [ones(copies_per_version,1); 2*ones(copies_per_version,1); 3*ones(copies_per_version,1)];
        if copies_remainder
            remainder_list = randperm(num_gridvers,copies_remainder)'; %for remainder, randomly select from the different versions
            version_list = [version_list; remainder_list]; %add to the list
        end
        version_list = version_list(randperm(length(version_list))); % scramble version list
        %assign versions to proper row of matrix.
        av.av_mtx(copies_idx,grid_version_idx)=version_list;
    end
    %the moves made, with a row for each move (not a row for each trial, as
    %above. 
    av.allmoves = nan(nTrials*40,3); % this part of the struct lists info about all of the moves
    AM_trial_idx = 1;
    AM_time = 2; %time of button press
    AM_key = 3;% button pressed


    %file naming stuff
    root = pwd; %name the parent folder
    stim_folder = 'stims/';
    results_dir =  fullfile(root,'task_results'); %name the folder where data will go
    results_mat_file = fullfile(results_dir,sprintf('%s_av_task.mat',subjectcode)); %name matlab file
    results_txt_file = fullfile(results_dir,sprintf('%s_av_task.txt',subjectcode)); %name text file

    %check if there are any other yokes with this sub number
    KbReleaseWait();
    FlushEvents('keyDown');  
    [keyIsDown, secs, keyCode] = KbCheck(-1);



    black = BlackIndex(screenNumber);

    grids = zeros(num_cells,num_gridvers);
    % Set up textures. 
    for m = 1:num_cells
        for n = 1:num_gridvers
                    img = imread([stim_folder num2str(m) '_' num2str(n) '.jpg']); %set "img" to the grid image.
                    tex = Screen('MakeTexture',window,img); %make a texture with the image
                    eval(['grid_' num2str(m) '_' num2str(n) '= tex;']); %save texture to the correct name.
                    grids(m,n) = tex; %store grid texture pointers 
        end
    end
    %0 0 grid
    img = imread([stim_folder,'0_0.jpg']);
    grid_0_0 = Screen('MakeTexture',window,img);
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
            CSm_img =  imread([stim_folder,'CS3.jpg']);
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
    fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'Trial_number', ...
    'CS_type','CS_offset_scheduled', 'ITI_offset_scheduled','CS_onset_actual', 'CS_offset_actual', ...
    'ITI_onset_actual', 'ITI_offset_actual', 'Num_circles', 'Shocked?','Shock_onset','Grid version','Num_presses');

    HideCursor; % hide the cursor

    %initialize KB tools,etc
    [~,~,keyCode]=KbCheck; % set up Keycode vector before any buttons have been pressed

    GetSecs;
    WaitSecs(.1);
    KbReleaseWait();
    KbReleaseWait(-1); %this solved the issue of the circle moving too fast in the first trial

    %initialize shock stuff
    %***************************
    object = io64;
    status = io64(object);
    if status~=0
        error('cannot access parallel port.')
    end
    address = hex2dec('C020');
    io64(object,address,0);
    %***************************
    pre_inst = GetSecs;

    %YOKE INSTRUCTIONS!
    instruction_type = 3; %yoke instructions
    av.checkcorrect =  av_instructions(instruction_type,window,windowRect,grids,position_grid,CSp,CSm,position_cs_left,position_cs_right);
    av.inst_duration = GetSecs - pre_inst;
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
            fclose(fid);
            RestrictKeysForKbCheck([]);

            return;
        end
    end

    keyCode = zeros(size(keyCode)); %***this line seems to have solved first trial jumping problem.
    % ----------------------------BEGIN TRIALS----------------------------
    RestrictKeysForKbCheck([space, quit_key]); % make it so only arrow keys can be read in
    % for loop--goes through all trials
    for x = 1:nTrials 
        av.av_mtx(x,trial_idx) = x; % set the trial number
        av.av_mtx(x,num_moves_yoke_idx) = 0;
        num_circles = av.av_mtx(x,num_circles_idx);
        grid_version = av.av_mtx(x,grid_version_idx);

        Screen('DrawTexture', window,eval(CSmap{av.av_mtx(x,cstype_idx)}),[], position_cs, 0); %display cs picture
        if num_circles >0
        Screen('DrawTexture', window, eval(['grid_' num2str(num_circles) '_' num2str(grid_version)]), [], position_grid, 0); % put the grid
        else
            Screen('DrawTexture',window,grid_0_0,[],position_grid,0);
        end
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
            if(keyCodeNum) % if something has been pressed, record info
                if (keyCodeNum == quit_key) %if user quits, end program
                    Screen('closeall');
                    Priority(0);
                    ShowCursor;
                    disp('... The program was terminated manually.');
                    return;
                else
                   move_number = move_number+1;
                   av.av_mtx(x,num_moves_yoke_idx) = av.av_mtx(x,num_moves_yoke_idx) + 1;%increment the move number for this trial
                   av.allmoves(move_number,AM_trial_idx) = x; %increment the overall move number and record details of move.
                   av.allmoves(move_number,AM_time) = GetSecs - exp_onset;
                   av.allmoves(move_number,AM_key) = keyCodeNum;
                       if(av.av_mtx(x,shocked_idx)==1)
                           KbReleaseWait(-1,exp_onset+av.av_mtx(x,cs_offset_idx)-shock_duration);
                       else
                           KbReleaseWait(-1,exp_onset+av.av_mtx(x,cs_offset_idx));
                       end
                end
            end



            %check if need to make AllMoves matrix bigger (if 3/4 of length
            %used up)
            if (av.allmoves(ceil(length(av.allmoves)*3/4),1)>1)
               av.allmoves = vertcat(av.allmoves,nan(nTrials*20,3));
                disp('Extended AllMoves mtx')
            end   
            [~,~,keyCode]=KbCheck; % this is where it actually checks for what key is being pressed.
            WaitSecs(0.001); % avoid CPU hogging
        end

        %GRID OVER
        % SHOCK:
        if(av.av_mtx(x,shocked_idx)==1)
            %***************************

            io64(object,address,100); %send shock
            io64(object,address,1);

              %***************************
            av.av_mtx(x,shock_onset_idx) = GetSecs-exp_onset;
        end
        while(GetSecs-exp_onset < av.av_mtx(x,cs_offset_idx))
           WaitSecs(.001);
        end
        av.av_mtx(x,cs_offset_act_idx) = GetSecs - exp_onset; %record cs offset time
        %***************************
        io64(object,address,0); %clear port
        %***************************
        %----------------------------ITI AFTER TRIAL----------------------------
        Screen('DrawTexture', window, grid_0_0, [], position_grid, 0); %load the new picture
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
                RestrictKeysForKbCheck([]);

                disp('... The program was terminated manually.');
                return;
            end
        end


        av.av_mtx(x,iti_offset_act_idx) = GetSecs - exp_onset; %record ITI offset time

        %print tab delimited results from this trial to text file
        fprintf(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ...
            av.av_mtx(x,:));

        save(results_mat_file, '-struct', 'av'); %save mat file
        keyCode = keyCode*0; %refresh keyCode before next trial
    end
    
    if(eyetrack)
        Eyelink('StopRecording');
    end
    inst_text(window,end_text,0,0,quit_key,expkey);
catch
    % Clear the screen.
    Screen('CloseAll'); 
    %shut down eyetracking stuff
    if(eyetrack)
     Eyelink('ShutDown');
    end
    %switch Matlab/Octave back to priority 0 -- normal priority:
    Priority(0);
    rethrow(lasterror)
    end

    %close connection to text file
    fclose(fid);
    RestrictKeysForKbCheck([]);

end

