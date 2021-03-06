%Author:    Kamil Stepien
%Date:      08 April 2016

close all                                                                   %close all windows
clear                                                                       %clear all variables
clc                                                                         %clear command window
tic;                                                                        %start measuring time

file = 'MEXTest.mp4';                                                       %define file to be processed

%Create video object with some properties,
%read video frames from video file
vid = vision.VideoFileReader(file,'ImageColorSpace','RGB',...
    'VideoOutputDataType','single');

%Create object Detectors(Eyes,Nose,Mouth)
detectFace = vision.CascadeObjectDetector();

%Create object Detectors(Eyes,Nose,Mouth)
detectEyes = vision.CascadeObjectDetector('EyePairBig');
detectNose = vision.CascadeObjectDetector('Nose','MergeThreshold',100);
detectMouth = vision.CascadeObjectDetector('Mouth','MergeThreshold',200);

%Create face detector properties
detectFace.MaxSize = [220 220];
detectFace.MinSize = [120 120];
detectFace.ScaleFactor = size(detectFace)/(size(detectFace)-0.01);
detectFace.MergeThreshold = 100;                                            %munimises multple faces detected

%Estimate object velocities / Optical Flow
%This need to be changed for future releases of Matlab
optFlo = vision.OpticalFlow('OutputValue',...
    'Horizontal and vertical components in complex form',...
    'ReferenceFrameDelay',3);
optFlo2 = vision.OpticalFlow('OutputValue',...
    'Horizontal and vertical components in complex form',...
    'ReferenceFrameDelay',3);

%Draw rectangles, lines, polygons, or circles on an image
%Create shape inserters for lines on optical flow
%This need to be changed for future releases of Matlab
shapeInsert = vision.ShapeInserter('Shape','Lines',...
    'BorderColor','Custom','CustomBorderColor',[255 255 0]);

%Find mean value of input or sequence of inputs
mean1 = vision.Mean;
mean2 = vision.Mean('RunningMean',true);
%2D median filtering
medianFilter = vision.MedianFilter;
%Perform morphological closing on image
morphClose = vision.MorphologicalClose('Neighborhood',strel('line',5,45));
%Perform morphological erosion on an image
morphErode = vision.MorphologicalErode('Neighborhood',strel('square',2));

numFrames = 0;                                                              %initial number of frames
frameList = {};                                                             %initial array of frame list
hasLines = zeros(10, 1, 'uint8');                                           %create array of all zeros

figH = figure;                                                              %assign figure to a variable

while ~isDone(vid)                                                          %run video until done
    colorFrame  = step(vid);                                                %set individual colour frames
    colorFrameRes = imresize(colorFrame,0.3);                               %resize colour frame for faster computation
    grayFrame = rgb2gray(colorFrameRes);                                    %convert resized colour frame to grey
        
    faceBbox = step(detectFace,colorFrameRes);                              %create bounding box(bbox) around the face
    addfbbox = insertObjectAnnotation(colorFrameRes,'rectangle',...
        faceBbox,'Face', 'Color','Blue','TextColor','White',...
        'LineWidth',2);                                                     %add bbox to the frame
    subplot(3,3,1); imshow(addfbbox,'border','tight');...
        title('Detected Face');                                             %show the above
    
    if size(faceBbox,1) == 0                                                %if no face detected
        disp('Face not Detected');                                          %display this
    else if size(faceBbox,1) > 1                                            %if more than 1 face detected
            disp('Too many faced detected');                                %display this
        else                                                                %for 1 face progress with the code
            colorFace = imcrop(colorFrameRes,faceBbox);                     %crop colour frame and face
            grayFace = imcrop(grayFrame,faceBbox);                          %crop grey frame and face
            sharpGrayFace = imsharpen(grayFace);                            %sharpen the grey frame
            sharpColorFace = imsharpen(colorFace);                          %sharpen the colour face frame
            adjustColorFace = imadjust(sharpColorFace,...
                [.1 .1 0; .6 .7 1],[]);                                     %adjust frame intensity values/colours
            subplot(3,3,2); imshow(adjustColorFace);...
                title('Face cropped & enhanced');                           %show enhanced colour image
            
            featuresDetected = detectHarrisFeatures(sharpGrayFace);         %detect Harris feature points
            subplot(3,3,3); imshow(sharpGrayFace), hold on,...
                plot(featuresDetected); title('Harris Feature Points');     %display Harris features
            
            eyesBbox = step(detectEyes,colorFace);                          %create bounding box around the eyes
            noseBbox = step(detectNose,colorFace);                          %create bounding box around the nose
            mouthBbox = step(detectMouth,colorFace);                        %create bounding box around the mouth
            
            if size(eyesBbox,1) == 0                                        %if no eyes detected
                disp('Eyes not detected');                                  %display this
            else if size(eyesBbox,1) > 1                                    %if more than 1 pair of eyes detected
                    disp('Too many pair of eyes detected');                 %display this
                else                                                        %for 1 pair of eyes progress with the code
                    eyes = imcrop(adjustColorFace,eyesBbox);                %crop the frame with eyes detected
                    subplot(3,3,4); imshow(eyes); title('Detected Eyes');   %show pair of eyes
                end                                                         %end of the statement
            end                                                             %end of the statement
            
            if size(noseBbox,1) == 0                                        %if no nose detected
                disp('Nose not detected');                                  %display this
            else if size(eyesBbox,1) > 1                                    %if more than 1 nose detected
                    disp('Too many noses detected');                        %display this
                else                                                        %for 1 nose progress with the code
                    nose = imcrop(adjustColorFace,noseBbox);                %crop the frame with nose detected
                    subplot(3,3,5); imshow(nose); title('Detected Nose');   %show nose
                end                                                         %end of the statement
            end                                                             %end of the statement
            
            if size(mouthBbox,1) == 0                                       %if no mouth detected
                disp('Mouth not detected');                                 %display this
            else if size(mouthBbox,1) > 1                                   %if more than 1 mouth detected
                    disp('Too many mouths detected');                       %display this
                else                                                        %for 1 mouth progress with the code
                    mouth = imcrop(adjustColorFace,mouthBbox);              %crop the frame with mouth detected
                    subplot(3,3,6); imshow(mouth);...
                        title('Detected Mouth');                            %show mouth
                end                                                         %end of the statement
            end                                                             %end of the statement
            
            optFloVect = step(optFlo,sharpGrayFace);                        %set optical flow on converted face frame
            lines = oflo(optFloVect,2);                                     %use the external function to draw lines for optical flow
            motionVect = step(shapeInsert,colorFace,lines);                 %set the lines of optical flow on the face frame
            subplot(3,3,7); imshow(motionVect);...
                title('Optical Flow on Face');                              %display optical flow on face
        end                                                                 %end of the statement
    end                                                                     %end of the statement
    
    release(optFlo);                                                        %release optical flow for next frame
    optFloVectors = step(optFlo2, grayFrame);                               %set optical flow on grey frame
    lines2 = oflo(optFloVectors,20);                                        %use the external function to draw lines for optical flow
    motionVectors = step(shapeInsert, colorFrameRes, lines2);               %set the lines of optical flow on the main colour frame
    subplot(3,3,8); imshow(motionVectors); title('Optical Flow on Frame');  %display optical flow on colour frame
    
    %The optical flow vectors are stored as complex numbers.
    %Compute their magnitude squared which will be used for thresholding.
    magnitudeSqr = optFloVectors .* conj(optFloVectors);
    velocityThreshold = 0.6 * step(mean2, step(mean1, magnitudeSqr));
    %Threshold the image and then filter it to remove speckle noise.
    segObj = step(medianFilter, magnitudeSqr >= velocityThreshold);
    %Thin-out the parts of the face and fill holes in the blobs.
    segObj = step(morphClose, step(morphErode, segObj));
    %show blob analysis based on optical flow
    subplot(3,3,9); imshow(segObj); title('Blob Analysis')
    
    %hasPoints stores a flag equal to ~isempty(points) for each of the 
    %last 10 frames. If all(hasPoints) is true, than all of the last 10 
    %frames detected a feature
    notEmpty = ~isempty(lines2); 
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
toc;                                                                        %stop counting time