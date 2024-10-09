param ([Switch]$testSkip, [Switch]$noPostman, [Switch]$noBuild, [Switch]$exitFailed)

$InformationPreference = "Continue"

function sublist
{
    param
    (
        [Array]
        $array,
        $newLength
    )
    $index = 1
    $returnArray = @()
    foreach($element in $array)
    {
        if(!($index -ge $newLength))
        {
            $returnArray += $element
        }
        $index = $index + 1
    }

    return $returnArray
}

function importModules
{
    param
    (
        $basePath
    )

    $splitString = $basePath -split "\\"
    $array = sublist -array $splitString -newLength ($splitString.Length-1)
    $seperator = "\"
    $returnValue

    foreach($element in $array)
    {
        if(!($element -eq $array[0]))
        {
            $returnValue = "$returnValue$seperator$element"
        }
        else
        {
            $returnValue = "$returnValue$element"
        }
    }
    $resourcesPath = "$returnValue\Resources\PowershellModules"
    $postman = "$resourcesPath\Postman.psm1"
    $npm = "$resourcesPath\NPM.psm1"
    $npmsetupandteardown = "$resourcesPath\NPMSetupAndTeardown.psm1"
    $Utils = "$resourcesPath\Utils.psm1"
    $maven = "$resourcesPath\Maven.psm1"
    $java = "$resourcesPath\Java.psm1"
    $errorPref = $ErrorActionPreference
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    try
    {
        Import-Module -Name $postman
        Import-Module -Name $npm
        Import-Module -Name $npmsetupandteardown
        Import-Module -Name $Utils
        Import-Module -Name $maven
        Import-Module -Name $java
    }
    catch [Exception]
    {
        Write-Error "Cant lock onto Resources folder $resourcesPath"
        exit 1
    }
    finally
    {
        $ErrorActionPreference = $errorPref
    }

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


function exitHandling
{
    <#
    .SYNOPSIS
    Handles exiting
    .DESCRIPTION
    Promts the user to type anything to exit once this is typed it stops node js and java process and then swaps the package back as well as writing the output of the command to the console
    #>

    param
    (
        $originalContent,
        [String]
    #The base path to the reposity should end in t31\
        $basePath
    )

    Read-Host -Prompt "type anything to exit"

    exiting -basePath $basePath -originalContent $originalContent
}

function exiting
{
    param
    (
        $originalContent,
        [String]
    #The base path to the reposity should end in t31\
        $basePath
    )

    try
    {
        Stop-Process -name node
        Stop-Process -Name java
    }
    catch {}

    NPMTeardown -basePath $basePath -originalContent $originalContent

    ReadCommandOut -basePath $basePath
}



function HandleLoadingClientAndServer
{
    param
    (
        $basePath
    )

    $originalContent = NPMSetup -basePath $basePath

    RunNPM -basePath $basePath

    exitHandling -basePath $basePath -originalContent $originalContent
}

function safeExit
{
    param
    (
        $basePath
    )

    exiting -basePath $basePath

    removeLogs -basePath $basePath

    RestEnviromentVariables
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
        [Boolean]
    #If it does not equal "" it will skip tests for building maven to ignore the security manager error in java version 18 and up
        $testSkip,

        [Boolean]
    #skips running postman tests
        $noPostman,

        [Boolean]
        $noBuild,

        [Boolean]
        $exitFailed
    )

    Write-Output "There is a chance that your project may work on linux but not on windows please test it on linux still"

    $basePath = Get-Base-Project-Path

    $canContinue = $true

    importModules -basePath $basePath

    if($exitFailed)
    {
        safeExit -basePath $basePath
        exit 0
    }

    SetupEnviromentVariables

    if(!$noBuild)
    {
        RunMavenCommands -basePath $basePath -testSkip $testSkip
    }

    try
    {
        if(!$noPostman)
        {
            RunPostman -basePath $basePath
        }
    }
    catch
    {
        $canContinue = $false
    }

    if($canContinue)
    {
        HandleLoadingClientAndServer -basePath $basePath
    }

    removeLogs -basePath $basePath

    RestEnviromentVariables
}

Run -testSkip $testSkip -noPostman $noPostman -noBuild $nobuild -exitFailed $exitFailed

#If you have a issue please check the issues page on the github for this and if it is not there feel free to post a issue