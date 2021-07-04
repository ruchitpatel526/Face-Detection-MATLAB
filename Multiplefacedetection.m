function varargout = Multiplefacedetection(varargin)
% MULTIPLEFACEDETECTION MATLAB code for Multiplefacedetection.fig
%      MULTIPLEFACEDETECTION, by itself, creates a new MULTIPLEFACEDETECTION or raises the existing
%      singleton*.
%
%      H = MULTIPLEFACEDETECTION returns the handle to a new MULTIPLEFACEDETECTION or the handle to
%      the existing singleton*.
%
%      MULTIPLEFACEDETECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTIPLEFACEDETECTION.M with the given input arguments.
%
%      MULTIPLEFACEDETECTION('Property','Value',...) creates a new MULTIPLEFACEDETECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Multiplefacedetection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Multiplefacedetection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Multiplefacedetection

% Last Modified by GUIDE v2.5 20-Apr-2017 00:49:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Multiplefacedetection_OpeningFcn, ...
                   'gui_OutputFcn',  @Multiplefacedetection_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Multiplefacedetection is made visible.
function Multiplefacedetection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Multiplefacedetection (see VARARGIN)

% Choose default command line output for Multiplefacedetection
handles.output = hObject;
global x;
% Update handles structure
guidata(hObject, handles);
delete(x);
x=webcam();
% UIWAIT makes Multiplefacedetection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Multiplefacedetection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global x;
frame=snapshot(x);
set(handles.start,'Enable','off');
set(handles.stop,'Enable','on');
set(handles.detect,'Enable','off');
set(handles.train,'Enable','off');

global runn;
runn = true;

facedetector = vision.CascadeObjectDetector;
while(runn)                                         
    img = snapshot(x);
    bbox = step(facedetector, img);
    annotatedImage = insertObjectAnnotation(img,'rectangle',bbox,'Face');
    imshow(annotatedImage,'parent',handles.axes1);
end


% --- Executes on button press in stop.
function stop_Callback(hObject, eventdata, handles)
% hObject    handle to stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.start,'Enable','on');
set(handles.stop,'Enable','off');
set(handles.detect,'Enable','on');
set(handles.train,'Enable','on');
global runn;
runn = false;

% --- Executes on button press in detect.
function detect_Callback(hObject, eventdata, handles)
% hObject    handle to detect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

answer = inputdlg('enter no. of faces to be detected:')
answer=answer{1};
    
    set(handles.start,'Enable','off');
    set(handles.stop,'Enable','on');
    set(handles.detect,'Enable','off');
    set(handles.train,'Enable','off');
    answer=str2num(answer);
    global x;
    cam=x;
    global runn;
    runn = true;

    frame = snapshot(cam);
    frameSize = size(frame);
    baseImage=image(zeros(frameSize(1),frameSize(2), 3),'parent', handles.axes1);
    isDone = false;
    preview(cam,baseImage);

    faceDetector = vision.CascadeObjectDetector;

    pause(5);
    while ~isDone && runn
        I = snapshot(cam);
        faceDetector.MergeThreshold=5;
        bboxes = step(faceDetector,I);
        if size(bboxes,1)==answer
            isDone = true;
        break;
        end
    end
    closePreview(cam);

    IFaces = insertObjectAnnotation(I, 'rectangle', bboxes, 'Face');
    figure, imshow(IFaces), title('Detected faces');

    ImageSetFace = imageSet('dataHouse', 'recursive');

    trainingFeatures = (210500);
    featureCount = 1;
    for i=1:size(ImageSetFace,2)
        for j = 1:ImageSetFace(i).Count        
            sizeNormalizedImage = imresize(rgb2gray(read(ImageSetFace(i),j)),[150 150]);
            trainingFeatures(featureCount,:) = extractHOGFeatures(sizeNormalizedImage);
            trainingLabel{featureCount} = ImageSetFace(i).Description;   
            featureCount = featureCount + 1;
        end
    end

    Img = cell(1,size(bboxes,1));

    for i = 1:size(bboxes,1)
         J= imcrop(I,[bboxes(i,1)-20 bboxes(i,2)-20 bboxes(i,3)+20 bboxes(i,4)+20]);
         scale=150/size(J,1);
         Img{i}=imresize(J,scale);
    end

    % Create Classifier 
    faceClassifier = fitcecoc(trainingFeatures,trainingLabel)
     figure;
    for  i= 1: length(Img)
            queryImage = Img{i};
            sizeNormalizedImage = imresize(rgb2gray(queryImage),[150 150]);
            %figure;imshow(sizeNormalizedImage)
            queryFeatures = extractHOGFeatures(sizeNormalizedImage);
            [personLabel] = predict(faceClassifier,queryFeatures);
            subplot(2,2,i)
            imshow(queryImage);title(personLabel);
    end

 %imshow(~zeros(frameSize(1),frameSize(2), 3),'parent', handles.axes1);

% --- Executes on button press in train.
function train_Callback(hObject, eventdata, handles)
% hObject    handle to train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answer = inputdlg('Enter Person Name : ');
global x;
global runn;
runn = true;
if isempty(answer)
else
    set(handles.start,'Enable','off');
    set(handles.stop,'Enable','on');
    set(handles.detect,'Enable','off');
    set(handles.train,'Enable','off');
    answer=answer{1};    
    cd dataHouse
    mkdir(answer);
    cd ..
    cam=x;
    frame = snapshot(cam);
    frameSize = size(frame);
    baseImage=image(zeros(frameSize(1),frameSize(2), 3),'parent', handles.axes1);
    preview(cam,baseImage);
    isDone = 0;
    faceDetector = vision.CascadeObjectDetector;
    set(handles.counttxt,'Visible','on');
    while isDone<50 && runn
        pause(0.1);
        I = snapshot(cam);
        set(handles.counttxt,'String',num2str(isDone));
        bboxes = step(faceDetector, I);
        if ~isempty(bboxes)
             isDone = isDone+1;
             J= imcrop(I,[bboxes(1)-20 bboxes(2)-20 bboxes(3)+20 bboxes(4)+20]);
             scale=150/size(J,1);
             J=imresize(J,scale);
             pathName = strcat('/Users/apple/Documents/facedetection/dataHouse/',answer);
             imwrite(J,fullfile(pathName,['img',num2str(isDone),'.jpg']))
        end
    end
    closePreview(cam);
    clear('cam');
    set(handles.start,'Enable','on');
    set(handles.stop,'Enable','off');
    set(handles.detect,'Enable','on');
    set(handles.train,'Enable','on');
    set(handles.counttxt,'Visible','off');
end


% --- Executes on button press in close.
function close_Callback(hObject, eventdata, handles)
% hObject    handle to close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global runn;
runn = false;
global x;
delete(x);
close all force;
