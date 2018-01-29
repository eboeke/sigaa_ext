function rec(subjectcode,eyetrack,screenStuff)
% runs retrieval phase of experiment for subjects in master condition.
%args:
%   subjectcode, a string
%   eyetrack, a bool indicating whether eyetracking data is being collected
%   screenStuff, a struct with info necessary to use Psychtoolbox's screen
%   functions
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



    %task parameters
    nTrials = 25; %number of trials
    initial_ITI_dur = 10;
    trial_dur = 6; %duration of trial
    fix_height = .25;
    cs_scale = 1.5;
    fix_string = ['+']; %string to present during fixation
    %order/response matrix
    rec.rec_mtx = nan(nTrials,8);
    %column indices for av mtx:
    trial_idx = 1; % lists trial number
    cstype_idx = 2;
    cs_offset_idx = 3;
    iti_offset_idx = 4;
    cs_onset_act_idx = 5;
    cs_offset_act_idx = 6;
    iti_onset_act_idx = 7;
    iti_offset_act_idx = 8;


    KbName('UnifyKeyNames'); %Unify key names--makes mapping betw mac and pc easier
    quit_key = KbName('q'); % definte a quit key
    space = KbName('space');
    expkey = KbName('`~');

    inst_1 = ['The next part of the experiment will be similar to\n'...
        'yesterday. You will see the same two faces appear on\n'...
        'the screen but today there will be no grid and you will\n'...
        'not be making any responses.\n\n'...
        'Let the experimenter know when you are ready to start.'];
    end_text = sprintf(['Time for a break. You can lean back in the chair. \n'...
        'Please let the experimenter know.']);

    %CS values (numeric representation of variables)
    csp_val = 1;
    csm_val = 2;
    CSmap = {'CSp','CSm'};

    %set orders
    if order==1
        %set iti durations
        ITI_durs=  [10 8 12 12 10 8 12 12 8 10 10 10 12 10 8 10 12 8 8 8 10 12 8 12 10]
        %set stim order
        rec.rec_mtx(:,cstype_idx) = [2 1 2 1 2 1 1 2 2 2 1 2 2 1 1 1 2 2 1 1 2 1 2 2 1]

    elseif order==2
        ITI_durs = [12 10 12 8 8 12 8 10 10 8 10 10 8 10 10 8 12 12 8 12 12 8 12 10 10]
        rec.rec_mtx(:,cstype_idx) = [2 2 1 2 1 2 2 1 2 1 1 2 1 2 1 2 2 1 1 1 2 2 1 1 2]
    end
    rec.rec_mtx(1,iti_offset_idx) = initial_ITI_dur + trial_dur + ITI_durs(1);%calculate time after first trial + ITI afterwards elapses
    rec.rec_mtx(1,cs_offset_idx) =initial_ITI_dur+trial_dur; %calculate time after first trial elapses 

    %set trial timing
    for x = 2:nTrials %makes a vectors of times that trials and ITIs should end, with respect to the start of the first ITI.
        rec.rec_mtx(x,cs_offset_idx) = rec.rec_mtx(x-1,cs_offset_idx)+ ITI_durs(x-1)+ trial_dur ;
        rec.rec_mtx(x,iti_offset_idx) = rec.rec_mtx(x-1,iti_offset_idx) + trial_dur + ITI_durs(x);
    end

    %file naming stuff
    root = pwd; %name the parent folder
    stim_folder = 'stims/';
    results_dir =  fullfile(root,'task_results'); %name the folder where data will go
    results_mat_file = fullfile(results_dir,sprintf('%s_rec_task.mat',subjectcode)); %name matlab file
    results_txt_file = fullfile(results_dir,sprintf('%s_rec_task.txt',subjectcode)); %name text file


    black = BlackIndex(screenNumber);
    
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

    %open text file
    fid = fopen(results_txt_file,'a');

    %put time stamp in text file
    fprintf(fid,'\n%d\t%d\t%d\t%d\t%d\t%2.3f\n\n',clock);

    %list the parent directory
    fprintf(fid, '%s\n\n',root);

    %delineate name of tabs in text file
    % write a header row to the text file describing what's in each of the columns
    fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'Trial_number', ...
    'CS_type','CS_offset_scheduled', 'ITI_offset_scheduled','CS_onset_actual', 'CS_offset_actual', ...
    'ITI_onset_actual', 'ITI_offset_actual');

    HideCursor; % hide the cursor

    %initialize KB tools,etc
    [~,~,keyCode]=KbCheck; % set up Keycode vector before any buttons have been pressed

    GetSecs;
    WaitSecs(.1);
    KbReleaseWait();
    KbReleaseWait(-1); %this solved the issue of the circle moving too fast in the first trial

    %initialize pp stuff
    %***************************

    object = io64;
    status = io64(object);
    if status~=0
         error('cannot access parallel port.')
    end
    address = hex2dec('C020');
    io64(object,address,0);

    %***************************
    % ----------------------------INSTRUCTIONS----------------------------

    inst_text(window,inst_1,0,0,quit_key,expkey);

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

    % ----------------------------BEGIN TRIALS----------------------------
    % for loop--goes through all trials
    for x = 1:nTrials 
        rec.rec_mtx(x,trial_idx) = x; % set the trial number

        Screen('DrawTexture', window,eval(CSmap{rec.rec_mtx(x,cstype_idx)}),[], position_cs, 0); %display cs picture
        Screen(window, 'Flip');
         %***************************
        io64(object,address,1); %send marker to acqknowledge
        %***************************
        rec.rec_mtx(x,cs_onset_act_idx) = GetSecs - exp_onset; % record the onset time of this grid trial
        %send event marker to eyelink
        if eyetrack
            Eyelink('Message', [CSmap{rec.rec_mtx(x,cstype_idx)} '_on']);
        end

        WaitSecs('UntilTime',exp_onset+rec.rec_mtx(x,cs_offset_idx));

        rec.rec_mtx(x,cs_offset_act_idx) = GetSecs - exp_onset; %record cs offset time
        %***************************

        io64(object,address,0); %clear port

        %***************************  
        %----------------------------ITI AFTER TRIAL----------------------------

        DrawFormattedText(window, fix_string, 'center',windowRect(3)*fix_height, black);% draw ITI and record time of onset
        [~,ITI_onset]=  Screen('Flip', window);  
        rec.rec_mtx(x,iti_onset_act_idx) = ITI_onset - exp_onset;
        %send event marker to eyelink
        if eyetrack
            Eyelink('Message', [CSmap{rec.rec_mtx(x,cstype_idx)} '_off']);
        end

        while (GetSecs < exp_onset + rec.rec_mtx(x,iti_offset_idx)) %while ITI time (minus anticipation time) has not elapsed
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
        
        
        rec.rec_mtx(x,iti_offset_act_idx) = GetSecs - exp_onset; %record ITI offset time

        %print tab delimited results from this trial to text file
        fprintf(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ...
            rec.rec_mtx(x,:));

        save(results_mat_file, '-struct', 'rec'); %save mat file

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
%allow kbcheck to look for all keys again
RestrictKeysForKbCheck([]);

%close connection to text file
fclose(fid);

end

