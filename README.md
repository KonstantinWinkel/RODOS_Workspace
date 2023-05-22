Created by: Konstantin Winkel

# RODOS Workspace Template

This is a workspace template centered around RODOS and provides easy to use scripts to make working with RODOS as easy as possible regardless of the platform you're working with.

Currently supported platforms: Linux, STM32F4 Discovery Board, RaspbianOS

Contents:
1. Basic information about RODOS
2. Contents of the workspace
3. Setup
4. Usage Examples

------------------------------
### 1. Basic information about RODOS
RODOS is a realtime operating system originally developed by Prof. Sergio Montenegro and Dr. Frank Dannemann and is currently being maintained by the University of Würzburg. It is build for embedded systems with high dependabilty demands. 

Further reading:
- RODOS Wikipedia articel: https://en.wikipedia.org/wiki/Rodos_%28operating_system%29
- RODOS Gitlab page: https://gitlab.com/rodos/rodos
- Original paper by Prof. Montenegro and Dr. Dannemann: https://www.montenegros.de/sergio/public/dasia2009-rodos.pdf

------------------------------
### 2. Contents of the workspace
This workspace contains everything you need to immediately start working with RODOS
- the `rodos_src` directory is the place where you should put all the files you create yourself. It already contains 2 simple example files that you can use to familiarise yourself with the scripts contained in this workspace
- the `scripts` directory contains all the scripts you need to work with RODOS as easily as possible. Every script has the parameter `-h` (for example `./setup.sh -h`) that provides a detailed explaination on how to use the desired script.
    - `setup.sh` initializes the workspace
    - `build-for-linux.sh` compiles your files and executes them on your linux machine
    - `build-for-discovery.sh` compiles your files and flashes them onto a STM32F4 Discovery Board 
- the file `CompileList.txt` is a file where you can specify which files you want to compile. This makes compiling multiple files even easier.
------------------------------
### 3. Setup
First make sure that the setup script has permission to execute by running `sudo chmod +rwx scripts/setup.sh` then execute the setup script by running `./scripts/setup.sh <platform>`. The script will then automatically make sure all required packages are installed and if not installs the missing packages. It then clones the most up to date RODOS master branch, compiles RODOS for the specified platform and gives execute permissions to the other scripts.

------------------------------
### 4. Usage Examples
Here are all the commands to setup the workspace for the STM32F4 Discovery Boards, compile all the example files from the CompileList.txt (parameter `-f`) and flash them onto the board:
```
./scripts/setup.sh discovery
./scripts/build-for-discovery.sh -f
```

As another example, here are the commands to setup the workspace for both Linux and the Discovery Board, and then only compile the HelloWorld.cpp file for Linux:

```
./scripts/setup.sh discovery linux
./scripts/build-for-linux.sh HelloWorld.cpp
```