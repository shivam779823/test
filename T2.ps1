
# Install Apache web server
$apacheDownloadUrl = "https://downloads.apache.org/httpd/httpd-2.4.48-win64-VC15.zip"
$apacheDownloadPath = "C:\temp\apache.zip"
$apacheExtractPath = "C:\Apache24"

Invoke-WebRequest -Uri $apacheDownloadUrl -OutFile $apacheDownloadPath
Expand-Archive -Path $apacheDownloadPath -DestinationPath $apacheExtractPath

# Configure Apache to serve PHP
$phpModulePath = "$apacheExtractPath\modules\php7apache2_4.dll"
$phpIniPath = "C:\php\php.ini"

$apacheConfigPath = "$apacheExtractPath\conf\httpd.conf"
$apacheConfigContent = Get-Content -Path $apacheConfigPath
$phpLoadModuleLine = "LoadModule php7_module '$phpModulePath'"
$phpIniLine = "PHPIniDir '$phpIniPath'"

$apacheConfigContent = $apacheConfigContent | ForEach-Object {
    if ($_ -match "^#LoadModule php7_module") {
        $_ -replace "^#LoadModule php7_module.*$", $phpLoadModuleLine
    } elseif ($_ -match "^#PHPIniDir") {
        $_ -replace "^#PHPIniDir.*$", $phpIniLine
    } else {
        $_
    }
}

$apacheConfigContent | Set-Content -Path $apacheConfigPath

# Download and extract WordPress
$wordpressUrl = "https://wordpress.org/latest.zip"
$downloadPath = "C:\temp\wordpress.zip"
$extractPath = "$apacheExtractPath\htdocs\wordpress"

Invoke-WebRequest -Uri $wordpressUrl -OutFile $downloadPath
Expand-Archive -Path $downloadPath -DestinationPath $extractPath

# Configure WordPress database connection
$cloudSqlInstance = "your-cloud-sql-instance"
$databaseName = "your-database-name"
$databaseUsername = "your-database-username"
$databasePassword = "your-database-password"

$wpConfigFile = "$extractPath\wp-config-sample.php"
$wpConfigDestination = "$extractPath\wp-config.php"

(Get-Content -Path $wpConfigFile) | ForEach-Object {
    $_ -replace "database_name_here", $databaseName `
       -replace "username_here", $databaseUsername `
       -replace "password_here", $databasePassword `
       -replace "localhost", $cloudSqlInstance
} | Set-Content -Path $wpConfigDestination

# Start Apache service
Start-Service -Name "Apache2.4"

Write-Host "Apache web server installation completed."
Write-Host "Open your web browser and navigate to http://localhost/wordpress to finish the setup."

