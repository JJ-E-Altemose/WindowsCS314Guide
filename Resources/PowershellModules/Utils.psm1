$InformationPreference = "Continue"

function removeLogs
{
    param
    (

        [String]
    #The base path to the reposity should end in t31\
        $basePath

    )

    $errorOutput = $basePath + "bin\console.err"
    $consoleOutput = $basePath + "bin\console.out"

    Remove-Item -Path $errorOutput
    Remove-Item -Path $consoleOutput
}

function GetFileString
{
    param
    (
        $filePath
    )

    $fileContent = Get-Content -Path $filePath
    $string = ""
    foreach($line in $fileContent)
    {
        $string = $string + $line + "`n"
    }
    return $string
}

function replaceAllInFile
{
    param
    (
        [String]
        $filePath,
        [String]
        $orginal,
        [String]
        $new
    )

    [String] $fileContent = (GetFileString -filePath $filePath)
    ($fileContent).Replace($orginal, $new) | Set-Content -Path $filePath
}

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

    try
    {
        Write-Output $fileContents
    }
    catch {}
}


function ReadCommandOutput
{
    param
    (

        [String]
    #The base path to the reposity should end in t31\
        $basePath

    )

    $consoleOutput = $basePath + "\bin\console.out"

    WriteFileToOutput -filePath $consoleOutput
}


function ReadCommandError
{
    param
    (

        [String]
    #The base path to the reposity should end in t31\
        $basePath

    )

    $consoleErrorOutput = $basePath + "\bin\console.err"

    WriteFileToOutput -filePath $consoleErrorOutput
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

    ReadCommandOutput -basePath $basePath
    ReadCommandError -basePath $basePath
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
    return $null
}

function StripPath
{
    param
    (

        [String]
    #The full path to a file
        $pathToFile

    )

    $splitString = $pathToFile -split "\\"

    return $splitString[$splitString.Length - 1]
}
