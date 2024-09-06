$pathToMavenCMD = ""

$pathToNPM = ""

$yourPackageFileName = "windowspackage.json"

$testSkip = "yes"

#param filePath
#returns nothing
function WriteFileToOutput
{
    param($filePath)

    $fileContents = Get-Content -Path $filePath

    Write-Output $fileContents
}

# No parameters
# Returns the base path including the final \
function Get-Base-Project-Path
{
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

#Param $basePath = the base path of the project aka the folder that contaians the the folder bin
#return nothing it writes a simple message to the console and builds the jar
function Build-Jar
{
    param($BasePath)

    $workingDirectory = $BasePath + "target\classes"

    $jarFileOutput = $basePath + "target\server.jar"
    $classFileInput = $basePath + "target\classes\com\tco\server\WebApplication.class"
    $class = "com.tco.server.WebApplication"

    $buildingJarMessage = "`nBuilding Jar file in " + $jarFileOutput
    Write-Output $buildingJarMessage

    Start-Process jar -ArgumentList "cfe", $jarFileOutput, $class, $classFileInput ` -RedirectStandardOutput '.\console.out' -RedirectStandardError '.\console.err' -WorkingDirectory 

    Write-Output "`nBuild complete"

    WriteFileToOutput -filePath '.\console.out'
    WriteFileToOutput -filePath '.\console.err'
}



#Param $basePath = the base path of the project aka the folder that contaians the the folder bin
#Return nothing just swaps the package and windows package for running
function Swap-Linux-Package-With-Windows-Package
{
    param($BasePath, $yourPackageFileName)

    $livePath = $BasePath + "client\package.json"

    $cachedPath = $BasePath + "bin\linuxpackage.json"

    Move-Item -Path $livePath -Destination $cachedPath

    $cachedPath = $BasePath + "bin\" + $yourPackageFileName

    Move-Item -Path $cachedPath -Destination $livePath
}

#param string to search for in enviromentpaths
#returns path that had that string in it ALWAYS returns first instance
function GetPathWith
{
    param($stringInPath)
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

#No parameters
#returns path to java folder
function GetJavaPath
{
    return GetPathWith -stringInPath "jdk"
}

#no parameters
#returns path to node.js exe
function GetNodeJSPathToExe
{
    $basePathForNodeJS = GetPathWith -stringInPath "nodejs"
    $nodeJSPath = $basePathForNodeJS + "\npm.cmd"

    return $nodeJSPath
}

#Param Basepath
#returns nothing just runs the npm command dev
function RunNodeJS
{
    param($basePath, $pathToNPM)

    $nodeJsPath = ""

    if(! $pathToNPM.Equals(""))
    {
        $nodeJsPath = $pathToNPM
    }
    
    $nodeJsPath = GetNodeJSPathToExe

    $pathToPackage = $basePath + "client\"

    $process = @{
        FilePath = $nodeJsPath
        RedirectStandardOutput = $basePath + "\bin\console.out"
        RedirectStandardError = $basePath + "\bin\console.err"
    }

    Start-Process @process -ArgumentList "run", "dev", "--prefix", $pathToPackage
}

#Param $basePath = the base path of the project aka the folder that contaians the the folder bin
#Return nothing just swaps the package and linux package other users that dont use windows
function Swap-Windows-Package-With-Linux-Package
{
    param($BasePath, $yourPackageFileName)

    $livePath = $BasePath + "client\package.json"

    $cachedPath = $BasePath + "bin\" + $yourPackageFileName

    Move-Item -Path $livePath -Destination $cachedPath

    $cachedPath = $BasePath + "bin\linuxpackage.json"

    Move-Item -Path $cachedPath -Destination $livePath
}

#Param Basepath yourCustomPackage
#returns nothing
function HandleExiting
{
    param($basePath, $yourPackageFileName)

    Read-Host -Prompt "type anything to exit"
    try
    {
        Stop-Process -name node
        Stop-Process -Name java
    }
    catch {}

    Swap-Windows-Package-With-Linux-Package -BasePath $basePath -yourPackageFileName $yourPackageFileName 

    $npmOutputDirectory = $basePath + "\bin\console.out"
    $npmErrorOutputDirectoy = $basePath + "\bin\console.err"

    $npmOutput  = Get-Content -Path $npmOutputDirectory
    $npmErrorOutput = Get-Content -Path $npmErrorOutputDirectoy

    Write-Output $npmOutput

    Write-Output $npmErrorOutput
}

#param basePath
#returns path to pom file
function GetPathToMavenPom
{
    param($basePath)

    return $basePath + "server\pom.xml"
}

#param pathToMavenCMD basePath mavenCommand ex install testSkip "" if no skip "anything" if skip
#returns nothing
function RunMavenCommand
{
    param($pathToMavenCMD, $basePath, $mavenCommand, $testSkip)

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
}

#param basePath
#returns nothing writes to console
function ReadMavenOut
{
    param($basePath)

    $mavenOut = $basePath + "\bin\console.out"
    $mavenErrorOut = $basePath + "\bin\console.err"

    $mavenOutContent = Get-Content -Path $mavenOut
    $mavenErrorOutContent = Get-Content -Path $mavenErrorOut

    Write-Output $mavenOutContent

    Write-Debug $mavenErrorOut
}

#parmas pathToMavenCMD, basePath
#returns nothing just runs all the maven commands (This is a very brute force way to help make sure it works but is slow)
function RunMavenCommands
{
    param($pathToMavenCMD, $basePath, $testSkip)
    
    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "dependency:resolve" -testSkip ""

    ReadMavenOut -basePath $basePath

    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "clean" -testSkip ""

    ReadMavenOut -basePath $basePath

    RunMavenCommand -pathToMavenCMD $pathToMavenCMD -basePath $basePath -mavenCommand "package" -testSkip $testSkip 

    ReadMavenOut -basePath $basePath
}

#param basePath yourPackageFileName
#returns nothing
function NPMRun
{
    param($basePath, $yourPackageFileName, $pathToNPM)

    Swap-Linux-Package-With-Windows-Package -BasePath $basePath -yourPackageFileName $yourPackageFileName

    RunNodeJS -basePath $basePath -pathToNPM $pathToNPM

    HandleExiting -basePath $basePath -yourPackageFileName $yourPackageFileName
}

#param basePath
#return nothing cleans all files written to for debugging
function Cleanup
{
    param($basePath)

    $errorOutput = $basePath + "bin\console.err"
    $output = $basePath + "bin\console.out"

    Remove-Item -Path $errorOutput
    Remove-Item -Path $output
}

#param yourPackageFileName pathToMavenCMD testSkip
# Without a path to maven cmd it will look for already built class
# returns nothing
function Run
{
    param($yourPackageFileName, $pathToMavenCMD, $testSkip, $pathToNPMCMD)

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
#JJ was here
#there may be some dead code... i may have been making it much more complicated then it needed to be oops