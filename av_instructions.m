function checkcorrect = av_instructions(instruction_type,window,windowRect,grids,position_grid,CSp,CSm,pos_left,pos_right)
% runs avoidance instructions for subjects in master condition.
%args:
%   instruction_type: 1 or 2, indicates condition 
%   window and windowRect, info necessary to use Psychtoolbox's screen
%   functions
%   grids, the grid textures
%   position_grid, numbers indicating the position of grid on screen
%   CSp and CSm, the images for CSp/CSm
%   pos_left and pos_right, numbers indicating positions of pictures when
%   they are side by side.
%output:
%   checkcorrect, a bool indicating whether the subject correctly
%   identified the CS+ on the first try.
grid_cols = 10; %number of columns in the grid 
grid_rows = 5; %number of rows in the grid
goal_reached_1 = 0; % this will mark, on a given trial, whether the "goal" n position was reached
goal_reached = 0;
goal = 1; % set this up and save for later, to mark what the "goal" n position is on a given trial
if (instruction_type)==1
    prac_dur = 12; % duration of practice period
else
    prac_dur = 6;
end
advance = 0; %flag indicating whether to advance past the "check" phase.
advance_prac = 0; %flag indicating whether to advance past practice.
count = 0; %will count number of times they go through check
checkcorrect = 0;%will return whether they identified the face correctly on the first try
%order/response matrix
%key codes
KbName('UnifyKeyNames'); %Unify key names--makes mapping betw mac and pc easier
left = KbName('leftArrow');   %left arrow key code
right = KbName('rightArrow');   %right arrow key code
up = KbName('upArrow'); % up arrow key code
down = KbName('downArrow'); %down arrow key code
quit_key = KbName('q'); % definte a quit key
space = KbName('space');
one = KbName('1!');
two = KbName('2@');
correct = KbName('c');%key for experiment to indicate whether response to
%check was correct (and thus advance through instructions)
incorrect = KbName('i');
expkey = KbName('`~'); %key for experimenter to begin task.


check1 = ['Which one of these is the threat face? Press the ''','1''','\n'...
    'key for the face on the left and the ''','2''','  key for the face\n'...
    'on the right. Use the number keys  at the top of the keyboard'];
check2 = 'You chose the face on the ';
%set up instruction text
inst_1 = ['In the next part of the experiment, you will see the the\n' ...
    'threat face and the no-threat face again. \n\n'...
    'Press the space bar to continue.'];
switch instruction_type
    case 1
inst_2 = ['This time, the grid shown below will appear beneath the\n'...
    'faces. When the threat face is on the screen, your task\n'...
    'will be to learn one simple action you can perform (by\n'...
     'moving the position of the red circle in the grid) \n'...
    'to prevent you from receiving a shock.\n'...
    '\n\n\n\n\n\n\n\n'...
'Press the space bar to continue.'];
inst_3 = ['You can think of the grid as two rooms connected by a\n'...
    'tunnel.  You will be able to use the arrow keys to\n'...
    'explore moving within and between the rooms. These are\n'...
    'the arrow keys you should use. \n\n\n\n\n\n\n\n'...
    'Press the space bar to continue.'];
inst_4 = ['On the next screen you will have a chance to try\n'...
    'moving within the grid. Don''','t worry, you won''','t receive \n'...
    'any shocks during this practice period.\n\n' ...
    'For this practice, the grid will be on the screen for\n'...
    '12 seconds.\n\n' ...
    'Press the space bar to continue.'] ;
inst_5 = ['Once you have learned the action in the grid that stops\n'...
    ' the shock, you should continue to use that action\n'...
    'whenever the threat face is on the screen.\n\n' ...
    'Press the space bar to continue.'] ;
inst_6 = ['When the no-threat face is on the screen, you will not\n'...
    'be able to move the circle. Instead, you should\n'...
    'press any arrow button about 10 times when the\n'...
    'no-threat face is on the screen.\n\n'...
    'When there is no face on the screen, don’''','t press\n'...
    'any buttons. Just focus your gaze on the plus sign (+)\n\n' ...
    'Press the space bar to continue.'] ;

inst_7 = ['To summarize, here are your tasks for the different\n'...
    'pictures:\n\n'...
    'Threat face: learn the action (by moving the red circle\n'...
    'in the grid) that allows you to avoid the shock, and\n'...
    'perform this action.\n\n'...
    'No threat face: Press any arrow key about 10 times.\n\n'...
    'No face: Don''','t press any buttons.\n\n'...
    'Let the experimenter know when you are ready to start.'];
    case 2

inst_2 = ['This time, the grid shown below will appear beneath the\n'...
    'faces. When the threat face is on the screen, you will\n'...
    'be able to perform an action (by moving the position of\n'...
    'the red circle in the grid) to prevent you from receiving a\n'...
    'shock.\n\n\n\n\n\n\n\n\n'...
'Press the space bar to continue.'];
inst_3 = ['You can think of the grid as two rooms connected by a\n'...
    'tunnel.  You will be able to use the arrow keys to\n'...
    'move the red circle within and between the rooms.\n'...
    'These are the arrow keys you should use. \n\n\n\n\n\n\n\n'...
    'Press the space bar to continue.'];
inst_4 = ['When the threat face is on the screen, if you move the\n'...
    'circle to the opposite room from where it started,\n'...
    'you will cancel the shock. For example, if the circle\n'...
    'is in the left room when the threat face appears,\n'...
    'you can move the circle into the right room to\n'...
    'prevent the shock. If the circle is in the right\n'...
    'room when the threat face appears, you can move \n'...
    'the circle to the left room to prevent the shock.\n\n'...
    'Press the space bar to continue.'];
inst_5 = ['On the next screen you will have a chance to try\n'...
    'performing the action that prevents the shock. Don''','t\n'...
    'worry, you won''','t receive any shocks during this\n'...
    'practice period.\n\n' ...
    'On the next screen, please perform the action that\n'...
    'prevents the shock (move the circle into the opposite\n'...
    'room using the arrow keys).\n\n' ...
    'Press the space bar move on to the practice.'] ;
correct_feedback = ['You performed the correct action.\n'...
    'Let''','s do another practice. Press the space bar.'];
incorrect_feedback = ['That wasn''','t the correct action.  Remember\n'...
    'to move the circle into the opposite room from the\n'...
    'starting position. Press the space bar to try again.'];
inst_6 = ['You performed the correct action.\n\n' ...
    'Press the space bar to continue.'] ;
inst_7 = ['When the no-threat face is on the screen, you will not\n'...
    'be able to move the circle. Instead, you should\n'...
    'press any arrow key about 3 times when the\n'...
    'no-threat face is on the screen.\n\n'...
    'When there is no face on the screen, don’''','t press\n'...
    'any buttons. Just focus your gaze on the plus sign (+)\n\n' ...
    'Press the space bar to continue.'] ;

inst_8 = ['To summarize, here are your tasks for the different\n'...
    'pictures:\n\n'...
    'Threat face: perform the action (moving the red circle\n'...
    'to the opposite grid room) that allows you to avoid \n'...
    'the shock. \n\n'...
    'No threat face: Press any arrow key about 3 times.\n\n'...
    'No face: Don''','t press any buttons.\n\n'...
    'Let the experimenter know when you are ready to start.'];
    case 3
    inst_2 = ['This time, a grid similar to the one shown below will \n'...
        'appear beneath the faces. Your job will be to press the\n'...
        'space bar as many times as the number of red circles in the\n'...
        'grid. Note that this number may be different on different\n'...
        'trials.\n\n\n\n\n\n\n\n\n'...
    'Press the space bar to continue.'];
    inst_3 = ['Press the space bar as many times as the number of red\n'...
        'circles in the grid. Do it every time the red circles appear\n'...
        'in the grid. For example, if there were 5 circles, like \n'...
        'in the grid below, you would press the space bar 5 times.\n'...
        'If the number of circles is very large, just do your best\n'...
        'to make that number of key presses. \n\n\n\n\n\n\n\n'...
    'Press the space bar to continue.'];
inst_4 = ['IMPORTANT NOTE: your key presses WILL NOT \n'...
        'influence the experiment by any means. You CANNOT, for\n'...
        'example, trigger or avoid shocks.\n\n'...
        'Let the experimenter know when you are ready to start.'];
        
end
    
%textures
%make texture for keyboard picture
kb_img = imread('stims/keyboard.tif'); %set "var" to the grid image.
keyboard = Screen('MakeTexture',window,kb_img); %make a texture with the image

 %keyboard:
 kb_n_pixels = size(kb_img,2);
kb_m_pixels = size(kb_img,1);
  left_edge_kb = (windowRect(3) - kb_n_pixels)/2; %left edge where keyboard will appear in instructions
 top_edge_kb = (windowRect(4) - kb_m_pixels)* .6; % top edge
 right_edge_kb = left_edge_kb + kb_n_pixels;
 bottom_edge_kb = top_edge_kb + kb_m_pixels;
 position_kb = [left_edge_kb top_edge_kb right_edge_kb bottom_edge_kb]';
 
%----------------------------INSTRUCTIONS----------------------------
%check they know which face is the threat face
while advance ==0
    count = count+1;
    Screen('DrawTexture', window, CSp, [], pos_left, 0);
    Screen('DrawTexture', window, CSm, [], pos_right, 0);

    DrawFormattedText(window, check1,'center', 100, 0, [],[],[],2); %draw text
    Screen('Flip', window);
    RestrictKeysForKbCheck([quit_key,one,two]);


    while ~KbCheck
    end
    [~,~, keyCode]=KbCheck; 
    KbReleaseWait; %wait for key to be released
    RestrictKeysForKbCheck([]);
    keyCodeNum = find(keyCode==1); %see which key was pressed
    if keyCodeNum == quit_key %if user quits, end program
                        Screen('closeall');
                        Priority(0);
                        ShowCursor;
                        disp('... The program was terminated manually.');
                        RestrictKeysForKbCheck([]);
                        return;
    elseif keyCodeNum==one
        side = 'left';
        if count==1
        checkcorrect = 1;
        end
    elseif keyCodeNum==two 
        side = 'right';
    end
    DrawFormattedText(window, [check2,side],'center', 100, 0, [],[],[],2); %draw text
    Screen('Flip', window);
    RestrictKeysForKbCheck([correct,incorrect]);
    while ~KbCheck
    end
    [~,~, keyCode]=KbCheck;
    KbReleaseWait; %wait for key to be released
    RestrictKeysForKbCheck([]);
    keyCodeNum = find(keyCode==1); 
    if keyCodeNum==correct
        advance = 1;
    end
end



 %present instructions (see bottom for function)
 inst_text(window,inst_1,0,0,quit_key,space);
 switch instruction_type
     case 1
inst_text(window,inst_2,grids(2,1),position_grid,quit_key,space);
inst_text(window,inst_3,keyboard,position_kb,quit_key,space) ;
inst_text(window,inst_4,0,0,quit_key,space);
     case 2
inst_text(window,inst_2,grids(2,1),position_grid,quit_key,space);
inst_text(window,inst_3,keyboard,position_kb,quit_key,space) ;
inst_text(window,inst_4,0,0,quit_key,space);
inst_text(window,inst_5,0,0,quit_key,space);
     case 3
inst_text(window,inst_2,grids(9,1),position_grid,quit_key,space);
inst_text(window,inst_3,grids(5,1),position_grid,quit_key,space) ;
inst_text(window,inst_4,0,0,quit_key,expkey);
 end

%----------------------------PRACTICE----------------------------
if instruction_type ~=3 %only do if not yoke
while advance_prac ==0
    if(instruction_type==1)
        advance_prac = 1; %if non instructed version, they just get one practice
    end
    prac_onset = GetSecs();
    RestrictKeysForKbCheck([left, right, up, down, quit_key]); %make it so kbcheck only checks for these keys
    if(~goal_reached_1)
        m = 2;%set up grid coordinates for practice start.
        n = 1;
    end
     if n<6 % if we're on the left
            goal = 7; % the goal is the rightmost column
        else
            goal = 4; % otherwise, the goal is the leftmost column
     end
    %set up initial screen
    [~,~,keyCode]=KbCheck; 
    Screen('DrawTexture', window, grids(m,n), [], position_grid, 0); % put the grid(starting position) on the screen 
    Screen(window, 'Flip');

    %while loop that checks for arrow presses and accordingly, makes moves,
    %while the practice duration has not elapsed.
    while (GetSecs - prac_onset)<=prac_dur % while it's been less than 10 secs
            if sum(keyCode)>1 %if 2 buttons pressed at once, act like nothing has been pressed.
                keyCode = keyCode*0; %did this do something weird? sometimes slow or something
            end

            keyCodeNum = find(keyCode==1); %figure out which key has been pressed.

             if(keyCodeNum) % if something has been pressed, update m and n pos and flip the screen. no need to update screen if nothing has been pressed   
                switch keyCodeNum
                    case  left
                        if n > 1 
                            if n == 7 % if in 7th col, could be next to middle wall. only decrease n if m is 3.
                                if m == 3
                                    n = n - 1;
                                end
                            else
                            n = n - 1;
                            end
                        end

                    case right
                        if  n < grid_cols
                            if n == 4 % if in 4th col, could be next to middle wall. only increase n if m is 3.
                                if m == 3
                                    n = n + 1;
                                end
                            else
                            n = n + 1;
                            end
                        end
                    case up
                        if m > 1
                            if (n ~= 5 & n ~= 6) %don't go up if in tunnel
                            m = m - 1;
                            end
                        end
                    case down
                        if m < grid_rows 
                            if (n ~= 5 & n ~= 6) %don't go down if in tunnel
                            m = m + 1;
                            end
                        end
                    case quit_key %if user quits, end program
                            Screen('closeall');
                            Priority(0); %set priority back to normal
                            ShowCursor;
                            disp('... The program was terminated manually.');
                            RestrictKeysForKbCheck([]); %make it so kbcheck checks for everything
                            fclose(fid);
                            return;
                end

               Screen('DrawTexture', window, grids(m,n), [], position_grid, 0); %load the new picture
               Screen('Flip', window); %flip the screen, to the one with the updated position
               if n == goal
                  goal_reached = 1;
               end
               KbReleaseWait; %wait for them to release the key before moving on in the loop  
            end

            [~,~,keyCode]=KbCheck; %this is where it actually checks for what key is being pressed.

           WaitSecs(0.001); %tiny wait to avoid CPU hogging
    end
    if(instruction_type==2)
                if goal_reached & goal ==7 %if they reached goal and it is the first practice, flag this
                    goal_reached_1 = 1;
                     inst_text(window,correct_feedback,0,0,quit_key,space);
                elseif goal_reached & goal ==4 %if they reached goal and it is the second practice, flag to advance instructions
                    advance_prac = 1;
                else
                     inst_text(window,incorrect_feedback,0,0,quit_key,space); % if they are in the other instruction condition, continue.
                end
    end
    goal_reached = 0;
end
RestrictKeysForKbCheck([]); %

%----------------------------MORE INSTRUCTIONS----------------------------
switch instruction_type
    case 1
        inst_text(window,inst_5,0,0,quit_key,space);
        inst_text(window,inst_6,0,0,quit_key,space);
        inst_text(window,inst_7,0,0,quit_key,expkey);
    case 2
        inst_text(window,inst_6,0,0,quit_key,space);
        inst_text(window,inst_7,0,0,quit_key,space);
        inst_text(window,inst_8,0,0,quit_key,expkey);
end

end


end
