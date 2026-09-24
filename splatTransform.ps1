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

        # Creates new directories if needed for 3DGS outputs
        [System.IO.Directory]::CreateDirectory($projectDir+'\output')       # Folder for processed ssog files
        [System.IO.Directory]::CreateDirectory($projectDir+'\extra') 
        
        Write-Host "Retrieving Model Data" -ForegroundColor Yellow
        $modelProperties = Get-Content -Raw -Path $projectDir'\output\model-data.json' | ConvertFrom-JSON
        Write-Host "Model Data for $modelProperties.fieldID retrieved" -ForegroundColor Green
        
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

        Exit-PSHostProcess
    }
}
else
{
    Write-Host "No directory was selected."
    Sleep(3)
    Exit-PSHostProcess
}