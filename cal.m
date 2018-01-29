function cal(subjectcode,screenStuff)
%collects baseline eyetracking data.
%args: 
   %subjectcode, a string
   %screenStuff, a struct with info necessary to use Psychtoolbox's screen
   %functions
window = screenStuff.winPtr;
windowRect = screenStuff.winRect;
screenNumber = screenStuff.number;
fix_string = '+';
black = BlackIndex(screenNumber);
duration = 300; %length of recording in seconds

KbName('UnifyKeyNames'); %Unify key names--makes mapping betw mac and pc easier
expkey = KbName('`~');
quit_key =KbName('q');
inst = ['Please listen to the experimenter''','s instructions.'];
end_text = ['You can lean back in the chair now.\n'...
    'Please wait for the experimenter to return.'];
inst_text(window,inst,0,0,quit_key,expkey);

 %display fixation cross for the required duration
DrawFormattedText(window, fix_string, 'center', 'center', black);
[~,start]=  Screen('Flip', window);  %flip the screen, record experiment onset
endtime = duration+start;
Eyelink('StartRecording');
WaitSecs('UntilTime', endtime);
Eyelink('StopRecording');
inst_text(window,end_text,0,0,quit_key,expkey);

end
