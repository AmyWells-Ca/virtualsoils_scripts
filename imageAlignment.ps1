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
        [System.IO.Directory]::CreateDirectory($projectDir+'\alignment')    # Folder for colmap aligned photos

        #
        # Colmap
        #

        ## Settings for RealityScan
        $argsRealityScan = @(
            "-addFolder $projectDir\input\",
            "-setProjectCoordinateSystem Local:1",
            "-detectMarkers `"$PSScriptRoot\reality_scan\36h11.xml`"",
            "-defineDistance `"$PSScriptRoot\reality_scan\Constraints.csv`"",
            "-align",
            "-selectMaximalComponent",
            
            "-calculatePreviewModel",
            "-calculateVertexColors",
            "-exportRegistration `"$projectDir\alignment\$fieldName.txt`" `"$PSScriptRoot\reality_scan\Export_Colmap.xml`"",
            "-exportSelectedModel $projectDir\HP_$fieldName.fbx `"$PSScriptRoot\reality_scan\Export_FBX.xml`"",
            "-save `"$projectDir\reality_scan\RS_$fieldName.rsproj`""
        )
        
        Write-Host $argsRealityScan

        Start-Process -FilePath "C:\Program Files\Epic Games\RealityScan_2.1\RealityScan.exe" -ArgumentList $argsRealityScan -Wait
    }
} else {
    Write-Host "No directory was selected."
    Sleep(3)
    Exit-PSHostProcess
}


Sleep(30)
