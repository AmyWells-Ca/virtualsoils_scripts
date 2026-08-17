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

        #
        # 3DGS
        #
        

        # Settings for the "high quality" models
        $argsLichtfeldStudioHigh = @(
            "-d `"$projectDir\alignment`"",
            "-o `"$projectDir\3DGS`"",
            "--config=`"$PSScriptRoot\lichtfeld_studio\lfs_config.json`""
        )
        Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudioHigh -WorkingDirectory "C:\Users\amys2001\LichtFeld-Studio" -Wait -WindowStyle Maximized

        <#
        # Settings for the "low quality" models
        $argsLichtfeldStudioLow = @(
            "-d `"$projectDir\alignment`"",
            "-o `"$projectDir\3DGS_Low`"",
            "--config=`"$PSScriptRoot\lichtfeld_studio\lfs_config_low.json`""
        )
        Start-Process -FilePath "C:\Users\amys2001\LichtFeld-Studio\bin\LichtFeld-Studio.exe" -ArgumentList $argsLichtfeldStudioLow -WorkingDirectory "C:\Users\amys2001\LichtFeld-Studio" -Wait -WindowStyle Maximized
        #>

    }
} else {
    Write-Host "No directory was selected."
    Sleep(3)
    Exit-PSHostProcess
}
