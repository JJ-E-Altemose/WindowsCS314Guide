function GetTeamNumber
{

    param
    (

        [String]
    #The base path to the reposity should end in t31\
        $basePath

    )

    $splitBasePath = $basePath -split "\\"
    $fullTeamString = $splitBasePath[$splitBasePath.Length - 2] # aditional offset because base path has trailing \
    $teamNumber = $fullTeamString.Replace("t", "")

    return $teamNumber
}