Import-Module -Name ($PSScriptRoot + "\Utils.psm1")
Import-Module -Name ($PSScriptRoot + "\CS314.psm1")

function GetJsonReplacePairs
{
    param
    (
        $teamNumber,
        $basePath
    )
    $package = $basePath +"client\" + "package.json"

    [String] $basePathCorrectSlash = $basePath -replace "\\", "/"
    $basePathCorrectSlash = $basePathCorrectSlash.substring(0,($basePathCorrectSlash.Length - 1) )

    $original = @('${BUILD_DIRECTORY_PREFIX}','$BUILD_DIRECTORY_PREFIX',"'development'",'${SERVER_PORT}','${CLIENT_PORT}','server-local.jar')
    $newString = "" + $basePathCorrectSlash + "  \/  " + $basePathCorrectSlash + "  \/  " + "development" + "  \/  " + "413" + $teamNumber + "  \/  " + "431" + $teamNumber + "  \/  " + "server-null.jar"
    $new = $newString -split "  \\/  "

    $pairs = $original,$new

    return $pairs
}

function AddParametersTOJSON
{
    param
    (
        $teamNumber,
        $basePath
    )
    $package = $basePath +"client\" + "package.json"

    $pairs = GetJsonReplacePairs -teamNumber $teamNumber -basePath $basePath

    $original = $pairs[0]
    $new = $pairs[1]

    $index = 0;
    foreach($orignalInJson in $original)
    {
        replaceAllInFile -filePath $package -orginal $orignalInJson -new $new[$index]
        $index = $index + 1
    }

}

function NPMSetup
{
    param
    (
        $basePath
    )

    $package = $basePath +"client\" + "package.json"

    $teamNumber = GetTeamNumber -basePath $basePath

    Copy-Item -Path $package -Destination "$PSScriptRoot\temp_package.json"

    AddParametersTOJSON -basePath $basePath -teamNumber $teamNumber
}

function NPMTeardown
{
    param
    (
        $basePath,
        $originalContent
    )

    $package = $basePath +"client\" + "package.json"

    Copy-Item -Path "$PSScriptRoot\temp_package.json" -Destination $package

    Remove-Item -Path "$PSScriptRoot\temp_package.json"
}