# Variables for Functionality
$projectDir = 
$launchDir = 
$no = @("n","N","no","No","NO")
$yes = @("y","Y","yes","Yes","YES")

Add-Type -AssemblyName System.Windows.Forms
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select a directory"
$result = $folderBrowser.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $projectDir = $folderBrowser.SelectedPath
    Write-Host "You selected: $projectDir" -ForegroundColor Green
    
    do {
        $fieldName = Split-Path -Path $projectDir -Leaf      
        $answ = Read-Host "Generated 3DGS from Images in '$projectDir'? Yes or No"
    } until ($no -contains$answ -or $yes -contains$answ) 

    if ($no -contains$answ) {
        ""
        Write-Host "Cancelled" -ForegroundColor Red
        Sleep(3)
        Exit-PSHostProcess

    } elseif ($yes -contains$answ) {
        Write-Host "Yay" -ForegroundColor Green

        # Creates new directories if needed for the alignment outputs, and the 3DGS outputs
        [System.IO.Directory]::CreateDirectory($projectDir+'\alignment')    # Output folder for COLMAP aligned photos
        [System.IO.Directory]::CreateDirectory($projectDir+'\extra')

        Write-Host "Retrieving Model Data" -ForegroundColor Yellow
        $modelProperties = Get-Content -Raw -Path $projectDir'\output\model-data.json' | ConvertFrom-JSON
        Write-Host "Model Data for $modelProperties.fieldID retrieved" -ForegroundColor Green

        #
        # RealityScan Image Alignment
        #
        $argsRealityScan = @(
            "-addFolder $projectDir\input\",
            "-setProjectCoordinateSystem Local:1",
            "-detectMarkers `"$PSScriptRoot\reality_scan\36h11.xml`"",
            "-defineDistance `"$PSScriptRoot\reality_scan\Constraints_V4.csv`"",
            "-align",
            "-selectMaximalComponent",
            "-align",
            "-selectMaximalComponent",
            "-calculatePreviewModel",
            "-calculateVertexColors",
            "-exportRegistration `"$projectDir\alignment\$fieldName.txt`" `"$PSScriptRoot\reality_scan\Export_Colmap_V4.xml`"",
            "-exportSelectedModel $projectDir\extra\$fieldName.fbx `"$PSScriptRoot\reality_scan\Export_FBX.xml`"",
            "-save `"$projectDir\reality_scan\RS_$fieldName.rsproj`""
            "-quit"
        )
        
        Write-Host "Alignment Arguments"
        Write-Host $argsRealityScan -ForegroundColor Cyan

        Write-Host "Launching RealityScan" -ForegroundColor Yellow
        Start-Process -FilePath "C:\Program Files\Epic Games\RealityScan_2.1\RealityScan.exe" -ArgumentList $argsRealityScan -Wait

        Write-Host "Alignment Commpleted" -ForegroundColor Green
        ""

        $modelProperties.metadata.softwareAlignment = "Reality Scan"
        $modelProperties.framesTracked = [System.IO.Directory]::GetFiles($projectDir+'\alignment\images\').Count
        $model
        $modelProperties.metadata.framesIn = [System.IO.Directory]::GetFiles($projectDir+'\input\').Count
        $modelProperties.metadata.aligned = $true

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
