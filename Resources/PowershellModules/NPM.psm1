Import-Module -Name ($PSScriptRoot + "\Utils.psm1")
Import-Module -Name ($PSScriptRoot + "\NPMSetupAndTeardown.psm1")

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
        $basePath

    )

    $nodeJsPath = GetNPMPathToExe

    $pathToPackage = $basePath + "client\"

    $process = @{
        FilePath = $nodeJsPath
        #RedirectStandardOutput = $basePath + "\bin\console.out"
        #RedirectStandardError = $basePath + "\bin\console.err"
    }

    Start-Process @process -ArgumentList "run", "dev", "--prefix", $pathToPackage
}

function RunNPM
{
    param
    (
        $basePath
    )
    RunNPMCommand -basePath $basePath
}