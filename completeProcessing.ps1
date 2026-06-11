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
        [System.IO.Directory]::CreateDirectory($projectDir+'\3DGS_High')    # Folder for high-quality (4m splat)
        [System.IO.Directory]::CreateDirectory($projectDir+'\3DGS_Low')     # Folder for low-quality (512k splat)
        [System.IO.Directory]::CreateDirectory($projectDir+'\output')       # Folder for processed .sog files

            # "-importGroundControlPoints `"$PSScriptRoot\$ver\ControlPoints.csv`" `"$PSScriptRoot\$ver\ControlPointSettings.xml`"",
            # "-setReconstructionRegion `"$PSScriptRoot\$ver\reconstructionRegion.rsbox`"",
        #
        # Colmap
        #
        
        ## Settings for RealityScan
        $argsRealityScan = @(
            "-addFolder $projectDir\input\",
            "-setProjectCoordinateSystem Local:1",
            "-detectMarkers `"$PSScriptRoot\reality_scan\36h11.xml`""
            "-detectMarkers `"$PSScriptRoot\reality_scan\36h11.xml`""
            "-detectMarkers `"$PSScriptRoot\reality_scan\36h11.xml`""
            "-defineDistance `"$PSScriptRoot\reality_scan\Constraints.csv`"",
            "-align",
            "-selectMaximalComponent",
            
            "-calculatePreviewModel",
            "-calculateVertexColors",
            "-exportRegistration `"$projectDir\alignment\$fieldName.txt`" `"$PSScriptRoot\reality_scan\Export_Colmap.xml`"",
            "-exportSelectedModel $projectDir\HP_$fieldName.fbx `"$PSScriptRoot\reality_scan\Export_FBX.xml`"",
            "-save `"$projectDir\reality_scan\RS_$fieldName.rsproj`"",
            "-quit"
        )
        
        Write-Host $argsRealityScan

        Start-Process -FilePath "C:\Program Files\Epic Games\RealityScan_2.1\RealityScan.exe" -ArgumentList $argsRealityScan -Wait
        

        #
        # 3DGS
        #
        
        # Settings for the "high quality" models
        $argsLichtfeldStudioHigh = @(
            "-d `"$projectDir\alignment`"",
            "-o `"$projectDir\3DGS_High`"",
            "--config=`"$PSScriptRoot\lichtfeld_studio\lfs_config.json`""
        )

        Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudioHigh -WorkingDirectory "C:\Users\amys2001\LichtFeld-Studio" -Wait -WindowStyle Maximized

        # Settings for the "low quality" models
        $argsLichtfeldStudioLow = @(
            "-d `"$projectDir\alignment`"",
            "-o `"$projectDir\3DGS_Low`"",
            "--config=`"$PSScriptRoot\lichtfeld_studio\lfs_config_low.json`""
        )

        Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudioLow -WorkingDirectory "C:\Users\amys2001\LichtFeld-Studio" -Wait -WindowStyle Maximized

        #
        # Splat Editing & SOG generation
        #

        cd $projectDir # Sets directory to the project directory as splat-transform needs to be run in that directory.

        $plyHigh = $projectDir+"\3DGS_High\splat_135000.ply"
        $plyLow = $projectDir+"\3DGS_Low\splat_75000.ply"
        
        splat-transform $plyHigh --filter-sphere "0,0,0,255" $fieldName"_HighQuality.ply" # Crops beyond 255m from origin
        splat-transform $plyHigh --filter-sphere "0,0,0,255" $fieldName"_HighQuality.sog"
        splat-transform $plyLow --filter-sphere "0,0,0,127" $fieldName"_LowQuality.ply"
        splat-transform $plyLow --filter-sphere "0,0,0,127" $fieldName"_LowQuality.sog"

        #
        # Metadata Companion File
        #
                
        $modelProperties = @{
            fieldID = $fieldName;
            name = $fieldName;
            country = "";
            province = "";
            locationName = ""
            lat = 0;
            long = 0;
            plyHigh = "";
            plyLow = "";
            sogHigh = "";
            sogLow = "";
            thumbHigh = "";
            $soilData = @{
                classification = "CSSC3";
                order = "";
                soilHorizons = @{
                    h1 = "";
                }
            }
            $metaData = @{
                capturedBy = "";
                captureDate = "";
                framesIn = [System.IO.Directory]::GetFiles($projectDir+'\input\', "*.jpg").Count;
                framesTracked = [System.IO.Directory]::GetFiles($projectDir+'\alignment\', "*.jpg").Count;
                softwareEditor = "";
                softwareGeneration = "LichtFeld Studio";
            }
        }

        <#
        $Shell = New-Object -ComObject Shell.Application
        $Folder = $Shell.Namespace($projectDir+'\input\')
        $File = $Folder.ParseName( (Get-ChildItem -Path $projectDir'\input\' -File | Select-Object -First 1) )

        $modelProperties.metadata.captureDate = $Folder.GetDetailsOf($File, 12)  # Reads photo metadata to determine capture date
        $modelProperties.metadata.capturedBy = $Folder.GetDetailsOf($File, 20)   # Reads photo metadata to determine who captured the model
        #>

        $modelProperties | ConvertTo-JSON | Out-File $projectDir'\output\modelData.json'
    }
} else {
    Write-Host "No directory was selected."
    Sleep(3)
    Exit-PSHostProcess
}
