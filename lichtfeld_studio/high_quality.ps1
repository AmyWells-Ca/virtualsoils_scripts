# Variables for Functionality
$projectDir = 
$launchDir = 
$ver = "Res_V1"
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
        # [System.IO.Directory]::CreateDirectory($projectDir+'\Alignment')
        [System.IO.Directory]::CreateDirectory($projectDir+'\3DGS')
        [System.IO.Directory]::CreateDirectory($projectDir+'\output')

            # "-importGroundControlPoints `"$PSScriptRoot\$ver\ControlPoints.csv`" `"$PSScriptRoot\$ver\ControlPointSettings.xml`"",
            # "-setReconstructionRegion `"$PSScriptRoot\$ver\reconstructionRegion.rsbox`"",
        

        <#
        ## Settings for RealityScan
        $argsRealityScan = @(
            "-addFolder $projectDir\Input\",
            "-setProjectCoordinateSystem Local:1",
            "-detectMarkers `"$PSScriptRoot\$ver\36h11.xml`""
            "-defineDistance `"$PSScriptRoot\$ver\Constraints.csv`"",
            "-align",
            "-selectMaximalComponent",
            
            "-calculatePreviewModel",
            "-calculateVertexColors",
            "-exportRegistration `"$projectDir\Alignment\$fieldName.txt`" `"$PSScriptRoot\$ver\Export_Colmap.xml`"",
            "-exportSelectedModel $projectDir\HP_$fieldName.fbx `"$PSScriptRoot\$ver\Export_FBX.xml`"",
            "-save `"$projectDir\RS_$fieldName.rsproj`"",
            "-quit"
            )
        #>
            
        ## Settings for Lichtfeld Studio
        $gaus = 8192 * 1000

        $argsLichtfeldStudio = @(
            "-d `"$projectDir\Alignment`"",
            "-o `"$projectDir\3DGS`"",
            "-r 2",
            "-i 30000",
            "--max-cap $gaus",
            "--steps-scaler 4",
            "--min-opacity=0.01",
            "--enable-sparsity",
            "--bilateral-grid",
            "--enable-sparsity",
            "--prune_ratio=0.5"
        )

        Write-Host $argsLichtfeldStudio
        Sleep(5)

        # Runs Lichtfeld Studio with the previously defined settings
#        Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudio -WorkingDirectory "C:\Users\amys2001\LichtFeld-Studio" -Wait
 #       Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudio -Wait
        Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudio -Wait

        Write-Host ""
        Write-Host "3DGS Completed!"
        Write-Host ""

        <#
        Write-Host "Editing 3DGS"
        Write-Host ""

        cd "$projectDir" # Sets directory to the project directory as splat-transform needs to be run in that directory.
        $highPly = "$projectDir\3DGS\splat_60000.ply"
        $lowPly = "$projectDir\3DGS\splat_75000.ply"
        splat-transform $highPly $fieldName"_Blender.ply" # Just copies the .PLY hehe
        splat-transform $highPly --filter-sphere "0,0,0,255" $fieldName"_WebHigh.ply" # Crops beyond 255m from origin
        splat-transform $highPly --filter-sphere "0,0,0,255" $fieldName"_WebHigh.sog"
        splat-transform $lowPly --filter-sphere "0,0,0,255" $fieldName"_WebLow.ply"
        splat-transform $lowPly --filter-sphere "0,0,0,255" $fieldName"_WebLow.sog"
        #>
    }
} else {
    Write-Host "No directory was selected."
    Sleep(3)
    Exit-PSHostProcess
}
