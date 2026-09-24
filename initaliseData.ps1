# Variables for Functionality
$projectDir = 
$launchDir = 
$no = @("n","N","no","No","NO")
$yes = @("y","Y","yes","Yes","YES")

Add-Type -AssemblyName System.Windows.Forms
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select a directory"
$result = $folderBrowser.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) 
{
    $projectDir = $folderBrowser.SelectedPath
    Write-Host "You selected: $projectDir" -ForegroundColor Green

    do
    {
        $fieldName = Split-Path -Path $projectDir -Leaf      
        $answ = Read-Host "Initialise model data in '$projectDir'? Yes or No"
    } 
    until ($no -contains$answ -or $yes -contains$answ) 
    if ($no -contains$answ)
    {
        ""
        Write-Host "Aborted Initialisation" -ForegroundColor Red
        Sleep(3)
        Exit-PSHostProcess
    }
    elseif ($yes -contains$answ)
    {
        ""
        Write-Host "Accepted" -ForegroundColor Green
        ""
        Write-Host "Model ID"
        $fieldID = Read-Host
        ""

        Write-Host "Name of the Capture Location"
        $nameLocation = Read-Host "e.g. Totem Research Station"
        ""
        
        Write-Host "Name of the Model"
        $nameModel = Read-Host "e.g. Lettuce Field"
        ""
        
        Write-Host "Location Information"
        Write-Host "Country of Capture"
        $country = Read-Host "[Default: Canada]"
        if([string]::IsNullOrWhiteSpace($country)){$country = "Canada"}
        ""
        Write-Host "Province of Capture"
        $province = Read-Host "Province"
        ""

        Write-Host "City of Capture"
        $city = Read-Host "City"
        ""
        [float]$lat = Read-Host "Latitude"
        [float]$long = Read-Host "Longitude"
        ""

        Write-Host "Capture Metadata"
        Write-Host "Who captured the Virtual Soil?"
        $capturedBy = Read-Host "[Default: Amy Wells]"
        if([string]::IsNullOrWhiteSpace($capturedBy)){$capturedBy = "Amy Wells"}
        ""
        Write-Host "When was the Virtual Soil captured?"
        $captureDate = Read-Host "YYYY-MM-DD"
        ""
        Write-Host "What software were photos edited in?"
        $softwareEdit = Read-Host "[Default: Adobe Lightroom]"
        if([string]::IsNullOrWhiteSpace($softwareEdit)){$softwareEdit = "Adobe Lightroom"}

        ""

        $modelProperties = [ordered]@{
            fieldID = $fieldID;
            nameLocation = $nameLocation;
            nameModel = $nameModel;
            country = $country;
            province = $province;
            city = $city;
            lat = $lat; 
            long = $long;
            processingData = [ordered]@{
                version = 4.0;
                aligned = $false;
                generated = $false;
                transformed = $false;
                approved = $false
            };
            metadata = [ordered]@{
                capturedBy = $capturedBy
                captureDate = $captureDate
                framesIn = 0;
                framesTracked = 0;
                softwareEdit = $softwareEdit;
                softwareAlignment = "";
                softwareGeneration = "";
            };
        }

        Write-Host "Writing Model Data" -ForegroundColor Yellow
        [System.IO.Directory]::CreateDirectory($projectDir+'\output')
        $modelProperties | ConvertTo-JSON | Out-File $projectDir'\output\model-data.json'
        Exit-PSHostProcess
    }
}
else
{
    Write-Host "No directory was selected." -ForegroundColor Red
    Sleep(3)
    Exit-PSHostProcess
}
