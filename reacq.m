function reacq(subjectcode,eyetrack,screenStuff)
% runs reacquisition phase of experiment for subjects in master condition.
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
    nTrials = 32; %number of trials
    initial_ITI_dur = 8; %duration of ITI (including anticipation time, when cross is red)
    trial_dur = 6; %duration of trial
    shock_duration = .2;
    fix_height = .25;
    cs_scale = 1.5;
    fix_string = ['+']; %string to present during fixation
    %order/response matrix
    reacq.reacq_mtx = nan(nTrials,10);
    reacq.checkcorrect = 0; 
    %column indices for av mtx:
    trial_idx = 1; % lists trial number
    cstype_idx = 2;
    cs_offset_idx = 3;
    iti_offset_idx = 4;
    cs_onset_act_idx = 5;
    cs_offset_act_idx = 6;
    iti_onset_act_idx = 7;
    iti_offset_act_idx = 8;
    shocked_idx = 9;
    shock_onset_idx = 10;

    KbName('UnifyKeyNames'); %Unify key names--makes mapping betw mac and pc easier
    quit_key = KbName('q'); % definte a quit key
    space = KbName('space');
    expkey = KbName('`~');
    one = KbName('1!');
    two = KbName('2@');

    inst_1 =['In this part of the study you are going to see\n'...
        'two new faces.\n\n'...
        'Press the space bar to continue.'];
    inst_2 =['Here are the two faces.\n\n\n\n\n\n\n\n\n\n'...
        'Press the space bar to continue.'];
    inst_3 = ['Again, one face will be the threat face, and will\n'...
        'sometimes be paired with shock, while the other face,\n'...
        'the no-threat face, will never be paired with shock.\n\n'...
        'Press the space bar to continue.'];
    inst_4 = ['In between each face, you''','ll see a plus sign (+)\n'...
        'in the center of the screen. During this time you will\n'...
        'never be shocked and you should focus your gaze\n'...
        'on the plus sign.\n\n'...
        'Press the space bar to continue.'];
    inst_5 = ['Your task is to figure out which face is sometimes\n'...
        'paired with shock (the threat face) and which is not\n'...
        '(the no-threat face). We will ask you about it later.\n'...
        'You won''','t make any responses during this part--just \n'...
        'pay attention.\n\n'...
        'Press the space bar to continue.'];
    inst_6 = ['Let the experimenter know when you are ready to start.'];
    check1 = ['Which one of these is the threat face? Press the ''','1''','\n'...
        'key for the face on the left and the ''','2''','  key for the face\n'...
        'on the right.'];
    end_text = sprintf(['You have completed this part of the experiment. \n'...
        'Please let the experimenter know.']);

    %CS values (numeric representation of variables)
    CSp_val = 1;
    CSm_val = 2;
    CSpu_val = 3;
    CSmap = {'CSp','CSm','CSp'};

    %set orders
    if order==1
        %set iti durations
        ITI_durs = [12 12 10 8 12 12 8 12 10 8 12 10 10 12 8 10 10 8 10 10 12 12 10 8 8 10 8 12 10 8 12 8]
        reacq.reacq_mtx(:,cstype_idx) = [ 3 1 2 3 1 2 1 3 1 2 2 3 2 1 1 1 2 3 2 1 3 2 3 2 1 1 2 3 1 1 2 2]

    elseif order==2
       ITI_durs = [8 12 10 12 10 12 8 10 10 8 8 10 12 10 8 10 8 ...
            10 12 8 12 12 8 12 10 10 8 12 12 10 8 12]
       reacq.reacq_mtx(:,cstype_idx) = [CSpu_val CSm_val CSp_val CSpu_val CSm_val CSm_val CSp_val...
            CSpu_val CSp_val CSm_val CSpu_val CSp_val CSm_val CSp_val CSm_val CSpu_val CSpu_val...
            CSm_val CSp_val CSp_val CSpu_val CSm_val CSp_val CSp_val CSm_val CSm_val CSm_val...
            CSpu_val CSm_val CSp_val CSp_val CSp_val];

    end
    reacq.reacq_mtx(1,iti_offset_idx) = initial_ITI_dur + trial_dur + ITI_durs(1);%calculate time after first trial + ITI afterwards elapses
    reacq.reacq_mtx(1,cs_offset_idx) =initial_ITI_dur+trial_dur; %calculate time after first trial elapses 

    %set trial timing
    for x = 2:nTrials %makes a vectors of times that trials and ITIs should end, with respect to the start of the first ITI.
        reacq.reacq_mtx(x,cs_offset_idx) = reacq.reacq_mtx(x-1,cs_offset_idx)+ ITI_durs(x-1)+ trial_dur ;
        reacq.reacq_mtx(x,iti_offset_idx) = reacq.reacq_mtx(x-1,iti_offset_idx) + trial_dur + ITI_durs(x);
    end

    %file naming stuff
    root = pwd; %name the parent folder
    stim_folder = 'stims/';
    results_dir =  fullfile(root,'task_results'); %name the folder where data will go
    results_mat_file = fullfile(results_dir,sprintf('%s_reacq_task.mat',subjectcode)); %name matlab file
    results_txt_file = fullfile(results_dir,sprintf('%s_reacq_task.txt',subjectcode)); %name text file
    if exist(results_txt_file,'file') ==2 %if the file exists
        disp('the specified file exists already. Please enter a different subject code.');
        return;
    end



    black = BlackIndex(screenNumber);

    %assign CS images
    switch face_version
        case 1
            CSp_img =  imread([stim_folder,'CS3.jpg']);
            CSm_img =  imread([stim_folder,'CS4.jpg']);
        case 2
            CSp_img =  imread([stim_folder,'CS4.jpg']);
            CSm_img =  imread([stim_folder,'CS3.jpg']); 
        case 3
            CSp_img =  imread([stim_folder,'CS1.jpg']);
            CSm_img =  imread([stim_folder,'CS2.jpg']);
        case 4
            CSp_img =  imread([stim_folder,'CS2.jpg']);
            CSm_img =  imread([stim_folder,'CS1.jpg']);
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
    pos_left = [left_edge_cs-250 top_edge_cs+150 right_edge_cs-250 bottom_edge_cs+150];
    pos_right = [left_edge_cs+250 top_edge_cs+150 right_edge_cs+250 bottom_edge_cs+150];

    %open text file
    fid = fopen(results_txt_file,'a');

    %put time stamp in text file
    fprintf(fid,'\n%d\t%d\t%d\t%d\t%d\t%2.3f\n\n',clock);

    %list the parent directory
    fprintf(fid, '%s\n\n',root);

    %delineate name of tabs in text file
    % write a header row to the text file describing what's in each of the columns
    fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'Trial_number', ...
    'CS_type','CS_offset_scheduled', 'ITI_offset_scheduled','CS_onset_actual', 'CS_offset_actual', ...
    'ITI_onset_actual', 'ITI_offset_actual', 'Shocked?','Shock_onset');

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
     % ----------------------------INSTRUCTIONS----------------------------

     inst_text(window,inst_1,0,0,quit_key,space);
     Screen('DrawTexture', window, CSp, [], pos_left, 0);
     Screen('DrawTexture', window, CSm, [], pos_right, 0);
     DrawFormattedText(window, inst_2,'center', 100, 0, [],[],[],2); %draw text
     Screen('Flip', window);
     RestrictKeysForKbCheck([quit_key, space]);
     while ~KbCheck
     end
     [~,~, keyCode]=KbCheck; 
 
     KbReleaseWait; %wait for key to be released
     keyCodeNum = find(keyCode==1); %see which key was pressed
     if keyCodeNum == quit_key %if user quits, end program
         Screen('closeall');
         Priority(0);
         ShowCursor;
         disp('... The program was terminated manually.');
         RestrictKeysForKbCheck([]);
         return;
     end
     RestrictKeysForKbCheck([]);
     inst_text(window,inst_3,0,0,quit_key,space);
     inst_text(window,inst_4,0,0,quit_key,space);
     inst_text(window,inst_5,0,0,quit_key,space);
     inst_text(window,inst_6,0,0,quit_key,expkey);

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
         reacq.reacq_mtx(x,trial_idx) = x; % set the trial number

         Screen('DrawTexture', window,eval(CSmap{reacq.reacq_mtx(x,cstype_idx)}),[], position_cs, 0); %display cs picture
         Screen(window, 'Flip');
         io64(object,address,1); %send marker to acqknowledge
         %***************************
         reacq.reacq_mtx(x,cs_onset_act_idx) = GetSecs - exp_onset; % record the onset time of this grid trial
         %send event marker to eyelink
         if eyetrack
             Eyelink('Message', [CSmap{reacq.reacq_mtx(x,cstype_idx)} '_on']);
         end
         if(reacq.reacq_mtx(x,cstype_idx)==CSpu_val)
             WaitSecs('UntilTime',(exp_onset+reacq.reacq_mtx(x,cs_offset_idx)-shock_duration));
             %***************************

             io64(object,address,100); %send shock 
             io64(object,address,1);

             %***************************
             reacq.reacq_mtx(x,shocked_idx) = 1; %record info ab shock
             reacq.reacq_mtx(x,shock_onset_idx) = GetSecs-exp_onset;
             WaitSecs('UntilTime',exp_onset+reacq.reacq_mtx(x,cs_offset_idx)) ;
         else
             WaitSecs('UntilTime',exp_onset+reacq.reacq_mtx(x,cs_offset_idx)) ;
         end
         
         reacq.reacq_mtx(x,cs_offset_act_idx) = GetSecs - exp_onset; %record cs offset time
         %***************************
         io64(object,address,0); %clear port
         %***************************
         %----------------------------ITI AFTER TRIAL----------------------------
         DrawFormattedText(window, fix_string, 'center',windowRect(3)*fix_height, black);% draw ITI and record time of onset
         [~,ITI_onset]=  Screen('Flip', window);  
         reacq.reacq_mtx(x,iti_onset_act_idx) = ITI_onset - exp_onset;
         %send event marker to eyelink
         if eyetrack
             Eyelink('Message', [CSmap{reacq.reacq_mtx(x,cstype_idx)} '_off']);
         end
         while (GetSecs < exp_onset + reacq.reacq_mtx(x,iti_offset_idx)) %while ITI time (minus anticipation time) has not elapsed
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
         
         
         reacq.reacq_mtx(x,iti_offset_act_idx) = GetSecs - exp_onset; %record ITI offset time

         %print tab delimited results from this trial to text file
         fprintf(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ...
         reacq.reacq_mtx(x,:));

         save(results_mat_file, '-struct', 'reacq'); %save mat file

     end
     
     Screen('DrawTexture', window, CSp, [], pos_right, 0);
     Screen('DrawTexture', window, CSm, [], pos_left, 0);
     DrawFormattedText(window, check1,'center', 100, 0, [],[],[],2); %draw text
     Screen('Flip', window);
     RestrictKeysForKbCheck([one,two]);

     while ~KbCheck
     end
     [~,~, keyCode]=KbCheck; 
     KbReleaseWait; %wait for key to be released
     RestrictKeysForKbCheck([]);
     keyCodeNum = find(keyCode==1); %see which key was pressed
     if keyCodeNum==two 
         reacq.checkcorrect = 1;
     end
     save(results_mat_file, '-struct', 'reacq'); %save mat file
     Eyelink('StopRecording');

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

