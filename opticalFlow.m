%Author:    Kamil Stepien
%Date:      08 April 2016

close all                                                                   %close all windows
clear                                                                       %clear all variables
clc                                                                         %clear command window

file = 'vid41.avi';                                                       %define file to be processed

%Create video object with some properties,
%read video frames from video file
vid = vision.VideoFileReader(file,'ImageColorSpace','RGB',...
    'VideoOutputDataType', 'single');

%Estimate object velocities / Optical Flow
%This need to be changed for future releases of Matlab
optFlo2 = vision.OpticalFlow('OutputValue',...
    'Horizontal and vertical components in complex form',...
    'ReferenceFrameDelay',1, 'DiscardIllConditionedEstimates',true);

%Draw rectangles, lines, polygons, or circles on an image
%Create shape inserters for lines on optical flow
%This need to be changed for future releases of Matlab
shapeInsert = vision.ShapeInserter('Shape','Lines',...
    'BorderColor','Custom','CustomBorderColor',[255 255 0]);

numFrames = 0;                                                              %initial number of frames
frameList = {};                                                             %initial array of frame list
hasLines = zeros(10, 1, 'uint8');                                           %create array of all zeros

figH = figure;                                                              %assign figure to a variable

while ~isDone(vid)                                                          %run video until done
    colorFrame  = step(vid);                                                %set individual colour frames
    colorFrameRes = imresize(colorFrame,0.3);                               %resize colour frame for faster computation
    grayFrame = rgb2gray(colorFrameRes);                                    %convert resized colour frame to grey
    
    optFloVectors = step(optFlo2, grayFrame);                               %set optical flow on grey frame
    
    lines = oflo(optFloVectors,50);                                         %use the external function to draw lines for optical flow
    motionVectors = step(shapeInsert, colorFrameRes, lines);                %set the lines of optical flow on the main colour frame
    imshow(motionVectors); title('Optical Flow on Frame');                  %display optical flow on colour frame
   
    %hasPoints stores a flag equal to ~isempty(points) for each of the 
    %last 10 frames. If all(hasPoints) is true, than all of the last 10 
    %frames detected a feature
    notEmpty = ~isempty(lines);
    if numel(notEmpty) ~= 1, notEmpty = 1; end
    hasLines = [hasLines(2:end); notEmpty];
    numFrames = numFrames + 1;
    
    %Stashing the frames, a circular buffer to track last 10 frames
    if numFrames >= 10
        frameList = [frameList(2:end) colorFrame];
    else
        frameList = [frameList colorFrame];
    end
    
    if numFrames >= 10 && all(hasLines)                                     %if all frames had lines
        disp('Micro-Expression Detected')                                   %micro-expression detected
    else                                                                    %if not
        disp('Not detected')                                                %display not detected
    end                                                                     %end of the statement
    
    if ~ishghandle(figH)                                                    %if the program is closed
        close all                                                           %close all windows
        break                                                               %stop the process of the system
    end                                                                     %end of the statement
end                                                                         %end while loop
release(vid);                                                               %release video