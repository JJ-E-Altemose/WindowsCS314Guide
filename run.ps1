$pathToMavenCMD = ""

$pathToNPM = ""

$yourPackageFileName = "windowspackage.json"

$testSkip = "yes"


function WriteFileToOutput
{
    <#
    .SYNOPSIS
    Write File to Console output
    .DESCRIPTION
    Write File to Console output
    #>

    param
    (

    [String]
    #path to the file you want to write to the console
    $filePath

    )

    $fileContents = Get-Content -Path $filePath

    Write-Output $fileContents
}


function ReadCommandOut
{
    <#
    .SYNOPSIS
    Reads the output from a command
    .DESCRIPTION
    Reads the output from console.out and console.err and writes it to the console
    #>

    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath

    )

    $output = $basePath + "\bin\console.out"
    $erroroutput = $basePath + "\bin\console.err"

    $outContent = Get-Content -Path $output
    $errorOutContent = Get-Content -Path $erroroutput

    Write-Output $outContent

    Write-Debug $errorOutContent
}


function Get-Base-Project-Path
{
    <#
    .SYNOPSIS
    Gets the base path of this project
    .DESCRIPTION
    Gets the base path of the project by going to the directory right before the bin directory
    .OUTPUTS
    System.String. Returns the path of this project
    #>

    $basePath = $PSScriptRoot

    $basePathArray = $basePath -split "\\"

    $basePath = ""

    foreach ($pathSegment in $basePathArray)
    {
        if( ! $pathSegment.Equals("bin"))
        {
            $basePath += $pathSegment + "\"
        }
    }

    return $basePath
}


function Swap-Linux-Package-With-Windows-Package
{
    <#
    .SYNOPSIS
    Swaps your package in for running
    .DESCRIPTION
    Swaps the spesified package with the default one in the client directory the swapped out file will tempory renamed to linuxpackage.json
    #>

    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath,

    [String]
    #The name of your json package must be in the bin folder along side this file
    $yourPackageFileName

    )

    $livePath = $BasePath + "client\package.json"

    $cachedPath = $BasePath + "bin\linuxpackage.json"

    Move-Item -Path $livePath -Destination $cachedPath

    $cachedPath = $BasePath + "bin\" + $yourPackageFileName

    Move-Item -Path $cachedPath -Destination $livePath
}


function GetPathWith
{
    <#
    .SYNOPSIS
    Gets the path to a exe or .cmd
    .DESCRIPTION
    Gets the path to a exe or .cmd by using enviroment variables
    #>

    param
    (

    [String]
    #the string the the enviroment path
    $stringInPath

    )

    $enviromentPaths = $env:Path -Split ";"
    foreach($path in $enviromentPaths)
    {
        
        $conditional = $path.IndexOf($stringInPath) -ge 0

        if($conditional)
        {
            return $path
        }
    }
}


function GetNPMPathToExe
{
    <#
    .SYNOPSIS
    Gets the path of npm.cmd
    .DESCRIPTION
    Gets the path of npm.cmd by using enviroment variables
    #>

    $basePathForNodeJS = GetPathWith -stringInPath "nodejs"
    $nodeJSPath = $basePathForNodeJS + "\npm.cmd"

    return $nodeJSPath
}


function RunNPMCommand
{
    <#
    .SYNOPSIS
    Runs the npm dev command
    .DESCRIPTION
    Runs the npm dev command within the spesified file
    #>

    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath,

    [String]
    #Path To NPM.CMD you should only set this if for some reason even after restarting your system it says npm is not recognized
    $pathToNPMCMD

    )

    $nodeJsPath = ""

    if(! $pathToNPM.Equals(""))
    {
        $nodeJsPath = $pathToNPM
    }
    
    $nodeJsPath = GetNPMPathToExe

    $pathToPackage = $basePath + "client\"

    $process = @{
        FilePath = $nodeJsPath
        RedirectStandardOutput = $basePath + "\bin\console.out"
        RedirectStandardError = $basePath + "\bin\console.err"
    }

    Start-Process @process -ArgumentList "run", "dev", "--prefix", $pathToPackage
}


function Swap-Windows-Package-With-Linux-Package
{
    <#
    .SYNOPSIS
    Swaps your package back out
    .DESCRIPTION
    Swaps your package back out of the client directory
    #>

    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath,

    [String]
    #The name of your json package must be in the bin folder along side this file
    $yourPackageFileName

    )

    $livePath = $BasePath + "client\package.json"

    $cachedPath = $BasePath + "bin\" + $yourPackageFileName

    Move-Item -Path $livePath -Destination $cachedPath

    $cachedPath = $BasePath + "bin\linuxpackage.json"

    Move-Item -Path $cachedPath -Destination $livePath
}


function HandleExiting
{
    <#
    .SYNOPSIS
    Handles exiting
    .DESCRIPTION
    Promts the user to type anything to exit once this is typed it stops node js and java process and then swaps the package back as well as writing the output of the command to the console
    #>

    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath,

    [String]
    #The name of your json package must be in the bin folder along side this file
    $yourPackageFileName

    )

    Read-Host -Prompt "type anything to exit"
    try
    {
        Stop-Process -name node
        Stop-Process -Name java
    }
    catch {}

    Swap-Windows-Package-With-Linux-Package -BasePath $basePath -yourPackageFileName $yourPackageFileName

    ReadCommandOut -basePath $basePath
}


function GetPathToMavenPom
{
    <#
    .SYNOPSIS
    Gets the path to the maven pom file
    .DESCRIPTION
    Gets the path to the maven pom file
    .OUTPUTS
    System.String. Path to the maven pom file
    #>

    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath

    )

    return $basePath + "server\pom.xml"
}


function RunMavenCommand
{
    <#
    .SYNOPSIS
    Runs the maven command passed into it
    .DESCRIPTION
    Runs the maven command passed into it and adds -Dmaven.test.skip if the testSkip argument is not ""
    #>

    param
    (

    [String]
    #Path To The mvn.cmd file or "" if you have maven building with your IDE
    $pathToMavenCMD,

    [String]
    #The base path to the reposity should end in t31\
    $basePath,

    [String]
    #The maven command to run
    $mavenCommand,

    [String]
    #If it does not equal "" it will skip tests for building maven to ignore the security manager error in java version 18 and up
    $testSkip

    )

    $mavenOut = $basePath + "\bin\console.out"
    $mavenErrorOut = $basePath + "\bin\console.err"

    $process = @{
        FilePath = $pathToMavenCMD
        RedirectStandardOutput = $mavenOut
        RedirectStandardError = $mavenErrorOut
    }

    $mavenPom = GetPathToMavenPom -basePath $basePath

    if(! $testSkip.Equals(""))
    {
        Start-Process @process -ArgumentList "-f", $mavenPom, $mavenCommand, "-Dmaven.test.skip" ` -Wait -NoNewWindow
    }
    else
    {
        Start-Process @process -ArgumentList "-f", $mavenPom, $mavenCommand ` -Wait -NoNewWindow
    }

    ReadCommandOut -basePath $basePath
}


function RunMavenCommands
{
    <#
    .SYNOPSIS
    Runs the commands to build the .jar
    .DESCRIPTION
    Runs the maven commands dependency:resolve, clean, package. If you run this you will need to change server.jar to server-null.jar in your package
    #>

    param
    (

    [String]
    #Path To The mvn.cmd file or "" if you have maven building with your IDE
    $pathToMavenCMD,

    [String]
    #The base path to the reposity should end in t31\
    $basePath,

    [String]
    #If it does not equal "" it will skip tests for building maven to ignore the security manager error in java version 18 and up
    $testSkip

    )
    
    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "dependency:resolve" -testSkip ""

    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "clean" -testSkip ""

    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "package" -testSkip $testSkip 

}


function NPMRun
{
    <#
    .SYNOPSIS
    Runs the npm dev command
    .DESCRIPTION
    Swaps in your package and runs the NPM command
    #>

    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath,

    [String]
    #The name of your json package must be in the bin folder along side this file
    $yourPackageFileName,

    [String]
    #Path To NPM.CMD you should only set this if for some reason even after restarting your system it says npm is not recognized
    $pathToNPMCMD

    )

    Swap-Linux-Package-With-Windows-Package -BasePath $basePath -yourPackageFileName $yourPackageFileName

    RunNPMCommand -basePath $basePath -pathToNPM $pathToNPM

    HandleExiting -basePath $basePath -yourPackageFileName $yourPackageFileName
}


function Cleanup
{
    <#
    .SYNOPSIS
    Cleans all biproducts of running this script
    .DESCRIPTION
    Swaps the package back with the default one for linux and removes the console.err and console.out files
    #>
    param
    (

    [String]
    #The base path to the reposity should end in t31\
    $basePath

    )

    $errorOutput = $basePath + "bin\console.err"
    $output = $basePath + "bin\console.out"

    Remove-Item -Path $errorOutput
    Remove-Item -Path $output
}


function Run
{
    <#
        .SYNOPSIS
        Runs the CS 314 Project
        .DESCRIPTION
        Run builds the project with maven if the path to maven variable is set. Then it runs the NPM commands and prompts the user with a exit command to exit cleanly. If testSkip is set to anything but "" it will skip the tests when building with maven
        None
    #>

    param
    (

    [String]
    #The name of your json package must be in the bin folder along side this file
    $yourPackageFileName,


    [String]
    #Path To The mvn.cmd file or "" if you have maven building with your IDE
    $pathToMavenCMD,


    [String]
    #If it does not equal "" it will skip tests for building maven to ignore the security manager error in java version 18 and up
    $testSkip,


    [String]
    #Path To NPM.CMD you should only set this if for some reason even after restarting your system it says npm is not recognized
    $pathToNPMCMD

    )

    Write-Output "You should still make sure it works through the dev ops page it is possible that it here but not there."

    $basePath = Get-Base-Project-Path

    if(! $pathToMavenCMD.Equals(""))
    {
        RunMavenCommands -pathToMavenCMD $pathToMavenCMD -basePath $basePath -testSkip $testSkip
    }

    NPMRun -basePath $basePath -yourPackageFileName $yourPackageFileName -pathToNPM $pathToNPMCMD

    Cleanup -basePath $basePath
}


Run -yourPackageFileName $yourPackageFileName -pathToMavenCMD $pathToMavenCMD -testSkip $testSkip -pathToNPMCMD $pathToNPM
#there may be some dead code... i may have been making it much more complicated then it needed to be oops