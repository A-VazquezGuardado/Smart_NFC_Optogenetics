# Smart NFC Optogenetics

This repository contains a stand-alone graphic user interface (GUI) implemented in MATLAB (The MathWorks Inc). This GUI establishes a connection via serial interface with the LRM2500-A(B) NFC reader (Feig Electronics Inc). 

The GUI is an intuitive interface that provides configuration/operation access to the implantable devices.

System requirements:
This GUI runs in MATLAB 2017a and newer versions in both Mac and Windows operating systems.
No additional toolboxes or libraries are needed to run this GUI.
MATLAB and the NFC reader are connected via RS232 serial interface and a RS232 to USB adapter is required. Commercial systems such as those provided by NeuroLux Inc are self-contained hardware that do not require any additional adapter.

Installation instructions:
This GUI does not require installation. However, MATLAB must be installed prior to utilizing this software.
Download the .m and .fig files to a local folder.

Operation:
Connect the NFC reader or NeuroLux PDC box.
Open the .m file in MATLAB and hit the run button. The GUI will open.
Select the serial port to establish communication with the hardware.
Detailed operation modes are described in the manuscript.

