# FlexComSwitch
is a cutting-edge VHDL communication controller that supports dynamic protocol switching between CAN, LIN, and FlexRay. Designed with advanced timing and synchronization, this project demonstrates a high level of hardware design proficiency.

## Features
- Multi-Protocol Support: Seamlessly switches between CAN, LIN, and FlexRay.
- Dynamic Switching: Adapts to network conditions in real-time.
- Advanced Timing and Sync: Ensures precise communication with enhanced synchronization.

## Getting Started
1. Clone the Repo:
    - `git clone https://github.com/yezzfusl/FlexComSwitch.git`
2. Compile the VHDL Files:
    - Navigate to the `src` directory:
        - `cd FlexComSwitch/src`
    - Use your preferred VHDL synthesis tool to compile the files. For example, using `ghdl`:
        `ghdl -a can_protocol/*.vhd lin_protocol/*.vhd flexray_protocol/*.vhd common/*.vhd top_level.vhd`
3. Run Simulations:
    - Analyze and Elaborate:
        - `ghdl -a top_level.vhd`
        - `ghdl -e top_level`
    - Run Simulation and Generate a VCD File:
        - `ghdl -r top_level --vcd=simulation.vcd`
    - View the Simulation Results:
        - `gtkwave simulation.vcd`

## Contribution
Feel free to fork the repo, make changes, and submit pull requests. Let’s innovate together!

## License
This project is licensed under the MIT License

