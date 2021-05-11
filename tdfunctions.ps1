<# 
    https://github.com/victor-nguyeners

    .Author           : Victor Nguyen
    .Script Name      : tdFunctions.ps1
    .Version          : 1.1

If you want to go the route and not assign global variables, you will have to rebuild some of the functions and pass the variables in like below. Keep scope in mind.
Some of these variables do not change so I converted them to global for ease.

function getfirstToken(){
[CmdletBinding()]
     Param(
        [Parameter(Mandatory=$true, Position=0)]
         [string] $code,
        [Parameter(Mandatory=$true, Position=1)]
         [string] $redirecturi,
        [Parameter(Mandatory=$true, Position=2)]
         [string] $consumerkey
    )
    $tokenpostbody = @{
        grant_type = "authorization_code"
        refresh_token = ""
        access_type = "offline"
        code = $code
        client_id = $consumerKey
        redirect_uri = $redirectUri
    }
    $tokenOBject = Invoke-RestMethod -Uri $authUrI -Method post -Body $tokenpostbody
    Return $tokenOBject
}

You would then assign it such as this.

$tokens = getfirsttoken

#>
function decodeUrl($url) { 
    $decodedURL = [System.Web.HttpUtility]::UrlDecode($url)
    return $decodedURL
}

function encodeUrl($url) { 
    $encodedUrl = [System.Web.HttpUtility]::UrlEncode($url)
    return $encodedUrl
}

#Update Configuration file that stores the tokens. As noted in the readme, it is much wiser to store encrypted or key vault.
#ClearAuth is for when we want to remove the auth ccode from the XML after successful use. 
function updateConfig() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [switch]$clearAuth
    )
    if ($clearAuth) { $config.config.auth_code = "" }
    $config.config.token.refresh_token = $refreshToken.toString()
    $config.config.token.refreshTokenExpiration = $refreshTokenExpiration.toString()
    $config.Save($configfile)
}

function assignTokens() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Object]$tokens,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("refresh", "access")]
        [String]$tokenType
    )
    # Write-Output "Assigning Tokens, token type $($tokentype)" | timestamp
    if ($tokenType -eq "refresh") {
        Write-Output "Token Type Refresh" | timestamp
        $global:refreshToken = $tokens.refresh_token
        $global:refreshTokenExpiration = (Get-Date).AddSeconds($tokens.refresh_token_expires_in)
    }
    $global:accessToken = $tokens.access_token
    $global:accessTokenExpiration = (Get-Date).AddSeconds($tokens.expires_in)
}


function getAccessToken() {
    $tokenPostBody = @{
        grant_type    = "refresh_token"
        refresh_token = $refreshToken
        client_id     = $consumerKey
    }
    Write-Output "Getting Access Token" | timestamp
    $tokens = Invoke-RestMethod -Uri $authUrI -Method post -Body $tokenPostBody
    assignTokens $tokens "access"
}

function getfirstToken() {
    $tokenPostBody = @{
        grant_type    = "authorization_code"
        refresh_token = ""
        access_type   = "offline"
        code          = $authCode
        client_id     = $consumerKey
        redirect_uri  = $redirectUri
    }
    if ($authCode.length -gt 30) {
        Write-Output "Auth code entry found, attempting to retrieve first Token" | timestamp
        $tokens = Invoke-RestMethod -Uri $authUrI -Method post -Body $tokenPostBody
        $global:tokensx = $tokenPostBody
        Write-Output "Assigning new tokens" | timestamp
        assignTokens $tokens "refresh"
        Write-Output "Updating Config" | timestamp
        updateConfig -clearAuth
    }
    else {
        [System.Windows.MessageBox]::Show('You will need to get a new auth code, read the readme file on how to do this; Exiting') 
        exit
    }
}

function renewRefreshToken() {
    $tokenPostBody = @{
        grant_type    = "refresh_token"
        refresh_token = $refreshToken
        access_type   = "offline"
        client_id     = $consumerKey
        redirectUri   = $redirectUri
    }
    Write-Output "Renewing refresh Token" | timestamp
    $tokens = Invoke-RestMethod -Uri $authUrI -Method post -Body $tokenPostBody
    $global:tokens2 = $tokens
    assignTokens $tokens "refresh"
    updateConfig
}


<#
It would be wise to enhannce this with some error handling to manage the return codes. Converting to a webrequest instead of restmethod would give you status codes to use.
Also, these scripts assume every time a token is updated, both the token and the expiration are updated in tandem. 
You can also pass the tokens in as parameters (recommended) and use validation methods to ensure whats being passed in matches the required criteria.
#>
function checkTokens() {
    [CmdletBinding()]Param(
        #Placeholder
    )
    $date = (Get-Date).AddMinutes(1) # Adding 1 minute to date to ensure we have dont have buffer issues or API issues.
    if ($accessTokenExpiration -gt $date) { return } #We're fine if the token is still valid. Exit out of the check function.
    elseif ($refreshTokenExpiration -gt $date) {
        # Retrieve new access token if refresh token is still valid. If expiring within 7 days, update. 
        #Update your buffer time in case your app is down and you dont want to do the auth code update. Or create a new script just to manage the update of the token / monitor it
        if ($refreshTokenExpiration -lt $date.AddDays(7)) {  
            $msg = "Refresh Token expires within 7 days, updating refresh Token"
            Write-Output $msg | timestamp
            renewRefreshToken
        }
        #If refresh token is still good, then just get an access token
        else { 
            
            Write-Output "Valid Refresh Token Found, retrieving access token" | timestamp
            getAccessToken 
        }
    }
    else {
        if ($authCode.Length -gt 30) { 
            Write-Output "No valid tokens found" | Timestamp
            Write-Output "Using AuthCode in config.xml beginning with $($authCode.substring(0,10))" | timestamp      
            getfirstToken
        }
        else {
            [System.Windows.MessageBox]::Show('You will need to get a new auth code, read the readme file on how to do this; Exiting')   
        }
    }
}

# I built this to store my keys locally,  you won't need this for testing or at all if you don't care to secure your keys.
# The keyfile is the AES key you created and encrypted the key with.
function get-Key() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String[]]
        $keyfile,
        [Paramter(Mandatory = $true)]
        $key
    )
    $string = (get-content $keyfile) | ConvertTo-SecureString -key (Get-Content $key)
    $securestring = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($string)
    $unencrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($securestring)
    return $unencrypted
}




