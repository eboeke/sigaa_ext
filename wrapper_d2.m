function wrapper_d2(subjectcode,eyetrack)
%runs day 1 of sigaa ext experiment.
%args:
%   subjectcode, a string in the format <subject number>_<task version>_<condition>
%   eyetrack, a bool indicating whether eyetracking data should be collected.
try
    edfFileHost = 'none';%initialize edf file name as 'none'
    %get subject/condition info and do checks
    components = regexp(subjectcode,regexptranslate('escape','_'),'split'); %split up subjectcode into components
    if size(components,2)~=3
        error('subjectcode not entered correctly. should be in the form 1_1_mi');
    end

    sub_num = components{1};
    task_version = components{2};
    condition =components{3};
    task_version = str2double(task_version);
    if strcmp(condition(1),'m')
        if length(condition)==2
            if ~(strcmp(condition(2),'i')|strcmp(condition(2),'n'))
                error('did not recognize condition (last bit of subjectcode');
            end
        else 
            error('did not recognize condition (last bit of subjectcode)');
        end  
    elseif strcmp(condition(1),'y')
    else
        error('did not recognize condition (last bit of subjectcode');
    end

    if(sum(task_version==1:8)<1)
        error('task version must be a number 1-8.');
    end
    d1_file = dir(['task_results/',sub_num,'_',num2str(task_version),'_',condition,'*_acq_task.mat']);
    if (size(d1_file,1)<1)
        error('no files from d1 for this subject.');
    end

    duplicate_m_file = dir(['task_results/',subjectcode,'_rec_task.mat']);

    duplicate_txt_file = dir(['task_results/',subjectcode,'_rec_task.txt']);

    if (size(duplicate_m_file,1)>0)
        error('rec file already exists.');
    end
    if (size(duplicate_txt_file,1)>0)
        error('rec file already exists.');
    end

if strcmp(condition(1),'m')
    if (size(dir(['task_results/' sub_num, '_*_m*rec*']),1)>0)
        error('An m subject with this number already exists. please rename.')
    end
end
    if(sum(eyetrack ==[ 0 1])~=1)
        error('eyetrack should be 1 or 0.')
    end

    %set up some psychtoolbox stuff
    PsychDefaultSetup(2);
    screens = Screen('Screens');
    screenStuff.number = max(screens);   
    priorityLevel = MaxPriority(screenStuff.number);
    Priority(priorityLevel);
    white = WhiteIndex(screenStuff.number);
    [screenStuff.winPtr, screenStuff.winRect] = PsychImaging('OpenWindow', screenStuff.number, white);
    Screen('TextFont', screenStuff.winPtr, 'Ariel');
    Screen('TextSize', screenStuff.winPtr, 35);

    HideCursor();

    %setup eyetracker stuff
    if(eyetrack)
        el = EyelinkInitDefaults(screenStuff.winPtr);
        EyelinkInit();
        edfFileHost = [sub_num,num2str(task_version),condition, 'd2.edf']; %edf file name on host computer
        edfFileDisp = ['task_results/',subjectcode, '_d2.edf']%edf file on display computer
        if exist(edfFileHost)
           error('this edf file already exists. please correct.')
        end
        status = Eyelink('OpenFile', edfFileHost);
        Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,PUPIL,AREA');
        EyelinkDoTrackerSetup(el);
        EyelinkDoDriftCorrection(el);
    end


    %change screen to white
    Screen('FillRect',screenStuff.winPtr,white)
    Screen('Flip',screenStuff.winPtr)

    %run rec and reacq phases
    rec(subjectcode,eyetrack,screenStuff);
    reacq(subjectcode,eyetrack,screenStuff);

    %shut down eyetracking stuff
     if(eyetrack)
        Eyelink('ReceiveFile', edfFileHost, edfFileDisp);
        Eyelink('ShutDown');
     end
     %switch Matlab/Octave back to priority 0 -- normal priority:
    Priority(0);
    % Clear the screen.
    Screen('CloseAll');
    ShowCursor();
catch
    %shut down eyetracking stuff
    if(eyetrack)
        if ~strcmp(edfFileHost,'none')
           Eyelink('ShutDown');
        end
    end
    ShowCursor();
    %switch Matlab/Octave back to priority 0 -- normal priority:
    Priority(0);
    % Clear the screen.
    Screen('CloseAll');
    rethrow(lasterror)

end
end