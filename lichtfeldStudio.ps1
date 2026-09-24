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

        # Creates new directories if needed for the 3DGS outputs
        [System.IO.Directory]::CreateDirectory($projectDir+'\3DGS')    # Folder for high-quality (4m splat)
        
        Write-Host "Retrieving Model Data" -ForegroundColor Yellow
        $modelProperties = Get-Content -Raw -Path $projectDir'\output\model-data.json' | ConvertFrom-JSON
        Write-Host "Model Data for $modelProperties.fieldID retrieved" -ForegroundColor Green

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
        Exit-PSHostProcess

    }
}
else
{
    Write-Host "No directory was selected." -ForegroundColor Red
    Sleep(3)
    Exit-PSHostProcess
}
