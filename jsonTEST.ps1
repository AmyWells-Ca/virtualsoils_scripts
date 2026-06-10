# $testNumber = 1
# $testString = "TestString"
# $testArray = @(number = "$testNumber"; string = "$testString")


$modelProperties = @{
    fieldID = "";
    modelHigh = "";
    modelLow = "l";
    metadata = @{
        capturedBy = "";
        captureDate = "";
        framesIn = 0;
        framesTracked = 0
    }
}

# $Shell = New-Object -ComObject Shell.Application
# $Folder = $Shell.Namespace("")
# $File = $Folder.ParseName("")

# $modelProperties.metadata.captureDate = $Folder.GetDetailsOf($File, 12)  # Reads photo metadata to determine capture date
# $modelProperties.metadata.capturedBy = $Folder.GetDetailsOf($File, 20)   # Reads photo metadata to determine who captured the model

$modelProperties.metadata.framesIn = [System.IO.Directory]::GetFiles($projectDir+'\input\').Count
$modelProperties.metadata.framesTracked = [System.IO.Directory]::GetFiles($projectDir+'\alignment\').Count

$modelProperties | ConvertTo-JSON | Out-File ".\testJSON.json"