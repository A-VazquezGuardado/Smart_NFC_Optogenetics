# Smart NFC Optogenetics

This repository contains the follwowing:
- Stand-alone graphic user interface (GUI) implemented in MATLAB (The MathWorks Inc). This GUI establishes a connection via serial interface with the LRM2500-A(B) NFC reader (Feig Electronics Inc), offering an intuitive interface to provide configuration/operation access to the implantable devices.
- CAD designs for bilateral head mounted (HM) with 3mm long probe and back mounted (BM) versions. 
- Arduino firmaware for the ATTINY84 microcontroller, compatible with both HM and BM.

## System requirements:

- This GUI runs in MATLAB 2017a and newer versions in both Mac and Windows operating systems.
- No additional toolboxes or libraries are needed to run this GUI.
- MATLAB and the NFC reader are connected via RS232 serial interface and requires a RS232 to USB adapter. Commercial systems such as those provided by NeuroLux Inc are self-contained hardware that do not require any additional adapter.

## Installation instructions:

- This GUI does not require installation. However, MATLAB must be installed prior to utilizing this software.
- Download the .m, .fig and .p files and store them in a local folder.

## Operation:

- Connect the NFC reader or NeuroLux PDC box.
- Open the .m file in MATLAB and hit the run button to open the GUI.
- Select the serial port to establish communication with the hardware.
- Detailed operation modes, such as configuration and operation of the devices, are described in the manuscript.

## Microcontroller programming:

- The library TinyWireM.h is required. Further information regarding use and installation can be found here (https://github.com/nadavmatalon/TinyWireM).
- Programming ATTINY84 using Arduino requires the ATTinyCore package. Instruction of how to install and use this package can be found here (https://github.com/SpenceKonde/ATTinyCore/blob/master/Installation.md).



https://zenodo.org/badge/latestdoi/371785386
