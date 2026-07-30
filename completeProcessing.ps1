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

        function Splat-Clean {
            param (
                $sourceSplat,
                $outputName
            )
            Write-Host $outputName

            $outputSplat = "output\"+$outputName+"\lod-meta.json"
            $outputSog = "output\"+$fieldName+"_"+$outputName+".sog"
            $outputVoxel = "output\"+$fieldName+"_"+$outputName+".voxel.json"

            [System.IO.Directory]::CreateDirectory($projectDir+'\temp')

            # Crops the scene to the center 255m
            splat-transform $sourceSplat --filter-sphere "0,0,0,255" $projectDir\temp\lod0.ply -w
            
            # Outputs a simple sog file of the cropped scene
            splat-transform $projectDir\temp\lod0.ply $outputSog

            # Splat-transform based collision mesh
            splat-transform $projectDir\temp\lod0.ply --filter-cluster $outputVoxel --voxel-floor-fill -K

            # Creates LODs 1-3 for SOG streaming
            splat-transform $projectDir\temp\lod0.ply --decimate 50% $projectDir\temp\lod1.ply -w
            splat-transform $projectDir\temp\lod1.ply --decimate 50% $projectDir\temp\lod2.ply -w
            splat-transform $projectDir\temp\lod2.ply --decimate 50% $projectDir\temp\lod3.ply -w

            # Final streamable SOG mesh
            splat-transform temp\lod0.ply --lod 0 temp\lod1.ply --lod 1 temp\lod2.ply --lod 2 temp\lod3.ply --lod 3 $outputSplat --filter-nan

        }

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
        
        Write-Host "Setting 'working directory' to $projecDir for splat cleaning" -ForegroundColor Green
                
        Splat-Clean -sourceSplat "3DGS_High\splat_135000.ply" -outputName "high"
        # Splat-Clean -sourceSplat "3DGS_Low\splat_75000.ply" -outputName "low"

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
            };
            $metaData = @{
                capturedBy = "";
                captureDate = "";
                framesIn = [System.IO.Directory]::GetFiles($projectDir+'\input\', "*.jpg").Count;
                framesTracked = [System.IO.Directory]::GetFiles($projectDir+'\alignment\', "*.jpg").Count;
                softwareEditor = "";
                softwareGeneration = "LichtFeld Studio";
            };
        }

        <#
        $Shell = New-Object -ComObject Shell.Application
        $Folder = $Shell.Namespace($projectDir+'\input\')
        $File = $Folder.ParseName( (Get-ChildItem -Path $projectDir'\input\' -File | Select-Object -First 1) )

        $modelProperties.metadata.captureDate = $Folder.GetDetailsOf($File, 12)  # Reads photo metadata to determine capture date
        $modelProperties.metadata.capturedBy = $Folder.GetDetailsOf($File, 20)   # Reads photo metadata to determine who captured the model
        #>

        $modelProperties | ConvertTo-JSON | Out-File $projectDir'\output\modelData.json'

        Sleep(30)
    }
} else {
    Write-Host "No directory was selected."
    Sleep(3)
    Exit-PSHostProcess
}


Sleep(30)
