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
          
        Write-Host "Retrieving Model Data" -ForegroundColor Yellow
        $modelProperties = Get-Content -Raw -Path $projectDir'\output\model-data.json' | ConvertFrom-JSON
        Write-Host "Model Data for $modelProperties.fieldID retrieved" -ForegroundColor Green

        if($modelProperties.processingData.aligned -eq $false){
            # Creates new directories if needed for the alignment outputs, and the 3DGS outputs
            [System.IO.Directory]::CreateDirectory($projectDir+'\alignment')    # Output folder for COLMAP aligned photos
            [System.IO.Directory]::CreateDirectory($projectDir+'\extra')

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
        }

        Write-Host "Retrieving Model Data" -ForegroundColor Yellow
        $modelProperties = Get-Content -Raw -Path $projectDir'\output\model-data.json' | ConvertFrom-JSON
        Write-Host "Model Data for $modelProperties.fieldID retrieved" -ForegroundColor Green

        if($modelProperties.processingData.generated -eq $false){
            # Creates new directories if needed for the 3DGS outputs
            [System.IO.Directory]::CreateDirectory($projectDir+'\3DGS')    # Folder for high-quality (4m splat)
        
            #
            # Lichtfeld Studio 3DGS Generation
            #
            $argsLichtfeldStudio = @(
                "-d `"$projectDir\alignment`"",
                "-o `"$projectDir\3DGS`"",
                "--config=`"$PSScriptRoot\lichtfeld_studio\lfs_config.json`""
            )

            
            Write-Host "Alignment Arguments"
            Write-Host $argsLichtfeldStudio

            Write-Host "Launching Lichtfeld Studio" -ForegroundColor Yellow
            Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudioHigh -WorkingDirectory "C:\Users\amys2001\LichtFeld-Studio" -Wait -WindowStyle Maximized

            Write-Host "Full Quality 3DGS Trained" -ForegroundColor Green
            ""

            $modelProperties.metadata.softwareGeneration = "Lichtfeld Studio"
            $modelProperties.metadata.generated = $true

            Write-Host "Writing Model Data" -ForegroundColor Yellow
            [System.IO.Directory]::CreateDirectory($projectDir+'\output')
            $modelProperties | ConvertTo-JSON | Out-File $projectDir'\output\model-data.json'
        }

        Write-Host "Retrieving Model Data" -ForegroundColor Yellow
        $modelProperties = Get-Content -Raw -Path $projectDir'\output\model-data.json' | ConvertFrom-JSON
        Write-Host "Model Data for $modelProperties.fieldID retrieved" -ForegroundColor Green
        
        if($modelProperties.processingData.transformed -eq $false){
            function Splat-Clean {
                param (
                    $sourceSplat
                )

                $outputSplat = "output\lod-meta.json"
                $outputPly = "extra\"+$fieldName+".ply"
                $outputSog = "extra\"+$fieldName+".sog"
                $outputVoxel = "extra\"+$fieldName+".voxel.json"

                [System.IO.Directory]::CreateDirectory($projectDir+'\temp')

                # Crops the scene to the center 255m
                splat-transform $sourceSplat --filter-sphere "0,0,0,255" $projectDir\temp\lod0.ply -w
                
                # Outputs a .ply and .sog files of the cropped scene
                splat-transform $projectDir\temp\lod0.ply $outputPly
                splat-transform $projectDir\temp\lod0.ply $outputSog

                # Creates LODs 1-3 for SOG streaming
                splat-transform $projectDir\temp\lod0.ply --decimate 50% $projectDir\temp\lod1.ply -w
                splat-transform $projectDir\temp\lod1.ply --decimate 50% $projectDir\temp\lod2.ply -w
                splat-transform $projectDir\temp\lod2.ply --decimate 50% $projectDir\temp\lod3.ply -w
                
                # Splat-transform based collision mesh
                splat-transform $projectDir\temp\lod1.ply --filter-sphere "0,0,0,63" --filter-cluster $outputVoxel --voxel-floor-fill -K

                # Final streamable SOG mesh
                splat-transform temp\lod0.ply -l 0 temp\lod1.ply -l 1 temp\lod2.ply -l 2 temp\lod3.ply -l 3 $outputSplat --filter-nan
            }

            cd $projectDir # Sets directory to the project directory as splat-transform needs to be run in that directory.
            
            Write-Host "Setting 'working directory' to $projecDir for splat cleaning" -ForegroundColor Green
            
            Splat-Clean -sourceSplat "3DGS\splat_135000.ply"

            Write-Host "Splat Transformed" -ForegroundColor Green
            ""
            
            $modelProperties.metadata.transformed = $true
            
            Write-Host "Writing Model Data" -ForegroundColor Yellow
            [System.IO.Directory]::CreateDirectory($projectDir+'\output')
            $modelProperties | ConvertTo-JSON | Out-File $projectDir'\output\model-data.json'
            
            Write-Host "Compressing Virtual Soil Model"
            Compress-Archive -Path $projectDir'\output\*' -DestinationPath $modelProperties.fieldID'\output.zip' -Force
        }

        ""
        Write-Host "Virtual Soil Model Generated!" -ForegroundColor Green
        ""
        Sleep(10)
        Exit-PSHostProcess
    }
}
else
{
    Write-Host "No directory was selected." -ForegroundColor Red
    Sleep(3)
    Exit-PSHostProcess
}
