Import-Module -Name ($PSScriptRoot + "\Java.psm1")
Import-Module -Name ($PSScriptRoot + "\Utils.psm1")
$InformationPreference = "Continue"

function BuildFoundPostmanMessage
{

    param
    (

        [String[]]
    #The full path to the postman folder
        $testFiles

    )

    $messageString =
    "================================" + "`n" +
            "Found Postman tests" + "`n" +
            "================================" + "`n"

    foreach($testFile in $testFiles)
    {
        $messageString += ($testFile + "`n")
    }

    $messageString += "================================"
    return $messageString
}

function GetPostmanTestFolder
{
    param
    (

        [String]
    #The base path to the reposity should end in t31\
        $basePath

    )

    $postmanTestFolder = $basePath + "Postman"

    return $postmanTestFolder
}

function GetPostmanTestJsons
{
    param
    (

        [String]
    #The base path to the reposity should end in tXX\
        $basePath

    )

    $postmanFolder = GetPostmanTestFolder -basePath $basePath

    $testFiles = Get-ChildItem -Path $postmanFolder -Name -Include *.json

    [String[]]$returnTestFiles = @()

    foreach($testFile in $testFiles)
    {
        [String]$testFileWithPath = $postmanFolder + "\" + $testFile
        $returnTestFiles += $testFileWithPath
    }
    $foundPostmanMessage = BuildFoundPostmanMessage -testFiles $testFiles
    Write-Information $foundPostmanMessage

    return $returnTestFiles
}

function RunCollection
{
    param
    (

        [String]
    #The base path to the reposity should end in t31
        $basePath,

        [String]
    #Postman Json
        $postmanJson,

        [String]
    #the name of the server jar file it may be server-null.jar or just server.jar
        $javaJarFileName

    )

    #StartServer -basePath $basePath -javaJarFileName $javaJarFileName

    $fileName = StripPath -pathToFile $postmanJson

    Write-Output "==============================================="

    $runningCollectionMessage = "Running Collection: " + $fileName

    Write-Output $runningCollectionMessage
    Write-Output "==============================================="

    $workingDirectory = $basePath + "client\node_modules\newman\bin"

    $errorOutput = $basePath + "bin\console.err"
    $consoleOutput = $basePath + "bin\console.out"

    $enviromentVariableArgument = "--env-var `"BASE_URL=" + $env:BASE_URL + "`""

    $nodeTest = Start-Process node -NoNewWindow -WorkingDirectory $workingDirectory -ArgumentList "newman.js", "run", $postmanJson, $enviromentVariableArgument  ` -Wait -PassThru
    $nodeTest.WaitForExit()
    ReadCommandOut -basePath $basePath

    if(! $nodeTest.ExitCode -eq 0)
    {
        $errorMessage = "Error occured while running Postman tests from " + $fileName
        Write-Output $errorMessage
        TryStopJava
        exit 1
    }
    else
    {
        Write-Output "Successful"
        #TryStopJava
        #todo make more like shell script
        #Start-Sleep -Seconds 2
    }
}


function RunPostman
{

    param
    (

        [String]
    #The base path to the reposity should end in t31
        $basePath

    )

    StartServer -basePath $basePath -javaJarFileName "server-null.jar"

    $testFiles = GetPostmanTestJsons -basePath $basePath

    foreach($testFile in $testFiles)
    {
        RunCollection -basePath $basePath -postmanJson $testFile -javaJarFileName "server-null.jar"
    }

    TryStopJava
}