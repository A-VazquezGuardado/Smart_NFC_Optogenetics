% To do:
    % Implement Tonic vs Burst mode at timing level
    % Implement a run and stop button
    % When changing devce from device list and click read, the options are
    % not updated.
    % If no response, then do not update the selected mode of operation
    
% Main GUI for optogentics supporting 4 channels  
% To be updated: Include intensity level

function varargout = SmartDevices(varargin)
% SmartDevices MATLAB code for SmartDevices.fig
%      SmartDevices, by itself, creates a new SmartDevices or raises the existing
%      singleton*.
%
%      H = SmartDevices returns the handle to a new SmartDevices or the handle to
%      the existing singleton*.
%
%      SmartDevices('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SmartDevices.M with the given input arguments.
%
%      SmartDevices('Property','Value',...) creates a new SmartDevices or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SmartDevices_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SmartDevices_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SmartDevices

% Last Modified by GUIDE v2.5 13-May-2021 19:09:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SmartDevices_OpeningFcn, ...
    'gui_OutputFcn',  @SmartDevices_OutputFcn, ...
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

% --- Executes just before SmartDevices is made visible.
function SmartDevices_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SmartDevices (see VARARGIN)

% Choose default command line output for SmartDevices
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

pos = get(gcf,'Position');
pos(1:2) = [-700 300];
set(gcf,'Position',pos);
axes(handles.pulses_fig);
plot_pulses(100,50,'00');

initialize_gui(hObject, handles, false);

% UIWAIT makes SmartDevices wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = SmartDevices_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)

handles.DEMO = 0;

ports = seriallist;
[~,b] = size(ports);
set(handles.serial_port,'String',ports);
set(handles.serial_port,'Value',b);

% Set up serial port
handles.serial.s = serial(' ','BaudRate',38400);
handles.serial.s.InputBufferSize = 128;
handles.serial.s.Timeout = 5;
handles.serial.s.Parity = 'even';
handles.serial.s.StopBits = 1;
handles.serial.s.DataBits = 8;
handles.serial.s.port = ports{b};

% Initializes some flags
handles.flags.receiving = 0;
handles.flags.serial_active = 0;

% Set up initial check button states, enables
% set(handles.connected,'Value',0);
% set(handles.ch_single,'Value',0);
% set(handles.ch_dual,  'Value',0);
% set(handles.ch1,      'Value',0);
% set(handles.ch2,      'Value',0);
% set(handles.ch3,      'Value',0);
% set(handles.ch4,      'Value',0);
% set(handles.ch_inph,  'Value',0);
% set(handles.ch_outph, 'Value',0);

% Disable unnesesary buttons
% set(handles.ch1,      'Enable','Inactive');
% set(handles.ch2,      'Enable','Inactive');
% set(handles.ch3,      'Enable','Inactive');
% set(handles.ch4,      'Enable','Inactive');
% set(handles.ch_single,'Enable','Inactive');
% set(handles.ch_dual,  'Enable','Inactive');
% set(handles.ch_outph, 'Enable','Inactive');
% set(handles.ch_inph,  'Enable','Inactive');
% set(handles.ON_OFF,   'Enable','Inactive');
% set(handles.cmd_indicator,'Enable','Inactive');
% set(handles.T,'Enable','Off');
% set(handles.DC,'Enable','Off');
% set(handles.text30,'Enable','Off');
% set(handles.burstperiod,'Enable','Off');

% set(handles.cmd_RF_ON_OFF,  'Enable','Off');
% set(handles.rf_power,       'Enable','Off');
% set(handles.cmd_set_rfpower,'Enable','Off');

% set(handles.cmd_write,      'Enable','Off');
% set(handles.cmd_read,      'Enable','Off');
% set(handles.cmd_read_UDID,    'Enable','Off');
% set(handles.cmd_memSummary,   'Enable','Off');
% set(handles.UDID_devices,     'Enable','Off');

dis_enableALL(handles,0);

% Initializes the UIUD parameters
handles.NFC.addressedmode = 1;
set(handles.UDID_devices,'Value',1);
set(handles.UDID_devices,'String','XX-XX-XX-XX-XX-XX-XX-XX');
    
% Initializes button captions
set(handles.serial_connect,   'String','Connect');

% Initializes NFC values
handles.NFC.mode = 0;           % Mode of operation
handles.NFC.channel = 0;        % Channel (in general)
handles.NFC.channelS = 1;       % Single channel
handles.NFC.channelD = 3;       % Dual channel
handles.NFC.dual_phase = 0;     % when going back from single to dual
handles.NFC.channelD0= 1;       % Very last dual channel selection
handles.NFC.channelD1= 2;       % Previous dual channel selection
handles.NFC.T = [0 100];        % Two bytes of data for the period
handles.NFC.T0 = 100;
handles.NFC.DC = 50;
handles.NFC.DC0= 20;            % Ref value in case the initial DC > 50 for dual mode
handles.NFC.pw = 10;            % Pulse width [ms]
handles.NFC.addressedmode = 1;  % Addressed mode of operation
handles.NFC.UDID = '';          % Unique device identifier for addressed mode
handles.NFC.address = 0;
handles.NFC.data = [0 0 0 0];
handles.NFC.nAttempts = 5;      % Number of attempts to read or write
handles.NFC.indicator = 0;
handles.NFC.OnOff = 0;
handles.NFC.P = 0;
handles.NFC.burstperiod = 1000; % Burst period, 1s default
handles.NFC.burst = 0;
handles.NFC.tonic = 1;

handles.debug = 0;

guidata(handles.figure1, handles);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                         Callback functions
function dis_enableALL(handles,opt)

    if opt == 1
        opt_enable = 'On';
        opt_value = 1;
    else
        opt_enable = 'Off';
        opt_value = 0;
    end
    set(handles.cmd_read_UDID,    'Enable','Off');
    set(handles.cmd_memSummary,   'Enable','Off');
    set(handles.cmd_memSummary,   'Enable','Off');
    set(handles.UDID_devices,     'Enable','Off');

    set(handles.cmd_RF_ON_OFF,  'Enable','Off');
    set(handles.rf_power,       'Enable','Off');
    set(handles.cmd_set_rfpower,'Enable','Off');

    set(handles.cmd_write,      'Enable','Off');
    set(handles.cmd_read,      'Enable','Off');
    set(handles.ch1,            'Enable','Off');
    set(handles.ch2,            'Enable','Off');
    set(handles.ch3,            'Enable','Off');
    set(handles.ch4,            'Enable','Off');
    set(handles.ch_single,      'Enable','Off');
    set(handles.ch_dual,        'Enable','Off');
    set(handles.ch_outph,       'Enable','Off');
    set(handles.ch_inph,        'Enable','Off');
    set(handles.ON_OFF,         'Enable','Off');
    set(handles.cmd_tonic,      'Enable','Off');
    set(handles.cmd_burst,      'Enable','Off');
    set(handles.cmd_indicator,  'Enable','Off');
    set(handles.T,              'Enable','Off');
    set(handles.DC,             'Enable','Off');
    set(handles.burstperiod,    'Enable','Off');
    set(handles.text25,         'Enable','Off');
    set(handles.text9,          'Enable','Off');
    set(handles.text29,         'Enable','Off');
    set(handles.text30,         'Enable','Off');
    
    set(handles.ch1,            'Value',0);
    set(handles.ch2,            'Value',0);
    set(handles.ch3,            'Value',0);
    set(handles.ch4,            'Value',0);
    set(handles.ch_single,      'Value',0);
    set(handles.ch_dual,        'Value',0);
    set(handles.ch_outph,       'Value',0);
    set(handles.ch_inph,        'Value',0);
    set(handles.ON_OFF,         'Value',0);
    set(handles.cmd_tonic,      'Value',0);
    set(handles.cmd_burst,      'Value',0);
    set(handles.cmd_indicator,  'Value',0);

function serial_connect_Callback(hObject, eventdata, handles)
if handles.flags.serial_active == 0
    if ~strcmp(handles.serial.s.port,' ') % Connect
        fclose(instrfind)
        fopen(handles.serial.s);
        handles.flags.serial_active = 1;
        
        set(handles.connected,      'Value',1);
        set(handles.serial_port,    'Enable','Off');
        set(handles.rf_power,       'Enable','On');
        set(handles.cmd_set_rfpower,'Enable','On');
        set(handles.serial_connect, 'String','Disconnect');
        set(handles.cmd_read_UDID,  'Enable','On');
        set(handles.cmd_RF_ON_OFF,  'Enable','On');
        set(handles.text29,         'Enable','On');


        fprintf('Port open.\n');
        
        % Read power on the Feig reader
        P0 = dec2hex(handles.NFC.P,2);
        msg = '02000DFF8A020101000301';
        msg0 = [];
        for j0=1:(length(msg)/2)
            msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
        end
        crc = CRC16(msg0);
        handles.NFC.message = [msg0 crc];
        handles.NFC.waittime = 0.5;
        dataReceived = send_commands(handles);
        
        P0 = dataReceived(13);
        handles.NFC.P = P0;
        set(handles.rf_power,'String',num2str(P0));
        
        
    else
        disp('Select port first');
    end
else % Disconnect
    fclose(handles.serial.s)
    handles.flags.serial_active = 0;
    
    set(handles.connected,        'Value',0);
    set(handles.serial_port,      'Enable','On');
    set(handles.cmd_write,      'Enable','Off');
    set(handles.cmd_read,      'Enable','Off');
    set(handles.serial_connect,   'String','Connect');

    set(handles.cmd_set_rfpower,'Enable','Off');
    set(handles.cmd_RF_ON_OFF,  'Enable','Off');
    set(handles.rf_power,       'Enable','Off');
    
    dis_enableALL(handles,0);
    
    fprintf('Port closed.\n');
end
guidata(hObject,handles)

function cmd_read_UDID_Callback(hObject, eventdata, handles)

disp(' ');
handles.NFC.waittime = 1;
[UDID,n] = get_inventory(handles);

if n > 0
    set(handles.UDID_devices,'Value',1);
    set(handles.UDID_devices,'String',UDID.str);
    handles.NFC.addressed = 1;
    handles.NFC.UDID = UDID.num{1};
    handles.NFC.UDID_n = n;                 % Number of devices
    handles.NFC.UDID_s = UDID.num;          % UDIDs in dec format
    handles.NFC.UDID_str = UDID.str;          % UDIDs in str format
    
    set(handles.cmd_read,       'Enable','On');
    set(handles.cmd_memSummary, 'Enable','On');
    set(handles.UDID_devices,   'Enable','On');

    guidata(hObject, handles);
else
    disp('There was not found any device!');
end

function cmd_read_Callback(hObject, eventdata, handles)
disp(' ');
% Read memory  state

str = [];
for j0 = 1:8
    str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
end
str = str(1:(end-1));
disp(['Addressed mode @ UDID: ' str]);
temp = strfind(str,'-');
str(temp) = '';
msg = ['020013FFB02301' str];

msg = [msg '0001'];
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.5;
dataReceived = send_commands(handles);

% If zero return, then the data is from error
if dataReceived(1) == 0
    disp('No response!');
    return;
end
% Check if the length is correct
if LengthCorrect(dataReceived) == 0
    disp('The received message length is not correct.');
    return;
end

% If ok, then update state paramters
handles.NFC.channelState = dataReceived(10:13);
if handles.NFC.channelState(3) == 0     % The channels are off
   set(handles.ON_OFF,'Value', 0);
   handles.NFC.OnOff = 0;
else
   set(handles.ON_OFF,'Value', 1);
   handles.NFC.OnOff = 1;
end
if handles.NFC.channelState(2) == 0     % The indicator is off
   set(handles.cmd_indicator,'Value', 0);
   handles.NFC.indicator = 0;
else
   set(handles.cmd_indicator,'Value', 1);
   handles.NFC.indicator = 1;
end

set(handles.text9,'Enable','On');
set(handles.text25,'Enable','On');
set(handles.cmd_tonic,'Enable','On');
set(handles.cmd_burst,'Enable','On');

handles = read_state(handles,dataReceived);
disp(' ');
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function cmd_write_Callback(hObject, eventdata, handles)
channindex = [1 3 0 5 0 0 0 7 0 0 0 0];
T0 = handles.NFC.T;

if handles.NFC.channel ~= 0
    switch handles.NFC.mode
        case 0 %'00'
            handles.NFC.address = channindex(handles.NFC.channelS);
            DC0 = handles.NFC.DC0;
        case 1% '01'
            handles.NFC.address = 11;
            DC0 = handles.NFC.DC0;       
        case 17 %'11'
            handles.NFC.address = 9;
            DC0 = handles.NFC.DC0;
    end
end

DC0 = dec2hex(round((T0(1)*256+T0(2))*DC0/100),4);
handles.NFC.data = ([T0 hex2dec(DC0(1:2)) hex2dec(DC0(3:4))]);
handles.NFC.message = assemble_message_modeoperation(handles,'setTiming');
send_commands(handles);

function str_send_Callback(hObject, eventdata, handles)
temp = get(hObject, 'String')
handles.strings.str_send = temp;
guidata(hObject,handles)

function ON_OFF_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end

disp('Command: Channel On/Off');
if handles.NFC.channelState(3) == 0
    %if the channel is off star start with either ch1 or ch1/2
    if handles.NFC.mode == 0 % Single channel
        handles.NFC.channelState(3) = handles.NFC.channel;
        set(handles.ch1,'Value',1);
        set(handles.ch_single,'Value',1);
    elseif  handles.NFC.mode == 1   % Dual channel out phase
        handles.NFC.channelState(3) = handles.NFC.channel;
        handles.NFC.channel = 1;
        set(handles.ch1,'Value',1);
        set(handles.ch2,'Value',1);
        set(handles.ch_dual,'Value',1);
        set(handles.ch_outph,'Value',1);
    elseif  handles.NFC.mode == 17   % Dual channel in phase
        handles.NFC.channelState(3) = handles.NFC.channel;
        set(handles.ch1,'Value',1);
        set(handles.ch2,'Value',1);
        set(handles.ch_dual,'Value',1);
        set(handles.ch_inph,'Value',1);
    end
end

if get(handles.ON_OFF,'Value') == 0 % Turn off
    handles.NFC.data = handles.NFC.channelState.*[1 1 0 0];
    handles.NFC.message = assemble_message_modeoperation(handles,'Channels_OFF');
    data = send_commands(handles);
    handles.NFC.OnOff = 0;
    if data(1) == 0
        handles.NFC.OnOff = 1;
        set(handles.ON_OFF,'Value',1)
    else 

    end
else % Turn on
    handles.NFC.data = [0 handles.NFC.indicator 0 handles.NFC.mode]...
        +handles.NFC.channel.*[0 0 1 0];
    handles.NFC.message = assemble_message_modeoperation(handles,'Channels_ON');
    data = send_commands(handles);
    handles.NFC.OnOff = 1;
    if data(1) == 0
        handles.NFC.OnOff = 0;
        set(handles.ON_OFF,'Value',0)
    else 
         handles.NFC.channelState = handles.NFC.data;
    end
end

guidata(hObject, handles);

function cmd_indicator_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end

disp('Command: Indicator On/Off');
if get(handles.cmd_indicator,'Value') == 0  % Turn off
    handles.NFC.data = handles.NFC.channelState.*[1 0 1 1];
    handles.NFC.message = assemble_message_modeoperation(handles,'Indicator_OFF');
    data = send_commands(handles);
    handles.NFC.indicator = 0;
    handles.NFC.channelState(2) = 0;
    if data(1) == 0
        handles.NFC.indicator = 1;
        set(handles.cmd_indicator,'Value',1)
    end
else
    handles.NFC.data = handles.NFC.channelState+[0 1 0 0];
    handles.NFC.message = assemble_message_modeoperation(handles,'Indicator_ON');
    data = send_commands(handles);
    handles.NFC.indicator = 1;
    handles.NFC.channelState(2) = 1;
    if data(1) == 0
        handles.NFC.indicator = 0;
        set(handles.cmd_indicator,'Value',0)
    end
end

guidata(hObject, handles);

function ch1_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end
handles.NFC.data = handles.NFC.channelState;
% handles.NFC.data = zeros(1,4);
% handles.NFC.data(2) = 1;
handles.NFC.data(4) = handles.NFC.mode;
if handles.NFC.mode == 0
    if get(handles.ch1,'Value') == 1
        set(handles.ch2,'Value',0);
        set(handles.ch3,'Value',0);
        set(handles.ch4,'Value',0);
        handles.NFC.channelS = 1;
    else
        handles.NFC.channelS = 0;
    end
    handles.NFC.channel = handles.NFC.channelS;
    handles.NFC.data(3) = handles.NFC.channel;
    handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
    data = send_commands(handles);
else
    if handles.NFC.channelD0 == 1 || handles.NFC.channelD1 == 1
        set(handles.ch1,'Value',1);
    else
        if get(handles.ch1,'Value') == 1
            off_channel(handles);
            handles.NFC.channelD = handles.NFC.channelD+1-handles.NFC.channelD0;
            handles.NFC.channelD0 = handles.NFC.channelD1;
            handles.NFC.channelD1 = 1;
            handles.NFC.channel = handles.NFC.channelD;
            handles.NFC.data(3) = handles.NFC.channel;
            handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
            data = send_commands(handles);
        end
    end
end
if data(1) ~= 0
    handles.NFC.channelState = handles.NFC.data;
end
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function ch2_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end

handles.NFC.data = handles.NFC.channelState;
% handles.NFC.data = zeros(1,4);
% handles.NFC.data(2) = 1;
handles.NFC.data(4) = handles.NFC.mode;
if handles.NFC.mode == 0%'00'
    if get(handles.ch2,'Value') == 1
        set(handles.ch1,'Value',0);
        set(handles.ch3,'Value',0);
        set(handles.ch4,'Value',0);
        handles.NFC.channelS = 2;
    else
        handles.NFC.channelS = 0;
    end
    handles.NFC.channel = handles.NFC.channelS;
    handles.NFC.data(3) = handles.NFC.channel;
    handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
    data = send_commands(handles);
else
    if handles.NFC.channelD0 == 2 || handles.NFC.channelD1 == 2
        set(handles.ch2,'Value',1);
    else
        if get(handles.ch2,'Value') == 1
            off_channel(handles);
            handles.NFC.channelD = handles.NFC.channelD+2-handles.NFC.channelD0;
            handles.NFC.channelD0 = handles.NFC.channelD1;
            handles.NFC.channelD1 = 2;
            handles.NFC.channel = handles.NFC.channelD;
            handles.NFC.data(3) = handles.NFC.channel;
            handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
            data = send_commands(handles);
        end
    end
end
if data(1) ~= 0
    handles.NFC.channelState = handles.NFC.data;
end
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function ch3_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end
handles.NFC.data = handles.NFC.channelState;
% handles.NFC.data = zeros(1,4);
% handles.NFC.data(2) = 1;
handles.NFC.data(4) = handles.NFC.mode;
if handles.NFC.mode == 0%'00'
    if get(handles.ch3,'Value') == 1
        set(handles.ch1,'Value',0);
        set(handles.ch2,'Value',0);
        set(handles.ch4,'Value',0);
        handles.NFC.channelS = 4;
    else
        handles.NFC.channelS = 0;
    end
    handles.NFC.channel = handles.NFC.channelS;
    handles.NFC.data(3) = handles.NFC.channel;
    handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
    data = send_commands(handles);
else
    if handles.NFC.channelD0 == 4 || handles.NFC.channelD1 == 4
        set(handles.ch3,'Value',1);
    else
        if get(handles.ch3,'Value') == 1
            off_channel(handles);
            handles.NFC.channelD = handles.NFC.channelD+4-handles.NFC.channelD0;
            handles.NFC.channelD0 = handles.NFC.channelD1;
            handles.NFC.channelD1 = 4;
            handles.NFC.channel = handles.NFC.channelD;
            handles.NFC.data(3) = handles.NFC.channel;
            handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
            data = send_commands(handles);
        end
    end
end
if data(1) ~= 0
    handles.NFC.channelState = handles.NFC.data;
end
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function ch4_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end
handles.NFC.data = handles.NFC.channelState;
% handles.NFC.data = zeros(1,4);
% handles.NFC.data(2) = 1;
handles.NFC.data(4) = handles.NFC.mode;
if handles.NFC.mode == 0%'00'
    if get(handles.ch4,'Value') == 1
        set(handles.ch1,'Value',0);
        set(handles.ch2,'Value',0);
        set(handles.ch3,'Value',0);
        handles.NFC.channelS = 8;
    else
        handles.NFC.channelS = 0;
    end
    handles.NFC.channel = handles.NFC.channelS;
    handles.NFC.data(3) = handles.NFC.channel;
    handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
    data = send_commands(handles);
else
    if handles.NFC.channelD0 == 8 || handles.NFC.channelD1 == 8
        set(handles.ch4,'Value',1);
    else
        if get(handles.ch4,'Value') == 1
            off_channel(handles);
            handles.NFC.channelD = handles.NFC.channelD+8-handles.NFC.channelD0;
            handles.NFC.channelD0 = handles.NFC.channelD1;
            handles.NFC.channelD1 = 8;
            handles.NFC.channel = handles.NFC.channelD;
            handles.NFC.data(3) = handles.NFC.channel;
            handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
            data = send_commands(handles);
        end
    end
end
if data(1) ~= 0
    handles.NFC.channelState = handles.NFC.data;
end
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function ch_single_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end

set(handles.ch_dual,  'Enable','On');
set(handles.ch_single,'Enable','Inactive');
set(handles.ch_dual,  'Value',0);
set(handles.ch_single,'Value',1);
set(handles.ch1,      'Enable','On');
set(handles.ch2,      'Enable','On');
set(handles.ch3,      'Enable','On');
set(handles.ch4,      'Enable','On');
set(handles.ch1,      'Value',0);
set(handles.ch2,      'Value',0);
set(handles.ch3,      'Value',0);
set(handles.ch4,      'Value',0);

pw = handles.NFC.T0 * handles.NFC.DC / 100;
set(handles.DC,       'String',num2str(pw));

on_channel(handles,handles.NFC.channelS);

set(handles.ch_inph,  'Visible','Off');
set(handles.ch_outph, 'Visible','Off');
handles.NFC.mode = 0; %'00';
handles.NFC.channel = handles.NFC.channelS;
handles.NFC.address = 0;
% handles.NFC.data = zeros(1,4);
handles.NFC.data = handles.NFC.channelState;
handles.NFC.data(3) = handles.NFC.channelS;
handles.NFC.data(4) = 0;
plot_pulses(handles.NFC.T0,handles.NFC.DC,handles.NFC.mode);
handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
data = send_commands(handles);
if data(1) ~= 0
    handles.NFC.channelState = handles.NFC.data;
end
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function ch_dual_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end
if 1
    set(handles.ch_dual,  'Enable','Inactive');
    set(handles.ch_single,'Enable','On');
    set(handles.ch1,      'Enable','On');
    set(handles.ch2,      'Enable','On');
    set(handles.ch3,      'Enable','On');
    set(handles.ch4,      'Enable','On');
    set(handles.ch_dual,  'Value',1);
    set(handles.ch_single,'Value',0);
    
    set(handles.ch1,      'Value',0);
    set(handles.ch2,      'Value',0);
    set(handles.ch3,      'Value',0);
    set(handles.ch4,      'Value',0);
    
    pw = handles.NFC.T0 * handles.NFC.DC0 / 100;
    set(handles.DC,       'String',num2str(pw));
end

temp = dec2bin(handles.NFC.channelD,4);

if strcmp(temp(1),'1'), set(handles.ch4, 'Value',1); end
if strcmp(temp(2),'1'), set(handles.ch3, 'Value',1); end
if strcmp(temp(3),'1'), set(handles.ch2, 'Value',1); end
if strcmp(temp(4),'1'), set(handles.ch1,  'Value',1); end

set(handles.ch_inph,  'Visible','On');
set(handles.ch_outph, 'Visible','On');
if handles.NFC.dual_phase == 0
    handles.NFC.mode =  1;  % Out of phase
    handles.NFC.dual_phase = 1;
    set(handles.ch_inph,  'Value',0);
    set(handles.ch_outph, 'Value',1);
    set(handles.ch_inph,  'Enable','On');
    set(handles.ch_outph, 'Enable','Inactive');
elseif handles.NFC.dual_phase == 1 % Out of phase
    handles.NFC.mode = handles.NFC.dual_phase;
    set(handles.ch_inph,  'Value',0);
    set(handles.ch_outph, 'Value',1);
    set(handles.ch_inph,  'Enable','On');
    set(handles.ch_outph, 'Enable','Inactive');
elseif handles.NFC.dual_phase == 17 % In of phase
    handles.NFC.mode = handles.NFC.dual_phase;
    set(handles.ch_inph,  'Value',1);
    set(handles.ch_outph, 'Value',0);
    set(handles.ch_outph,  'Enable','On');
    set(handles.ch_inph, 'Enable','Inactive');
end

handles.NFC.channel = handles.NFC.channelD;
handles.NFC.address = 0;
handles.NFC.data = handles.NFC.channelState;
handles.NFC.data(3:4) = [handles.NFC.channel handles.NFC.mode];
handles.NFC.channelState = handles.NFC.data;

plot_pulses(handles.NFC.T0,handles.NFC.DC0,handles.NFC.mode);
handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
data = send_commands(handles);
if data(1)~= 0
    handles.NFC.channelState = handles.NFC.data;
    handles.NFC.dual_phase = handles.NFC.mode;
end
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function ch_inph_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end
set(handles.ch_inph, 'Value',1);
set(handles.ch_outph,'Value',0);
set(handles.ch_inph, 'Enable','Inactive');
set(handles.ch_outph,'Enable','On');
handles.NFC.mode = 17;%'11';
handles.NFC.address = 0;

handles.NFC.data = handles.NFC.channelState;
handles.NFC.data(3:4) = [handles.NFC.channel handles.NFC.mode];
disp(handles.NFC.T0)

plot_pulses(handles.NFC.T0,handles.NFC.DC0,handles.NFC.mode);
handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
data = send_commands(handles);
if data(1)~= 0
    handles.NFC.channelState = handles.NFC.data;
    handles.NFC.dual_phase = handles.NFC.mode;
end
if handles.debug == 1
    display_variables(handles);
end
guidata(hObject, handles);

function ch_outph_Callback(hObject, eventdata, handles)
disp(' ');
if handles.debug == 1
    display_variables(handles);
end

set(handles.ch_inph, 'Value',0);
set(handles.ch_outph,'Value',1);
set(handles.ch_inph, 'Enable','On');
set(handles.ch_outph,'Enable','Inactive');
handles.NFC.mode = 1; %'01';
handles.NFC.address = 0;
handles.NFC.data = handles.NFC.channelState;
handles.NFC.data(3:4) = [handles.NFC.channel handles.NFC.mode];

if handles.NFC.DC0 > 50
    handles.NFC.DC0 = 50;
    set(handles.DC,     'String','50');
end

plot_pulses(handles.NFC.T0,handles.NFC.DC0,handles.NFC.mode);
handles.NFC.message = assemble_message_modeoperation(handles,'setchannel');
data = send_commands(handles);
if data(1) ~= 0
    handles.NFC.channelState = handles.NFC.data;
    handles.NFC.dual_phase = handles.NFC.mode;
end
if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);

function T_Callback(hObject, eventdata, handles)
% Converts from frequency to period
temp = str2double(get(hObject,'String'));
temp0 = temp;
temp = dec2hex(round(1000/temp),4);

handles.NFC.T(1) = hex2dec(temp(1:2));  % MSB
handles.NFC.T(2) = hex2dec(temp(3:4));  % LSB
handles.NFC.T0 = hex2dec(temp);
fprintf('Frequency updated to %d Hz (p = %d ms): ',temp0,handles.NFC.T0);
% Checks how much pw is currently there
handles.NFC.DC0 = round(100*handles.NFC.pw/handles.NFC.T0);
if handles.NFC.T0 < handles.NFC.pw
    handles.NFC.pw = round(handles.NFC.T0/2);
    set(handles.DC,'String',handles.NFC.pw);
    handles.NFC.DC0 = round(100*handles.NFC.pw/handles.NFC.T0);
    fprintf('pulsewidth updated to %d ms (dc = %d %%)\n',handles.NFC.pw,handles.NFC.DC0);
else
    fprintf('pw = %d ms (dc = %d %%)\n',handles.NFC.pw,handles.NFC.DC0);
end
plot_pulses(handles.NFC.T0,handles.NFC.DC0,handles.NFC.mode);
guidata(hObject, handles);

function DC_Callback(hObject, eventdata, handles)
temp = (str2double(get(hObject,'String')));
if handles.NFC.mode == 0 || handles.NFC.mode == 17 % Opt 00 or 11 (single or dual in phase)
    if temp > handles.NFC.T0
        beep;
        set(hObject,'String',handles.NFC.T0);
        handles.NFC.DC0 = 100;
        handles.NFC.pw = handles.NFC.T0;
        fprintf('Frequency = %d Hz (p = %d ms): Maximum pw = %d ms (100%%)!\n',...
            round(1000/handles.NFC.T0),handles.NFC.T0,handles.NFC.T0);
    else
        dc = round(100*temp/handles.NFC.T0);
        handles.NFC.DC0 = dc;
        handles.NFC.pw = temp;
        set(hObject,'String',temp);
        fprintf('Frequency = %d Hz (p = %d ms), pw = %d ms (dc = %d%%)\n',...
            round(1000/handles.NFC.T0),handles.NFC.T0,temp,dc);
    end
    plot_pulses(handles.NFC.T0,handles.NFC.DC0,handles.NFC.mode);
else
    if temp > handles.NFC.T0/2
        beep;
        set(hObject,'String',handles.NFC.T0/2);
        handles.NFC.DC0 = 50;
        handles.NFC.pw = handles.NFC.T0/2;
        fprintf('Frequency = %d Hz (p = %d ms): Maximum pw = %d ms (50%%)!\n',...
            (1000/handles.NFC.T0),handles.NFC.T0,handles.NFC.T0/2);
    else
        dc = 100*temp/handles.NFC.T0;
        handles.NFC.DC0 = dc;
        handles.NFC.pw = temp;
        fprintf('Frequency = %d Hz (p = %d ms), pw = %d ms (dc = %d%%)\n',...
            (1000/handles.NFC.T0),handles.NFC.T0,temp,dc);
    end
    plot_pulses(handles.NFC.T0,handles.NFC.DC0,handles.NFC.mode);
end
guidata(hObject, handles);

function cmd_set_rfpower_Callback(hObject, eventdata, handles)
P0 = dec2hex(handles.NFC.P,2);
msg = ['02002CFF8B020101011E00030008' P0 '800000000000000000000000000000000000000000000000000000'];
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.25; 
dataReceived = send_commands(handles);

if dataReceived(6) == 0
    disp('Data received.');
    msg = '020007FF63';
    msg0 = [];
    for j0=1:(length(msg)/2)
        msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
    end
    crc = CRC16(msg0);
    handles.NFC.message = [msg0 crc];
    handles.NFC.waittime = 0.5;
    dataReceived = send_commands(handles);
else
end

function serial_port_Callback(hObject, eventdata, handles)
contents = cellstr(get(hObject,'String'));
handles.serial.s.port = contents{get(hObject,'Value')};
guidata(hObject, handles);

function cmd_memSummary_Callback(hObject, eventdata, handles)
% Reads the device's entire memory.
if handles.NFC.addressedmode == 0
    disp('Non-addressed mode!');
    msg = '02000BFFB0230000'; %Read 8 blocks starting at 0
else
    str = [];
    for j0 = 1:8
        str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
    end
    str = str(1:(end-1));
    disp(['Addressed mode @ UDID: ' str]);
    temp = strfind(str,'-');
    str(temp) = '';
    msg = ['020013FFB02301' str];
end
msg = [msg '000F']; % Read 0x0F (16) byes from memory starting at 0x00
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
handles.NFC.waittime = 0.5;
data = send_commands(handles);
for j0 = 1:15 
    dataMem(j0,:) = data([2:5]+8+(j0-1)*5)';
end

str0 = sprintf(' \n');
str0 = [str0 sprintf('---------------------------------------------------\n')];
str0 = [str0 sprintf('Block | B3 B2 B1 B0      Description\n')];
str0 = [str0 sprintf('---------------------------------------------------\n')];

data0 = [];

for j0 = 1:13
    data0(j0,1:4) = dataMem(j0,:);
    str0 = [str0 sprintf('  %.2d  |',j0-1)];
    for i0 = 1:4
        str0 = [str0 sprintf(' %s',dec2hex(data0(j0,i0),2))];
    end
    if j0 == 1
        str0 = [str0 sprintf(' -> Mode: ')];
        if data0(j0,2) == 0, indstr = ': Ind OFF';
        else, indstr = ': Ind ON';
        end
        if data0(j0,3) == 0
            str0 = [str0 sprintf(' All OFF')];
        else
            if data0(j0,4) == 0
                str0 = [str0 sprintf(' SC:')];
            elseif data0(j0,4) == 1 
                str0 = [str0 sprintf(' DC-OutPh:')];
            elseif data0(j0,4) == 17
                str0 = [str0 sprintf(' DC-InPh')];
            end
            % Print value
            switch data0(j0,3)
                case 1,  str0 = [str0 sprintf(' Ch1') indstr];
                case 2,  str0 = [str0 sprintf(' Ch2') indstr];
                case 3,  str0 = [str0 sprintf(' Ch1&Ch2') indstr];
                case 4,  str0 = [str0 sprintf(' Ch3') indstr];
                case 5,  str0 = [str0 sprintf(' Ch3&Ch1') indstr];
                case 6,  str0 = [str0 sprintf(' Ch3&Ch2') indstr];
                case 8,  str0 = [str0 sprintf(' Ch4') indstr];
                case 9,  str0 = [str0 sprintf(' Ch4&Ch1') indstr];
                case 10, str0 = [str0 sprintf(' Ch4&Ch2') indstr];
                case 12, str0 = [str0 sprintf(' Ch4&Ch3') indstr];

            end
            % Select which mode
            switch data0(j0,3)
                case {1, 2, 4, 8}
                    set(handles.ch_single,  'Enable','On');
                    set(handles.ch_single,  'Value',1);
                    set(handles.ch_single,'Enable','Inactive');
                case {3, 5, 6, 9, 10, 12}
                    set(handles.ch_dual,'Enable','On');
                    set(handles.ch_dual,'Value',1);
                    set(handles.ch_dual,'Enable','Inactive');
            end
            % Select channel
            switch data0(j0,3)
                case 1 
                    set(handles.ch1,      'Value',1);
                case 2
                    set(handles.ch2,      'Value',1);
                case 3
                    set(handles.ch1,      'Value',1);
                    set(handles.ch2,      'Value',1);
                case 4
                    set(handles.ch3,      'Value',1);
                case 5
                    set(handles.ch1,      'Value',1);
                    set(handles.ch4,      'Value',1);
                case 6
                    set(handles.ch2,      'Value',1);
                    set(handles.ch4,      'Value',1);
                case 8
                    set(handles.ch4,      'Value',1);
                case 9
                    set(handles.ch1,      'Value',1);
                    set(handles.ch8,      'Value',1);
                case 10
                    set(handles.ch2,      'Value',1);
                    set(handles.ch8,      'Value',1);
                case 12
                    set(handles.ch4,      'Value',1);
                    set(handles.ch8,      'Value',1);
            end
        end
    end
    T0tmp = data0(j0,1)*256+data0(j0,2);
    DC0tmp = round(100*(data0(j0,3)*256+data0(j0,4))/T0tmp);
    f = round(1000/T0tmp);
    pw = data0(j0,3)*256+data0(j0,4);
    switch j0-1
        
        case 1
            str0 = [str0 sprintf(' -> Ch 1 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];%hex2dec([dec2hex(data0(j0,2)) dec2hex(data0(j0,3))]),data0(j0,4))];
        case 3
            str0 = [str0 sprintf(' -> Ch 2 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];%hex2dec([dec2hex(data0(j0,2)) dec2hex(data0(j0,3))]),data0(j0,4))];
        case 5
            str0 = [str0 sprintf(' -> Ch 3 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];%hex2dec([dec2hex(data0(j0,2)) dec2hex(data0(j0,3))]),data0(j0,4))];
        case 7
            str0 = [str0 sprintf(' -> Ch 4 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];%hex2dec([dec2hex(data0(j0,2)) dec2hex(data0(j0,3))]),data0(j0,4))];
        case 9
            str0 = [str0 sprintf(' -> Dual in phase F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];%hex2dec([dec2hex(data0(j0,2)) dec2hex(data0(j0,3))]),data0(j0,4))];
        case 11
            str0 = [str0 sprintf(' -> Dual out of phase F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];%hex2dec([dec2hex(data0(j0,2)) dec2hex(data0(j0,3))]),data0(j0,4))];

    end
    str0 = [str0 sprintf('\n')];
    
end
str0 = [str0 sprintf('---------------------------------------------------\n')];
disp(str0);
set(handles.ch1,      'Enable','On');
set(handles.ch2,      'Enable','On');
set(handles.ch3,      'Enable','On');
set(handles.ch4,      'Enable','On');
guidata(hObject, handles);

function UDID_devices_Callback(hObject, eventdata, handles)
temp = get(hObject,'Value');
handles.NFC.UDID = handles.NFC.UDID_s{temp};
guidata(hObject, handles);

function rf_power_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
temp = floor(temp);
if (temp < 2)
    temp = 2;
    set(hObject,'String',2);
elseif (temp > 12)
    temp = 12;
    set(hObject,'String',12);
else 
    set(hObject,'String',temp);
end

handles.NFC.P = temp;
guidata(hObject, handles);

function cmd_RF_ON_OFF_Callback(hObject, eventdata, handles)


function burstperiod_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
temp = floor(temp*1000); % Converts to ms
if (temp > 65000)
    temp = 65000;
    set(hObject,'String',65);
end

handles.NFC.burstperiod = temp;
guidata(hObject, handles);

function cmd_tonic_Callback(hObject, eventdata, handles)
set(handles.cmd_burst,'Value',0);
set(handles.text30,'Enable','Off');
set(handles.burstperiod,'Enable','Off');
handles.NFC.burst = 0;
handles.NFC.tonic = 1;
if get(hObject,'Value') == 0
    set(hObject,'Value',1)
end

function cmd_burst_Callback(hObject, eventdata, handles)
set(handles.cmd_tonic,'Value',0);
set(handles.text30,'Enable','On');
set(handles.burstperiod,'Enable','On');
handles.NFC.burst = 1;
handles.NFC.tonic = 0;
if get(hObject,'Value') == 0
    set(hObject,'Value',1)
end


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                            My funtions
function data = send_commandsX(handles)
if handles.NFC.waittime == 0
    handles.NFC.waittime = 0.1;
end
flushinput(handles.serial.s);            % Cleans input buffer
fprintf('|Sent>>     ');
for ia = 1:length(handles.NFC.message)
    fprintf('%s ',dec2hex(handles.NFC.message(ia),2));
end
fprintf('\n');
if handles.flags.serial_active == 1
    for nAttempts = 1:handles.NFC.nAttempts
        fwrite(handles.serial.s,handles.NFC.message);
        handles.flags.receiving = 1;
        pause(handles.NFC.waittime);
        nData = handles.serial.s.BytesAvailable;
        if nData > 0
            data = fread(handles.serial.s,nData)';
            fprintf('<<Received| ');
            for j0 = 1:(length(data))
                fprintf('%s ',dec2hex(data(j0),2));
            end
            switch dec2hex(data(6),2)
                case '00'
%                     handles.NFC.error = 0;
                    fprintf('\n');
                    return
                case '01'
%                     handles.NFC.error = 1;
                    data = 0;
                    fprintf('\nReader: No transponder in the Reader Field');
                    fprintf('| No response, attempt %d of %d',nAttempts, handles.NFC.nAttempts);
                case '84'
                    if data(7) == 0
%                         handles.NFC.error = 1;
                        data = 0;
                        fprintf('\nReader: RF-Warning\n');
                        return
                    end
            end
        end
        fprintf('\n');
    end
end

function data = send_commands(handles)
if handles.NFC.waittime == 0
    handles.NFC.waittime = 0.25;
end
flushinput(handles.serial.s);            % Cleans input buffer
fprintf('   |Sent>>  ');

for ia = 1:length(handles.NFC.message)
    fprintf('%s ',dec2hex(handles.NFC.message(ia),2));
end
fprintf('\n');

if handles.DEMO == 0
    
    if handles.flags.serial_active == 1
        for nAttempts = 1:handles.NFC.nAttempts
            
            fwrite(handles.serial.s,handles.NFC.message);
            handles.flags.receiving = 1;
            pause(handles.NFC.waittime);
            nData = handles.serial.s.BytesAvailable;
            
            if nData > 0
                data = fread(handles.serial.s,nData)';
                nLength = data(2)*256+data(3);
                
                fprintf('<<Received| ');
                for j0 = 1:(length(data))
                    fprintf('%s ',dec2hex(data(j0),2));
                    if mod(j0,30) == 0
                        fprintf('\n            ');
                    end
                    if j0 > 115
                        break;
                    end
                end
                
                if length(data) >= nLength
                    fprintf('| data OK.');
                    switch dec2hex(data(6),2)
                        case '00'
                            fprintf('\n');
                            return
                        case '01'
                            data = 0;
                            fprintf('\nReader: No transponder in the Reader Field');
                            fprintf('| No response, attempt %d of %d',nAttempts, handles.NFC.nAttempts);
                        case '84'
                            if data(7) == 0
                                %                         handles.NFC.error = 1;
                                data = 0;
                                fprintf('\nReader: RF-Warning\n');
                                return
                            end
                    end
                    fprintf('\n');
                else
                    fprintf('| data loss.');
                end
            end
            if nData == 0
                data = 0;
%                 return
            end
%             fprintf('\n');
            
        end
    end
else
    data = 0;
end

function message = assemble_message_modeoperation(handles,command)
addr = handles.NFC.address;

% Add addressing mode
if handles.NFC.addressedmode == 0
    disp('Non-addressed mode!');
    msgUDID = ''; 
    msgLextra = [0 0];
    addrMode = 0;
else
    str = [];
    for j0 = 1:8
        str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
    end
    str = str(1:(end-1));
    disp(['Addressed mode @ UDID: ' str]);
    temp = strfind(str,'-');
    str(temp) = '';
    msgUDID = handles.NFC.UDID;
    msgLextra = [0 8];
    addrMode = 1;
end

switch command
    case 'setchannel'           %write data
        msgLength = [0 16];
        message = [2 msgLength+msgLextra 255 176 36 addrMode msgUDID addr 1 4 handles.NFC.data];
    case 'readmodeoperation'    %read data
        %02 00 13 FF B0 23 01 E0 02 59 EA B2 43 43 20 00 0F BC D7 
        msgLength = [0 11];
        a = [2 msgLength+msgLextra 255 176 35 addrMode addr '01'];
    case 'setTiming'            %write data
        msgLength = [0 16];
        message = [2 msgLength+msgLextra 255 176 36 addrMode msgUDID addr 1 4 handles.NFC.data];
    case 'Channels_ON'
        msgLength = [0 16];
        message = [2 msgLength+msgLextra 255 176 36 addrMode msgUDID addr 1 4 handles.NFC.data];
    case 'Channels_OFF'
        msgLength = [0 16];
        message = [2 msgLength+msgLextra 255 176 36 addrMode msgUDID addr 1 4 handles.NFC.data];
    case 'Indicator_ON'
        msgLength = [0 16];
        message = [2 msgLength+msgLextra 255 176 36 addrMode msgUDID addr 1 4 handles.NFC.data];
    case 'Indicator_OFF'
        msgLength = [0 16];
        message = [2 msgLength+msgLextra 255 176 36 addrMode msgUDID addr 1 4 handles.NFC.data];
    
end
message = [message CRC16(message)];

function plot_pulses(T0,DC0,Mode0)
% Phase0 = 0, out of phase
np = round(1000/T0);
switch Mode0
    case 0   % Sigle
        for ip = 1:np
            plot([0 0 1 1]*(T0*DC0/100)+T0*(ip-1),[0 1 1 0],'k');
            hold on;
        end
    case 1   % Dual out of phase
        for ip = 1:np
            plot([0 0 1 1]*(T0*DC0/100)+T0*(ip-1),[0 1 1 0],'k');
            hold on;
            plot([0 0 1 1]*(T0*DC0/100)+T0*(ip-0.5),[0 1 1 0],'r');
        end
    case 17   % Dual in phase
        for ip = 1:np
            plot([0 0 1 1]*(T0*DC0/100)+T0*(ip-1),[0 1 1 0],'k');
            hold on;
            plot([0 0 1 1]*(T0*DC0/100)+T0*(ip-1),[0 1 1 0],'--r');
        end
end
hold off;
box off;
xlim([0 1000])
ylim([0 1]);
xlabel('Time (ms)','FontSize',12,'FontWeight','Bold');
ylabel('Signal','FontSize',12,'FontWeight','Bold','Color','None');
set(gca,'FontSize',10,'XTick',0:100:1000,'YTick',[0 1],...
    'YColor','None','Color','None','TickDir','Out');

function data = CRC16(msg)
crc_poly = uint16(hex2dec('8408'));
crc = uint16(hex2dec('FFFF'));
for i=1:length(msg)
    crc = bitxor(crc,msg(i));
    for j=1:8
        if bitand(crc,1)
            crc = bitxor(bitshift(crc,-1),crc_poly);
        else
            crc = bitshift(crc,-1);
        end
    end
end
data = dec2hex(crc,4);
data = [hex2dec(data(3:4)) hex2dec(data(1:2))];

function data = str_hex2dec(data0)
for i0=1:0.5*length(data0)
    data(i0) = hex2dec(data0((i0-1)*2+[1 2]));
end

function off_channel(handles)
switch handles.NFC.channelD0
    case 1, set(handles.ch1,      'Value',0);
    case 2, set(handles.ch2,      'Value',0);
    case 4, set(handles.ch3,      'Value',0);
    case 8, set(handles.ch4,      'Value',0);
end

function on_channel(handles,option)
    set(handles.ch1,'Value',0);
    set(handles.ch2,'Value',0);
    set(handles.ch3,'Value',0);
    set(handles.ch4,'Value',0);
switch option
    case 1, set(handles.ch1,'Value',1);
    case 2, set(handles.ch2,'Value',1);
    case 3, set(handles.ch1,'Value',1); set(handles.ch2,'Value',1);
    case 4, set(handles.ch3,'Value',1);
    case 5, set(handles.ch3,'Value',1); set(handles.ch1,'Value',1);
    case 6, set(handles.ch3,'Value',1); set(handles.ch2,'Value',1);
    case 8, set(handles.ch4,'Value',1);
    case 9, set(handles.ch4,'Value',1); set(handles.ch1,'Value',1);
    case 10, set(handles.ch4,'Value',1); set(handles.ch2,'Value',1);
    case 12, set(handles.ch4,'Value',1); set(handles.ch3,'Value',1);
end

function handles0 = read_state(handles,data)

if handles.debug == 1
    display_variables(handles);
end

handles.NFC.channelState = data((2:5)+8);
State = fliplr(data((2:5)+8));
addrs = [1 3 0 5 0 0 0 7 0 0 0 0];
handles.NFC.mode = State(1);
%Check either channels are on or off
% handles.NFC.indicator = State(3);
% handles.NFC.OnOff = State(2);

% if State(2) == 0, set(handles.ON_OFF,'Value',0); 
% else, set(handles.ON_OFF,'Value', 1); handles.NFC.OnOff = 1;
% end

%Check if the indicator is on or off
indstr = 'OFF';
if State(3) ~= 0, indstr = 'ON'; end
%Check if tonic or burst
if State(4) == 0
    handles.NFC.tonic = 1;
    handles.NFC.burst = 0;
    set(handles.cmd_tonic,'Value',1);
    set(handles.cmd_burst,'Value',0);
    set(handles.text30,'Enable','Off');
    set(handles.burstperiod,'Enable','Off');
else 
    handles.NFC.tonic = 0;
    handles.NFC.burst = 1;
    set(handles.cmd_tonic,'Value',0);
    set(handles.cmd_burst,'Value',1);
    set(handles.text30,'Enable','On');
    set(handles.burstperiod,'Enable','On');
end

if State(2) ~= 0
    switch State(1) %probe the mode
        case 0 % if single channel
            if State(2) == 0, addrs0 = 0;
            else, addrs0 = addrs(State(2));
            end
            handles.NFC.channel = State(2);
            handles.NFC.channelS = State(2);
            set(handles.ch_single,'Value',1);
            set(handles.ch_dual,  'Value',0);
            set(handles.ch_single,'Enable','Inactive');
            set(handles.ch_dual,'Enable','On');
            on_channel(handles,State(2));
        case 1 % out of phase
            addrs0 = 11;
            handles.NFC.channel = State(2);
            handles.NFC.channelD = State(2);
            temp0 = dec2bin(State(2),4);
            temp = strfind(temp0,'1');
            temp0(temp(1)) = '0';
            handles.NFC.channelD0 = bin2dec(temp0);       % Very last dual channel selection
            temp0 = dec2bin(State(2),4);
            temp0(temp(2)) = '0';
            handles.NFC.channelD1 = bin2dec(temp0) ;      % Previous dual channel selection
            
            on_channel(handles,State(2));
            set(handles.ch_inph,  'Visible','On');
            set(handles.ch_outph, 'Visible','On');
            set(handles.ch_inph, 'Enable','On');
            set(handles.ch_outph,'Enable','Inactive');
            set(handles.ch_inph, 'Value',0);
            set(handles.ch_outph,'Value',1);
            
            set(handles.ch_single,'Value',0);
            set(handles.ch_dual,'Value',1);
            set(handles.ch_single,'Enable','On');
            set(handles.ch_dual,'Enable','Inactive');
        case 17 % in phase
            addrs0 = 9;
            handles.NFC.channel = State(2);
            handles.NFC.channelD = State(2);
            temp0 = dec2bin(State(2),4); temp = strfind(temp0,'1'); temp0(temp(1)) = '0';
            handles.NFC.channelD0 = bin2dec(temp0);       % Very last dual channel selection
            temp0 = dec2bin(State(2),4); temp0(temp(2)) = '0';
            handles.NFC.channelD1 = bin2dec(temp0);       % Previous dual channel selection
            
            on_channel(handles,State(2));
            set(handles.ch_inph,  'Visible','On');
            set(handles.ch_outph, 'Visible','On');
            set(handles.ch_inph, 'Enable','Inactive');
            set(handles.ch_outph,'Enable','On');
            set(handles.ch_inph, 'Value',1);
            set(handles.ch_outph,'Value',0);
            
            set(handles.ch_single,'Value',0);
            set(handles.ch_dual,'Value',1);
            set(handles.ch_single,'Enable','On');
            set(handles.ch_dual,'Enable','Inactive');
    end
    
    if handles.NFC.addressedmode == 0
        %     disp('Non-addressed mode!');
        msg = '02000BFFB02300'; %Read 8 blocks starting at 0
    else
        str = [];
        for j0 = 1:8
            str = [str dec2hex(handles.NFC.UDID(j0),2) '-'];    % UDID in string form
        end
        str = str(1:(end-1));
        %     disp(['Addressed mode @ UDID: ' str]);
        temp = strfind(str,'-');
        str(temp) = '';
        msg = ['020013FFB02301' str];
    end
    msg = [msg dec2hex(addrs0,2) dec2hex(1,2)];
    msg0 = [];
    for j0=1:(length(msg)/2)
        msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
    end
    crc = CRC16(msg0);
    handles.NFC.message = [msg0 crc];
    
    % Send commands for finding timing
    data = send_commands(handles);
    % If zero return, then the data is from error
    if data(1) == 0
        disp('No response!');
        return;
    end
    % Check if the length is correct
    if LengthCorrect(data) == 0
        disp('The received message length is not correct.');
        return;
    end
    
    data = data((2:5)+8)';
    fprintf(' -> Mode: ');
    
    if State(2) == 0
        fprintf(' All OFF');
    else
        if State(1) == 0
            fprintf(' Single channel:');
        elseif State(1) == 1
            fprintf(' Dual channel out of phase:');
        elseif State(1) == 17
            fprintf(' Dual channel in phase:')
        end
        switch State(2)
            case 1,  fprintf(' Ch1');
            case 2,  fprintf(' Ch2');
            case 3,  fprintf(' Ch1 & Ch2');
            case 4,  fprintf(' Ch3');
            case 5,  fprintf(' Ch3 & Ch1');
            case 6,  fprintf(' Ch3 & Ch2');
            case 8,  fprintf(' Ch4');
            case 9,  fprintf(' Ch4 & Ch1');
            case 10, fprintf(' Ch4 & Ch2');
            case 12, fprintf(' Ch4 & Ch3');
                
        end
        if State(4) == 0
            fprintf(', Tonic');
        else
            fprintf(', Burst');
        end
    end
    T0tmp = data(1)*256+data(2);
    DC0tmp = round(100*(data(3)*256+data(4))/T0tmp);
    pw = data(3)*256+data(4);
    f = round(1000/T0tmp);
    fprintf(', \n           F = %d Hz (P = %d ms): pw = %d ms (dc = %d%%), Indicator %s\n',f,T0tmp,pw,DC0tmp,indstr);
    
    % temp = dec2hex(str2double(get(hObject,'String')),4);
    
    handles.NFC.T(1) = data(1);
    handles.NFC.T(2) = data(2);
    handles.NFC.T0 = T0tmp;% hex2dec([dec2hex(data(3)) dec2hex(data(4))]);
    handles.NFC.DC = DC0tmp;%data(4);
    handles.NFC.DC0= DC0tmp;%data(4);
    
    set(handles.T,'String',num2str(f));
    set(handles.DC,'String',num2str(pw));
    plot_pulses(handles.NFC.T0,handles.NFC.DC,handles.NFC.mode);
    
else
    
    disp([' -> Mode:  Channels OFF, Indicator ',indstr]);
end
% Enable buttons

set(handles.cmd_write,     'Enable','On');
set(handles.ch_single,     'Enable','On');
set(handles.ch_dual,       'Enable','On');
set(handles.ON_OFF,        'Enable','On');
set(handles.cmd_indicator, 'Enable','On');
set(handles.T,             'Enable','On');
set(handles.DC,            'Enable','On');

set(handles.ch1,           'Enable','On');
set(handles.ch2,           'Enable','On');
set(handles.ch3,           'Enable','On');
set(handles.ch4,           'Enable','On');

handles0 = handles;

function [UDID,n] = get_inventory(handles)
msg = '020009FFB00100';
msg0 = [];
for j0=1:(length(msg)/2)
    msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
end
crc = CRC16(msg0);
handles.NFC.message = [msg0 crc];
data = send_commands(handles);
UDID = [];
str0 = [];
n = 0;
if data(1) == 0
    return
end
n = data(7);                                % Number of devices found

for i0 = 1:n
    
    UDID.num{i0} = data(i0*10-1+(1:8));     % Get the UDID value, dec
    str = [];
    for j0 = 1:8
        str = [str dec2hex(UDID.num{i0}(j0),2) '-'];    % UDID in string form
    end
    UDID.str{i0} = str(1:(end-1));
    
end

function data0 = LengthCorrect(data)
ndata = length(data);
nmessage = data(2)*256+data(3);
data0 = 0;
if nmessage == ndata, data0 = 1; end

function  display_variables(handles0)
disp('Workspace - - - - - - - - - - - - - - - - - - - - - - -');
disp(['channelState = ',num2str(handles0.NFC.channelState)]);
disp(['mode = ',num2str(handles0.NFC.mode)]);
disp(['OnOff = ',num2str(handles0.NFC.OnOff)]);
disp(['Indicator = ',num2str(handles0.NFC.indicator)]);
% disp(['dual_phase = ',num2str(handles0.NFC.dual_phase)]);
disp(['Channel = ',num2str(handles0.NFC.channel)]);
disp('- - - - - - - - - - - - - - - - - - - - - - - - - - - -');

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                     Functions used by the app
function DC_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function T_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function str_send_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function str_received_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function DC_var_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function pulses_fig_CreateFcn(hObject, eventdata, handles)
function addressed_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to addressed_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function rf_power_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rf_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function serial_port_CreateFcn(hObject, eventdata, handles)
% hObject    handle to serial_port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function memory_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to memory_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function UDID_devices_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UDID_devices (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% function memory_txt_Callback(hObject, eventdata, handles)
% hObject    handle to memory_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of memory_txt as text
%        str2double(get(hObject,'String')) returns contents of memory_txt as a double


% --- Executes on button press in read_write_opt.
% function read_write_opt_Callback(hObject, eventdata, handles)
% hObject    handle to read_write_opt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of read_write_opt


% --- Executes on button press in cmd_RF_ON_OFF.
% hObject    handle to cmd_RF_ON_OFF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% hObject    handle to cmd_burst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cmd_burst



% hObject    handle to burstperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of burstperiod as text
%        str2double(get(hObject,'String')) returns contents of burstperiod as a double


% --- Executes during object creation, after setting all properties.
function burstperiod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to burstperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
