$InformationPreference = "Continue"

Import-Module -Name ($PSScriptRoot + "\CS314.psm1")
Import-Module -Name ($PSScriptRoot + "\utils.psm1")

function TryStopJava
{
    try
    {
        Stop-Process -Name java
    }
    catch
    {
        Write-Information "Warning java may already have stopped Or is unable to be stopped"
    }
}

function WaitUntilStartMessage
{
    param
    (
        $basePath
    )

    $consoleOut = $basePath + "bin\console.err"
    $maxChecks = 1000

    $checksComplete = 0
    $conditon = $true
    while($conditon -eq $true)
    {
        $fileContent = Get-Content -Path $consoleOut
        foreach($line in $fileContent)
        {
            if($line.contains("[Thread-0] INFO org.eclipse.jetty.server.Server - Started"))
            {
                $conditon = $false
            }
        }
        if($checksComplete -ge $maxChecks)
        {
            return
        }

        $checksComplete += 1
    }
}

function StartServer
{

    param
    (

        [String]
    #The base path to the reposity should end in t31\
        $basePath,

        [String]
    #the name of the server jar file it may be server-null.jar or just server.jar
        $javaJarFileName

    )
    $errorOutput = $basePath + "bin\console.err"
    $consoleOutput = $basePath + "bin\console.out"


    $jarFile = $basePath + "target\" + $javaJarFileName

    $teamNumber = GetTeamNumber -basePath $basePath

    $port = "413" + $teamNumber

    Start-Process java -ArgumentList "-Dorg.slf4j.simpleLogger.log.com.tco=error", "-jar", $jarFile, "$port" ` -RedirectStandardOutput $consoleOutput -RedirectStandardError $errorOutput

    $url = "http://localhost:" + $port

    $env:BASE_URL = $url

    WaitUntilStartMessage -basePath $basePath
}

function StashEnviromentVariables
{
    $javaHome = $env:JAVA_HOME
    Set-Content -Path "$PSScriptRoot\EnviromentCash.txt" -Value $javaHome;
}

function SetupEnviromentVariables
{
    StashEnviromentVariables

    SetPathIfNotSet

    $javaHome = ((Get-Item -Path $PSScriptRoot).Parent).FullName + "\jdk11.0.24_8"

    $env:JAVA_HOME = $javaHome
}

function RestEnviromentVariables
{
    $javaHome = Get-Content -Path "$PSScriptRoot\EnviromentCash.txt"

    if(Test-Path -Path "$PSScriptRoot\EnviromentCash.txt")
    {
        $env:JAVA_HOME = $javaHome
    }
}

function SetPathIfNotSet
{
    $path = GetPathWith -stringInPath "jdk11.0.24_8"
    if($path -eq $null)
    {
        ($env:Path) += "$PSScriptRoot\jdk11.0.24_8\bin"
    }
}