Created by: Konstantin Winkel

# RODOS Workspace Template

This is a workspace template centered around RODOS and provides easy to use scripts to make working with RODOS as easy as possible regardless of the platform you're working with.

Currently supported platforms: Linux, STM32F4 Discovery Board, RaspbianOS

Contents:
1. Basic information about RODOS
2. Contents of the workspace
3. Setup and configuration
4. Usage examples
5. Having multiple source directories in one workspace

------------------------------
### 1. Basic information about RODOS
RODOS is a realtime operating system originally developed by Prof. Sergio Montenegro and Dr. Frank Dannemann and is currently being maintained by the University of Würzburg. It is built for embedded systems with high dependabilty demands. 

Further reading:
- RODOS Wikipedia articel: https://en.wikipedia.org/wiki/Rodos_%28operating_system%29
- RODOS Gitlab page: https://gitlab.com/rodos/rodos
- Original paper by Prof. Montenegro and Dr. Dannemann: https://www.montenegros.de/sergio/public/dasia2009-rodos.pdf

------------------------------
### 2. Contents of the workspace
This workspace contains everything you need to immediately start working with RODOS:
- The `rodos_src` directory is the place where you should put all the files you create yourself. It already contains 2 simple example files that you can use to familiarise yourself with working with the scripts contained in this workspace.
- The `scripts` directory contains all the scripts you need to work with RODOS as easily as possible. Every script has the parameter `-h` (for example `./setup.sh -h`) that provides a detailed explaination on how to use the desired script.
    - The `build` directory inside `scripts` contains all the scripts needed to build your RODOS programms for different platforms:
        - `build-for-linux.sh` compiles your files and executes them on your linux machine.
        - `build-for-discovery.sh` compiles your files and flashes them onto a STM32F4 Discovery Board.
        - `build-for-raspbian.sh` compiles your files and executes them on your RaspbianOS.
        - `build-generic.sh` contains functionalities that all build scripts need (such as compilation, help functions etc) and shouldn't be called directly.
    - `build.sh` calls a specific build script based on the preferred platform in workspace.config.
    - `configure-workspace.sh` provides an easy way to change the configuration file form the command line.
    - `setup.sh` initializes the workspace.
- The file `CompileList.txt` is a file where you can specify which files you want to compile. This makes compiling multiple files even easier.
- The file `workspace.config` contains all configuration parameters needed for the scripts to work properly (such as source directory and preferred platform).

------------------------------
### 3. Setup and configuration
First make sure that the setup script has permission to execute by running `sudo chmod +rwx scripts/setup.sh` then execute the setup script by running:
```
./scripts/setup.sh <linux/discovery/rapsbian/other platform>
```
The script will then automatically make sure all required packages are installed and if not installs the missing packages.
It then clones the most up to date RODOS master branch, compiles RODOS for the specified platform and gives execute permissions to the other scripts.

Next you want to configure your workspace to best suit your needs. For this the `configure-workspace.sh` script will come in handy as it provides you with a command line tool to easily change the contents of the `workspace.config` file (of course you can als manually change the file but that can cause errors if the values you write into the file are not valid. When using the scipts it makes sure that everything written to `workspace.config` is valid). 

To change the source directory (or create a new one if the directory specified doesnt exists) use this command:
```
./scripts/configure-workspace.sh -src_dir <name_of_dir>
```

To change the preferred compilation target use this command (make sure that the parameter is one of the supported platforms):
```
./scripts/configure-workspace.sh -target_pref <linux/discovery/raspbian>
```

To change the preferred compile list file usse this command:
```
./scripts/configure-workspace.sh -list_pref <path_to_file>
```

------------------------------
### 4. Usage examples
Here are all the commands to setup the workspace for the STM32F4 Discovery Boards, compile all the example files from the CompileList.txt (parameter `-f`) and flash them onto the board:
```
./scripts/setup.sh discovery
./scripts/build/build-for-discovery.sh -f
```

As another example, here are the commands to setup the workspace for both Linux and the Discovery Board, and then only compile the HelloWorld.cpp file for Linux:

```
./scripts/setup.sh discovery linux
./scripts/build/build-for-linux.sh HelloWorld.cpp
```
Alternatively, since Linux is the preferred target by default, instead of the second command you can simply use:
```
./scripts/build.sh HelloWorld.cpp
```

------------------------------
### 5. Having multiple source directories in one workspace
This workspace allows you to have multiple source directories and multiple compile lists.
When building from the file list and source directory listed in workspace.config simply adding the `-f` parameter to your build script will be enough (as shown in 4.). If you want to build files from a different source directory or compile list without changing the values of workspace.config you can do so by using the `-d=other_src_dir` and the `-f=other_compile_list.txt` parameters respectively. These parameters work on all build scripts and make handling subprojects really easy while only needing a single instance of RODOS

Example:
```
./scripts/build.sh -f=OtherList.txt -d=other_src_dir
```
