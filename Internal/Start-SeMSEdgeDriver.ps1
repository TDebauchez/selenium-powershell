function Start-SeMSEdgeDriver {
    [cmdletbinding(DefaultParameterSetName = 'default')]
    param(
        [string]$StartURL,
        [SeWindowState]$State,
        [System.IO.FileInfo]$WebDriverPath,
        [System.IO.FileInfo]$BinaryPath,
        [System.IO.FileInfo]$DefaultDownloadPath,
        [System.IO.FileInfo]$ProfilePath,
        [switch]$PrivateBrowsing,
        [Double]$ImplicitWait,
        [System.Drawing.Size]$Size,
        [System.Drawing.Point]$Position,
        [OpenQA.Selenium.DriverService]$service,
        [OpenQA.Selenium.DriverOptions]$Options,
        [String[]]$Switches,
        [OpenQA.Selenium.LogLevel]$LogLevel,
        [String]$UserAgent,
        [Switch]$AcceptInsecureCertificates
    )

    process {
        #region Edge set-up options
        if ($state -eq [SeWindowState]::Headless) { Write-Warning 'Pre-Chromium Edge does not support headless operation; the Headless switch is ignored' }
    
        if (-not $PSBoundParameters.ContainsKey('Service')) {
            $ServiceParams = @{}
            if ($WebDriverPath) { $ServiceParams.Add('WebDriverPath', $WebDriverPath) }
            $service = New-SeDriverService -Browser MSEdge @ServiceParams -ErrorAction Stop
        }
    
        if ($PrivateBrowsing) { $options.UseInPrivateBrowsing = $true }
	
	    if ($ProfilePath) {
		    $ProfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilePath)
		    Write-Verbose "Setting Profile directory: $ProfilePath"
		    $Options.AddArgument("user-data-dir=$ProfilePath")
	    }
	
        if ($StartURL) { $options.StartPage = $StartURL }
        #endregion

        if ($PSBoundParameters.ContainsKey('LogLevel')) {
            Write-Warning "LogLevel parameter is not implemented for $($Options.SeParams.Browser)"
        }

        try {
            $Driver = [OpenQA.Selenium.Edge.EdgeDriver]::new($service , $options)
        }
        catch [OpenQA.Selenium.WebDriverArgumentException]{
            Write-Host "Flute"
            Write-Warning $_.Exception.message

        }
        catch {
            $driverversion = (Get-Item .\assemblies\MicrosoftWebDriver.exe).VersionInfo.ProductVersion
            $WindowsVersion = [System.Environment]::OSVersion.Version.ToString()
            Write-Warning -Message "Edge driver is $driverversion. Windows is $WindowsVersion. If the driver is out-of-date, update it as a Windows feature,`r`nand then delete $PSScriptRoot\assemblies\MicrosoftWebDriver.exe"
            throw $_ ; return
        }
        if (-not $Driver) { Write-Warning "Web driver was not created"; return }
        Add-Member -InputObject $Driver -MemberType NoteProperty -Name 'SeServiceProcessId' -Value $Service.ProcessID
        #region post creation options
        if ($PSBoundParameters.ContainsKey('Size')) { $Driver.Manage().Window.Size = $Size }
        if ($PSBoundParameters.ContainsKey('Position')) { $Driver.Manage().Window.Position = $Position }
        $Driver.Manage().Timeouts().ImplicitWait = [TimeSpan]::FromMilliseconds($ImplicitWait * 1000)

        switch ($State) {
            { $_ -eq [SeWindowState]::Minimized } { $Driver.Manage().Window.Minimize() }
            { $_ -eq [SeWindowState]::Maximized } { $Driver.Manage().Window.Maximize() }
            { $_ -eq [SeWindowState]::Fullscreen } { $Driver.Manage().Window.FullScreen() }
        }

        #endregion

        Return $Driver
    }
}