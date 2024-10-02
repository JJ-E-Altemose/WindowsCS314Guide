param
(
[String]
$f
)

if(($f -eq $null) -or ($f.Equals("")))
    {
        Write-Host "Failed to spesify folder"
        exit 1
    }

Write-Host "This project uses maven and java 11"
Write-Host "This install script is prone to DNS posioning so make sure that you are using a trusted dns when installing"
$input = Read-Host "By typing Y you confirm that you have read and agreed to there liscence agreements at https://aws.amazon.com/corretto/faqs/ and https://www.apache.org/licenses/LICENSE-2.0.txt, type N to cancel"
if($input.Equals("Y"))
{
    if((Read-Host "Does this look like the correct path $f `nType Y to confirm`n").Equals("Y"))
    {
        $webClient = New-Object net.webclient
        Write-Host "Downloading files ."
        $webClient.Downloadfile("https://corretto.aws/downloads/latest/amazon-corretto-11-x64-windows-jdk.zip", "$f\JavaDownload.zip")
        Write-Host "Downloading files .."
        $webClient.Downloadfile("https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip", "$f\MavenDownload.zip")
        Write-Host "Downloading files ..."
        Write-Host "Expanding zip files"
        Expand-Archive -LiteralPath "$f\JavaDownload.zip" -DestinationPath $f
        Expand-Archive -LiteralPath "$f\MavenDownload.zip" -DestinationPath $f
        Write-Host "Removing zip files"
        Remove-Item "$f\JavaDownload.zip"
        Remove-Item "$f\MavenDownload.zip"
        Write-Host "Changing powershell file execution polices nessisary scripts"
        $powershellFileNames = @("CS314.psm1", "Java.psm1", "Maven.psm1", "NPM.psm1", "NPMSetupAndTeardown.psm1", "Postman.psm1", "run.ps1", "Utils.psm1")

        foreach($fileName in $powershellFileNames)
        {
            Write-Host "Unblocking $fileName"
            $path = "$f\PowershellModules\$fileName"
            Unblock-File -Path $path
        }

        Write-Host "Have a great day :) (Deleting self)"
        Remove-Item "$f\install.ps1"
    }
}
    