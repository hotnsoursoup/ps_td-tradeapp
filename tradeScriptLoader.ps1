# Loader file. Removing some unncessary congestion in the main script
# Timestamps for outputting to log or console for testing! Very useful
filter timestamp { "$(Get-Date -Format o): $_" }

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName PresentationFramework
#Set your working directory where related config files and script files are held.


#importing primary configuration file. 
[xml]$config = Get-Content $configfile
$consumerKey = $config.config.consumer_key.Trim() + "@AMER.OAUTHAP"
$redirectUri = $config.config.redirecturi.Trim()
$authCode = [System.Web.HttpUtility]::UrlDecode($config.config.auth_code.Trim())
$quoteUri = $config.config.endpoints.getquoteuri.Trim()
$multiQuoteUri = $config.config.endpoints.getallquotesuri.Trim()
$authUri = $config.config.endpoints.authuri.Trim()
$accountsURI = "https://api.tdameritrade.com/v1/accounts"
#You don't necessarily have to assign the global now since it's at the script scope, but inside the functions you will need to.
$global:AccessToken = $null
$global:AccessTokenExpiration = (Get-Date).AddDays(-1)
if ($config.config.token.refresh_token.trim().length -gt 20) { 
    $global:refreshToken = $config.config.token.refresh_token.Trim()
    $global:refreshTokenExpiration = Get-Date ($config.config.token.refreshTokenExpiration.Trim())
}
else { 
    $global:refreshToken = $null
    $global:refreshTokenExpiration = (Get-Date).AddDays(-1) 
}


If (-not (Test-Path "$dir/datafiles" -PathType container)) {
    New-Item -ItemType "directory" -Path "$dir\datafiles"
}

#reference the functions file. Some functions refer to some endpoints from the config file so I stored it here.
#Alternatively you can move the config file import to the functions file to make this look cleaner.

. .\tdfunctions.ps1
