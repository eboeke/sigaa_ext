function wrapper_d1(subjectcode,eyetrack)
%runs day 1 of sigaa ext experiment.
%args:
%   subjectcode, a string in the format <subject number>_<task version>_<condition>
%   eyetrack, a bool indicating whether eyetracking data should be collected.
try
    

    edfFileHost = 'none'; %initialize edf file name as 'none'
    %some checks
    %determine version etc based on subject code. print errors if subject code
    %is problematic.
    components = regexp(subjectcode,regexptranslate('escape','_'),'split'); %split up subjectcode into components
    if size(components,2)~=3
        error('subjectcode not entered correctly. should be in the form 1_1_mi');
    end
    sub_num = components{1};
    task_version = components{2};
    condition =components{3};
    if strcmp(condition(1),'m')
        if length(condition)==2
            if ~(strcmp(condition(2),'i')|strcmp(condition(2),'n'))
                error('did not recognize condition (last bit of subjectcode');
            end
        else 
            error('did not recognize condition (last bit of subjectcode)');
        end  
        if (size(dir(['task_results/' sub_num, '_*_m*acq*']),1)>0)
            error('An m subject with this number already exists. please rename.')
        end
    elseif strcmp(condition(1),'y')
        %if yoke, make sure there's a master file
    master_file = dir(['task_results/',sub_num,'_',num2str(task_version),'_m*_acq_task.mat']);
    if (size(master_file,1)<1)
        error('master file does not exist');
    end
    if (size(dir(['task_results/' sub_num, '_*_y*av*']),1)>0)
        disp('A y subject with this number already exists. hit 1 to continue, 2 to quit.')
        [~, ~, keyCode] = KbCheck(-1);
        while (keyCode(KbName('1!'))==0 && keyCode(KbName('2@'))==0)
              [keyIsDown, secs, keyCode] = KbCheck(-1);
              if keyIsDown==1
                  if find(keyCode,1)==KbName('1!') 
                      break
                  elseif  find(keyCode,1)==KbName('2@')
                      return
                  end
              end
         end
    end

    else
        error('did not recognize condition (last bit of subjectcode');
    end


    duplicate_m_file = dir(['task_results/',subjectcode,'_acq_task.mat']);

    duplicate_txt_file = dir(['task_results/',subjectcode,'_acq_task.txt']);

    if (size(duplicate_m_file,1)>0)
        error('acq file already exists.');
    end
    if (size(duplicate_txt_file,1)>0)
        error('acq file already exists.');
    end




    task_version = str2double(task_version);
    if(sum(task_version==1:8)<1)
        error('task version must be a number 1-8.');
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
    gray = GrayIndex(screenStuff.number);

    [screenStuff.winPtr, screenStuff.winRect] = PsychImaging('OpenWindow', screenStuff.number, gray);
    Screen('TextFont', screenStuff.winPtr, 'Ariel');
    Screen('TextSize', screenStuff.winPtr, 35);
    HideCursor();

    %setup eyetracker stuff
    if(eyetrack)
        el = EyelinkInitDefaults(screenStuff.winPtr);
        EyelinkInit();
        edfFileHost = [sub_num,num2str(task_version),condition, 'd1.edf']; %edf file name on host computer
        edfFileDisp = ['task_results/',subjectcode, '_d1.edf'];%edf file on display computer
        if exist(edfFileHost)
           error('this edf file already exists. please correct.');
        end
        status = Eyelink('OpenFile', edfFileHost);

        Eyelink('command', 'link_sample_data = LEFT,RIGHT,GAZE,PUPIL,AREA');
        EyelinkDoTrackerSetup(el);
        EyelinkDoDriftCorrection(el);
    end


    %EXPERIMENT
    %collect baseline eyetracking data
    if(eyetrack)
        cal(subjectcode, screenStuff)
    end


    %run acquisition phase:
    Screen('FillRect',screenStuff.winPtr,white)
    Screen('Flip',screenStuff.winPtr)
    acq(subjectcode,eyetrack,screenStuff);



    %run av/ext phase:
    if strcmp(condition(1),'m')
        av(subjectcode,eyetrack,screenStuff);
    else
        av_y(subjectcode,eyetrack,screenStuff);
    end

    %shut down eyetracking stuff
     if(eyetrack)
    Eyelink('ReceiveFile', edfFileHost, edfFileDisp);
    Eyelink('ShutDown');
     end
    ShowCursor();
     %switch Matlab/Octave back to priority 0 -- normal priority:
    Priority(0);
    % Clear the screen.
    Screen('CloseAll');
catch
    %shut down eyetracking stuff
     if(eyetrack)
         if ~strcmp(edfFileHost,'none')
            Eyelink('ReceiveFile', edfFileHost, edfFileDisp);
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




