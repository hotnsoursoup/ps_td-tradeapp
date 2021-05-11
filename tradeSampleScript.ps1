<# 
. Synopsis
TD Ameritrade trading quick start

.Author
Victor Nguyen

.Version
1.1

.Author Notes
Clone entire branch for full functionality @ https://github.com/victor-nguyeners/td_tradeapp

Only a means to get started. Theres not much validation. error handling, or logging. ALso, this will only get prices. 
You will need to build the algo part yourself and determine what metrics/kpis you would like to save.
If you want high volume algo trades, TD ameritrade isn't the one ;)



#>

# Set your directory to a static one of if you wish
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
cd $dir
$configfile = "$dir\config.xml"
$datafiles = "$dir\datafiles\"


# Load some initial settings. The loader then loads the functions
. .\tradeScriptLoader.ps1

#Checks for a refresh token, if it is the first one, it'll request it.
try {
    Write-Output "Script Started" | timestamp
    #Simple check to see if the length of that field is less than 50. Tokens are much longer so this accomodates placeholder text in the xml
    #Or if the existing token is already expired. There are better ways to validate tokens, but for now we'll use this.

    Write-Output "Checking for refresh Token" | timestamp

    #Calculate time till expiration on refresh token (if there is one), we're not concerned if this errors in case the field is empty so we'll add a contiue
    try { ($refreshTokenDTE = $refreshTokenExpiration - (Get-Date)) | Out-Null } catch { Continue }

    Write-Output "Refresh Token found, expires in $($refreshTokenDTE.days) days, $($refreshTokenDTE.hours) hours, and $($refreshTokenDTE.minutes) minutes" | Timestamp
        
    # For the purpose of this example, we'll check for a csv file and  update the csv file with the data. No actual trading going on.
    $date = Get-Date
    $dataFileName = "$datafiles\$($date.month)-$($date.day)-$($date.year)_tdAppPriceLog.csv"
    If (-not (Test-Path $dataFileName -PathType leaf)) {
        Write-Output "No datafile found, creating file" | timestamp
        $file = [pscustomobject]@{datetime = ''; ticker = ''; watchlist = ''; price = '' }
        $file | Export-Csv $dataFileName -NoTypeInformation -
    }

    #################################### The meat of things ###################################

    #Start your loop! For this example i'll just use elapsed time. You could run it forever, but just keep in mind memory restrictions.
    $Time = [System.Diagnostics.Stopwatch]::StartNew()
    $watchlist = Import-csv "$dir\watchlist.csv"
    $count = 0
    $totalcount = 0
    $allQuotes = @()
    $firstRun = $true
    Write-Output "Starting loop" | timestamp
    Do {
        
        checkTokens 
        if ($firstRun -eq $true) { Write-output "Acquired Token, connecting to API and fetching data. Will not output more streams until 50 loops have been run (line #111 controls this)" | timestamp }
        $header = @{ "Authorization" = "Bearer $accessToken" }

        ForEach ($list in $watchlist) {
            if ($list.tickers.split(',').count -eq 1) {
                #if the watchlist only has 1 ticker
                $ticker = $list.tickers.trim()
                $uri = $quoteUri.replace('TICKER', $ticker)
                ########################## Actual request to the API
                $quote = Invoke-RestMethod -uri $uri -headers $header | Select-Object -ExpandProperty $ticker
                $quoteTime = Get-Date -Format G
                
                $newObj = [pscustomobject]@{datetime = $quotetime; ticker = $ticker; watchlist = $list.name; price = $quote.lastPrice }
                $allQuotes += $newObj
                Clear-Variable newObj
                # Accomodating API limits. Play with this number based on your needs
                Start-Sleep -Milliseconds 750
                
            }
            else {
                #Write-Output "Checking watchlist tickers $($list.tickers)" | timestamp
                $tickers = $list.tickers.replace(' ', '')
                $quotesBody = @{ "Authorization" = "Bearer $accessToken"; "symbol" = $tickers }
                $quote = Invoke-restmethod -uri $multiQuoteUri -headers $header -body $quotesBody 
                $quoteTime = Get-Date -format G
                #It's poor form to have same variable names in different parts of loop used for different things, but it still works here. ($ticker)
                ForEach ($ticker in $tickers.split(',')) {
                
                    $singleTicker = $quote | Select-Object -ExpandProperty $ticker
                    $newObj = [pscustomobject]@{datetime = $quotetime; ticker = $ticker; watchlist = $list.name; price = $singleTicker.lastPrice }
                    $allQuotes += $newObj
                           
                    Clear-Variable newObj              
                }
                Start-Sleep -Milliseconds 750
            }
        }
            
        $count ++
        $totalcount ++
        if ($count -eq 50) {
            Write-Output "Processed $totalcount total queries " | timestamp
            $count = 0

        }
    
        if ($allQuotes.count -eq 500) {
            # Every X lines, dump.
            Write-Output "Dumping current batch (500) to datafile" | timestamp
            $allQuotes[0..499] | export-csv $dataFileName -NoTypeInformation -Append
            $allQuotes = $allQuotes[500..$allQuotes.count]

            # If you don't want to clear out the log in memory, you can do something like this.
            # $batch = 0 # (This is before the loop starts)
            
            # do {
            # $allQuotes[0..499] | export-csv $dataFileName -NoTypeInformation -Append
            # $allQuotes = $allQuotes[($batch*500)..$allQuotes.count]
            # $batch ++ 
            # } until($peopledonateToMe -eq $true)
        }
        if ($firstRun = $true) { $firstRun = $false }        
    } Until ($time.hours -gt 2) #2 hour runtime
    $time.stop()
}


catch {
    Write-Output $_.Exception | timestamp
    $errors = $_.Exception
    # Error handling not in scope for this example!
}
