Import-Module -Name ($PSScriptRoot + "\Utils.psm1")

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

        [Boolean]
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

    if($testSkip)
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
    #The base path to the reposity should end in t31\
        $basePath,

        [Boolean]
    #If it does not equal "" it will skip tests for building maven to ignore the security manager error in java version 18 and up
        $testSkip
    )
    
    $pathToMavenCMD = ((Get-Item -Path $PSScriptRoot).Parent).FullName + "\apache-maven-3.9.9\bin\mvn.cmd"
    Write-Host $pathToMavenCMD
    Write-Host (GetPathToMavenPom -basePath $basePath)
    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "dependency:resolve" -testSkip $testSkip

    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "clean" -testSkip $false

    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "package" -testSkip $testSkip

}