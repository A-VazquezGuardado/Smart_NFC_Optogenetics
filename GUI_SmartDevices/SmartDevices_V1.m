% Main GUI for optogentics smart devices supporting 4 channels  

% Description: 
% This graphic user interface provides the framework to manipulate up to 
% four NFC optogenetic devices, each containing a single illumination 
% channel (one probe with one LED), within the same experimental enclosure.
% Parameters such as frequency, duty cycle, or tonic vs burst operation 
% can be individually programmed.
%
% Hardware requirement: 
% This GUI interfaces with a FEIG reader model LRM2500-A using RS232 
% serial communication. It uses 38400 baud rate.
%
% Possible issues: 
% -This GUI was tested in MATLAB versions 2018a and 2019b. Possible software
%  incompatibility might arise if attempting to use in newer versions of MATLAB. 
% -This GUI was designed to minimized code crashes. Any further modification 
%  could result in code instability.
% -The software uses RS232 serial communication and a RS232/USB converter
%  might be needed in most modern computers, for which the proper driver 
%  needs to be installed first prior to using this software. 
%
% Disclaimer:
% This GUI was developed to satisfy the experimental needs. Thus, it is 
% not warranted that all functions contained in this program will meet 
% your requirements, neither the operation of the program will be 
% error-free. However, its structural layout and functional logic might
% serve to as the basis to create customized versions that will satisfy 
% specific applications.
%
% Author: Abraham Vazquez-Guardado
% Center for Bio-Integrated Electronics
% Querrey Simpson Institute for Bioelectronics
% Northwestern Univeristy
% Fall 2020
%
% Last Update: Oct. 21nd 2021

function varargout = SmartDevices_V1(varargin)
% SmartDevices_V1 MATLAB code for SmartDevices_V1.fig
%      SmartDevices_V1, by itself, creates a new SmartDevices_V1 or raises the existing
%      singleton*.
%
%      H = SmartDevices_V1 returns the handle to a new SmartDevices_V1 or the handle to
%      the existing singleton*.
%
%      SmartDevices_V1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SmartDevices_V1.M with the given input arguments.
%
%      SmartDevices_V1('Property','Value',...) creates a new SmartDevices_V1 or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SmartDevices_V1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SmartDevices_V1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SmartDevices_V1

% Last Modified by GUIDE v2.5 20-Oct-2021 22:29:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SmartDevices_V1_OpeningFcn, ...
    'gui_OutputFcn',  @SmartDevices_V1_OutputFcn, ...
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

% --- Executes just before SmartDevices_V1 is made visible.
function SmartDevices_V1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SmartDevices_V1 (see VARARGIN)

% Choose default command line output for SmartDevices_V1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

pos = get(gcf,'Position');
pos(1:2) = [-700 300];
set(gcf,'Position',pos);
axes(handles.pulses_fig);
plot_pulses(100,50,'00');

initialize_gui(hObject, handles, false);

% UIWAIT makes SmartDevices_V1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = SmartDevices_V1_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)

handles.DEMO = 0;
global NFC_Ctrl;

ports = seriallist;
[~,b] = size(ports);
set(handles.serial_port,'String',ports);
set(handles.serial_port,'Value',b);

% Set up serial port
NFC_Ctrl = [];
NFC_Ctrl.serial.port = ports{b};      % Serial port used to communicate to the Neurolux PDC box.
NFC_Ctrl.serial.BaudRate = 38400;
NFC_Ctrl.showCommands = 1;          % Display communication commands, good for debugging.
NFC_Ctrl.nTries = 10;               % In some cases there is not communicaiton link in the first attempt
                                    % this variable will indicate how many
                                    % persitent apptents the used want

% Initializes some flags
handles.flags.receiving = 0;
handles.flags.serial_active = 0;
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

handles.NFC.Tch = zeros(1,6);
handles.NFC.pwch = zeros(1,6);
handles.NFC.DCch = zeros(1,6);
handles.NFC.fch = zeros(1,6);
handles.NFC.nPch = zeros(1,6);
        
        
handles.NFC.T = 100;            % Selected period
handles.NFC.f = 10;             % Selected frequency
handles.NFC.pw = 10;            % Selected pulse width [ms]

handles.NFC.UDID = '';          % Unique device identifier for addressed mode
handles.NFC.address = 0;
handles.NFC.data = [0 0 0 0];
handles.NFC.nAttempts = 5;      % Number of attempts to read or write
handles.NFC.indicator = 0;
handles.NFC.OnOff = 0;
handles.NFC.P = 0;

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
    set(handles.f,              'Enable','Off');
    set(handles.pw,             'Enable','Off');
    set(handles.burstperiod,    'Enable','Off');
    set(handles.text25,         'Enable','Off');
    set(handles.text9,          'Enable','Off');
    set(handles.text29,         'Enable','Off');
    set(handles.text30,         'Enable','Off');
    set(handles.npulses,        'Enable','Off');
    set(handles.text32,        'Enable','Off');
    
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

function serial_port_Callback(hObject, eventdata, handles)
global NFC_Ctrl;
contents = cellstr(get(hObject,'String'));
NFC_Ctrl.serial.port = contents{get(hObject,'Value')};
guidata(hObject, handles);

function serial_connect_Callback(hObject, eventdata, handles)
global NFC_Ctrl;
for i=1:40, fprintf('- '); end
fprintf('\nConnecting to RF power module.\n');

if handles.flags.serial_active == 0
    fprintf('Connecting to port: %s\n',NFC_Ctrl.serial.port);
    
    if ~strcmp(NFC_Ctrl.serial.port,' ') % Connect
                
        NFC_Ctrl = NFC_Control(NFC_Ctrl,'CONNECT');
        
        % Reads the current power setting of the RF module        
        NFC_Ctrl = NFC_Control(NFC_Ctrl,'RF_POWER','READ');
        
        if NFC_Ctrl.Acknowledged == 0
            disp('Wrong port!')
            fclose(NFC_Ctrl.serial);
            return
        end
        
        P0 = NFC_Ctrl.RFpower;
        handles.NFC.P = P0;
        set(handles.rf_power,'String',num2str(P0));
        handles.NFC.RFON = 1;
       
        handles.flags.serial_active = 1;
        
        %fprintf('Port open.\n');
        
        % Read power on the Feig reader
%         P0 = dec2hex(handles.NFC.P,2);
%         msg = '02000DFF8A020101000301';
%         msg0 = [];
%         for j0=1:(length(msg)/2)
%             msg0(j0) = hex2dec(msg((j0-1)*2+[1 2]));
%         end
%         crc = CRC16(msg0);
%         handles.NFC.message = [msg0 crc];
%         handles.NFC.waittime = 0.5;
%         dataReceived = send_commands(handles);
        
%         if dataReceived(1) > 0
%             P0 = dataReceived(13);
%             handles.NFC.P = P0;
%             set(handles.rf_power,'String',num2str(P0));
%         else
%             fprintf('\nWrong port.\n');
%             fclose(handles.serial.s);
%             handles.flags.serial_active = 0;
%             return;
%         end
        set(handles.connected,      'Value',1);
        set(handles.serial_port,    'Enable','Off');
        set(handles.rf_power,       'Enable','On');
        set(handles.cmd_set_rfpower,'Enable','On');
        set(handles.serial_connect, 'String','Disconnect');
        set(handles.cmd_read_UDID,  'Enable','On');
        set(handles.cmd_RF_ON_OFF,  'Enable','On');
        set(handles.text29,         'Enable','On');
        
    else
        disp('Select port first');
    end
else % Disconnect
    fprintf('Disconnecting form port: %s\n',NFC_Ctrl.serial.port);
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'DISCONNECT');
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
for i=1:40, fprintf('- '); end
fprintf('\nLooking for devices.\n');
global NFC_Ctrl
NFC_Ctrl = NFC_Control(NFC_Ctrl,'READ_UDID');   
NFC_Ctrl.Acknowledged;

n = NFC_Ctrl.UDID.n;
UDID = NFC_Ctrl.UDID;

if n==0
    disp('No devices found.');
    return;
else
    set(handles.UDID_devices,'Value',1);
    set(handles.UDID_devices,'String',UDID.str);
    handles.NFC.UDID = UDID.num{1};
    handles.NFC.UDID_n = n;                 % Number of devices
    handles.NFC.UDID_s = UDID.num;          % UDIDs in dec format
    handles.NFC.UDID_str = UDID.str;          % UDIDs in str format
    set(handles.cmd_read,       'Enable','On');
    set(handles.cmd_memSummary, 'Enable','On');
    set(handles.UDID_devices,   'Enable','On');
    handles.NFC.UDID_sel = 1;
    guidata(hObject, handles);
end

function cmd_memSummary_Callback(hObject, eventdata, handles)
% Reads the device's entire memory.
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nReading memory summary.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);
% Read 15 block from memory startint at 0
BlockAddr = 0;
NoBlocks = 15;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_RD',BlockAddr,NoBlocks);

if NFC_Ctrl.Acknowledged == 0
    fprintf('Read error, try again.\n');
    return;
end

data = NFC_Ctrl.DataOut;
dataMem = reshape(data,4,15)';
dataMem = fliplr(dataMem);

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
        %data0
        str0 = [str0 sprintf(' -> Mode: ')];
        % Test the indicator
        if data0(j0,2) == 0
            indstr = ': Ind OFF'; 
            set(handles.cmd_indicator,'Value',0);
            handles.NFC.indicator = 0;
        else
            indstr = ': Ind ON'; 
            set(handles.cmd_indicator,'Value',1);
            handles.NFC.indicator = 1;
        end
        
        set(handles.ch1,'Value',0);
        set(handles.ch2,'Value',0);
        set(handles.ch3,'Value',0);
        set(handles.ch4,'Value',0);
        set(handles.cmd_tonic,'Value',1);
        set(handles.cmd_tonic,'Enable','Inactive');
        set(handles.cmd_burst,  'Enable','On');
            
        %Test if there is any channel selected
        if data0(j0,3) == 0
            str0 = [str0 sprintf(' All OFF')];
            set(handles.ON_OFF,'Value',0);
            set(handles.ch_single,'Value',1);
            set(handles.ch_single,'Enable','On');
            set(handles.ch_dual,'Enable','Inactive');
            set(handles.ch_inph,'Visible','Off');
            set(handles.ch_outph,'Visible','Off');
            chindex = 1;            
            handles.NFC.OnOff = 0;
        else
            set(handles.ON_OFF,'Value',1);
            handles.NFC.OnOff = 1;
            % Check if it is in or out of phase
            if data0(j0,4) == 0
                str0 = [str0 sprintf(' SC:')];
                set(handles.ch_single,'Value',1);
                set(handles.ch_dual,'Value',0);
                switch data0(j0,3)
                    case {1,2,4,8}
                        chindex = log2(data0(j0,3))+1;
                    otherwise
                        chindex = 1;
                        data0(j0,3) = 1;
                end
            elseif data0(j0,4) == 1 % out of phase
                str0 = [str0 sprintf(' DC-OutPh:')]; 
                set(handles.ch_inph,'Value',0);
                set(handles.ch_outph,'Value',1);
                set(handles.ch_single,'Value',0);
                set(handles.ch_dual,'Value',1);
                chindex = 6;
            elseif data0(j0,4) == 17 % in phase
                str0 = [str0 sprintf(' DC-InPh')]; 
                set(handles.ch_inph,'Value',1);
                set(handles.ch_outph,'Value',0);
                set(handles.ch_single,'Value',0);
                set(handles.ch_dual,'Value',1);
                chindex = 5;
            end
            
            % Print value
            %data0(j0,3)
            switch data0(j0,3)
                case 1,  str0 = [str0 sprintf(' Ch1') indstr]; chindex = 1;
                case 2,  str0 = [str0 sprintf(' Ch2') indstr]; chindex = 2;
                case 3,  str0 = [str0 sprintf(' Ch1&Ch2') indstr];
                case 4,  str0 = [str0 sprintf(' Ch3') indstr]; chindex = 3;
                case 5,  str0 = [str0 sprintf(' Ch3&Ch1') indstr];
                case 6,  str0 = [str0 sprintf(' Ch3&Ch2') indstr];
                case 8,  str0 = [str0 sprintf(' Ch4') indstr]; chindex = 4;
                case 9,  str0 = [str0 sprintf(' Ch4&Ch1') indstr];
                case 10, str0 = [str0 sprintf(' Ch4&Ch2') indstr];
                case 12, str0 = [str0 sprintf(' Ch4&Ch3') indstr];
            end
            
            % Select which mode
            switch data0(j0,3)
                case {1, 2, 4, 8}
                    set(handles.ch_single,'Enable','On');
                    set(handles.ch_single,'Enable','Inactive');
                    set(handles.ch_dual,'Enable','On');
                    set(handles.ch_outph,'Visible','Off');
                    set(handles.ch_inph,'Visible','Off');
                case {3, 5, 6, 9, 10, 12}
                    set(handles.ch_dual,'Enable','On');
                    set(handles.ch_dual,'Enable','Inactive');
                    set(handles.ch_single,'Enable','On');
                    set(handles.ch_inph,'Enable','On');
                    set(handles.ch_outph,'Enable','On');
                    set(handles.ch_outph,'Visible','On');
                    set(handles.ch_inph,'Visible','On');
                    if data0(j0,4) == 1 % Out of phase
                        set(handles.ch_inph,'Enable','On');
                        set(handles.ch_outph,'Enable','Inactive');
                        set(handles.ch_single,'Enable','On');
                    elseif data0(j0,4) == 17 % In phase
                        set(handles.ch_inph,'Enable','Inactive');
                        set(handles.ch_outph,'Enable','On');
                        set(handles.ch_single,'Enable','On');
                    end        
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
                    set(handles.ch3,      'Value',1);
                case 6
                    set(handles.ch2,      'Value',1);
                    set(handles.ch3,      'Value',1);
                case 8
                    set(handles.ch4,      'Value',1);
                case 9
                    set(handles.ch1,      'Value',1);
                    set(handles.ch4,      'Value',1);
                case 10
                    set(handles.ch2,      'Value',1);
                    set(handles.ch4,      'Value',1);
                case 12
                    set(handles.ch3,      'Value',1);
                    set(handles.ch4,      'Value',1);
            end
        end
    end
    
    T0tmp = data0(j0,1)*256+data0(j0,2);
    DC0tmp = round(100*(data0(j0,3)*256+data0(j0,4))/T0tmp);
    f = round(1000/T0tmp);
    pw = data0(j0,3)*256+data0(j0,4);
   
    switch j0-1
        
        case 1
            str0 = [str0 sprintf(' -> Ch 1 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];
            handles.NFC.Tch(1) = T0tmp;
            handles.NFC.fch(1) = f;
            handles.NFC.pwch(1) = pw;
            handles.NFC.DCch(1) = DC0tmp;
        case 3
            str0 = [str0 sprintf(' -> Ch 2 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];
            handles.NFC.Tch(2) = T0tmp;
            handles.NFC.fch(2) = f;
            handles.NFC.pwch(2) = pw;
            handles.NFC.DCch(2) = DC0tmp;
        case 5
            str0 = [str0 sprintf(' -> Ch 3 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];
            handles.NFC.Tch(3) = T0tmp;
            handles.NFC.fch(3) = f;
            handles.NFC.pwch(3) = pw;
            handles.NFC.DCch(3) = DC0tmp;
        case 7
            str0 = [str0 sprintf(' -> Ch 4 F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];
            handles.NFC.Tch(4) = T0tmp;
            handles.NFC.fch(4) = f;
            handles.NFC.pwch(4) = pw;
            handles.NFC.DCch(4) = DC0tmp;
        case 9
            str0 = [str0 sprintf(' -> Dual in phase F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];
            handles.NFC.Tch(5) = T0tmp;
            handles.NFC.fch(5) = f;
            handles.NFC.pwch(5) = pw;
            handles.NFC.DCch(5) = DC0tmp;
        case 11
            str0 = [str0 sprintf(' -> Dual out of phase F=%dHz (P=%dms): pw=%dms (dc=%d%%)',f,T0tmp,pw,DC0tmp)];
            handles.NFC.Tch(6) = T0tmp;
            handles.NFC.fch(6) = f;
            handles.NFC.pwch(6) = pw;
            handles.NFC.DCch(6) = DC0tmp;
    end
    str0 = [str0 sprintf('\n')];
    
end

str0 = [str0 sprintf('---------------------------------------------------\n')];
disp(str0);
set(handles.ch1,      'Enable','On');
set(handles.ch2,      'Enable','On');
set(handles.ch3,      'Enable','On');
set(handles.ch4,      'Enable','On');
set(handles.ON_OFF,   'Enable','On');
set(handles.cmd_indicator,'Enable','On');

set(handles.f,  'Enable','On');
set(handles.pw,  'Enable','On');
set(handles.cmd_write,  'Enable','On');
set(handles.text25,  'Enable','On');
set(handles.text9,  'Enable','On');

handles.NFC.channelState = fliplr(data0(1,:));
handles.NFC.T  = handles.NFC.Tch(chindex);
handles.NFC.f  = handles.NFC.fch(chindex);
handles.NFC.pw = handles.NFC.pwch(chindex);
handles.NFC.DC = handles.NFC.DCch(chindex);
%handles.NFC.channelState
%chindex
handles.NFC.mode = handles.NFC.channelState(1);
handles.NFC.dual_phase = handles.NFC.mode;
set(handles.f,'String',handles.NFC.f);
set(handles.pw,'String',handles.NFC.pw);
plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);

guidata(hObject, handles);


function f_Callback(hObject, eventdata, handles)
% Converts from frequency to period
f = str2double(get(hObject,'String'));

switch handles.NFC.channelState(1)
    case 1 %out of phase
        chindex = 6;
    case 17
        chindex = 5;
    case 0
        chindex = 1;
        if handles.NFC.channelState(2) > 0
            chindex = log2(handles.NFC.channelState(2))+1;
        end
end

if handles.NFC.burst == 1 
    handles.NFC.f  = f;
    handles.NFC.fch(chindex)  = f;
    plot_pulsesBurst(handles.NFC);
    guidata(hObject, handles);
    return
end

T = round(1000/f);
pw = handles.NFC.pw;
DC = handles.NFC.DC;
fprintf('Frequency updated to %d Hz (p = %d ms): ',f,T);

% Checks how much pw is currently there
if T < pw
    pw = round(T/2);
    set(handles.pw,'String',pw);
    DC = round(100*pw/T);
    fprintf('pulsewidth updated to %d ms (dc = %d %%)\n',pw,DC);
else
    fprintf('pw = %d ms (dc = %d %%)\n',pw,DC);
end

handles.NFC.T  = T;
handles.NFC.f  = f;
handles.NFC.pw = pw;
handles.NFC.DC = DC;

handles.NFC.Tch(chindex)  = T;
handles.NFC.fch(chindex)  = f;
handles.NFC.pwch(chindex) = pw;
handles.NFC.DCch(chindex) = DC;

plot_pulses(T,DC,handles.NFC.mode);
guidata(hObject, handles);

function pw_Callback(hObject, eventdata, handles)
pw = str2double(get(hObject,'String'));

switch handles.NFC.channelState(1)
    case 1 % out of phase
        chindex = 6;
    case 17
        chindex = 7;
    case 0
        chindex = 1;
        if handles.NFC.channelState(2) > 0
            chindex = log2(handles.NFC.channelState(2))+1;
        end
end

if handles.NFC.burst == 1
    handles.NFC.pw = pw;
    handles.NFC.pwch(chindex) = pw;
    plot_pulsesBurst(handles.NFC);
    guidata(hObject, handles);
    return
end

T = handles.NFC.T;
f = handles.NFC.f;
DC = round(100*pw/T);

if handles.NFC.mode == 0 || handles.NFC.mode == 17 % Opt 00 or 11 (single or dual in phase)
    if pw > T
        beep;
        pw = round(T/2);
        DC = round(100*pw/T);
        set(hObject,'String',pw);
        fprintf('Frequency = %d Hz (p = %d ms): Maximum allowed pw = %d ms (100%%)!\n',f,T,T);
    else
        set(hObject,'String',pw);
        fprintf('Frequency = %d Hz (p = %d ms), pw = %d ms (dc = %d%%)\n',f,T,pw,DC);
    end
    plot_pulses(T,DC,handles.NFC.mode);
else
    if pw > T/2
        beep;
        set(hObject,'String',T/2);
        DC = 50;
        pw = round(T/2);
        set(hObject,'String',pw);
        fprintf('Frequency = %d Hz (p = %d ms): Maximum pw = %d ms (50%%)!\n',f,T,pw);
    else
        set(hObject,'String',pw);
        fprintf('Frequency = %d Hz (p = %d ms), pw = %d ms (dc = %d%%)\n',f,T,pw,DC);
    end
    plot_pulses(T,DC,handles.NFC.mode);
end


    
handles.NFC.T  = T;
handles.NFC.f  = f;
handles.NFC.pw = pw;
handles.NFC.DC = DC;

handles.NFC.Tch(chindex)  = T;
handles.NFC.fch(chindex)  = f;
handles.NFC.pwch(chindex) = pw;
handles.NFC.DCch(chindex) = DC;

guidata(hObject, handles);

function burstperiod_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
temp = floor(temp); % Converts to ms
if (temp > 65000)
    temp = 65000;
    set(hObject,'String',65000);
end

switch handles.NFC.channelState(1)
    case 1 % out of phase
        chindex = 6;
    case 17
        chindex = 7;
    case 0
        chindex = 1;
        if handles.NFC.channelState(2) > 0
            chindex = log2(handles.NFC.channelState(2))+1;
        end
end

handles.NFC.T  = temp;
handles.NFC.Tch(chindex) = temp;

if handles.NFC.tonic
    plot_pulses(T,DC,handles.NFC.mode);
else
    plot_pulsesBurst(handles.NFC);
end

guidata(hObject, handles);

function npulses_Callback(hObject, eventdata, handles)
temp = str2double(get(hObject,'String'));
temp = floor(temp);

switch handles.NFC.channelState(1)
    case 1 % out of phase
        chindex = 6;
    case 17
        chindex = 7;
    case 0
        chindex = 1;
        if handles.NFC.channelState(2) > 0
            chindex = log2(handles.NFC.channelState(2))+1;
        end
end

handles.NFC.nP  = temp;
handles.NFC.nPch(chindex) = temp;
if handles.NFC.tonic == 1
    plot_pulses(T,DC,handles.NFC.mode);
else
    plot_pulsesBurst(handles.NFC);
end

guidata(hObject, handles);


function cmd_read_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nRead command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

BlockAddr = 0;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_RD',BlockAddr,1);

if NFC_Ctrl.Acknowledged == 0
    fprintf('Read error, try again.\n');
    return
end

handles.NFC.channelState = NFC_Ctrl.DataOut;

handles = read_state(handles);

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);

function cmd_write_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nRead command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.NFC.tonic == 1
    channindex = [1 3 0 5 0 0 0 7 0 0 0 0];
    T = handles.NFC.T;
    pw = handles.NFC.pw;
    
    if handles.NFC.channel ~= 0
        switch handles.NFC.mode
            case 0 %'00'
                handles.NFC.address = channindex(handles.NFC.channelS);
            case 1% '01'
                handles.NFC.address = 11;
            case 17 %'11'
                handles.NFC.address = 9;
        end
    end
    
    msg = [bitand(pw,255) bitshift(pw,-8) bitand(T,255) bitshift(T,-8)];
    BlockAddr = handles.NFC.address;
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',BlockAddr,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    end
end

if handles.NFC.burst == 1
    channindex = [1 3 0 5 0 0 0 7 0 0 0 0];
    handles.NFC.address = channindex(handles.NFC.channel);
    
    f_hf = handles.NFC.f;%[Hz]
    T_lf = handles.NFC.T;%[ms]
    nP = handles.NFC.nP;%Integer
    pw = handles.NFC.pw;%[ms]
    
    T_hf = uint16(1000000/f_hf);    %[us]
    pw_lf = uint16(T_hf*nP/1000);   %[us]
    dc_hf = uint16(pw*100000/T_hf); %[%]

    msg = [bitand(pw_lf,255) bitshift(pw_lf,-8) bitand(T_lf,255) bitshift(T_lf,-8)];
    BlockAddr = handles.NFC.address;
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',BlockAddr,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    end
    pause(0.1);
    
    msg = [dc_hf bitand(T_hf,255) bitshift(T_hf,-8) 0];
    BlockAddr = handles.NFC.address+1;
    
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',BlockAddr,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    end   

end


function ON_OFF_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

disp('Command: Channel On/Off');
if handles.NFC.channelState(2) == 0
    %if the channel is off star start with either ch1 or ch1/2
    if handles.NFC.mode == 0 % Single channel
        handles.NFC.channelState(2) = handles.NFC.channel;
        set(handles.ch_single,'Value',1);
        
    elseif  handles.NFC.mode == 1   % Dual channel out phase
        handles.NFC.channelState(2) = handles.NFC.channel;
        handles.NFC.channel = 1;
        set(handles.ch1,'Value',1);
        set(handles.ch2,'Value',1);
        set(handles.ch_dual,'Value',1);
        set(handles.ch_outph,'Value',1);
    elseif  handles.NFC.mode == 17   % Dual channel in phase
        handles.NFC.channelState(2) = handles.NFC.channel;
        set(handles.ch1,'Value',1);
        set(handles.ch2,'Value',1);
        set(handles.ch_dual,'Value',1);
        set(handles.ch_inph,'Value',1);
    end
end

if get(handles.ON_OFF,'Value') == 0 % Turn off
    handles.NFC.data = handles.NFC.channelState.*[1 0 1 0];
    msg = handles.NFC.data;
    handles.NFC.OnOff = 0;
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
        handles.NFC.OnOff = 1;
        set(handles.ON_OFF,'Value',1)
    end
else % Turn on
    handles.NFC.data = handles.NFC.channelState;
    msg = handles.NFC.data;
    handles.NFC.OnOff = 1;
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
        handles.NFC.OnOff = 0;
        set(handles.ON_OFF,'Value',1)
    end
end

guidata(hObject, handles);

function cmd_indicator_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

disp('Command: Indicator On/Off');
if get(handles.cmd_indicator,'Value') == 0  % Turn off
    handles.NFC.data = handles.NFC.channelState.*[1 1 0 1];
    msg = handles.NFC.data;
    handles.NFC.indicator = 0;
    handles.NFC.channelState(3) = 0;
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
        handles.NFC.indicator = 1;
        handles.NFC.channelState(3) = 1;
        set(handles.cmd_indicator,'Value',1)
    end
else
    handles.NFC.data = handles.NFC.channelState + [0 0 1 0];
    msg = handles.NFC.data;
    handles.NFC.indicator = 1;
    handles.NFC.channelState(3) = 1;
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
        handles.NFC.indicator = 0;
        handles.NFC.channelState(3) = 0;
        set(handles.cmd_indicator,'Value',1)
    end
end

guidata(hObject, handles);

function ch1_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

if handles.NFC.tonic == 1
handles.NFC.data = handles.NFC.channelState;
handles.NFC.data(1) = handles.NFC.mode;
if handles.NFC.mode == 0 % this is for single channel
    if get(handles.ch1,'Value') == 1
        set(handles.ch2,'Value',0);
        set(handles.ch3,'Value',0);
        set(handles.ch4,'Value',0);
        handles.NFC.channelS = 1;
    else
        handles.NFC.channelS = 0;
    end
    handles.NFC.channel = handles.NFC.channelS;
    handles.NFC.data(2) = handles.NFC.channel;
    chindex = 1;
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
            handles.NFC.data(2) = handles.NFC.channel;
        end
    end
    chindex = 6; % in phase
    if handles.NFC.mode == 1 % out of phase
        chindex = 5;
    end    
end

msg = handles.NFC.data.*[1 handles.NFC.OnOff handles.NFC.indicator 1];

NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
pause(0.25); 
if NFC_Ctrl.Acknowledged == 0
    disp('No data saved to device.');
else
    handles.NFC.T  = handles.NFC.Tch(chindex);
    handles.NFC.f  = handles.NFC.fch(chindex);
    handles.NFC.pw = handles.NFC.pwch(chindex);
    handles.NFC.DC = handles.NFC.DCch(chindex);
    handles.NFC.channelState = handles.NFC.data;
    
    if handles.NFC.f > 0
        plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
        set(handles.f,'String',handles.NFC.f);
        set(handles.pw,'String',handles.NFC.pw);
    end
    
end
end

if handles.NFC.burst == 1
    handles.NFC.data = handles.NFC.channelState;
    if handles.NFC.mode == 0 % this is for single channel
        if get(handles.ch1,'Value') == 1
            set(handles.ch2,'Value',0);
            set(handles.ch3,'Value',0);
            set(handles.ch4,'Value',0);
            handles.NFC.channel = 1;
        else
            handles.NFC.channel = 0;
        end
        handles.NFC.data(2) = handles.NFC.channel;
        chindex = 1;
    end
    
    msg = handles.NFC.data.*[0 handles.NFC.OnOff handles.NFC.indicator 1];
    
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    else
        handles.NFC.f = handles.NFC.fch(chindex);
        handles.NFC.T = handles.NFC.Tch(chindex);
        handles.NFC.nP = handles.NFC.nPch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.channelState = handles.NFC.data;

        if handles.NFC.f > 0
            plot_pulsesBurst(handles.NFC);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
            set(handles.burstperiod,'String',handles.NFC.T);
            set(handles.npulses,'String',handles.NFC.nP);
        end
    end
 
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);

function ch2_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

if handles.NFC.tonic == 1
    handles.NFC.data = handles.NFC.channelState;
    handles.NFC.data(1) = handles.NFC.mode;
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
        handles.NFC.data(2) = handles.NFC.channel;
        chindex = 2;
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
                handles.NFC.data(2) = handles.NFC.channel;
            end
        end
        chindex = 6; % in phase
        if handles.NFC.mode == 1 % out of phase
            chindex = 5;
        end
    end
    
    msg = handles.NFC.data.*[1 handles.NFC.OnOff handles.NFC.indicator 1];
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    else
        handles.NFC.T  = handles.NFC.Tch(chindex);
        handles.NFC.f  = handles.NFC.fch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.DC = handles.NFC.DCch(chindex);
        handles.NFC.channelState = handles.NFC.data;
        
        if handles.NFC.f > 0
            plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
        end
        
    end
end

if handles.NFC.burst == 1
    handles.NFC.data = handles.NFC.channelState;
    if handles.NFC.mode == 0 % this is for single channel
        if get(handles.ch2,'Value') == 1
            set(handles.ch1,'Value',0);
            set(handles.ch3,'Value',0);
            set(handles.ch4,'Value',0);
            handles.NFC.channel = 2;
        else
            handles.NFC.channel = 0;
        end
        handles.NFC.data(2) = handles.NFC.channel;
        chindex = 2;
    end
    
    msg = handles.NFC.data.*[0 handles.NFC.OnOff handles.NFC.indicator 1];
    
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    else
        handles.NFC.f = handles.NFC.fch(chindex);
        handles.NFC.T = handles.NFC.Tch(chindex);
        handles.NFC.nP = handles.NFC.nPch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.channelState = handles.NFC.data;

        if handles.NFC.f > 0
            plot_pulsesBurst(handles.NFC);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
            set(handles.burstperiod,'String',handles.NFC.T);
            set(handles.npulses,'String',handles.NFC.nP);
        end
    end
 
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);

function ch3_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

if handles.NFC.tonic == 1
    handles.NFC.data = handles.NFC.channelState;
    handles.NFC.data(1) = handles.NFC.mode;
    
    if handles.NFC.mode == 0
        if get(handles.ch3,'Value') == 1
            set(handles.ch1,'Value',0);
            set(handles.ch2,'Value',0);
            set(handles.ch4,'Value',0);
            handles.NFC.channelS = 4;
        else
            handles.NFC.channelS = 0;
        end
        handles.NFC.channel = handles.NFC.channelS;
        handles.NFC.data(2) = handles.NFC.channel;
        chindex = 3;
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
                handles.NFC.data(2) = handles.NFC.channel;
            end
        end
        chindex = 6; % in phase
        if handles.NFC.mode == 1 % out of phase
            chindex = 5;
        end
    end
    
    msg = handles.NFC.data.*[1 handles.NFC.OnOff handles.NFC.indicator 1];
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    else
        handles.NFC.T  = handles.NFC.Tch(chindex);
        handles.NFC.f  = handles.NFC.fch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.DC = handles.NFC.DCch(chindex);
        handles.NFC.channelState = handles.NFC.data;
        
        if handles.NFC.f > 0
            plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
        end
        
    end
end

if handles.NFC.burst == 1
    handles.NFC.data = handles.NFC.channelState;
    if handles.NFC.mode == 0 % this is for single channel
        if get(handles.ch3,'Value') == 1
            set(handles.ch2,'Value',0);
            set(handles.ch1,'Value',0);
            set(handles.ch4,'Value',0);
            handles.NFC.channel = 4;
        else
            handles.NFC.channel = 0;
        end
        handles.NFC.data(2) = handles.NFC.channel;
        chindex = 3;
    end
    
    msg = handles.NFC.data.*[0 handles.NFC.OnOff handles.NFC.indicator 1];
    
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    else
        handles.NFC.f = handles.NFC.fch(chindex);
        handles.NFC.T = handles.NFC.Tch(chindex);
        handles.NFC.nP = handles.NFC.nPch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.channelState = handles.NFC.data;

        if handles.NFC.f > 0
            plot_pulsesBurst(handles.NFC);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
            set(handles.burstperiod,'String',handles.NFC.T);
            set(handles.npulses,'String',handles.NFC.nP);
        end
    end
 
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);

function ch4_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

if handles.NFC.tonic == 1
    handles.NFC.data = handles.NFC.channelState;
    handles.NFC.data(1) = handles.NFC.mode;
    
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
        handles.NFC.data(2) = handles.NFC.channel;
        chindex = 4;
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
                handles.NFC.data(2) = handles.NFC.channel;
            end
        end
        chindex = 6; % in phase
        if handles.NFC.mode == 1 % out of phase
            chindex = 5;
        end
    end
    
    msg = handles.NFC.data.*[1 handles.NFC.OnOff handles.NFC.indicator 1];
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    else
        handles.NFC.T  = handles.NFC.Tch(chindex);
        handles.NFC.f  = handles.NFC.fch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.DC = handles.NFC.DCch(chindex);
        handles.NFC.channelState = handles.NFC.data;
        
        if handles.NFC.f > 0
            plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
        end
        
    end
end

if handles.NFC.burst == 1
    handles.NFC.data = handles.NFC.channelState;
    if handles.NFC.mode == 0 % this is for single channel
        if get(handles.ch4,'Value') == 1
            set(handles.ch2,'Value',0);
            set(handles.ch3,'Value',0);
            set(handles.ch1,'Value',0);
            handles.NFC.channel = 8;
        else
            handles.NFC.channel = 0;
        end
        handles.NFC.data(2) = handles.NFC.channel;
        chindex = 4;
    end
    
    msg = handles.NFC.data.*[0 handles.NFC.OnOff handles.NFC.indicator 1];
    
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
    pause(0.25);
    if NFC_Ctrl.Acknowledged == 0
        disp('No data saved to device.');
    else
        handles.NFC.f = handles.NFC.fch(chindex);
        handles.NFC.T = handles.NFC.Tch(chindex);
        handles.NFC.nP = handles.NFC.nPch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.channelState = handles.NFC.data;

        if handles.NFC.f > 0
            plot_pulsesBurst(handles.NFC);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
            set(handles.burstperiod,'String',handles.NFC.T);
            set(handles.npulses,'String',handles.NFC.nP);
        end
    end
 
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);


function ch_single_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

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

on_channel(handles,handles.NFC.channelS);
set(handles.ch_inph,  'Visible','Off');
set(handles.ch_outph, 'Visible','Off');
handles.NFC.mode = 0; %'00';
handles.NFC.channel = handles.NFC.channelS;
handles.NFC.address = 0;
handles.NFC.data = handles.NFC.channelState;
handles.NFC.data(2) = handles.NFC.channelS;
handles.NFC.data(1) = 0;

msg = handles.NFC.data.*[0 handles.NFC.OnOff handles.NFC.indicator 1];

NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
pause(0.25); 

if NFC_Ctrl.Acknowledged == 0
    disp('No data saved to device.');
else
    if handles.NFC.channelS > 0
        chindex = log2(handles.NFC.channelS)+1;
        handles.NFC.T  = handles.NFC.Tch(chindex);
        handles.NFC.f  = handles.NFC.fch(chindex);
        handles.NFC.pw = handles.NFC.pwch(chindex);
        handles.NFC.DC = handles.NFC.DCch(chindex);
        handles.NFC.channelState = handles.NFC.data;
        
        if handles.NFC.f > 0
            plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
            set(handles.f,'String',handles.NFC.f);
            set(handles.pw,'String',handles.NFC.pw);
        end
    end
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);

function ch_dual_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

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
    
%     pw = handles.NFC.T0 * handles.NFC.DC0 / 100;
%     set(handles.pw,       'String',num2str(pw));
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
handles.NFC.data(1:2) = [handles.NFC.mode handles.NFC.channel];
handles.NFC.channelState = handles.NFC.data;

msg = handles.NFC.data.*[1 handles.NFC.OnOff handles.NFC.indicator 1];

NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
pause(0.25); 

chindex = 5;
if handles.NFC.mode == 1 % out of phase
    chindex = 6;
end

if NFC_Ctrl.Acknowledged == 0
    disp('No data saved to device.');
else
    handles.NFC.T  = handles.NFC.Tch(chindex);
    handles.NFC.f  = handles.NFC.fch(chindex);
    handles.NFC.pw = handles.NFC.pwch(chindex);
    handles.NFC.DC = handles.NFC.DCch(chindex);
    handles.NFC.channelState = handles.NFC.data;
    
    if handles.NFC.f > 0
        plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
        set(handles.f,'String',handles.NFC.f);
        set(handles.pw,'String',handles.NFC.pw);
    end
    
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);


function ch_inph_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

set(handles.ch_inph, 'Value',1);
set(handles.ch_outph,'Value',0);
set(handles.ch_inph, 'Enable','Inactive');
set(handles.ch_outph,'Enable','On');
handles.NFC.mode = 17;
handles.NFC.dual_phase = 17;

msg = handles.NFC.channelState.*[0 handles.NFC.OnOff handles.NFC.indicator 1];
msg(1) = handles.NFC.mode;

NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
pause(0.25); 

if NFC_Ctrl.Acknowledged == 0
    disp('No data saved to device.');
    set(handles.ch_inph, 'Value',0);
    set(handles.ch_outph,'Value',0);
    set(handles.ch_inph, 'Enable','On');
    set(handles.ch_outph,'Enable','On');
else
    chindex = 5;
    handles.NFC.T  = handles.NFC.Tch(chindex);
    handles.NFC.f  = handles.NFC.fch(chindex);
    handles.NFC.pw = handles.NFC.pwch(chindex);
    handles.NFC.DC = handles.NFC.DCch(chindex);
    
    if handles.NFC.f > 0
        plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
        set(handles.f,'String',handles.NFC.f);
        set(handles.pw,'String',handles.NFC.pw);
    end
    
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);

function ch_outph_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

if handles.debug == 1
    display_variables(handles);
end

set(handles.ch_inph, 'Value',0);
set(handles.ch_outph,'Value',1);
set(handles.ch_inph, 'Enable','On');
set(handles.ch_outph,'Enable','Inactive');
handles.NFC.mode = 1; %'01';
handles.NFC.dual_phase = 1;

msg = handles.NFC.channelState.*[0 handles.NFC.OnOff handles.NFC.indicator 1];
msg(1) = handles.NFC.mode;

NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);
pause(0.25); 

if NFC_Ctrl.Acknowledged == 0
    disp('No data saved to device.');
    set(handles.ch_inph, 'Value',0);
    set(handles.ch_outph,'Value',0);
    set(handles.ch_inph, 'Enable','On');
    set(handles.ch_outph,'Enable','On');
else
    chindex = 6;
    handles.NFC.T  = handles.NFC.Tch(chindex);
    handles.NFC.f  = handles.NFC.fch(chindex);
    handles.NFC.pw = handles.NFC.pwch(chindex);
    handles.NFC.DC = handles.NFC.DCch(chindex);
    
    if handles.NFC.f > 0
        plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
        set(handles.f,'String',handles.NFC.f);
        set(handles.pw,'String',handles.NFC.pw);
    end
    
end

if handles.debug == 1
    display_variables(handles);
end

guidata(hObject, handles);


function cmd_tonic_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

fprintf('\nTiming parameters need to be reprogrammed!.\n');
beep;

set(handles.cmd_burst,'Value',0);
set(handles.text30,'Enable','Off');
set(handles.burstperiod,'Enable','Off');
set(handles.npulses,'Enable','Off');
set(handles.text32,'Enable','Off');
set(handles.cmd_tonic,'Enable','Inactive');
set(handles.cmd_burst,'Enable','On');
set(handles.ch_dual,'Visible','On');
set(handles.ch_single,'Value',1);
set(handles.ch_dual,'Value',0);
set(handles.ch1,'Value',0);
set(handles.ch2,'Value',0);
set(handles.ch3,'Value',0);
set(handles.ch4,'Value',0);
set(handles.cmd_indicator,'Value',1);
set(handles.ON_OFF,'Value',0);
handles.NFC.channelState = [0 0 1 0];
handles.NFC.OnOff = 0;
handles.NFC.indicator = 1;

handles.NFC.burst = 0;
handles.NFC.tonic = 1;

handles.NFC.channelState = [0 0 1 0];
msg = handles.NFC.channelState;

NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);

if NFC_Ctrl.Acknowledged == 0
    disp('No data saved to device.');
    return;
end

if get(hObject,'Value') == 0
    set(hObject,'Value',1)
end
guidata(hObject, handles);

function cmd_burst_Callback(hObject, eventdata, handles)
global NFC_Ctrl
for i=1:40, fprintf('- '); end
fprintf('\nWrite command.\n');
index = handles.NFC.UDID_sel;
NFC_Ctrl = NFC_Control(NFC_Ctrl,'SELECT_NFC_DEVICE',index);

handles.NFC.channelState = [0 0 1 1];
msg = handles.NFC.channelState;

NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_WR',0,msg);

if NFC_Ctrl.Acknowledged == 0
    disp('No data saved to device.');
    return;
end

fprintf('\nBurst mode activated. Update parameters for each channel. Dual modes is not supported yet\n');

% This functionality is not implemented yet
set(handles.cmd_tonic,'Value',0);
set(handles.text30,'Enable','On');
set(handles.burstperiod,'Enable','On');
set(handles.cmd_burst,'Enable','Inactive');
set(handles.cmd_tonic,'Enable','On');
set(handles.text32,'Enable','On');
set(handles.npulses,'Enable','On');
set(handles.ch_dual,'Visible','Off');
set(handles.ch_inph,'Visible','Off');
set(handles.ch_outph,'Visible','Off');
set(handles.ch_single,'Value',1);
set(handles.ch1,'Value',1);
set(handles.ch2,'Value',0);
set(handles.ch3,'Value',0);
set(handles.ch4,'Value',0);
handles.NFC.burst = 1;
handles.NFC.tonic = 0;

set(handles.cmd_indicator,'Value',1);
set(handles.ON_OFF,'Value',0);
handles.NFC.channelState = [0 0 1 1];
handles.NFC.OnOff = 0;
handles.NFC.indicator = 1;

handles.NFC.channel = 1;
handles.NFC.mode = 0;
handles.NFC.address = 1;

% Write the burst period example
% 1 s period, 5 pulses with 10 ms pw @ 20 Hz
chindex = 1;

% Input parameters
f_hf = 20;      %[Hz]
pw_hf = 10;        %[ms]
T_lf = 1000;    %[ms]
nP = 5;         %Integer

T_hf = 1000000/f_hf;    %[us]
pw_lf = T_hf*nP/1000;   %[us]
dc_hf = pw_hf*100000/T_hf; %[%]

handles.NFC.fch(chindex) = f_hf;
handles.NFC.Tch(chindex) = T_lf;
handles.NFC.nPch(chindex) = nP;
handles.NFC.pwch(chindex) = pw_hf;

handles.NFC.f = f_hf;
handles.NFC.T = T_lf;
handles.NFC.nP = nP;
handles.NFC.pw = pw_hf;

set(handles.f,'String',f_hf)
set(handles.pw,'String',pw_hf)
set(handles.burstperiod,'String',T_lf);
set(handles.npulses,'String',nP);

plot_pulsesBurst(handles.NFC);

if get(hObject,'Value') == 0
    set(hObject,'Value',1)
end


guidata(hObject, handles);


function UDID_devices_Callback(hObject, eventdata, handles)
temp = get(hObject,'Value');
handles.NFC.UDID = handles.NFC.UDID_s{temp};
handles.NFC.UDID_sel = temp;
guidata(hObject, handles);

function cmd_set_rfpower_Callback(hObject, eventdata, handles)
for i=1:40, fprintf('- '); end
fprintf('\n');
global NFC_Ctrl
P0 = handles.NFC.P;
fprintf('Setting RF power = %d W.\n',P0); 
NFC_Ctrl = NFC_Control(NFC_Ctrl,'RF_POWER','SET',P0);

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
for i=1:40, fprintf('- '); end
fprintf('\n');

global NFC_Ctrl
if handles.NFC.RFON == 1 % If ON, then turn OFF
    fprintf('Turning off RF field.\n');
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'RF_POWER','OFF');
    set(handles.cmd_RF_ON_OFF,'String','RF ON');
    handles.NFC.RFON = 0;
else
    fprintf('Turning RF field back on.\n');
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'RF_POWER','ON');
    handles.NFC.RFON = 1;
    set(handles.cmd_RF_ON_OFF,'String','RF OFF');
end
guidata(hObject, handles);


function str_send_Callback(hObject, eventdata, handles)
temp = get(hObject, 'String')
handles.strings.str_send = temp;
guidata(hObject,handles)
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                            My funtions

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

function plot_pulsesBurst(NFC)

f_hf = NFC.f;
T_lf = NFC.T;
nP = NFC.nP;
pw_hf = NFC.pw;
T_hf = 1000/f_hf;

for ip = 1:nP
    plot([0 0 1 1]*(pw_hf)+T_hf*(ip-1),[0 1 1 0],'k');
    hold on;
end

xTicks = 0:T_lf/10:T_lf;
hold off;
box off;
xlim([0 T_lf])
ylim([0 1]);
xlabel('Time (ms)','FontSize',12,'FontWeight','Bold');
ylabel('Signal','FontSize',12,'FontWeight','Bold','Color','None');
set(gca,'FontSize',10,'XTick',xTicks,'YTick',[0 1],...
    'YColor','None','Color','None','TickDir','Out');

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

function handles0 = read_state(handles)
global NFC_Ctrl

if handles.debug == 1
    display_variables(handles);
end

State = handles.NFC.channelState; %[MODE, CH, IND, BT]
% CH will be used from the selected options

%Check if the indicator is on or off
indstr = 'OFF';
if State(3) ~= 0 % The indicator is on
    indstr = 'ON'; 
   set(handles.cmd_indicator,'Value', 1);
   handles.NFC.indicator = 1;
else % The indicator is off
   set(handles.cmd_indicator,'Value', 0);
   handles.NFC.indicator = 0;
end

if State(2) == 0     % The channels are off
   set(handles.ON_OFF,'Value', 0);
   handles.NFC.OnOff = 0;
else
   set(handles.ON_OFF,'Value', 1);
   handles.NFC.OnOff = 1;
end

if State(1) == 0
    if get(handles.ch1,'Value') == 1
        State(2) = 1;
    elseif get(handles.ch2,'Value') == 1
        State(2) = 2;
    elseif get(handles.ch3,'Value') == 1
        State(2) = 4;
    elseif get(handles.ch4,'Value') == 1
        State(2) = 8;
    else
        State(2) = 1;
    end
end

addrs = [1 3 0 5 0 0 0 7 0 0 0 0];
handles.NFC.mode = State(1);
handles.NFC.dual_phase = State(1);

%Check if tonic or burst
if State(4) == 0 % Tonic
    handles.NFC.tonic = 1;
    handles.NFC.burst = 0;
    set(handles.cmd_tonic,'Value',1);
    set(handles.cmd_tonic,'Enable','Inactive');
    set(handles.cmd_burst,'Value',0);
    set(handles.cmd_burst,'Enable','On');
    set(handles.text30,'Enable','Off');
    set(handles.burstperiod,'Enable','Off');
    nB = 1;
else % Burst
    handles.NFC.tonic = 0;
    handles.NFC.burst = 1;
    set(handles.cmd_tonic,'Value',0);
    set(handles.cmd_tonic,'Enable','On');
    set(handles.cmd_burst,'Value',1);
    set(handles.cmd_burst,'Enable','Inactive');
    set(handles.text30,'Enable','On');
    set(handles.burstperiod,'Enable','On');
    nB = 2; % it read two blocks if using burst mode
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
    
    NFC_Ctrl = NFC_Control(NFC_Ctrl,'NFC_RD',addrs0,nB);

    if NFC_Ctrl.Acknowledged == 0
        fprintf('Read error, try again.\n');
        return
    end
    
    data = fliplr(NFC_Ctrl.DataOut);
   
    fprintf(' -> Mode: ');
    
    if State(2) == 0
        fprintf(' All OFF');
        chindex = 1;
    else
        if State(1) == 0
            fprintf(' Single channel:');
            if State(2) > 0
                chindex = log2(State(2))+1;
            else
                chindex = 1;
            end
        elseif State(1) == 1 % out of phase
            fprintf(' Dual channel out of phase:');
            chindex = 6;
        elseif State(1) == 17
            fprintf(' Dual channel in phase:');
            chindex = 5;
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
    
    if handles.NFC.tonic == 1
        T0tmp = data(1)*256+data(2);
        DC0tmp = round(100*(data(3)*256+data(4))/T0tmp);
        pw = data(3)*256+data(4);
        f = round(1000/T0tmp);
        fprintf(', \n           F = %d Hz (P = %d ms): pw = %d ms (dc = %d%%), Indicator %s\n',f,T0tmp,pw,DC0tmp,indstr);

        handles.NFC.Tch(chindex) = T0tmp;
        handles.NFC.fch(chindex) = f;
        handles.NFC.pwch(chindex) = pw;
        handles.NFC.DCch(chindex) = DC0tmp;

        handles.NFC.T  = T0tmp;
        handles.NFC.pw = pw;
        handles.NFC.DC = DC0tmp;
        handles.NFC.f  = f;

        set(handles.f,'String',num2str(f));
        set(handles.pw,'String',num2str(pw));

        plot_pulses(handles.NFC.T,handles.NFC.DC,handles.NFC.mode);
    end
    
    if handles.NFC.burst == 1

        % All numbers in ms
        data = fliplr(data);
        T_lf = data(4)*256+data(3);
        pw_lf = data(2)*256+data(1); % Used to estimate the number of pulses
        T_hf = (data(7)*256+data(6))/1000;
        dc_hf = data(5);
        
        pw_hf = T_hf*dc_hf/100;
        f_hf = 1e3/(T_hf);
        nP = floor(pw_lf/T_hf);
        
        fprintf(' mode,\n           Period = %d ms: %d pulses, pw = %d ms, at F = %d Hz, Indicator %s\n',...
                 T_lf,nP,pw_hf,f_hf,indstr);

        handles.NFC.fch(chindex) = f_hf;
        handles.NFC.Tch(chindex) = T_lf;
        handles.NFC.nPch(chindex) = nP;
        handles.NFC.pwch(chindex) = pw_hf;

        handles.NFC.f = f_hf;
        handles.NFC.T = T_lf;
        handles.NFC.nP = nP;
        handles.NFC.pw = pw_hf;
 
        set(handles.f,'String',f_hf);
        set(handles.pw,'String',pw_hf);
        set(handles.burstperiod,'String',T_lf);
        set(handles.npulses,'String',nP);
        plot_pulsesBurst(handles.NFC);

        set(handles.ch_dual,'Visible','Off');
        set(handles.ch_inph,'Visible','Off');
        set(handles.ch_outph,'Visible','Off');
    end
    
else
    disp([' -> Mode:  Channels OFF, Indicator ',indstr]);
end
% Enable buttons

set(handles.cmd_write,     'Enable','On');
set(handles.ON_OFF,        'Enable','On');
set(handles.cmd_indicator, 'Enable','On');
set(handles.f,             'Enable','On');
set(handles.pw,            'Enable','On');

set(handles.ch1,           'Enable','On');
set(handles.ch2,           'Enable','On');
set(handles.ch3,           'Enable','On');
set(handles.ch4,           'Enable','On');

set(handles.text9,         'Enable','On');
set(handles.text25,        'Enable','On');

handles0 = handles;

function  display_variables(handles0)
disp('Workspace - - - - - - - - - - - - - - - - - - - - - - -');
disp(['channelState = ',num2str(handles0.NFC.channelState)]);
disp(['mode = ',num2str(handles0.NFC.mode)]);
disp(['OnOff = ',num2str(handles0.NFC.OnOff)]);
disp(['Indicator = ',num2str(handles0.NFC.indicator)]);
disp(['Channel = ',num2str(handles0.NFC.channel)]);
disp('- - - - - - - - - - - - - - - - - - - - - - - - - - - -');

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%                     Functions used by the app
function pw_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function f_CreateFcn(hObject, eventdata, handles)
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
function burstperiod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to burstperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function npulses_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
