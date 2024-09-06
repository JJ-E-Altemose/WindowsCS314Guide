# Disclaimer
This is not an official script you should still run it on a linux machine to make sure it works
# Guide
Step 1. Download the run.ps1 and windowspackage.json and place it in the bin folder of your repository.  
  
Step 2 Open up the windowspackage.json and replace all <TeamNumber> with your team number and replace all <REPOSITORY DIRECTORY> with the path to your repository make sure to replace all / with back slashes in your path 
  
Step 2A rename the the windowspackage.json to what ever you wish and then change the variable at the top of the ps1 called $yourPackageFileName to the new name

Step 3 Maven you have to options for setting up maven you can either set it up in your IDE and build it before you run the powershell file or you can install it from https://maven.apache.org/download.cgi (make sure to install the binary file not the source file) and set the $pathToMavenCMD variable to the path to the mvn.cmd in that folder and in the windowspackage change server.jar to server-null.jar

Step 4 Download Node.js from https://nodejs.org/en/download/prebuilt-installer

Step 5 cd into your bin folder in command line and run npm -install

Step 6 restart pc

Step 7 terminal into the base path of your directory and enter \bin\run.ps1

# Java important info 
It is recommended to have the same version of linux as the cs machines the current version is 1.8 if you are running jave 18+ you will need to switch off of it as one of the test will not run (there is a option to disable testing in the powershell by changing the $testSkip variable to "yes" but this is not recommended)

If you get a java version missmatch your java -version and javac -version commands will show a diffrent output if this is the case uninstall all instances of java and reinstall it (you can also edit system paths but i would not recommend this)

# Other Info

<span style="color:red"> DO NOT CTRL+C to stop execution of the powershell file</span>
<br>
<span style="color:yellow"> Does not run postman tests I might add that later</span>.