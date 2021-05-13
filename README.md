# **Interacting with TD Ameritrade API with Powershell**

## Author Notes
Hey guys it's Victor. 

This script was built for educational purposes and help jump start YOUR OWN build. This is NOT a fully built script designed to help you trade from minute one. You are free to use it however you wish, though you will have to build your own trading algos. Yes I know PowerShell isn't the best, but it's readily available on everyones Windows PC. This will get you connected quickly to the TD AMER API and retrieve quotes. Not everyone has SQL Server installed on their desktop so I figured CSV was the way to go to get people started for data storage. Otherwise I may upload some of my SQL Update scripts in future and/or integrate them in here. 

You will need at least some understanding of programming/scripting.

This script will **NOT**
* Handle errors
* Validate data
* Create a log
* Trade for you

Please build these parts out. 

## Prerequisites

### Version
This script was built on version 5.1 of PS. PowerShell ISE should be on your windows machine by default. If you use PowerShell Core, I'm afraid it hasn't been tested.

You can check your verson with 
```powershell
$PSVersiontable
 ```
### Clone repository
You will need to clone the entire repo including the configs.

```ssh
git clone https://github.com/victor-nguyeners/td_tradeapp.git
```

### Token and keyfile storage
It is HIGHLY recommend you do not store keys directly in the XML as given in the example. Build out the keyfile storage and retrieve the key with the provided function get-key.

Here's a reference for making the key file --> https://www.altaro.com/msp-dojo/encrypt-password-powershell/ 

You can, alternatively, use a key vault like azure key vault.

### Modifying the watchlist
You'll need to modify the watchlist.csv file to add in your own ticker(s). The API also allows you to fetch your own watchlist, but that's out of scope for the current version.

| Name | Tags | Description | Tickers
| ------------- | ------------- |------------- |------------- |
| MyFirstList | Tech | Donate to my stock funds | TSLA |
| MyOtherList | ETF | Donate to my stock funds | SPY, QQQ |


## Getting Started

### Register your app + retrieve initial consumer key

You will need to retrieve your keys first. This is done on the developer site. The "Getting Started" section should help you there. 

https://developer.tdameritrade.com/guides

https://developer.tdameritrade.com/content/getting-started

Alternatively, there's this decent write up as well.

https://www.reddit.com/r/algotrading/comments/914q22/successful_access_to_td_ameritrade_api/

Below is my take on it... 

### Retrieving your Auth Code

* Step 1: Plug your consumer key and redirect uri into this URL and navigate to it. For testing, I used localhost and I'll use a fake consumer key for my app here.  ""
 	* template: https://auth.tdameritrade.com/oauth?client_id=**YOUR_CONSUMERKEY_HERE*@AMER.OAUTHAP&response_type=code&redirect_uri=**YOUR_REDIRECT_URI**
 	* example url: https://auth.tdameritrade.com/oauth?client_id=**GX314K34JJKDMMXHB4DX**@AMER.OAUTHAP&response_type=code&redirect_uri=**http://localhost**
* Step 2: Log in using your app credentials
* Step 3: COPY the code part of the output in the browser address bar. The site may come up empty, but you'll get an AUTHORIZATION code similar to this in the address bar, except a LOT longer.
 	* e.g. https://localhost/?code=**xh13gjhohjhey12jx%41abxnjk213b12hj3k1bjkxbm1ads9x81z21jkxkam%B2Fstxe4i9jn32G%2jjkjk%**
	 * The extracted code would then be "_xh13gjhohjhey12jx%41abxnjk213b12hj3k1bjkxbm1ads9x81z21jkxkam%B2Fstxe4i9jn32G%2jjkjk%2_"

### Modify config.xml
Place the code into the config.xml file for the section on auth_code, consumer key, and redirecturi. I put in my redirectUri below.
```xml
<redirecturi>http://localhost</redirecturi>
<consumer_key>YOUR_CONSUMER_KEY_HERE</consumer_key>
<auth_code>YOUR_CODE_HERE</auth_code>
```
**IMPORTANT** Your Auth code expires quite quickly. If you find that the auth code is not working and you've figured the script out, get a new auth code and try again.
Also, the auth code is worthless after it is traded for the first refresh token. The script will remove it on its own if that is the case.

Next, update your consumer key and redirectURI as configured in your app. Nothing else in the config.xml file has to be updated. 

### Modify folder path
The current beta version has the current invocation location configured, but if you want to change your directory to a static directory you can do so like below in the sample script.

```powershell
#Set your working directory where related config files and script files are held. 
$dir = "E:\trading"
cd $dir
$configfile = "$dir\config.xml"
$datafile = "$dir\datafiles\"
```

## Use

If you've run the script within a few minutes of placing in your auth code, consumer key, and redirect URI,  you can hit the run button and it should start printing quotes. 

The functions were built with a global variable set, which means most of them don't require passing in variables. You may want to convert the functions and pass in variables and return variables in the functions. The tdfunctions file will include an example of how to convert one of them. The rest is up to you.


### Sample output from a ticker. (TSLA)
```
assetType                          : EQUITY
asset

Type                      : EQUITY
cusip                              : 88160R101
symbol                             : TSLA
description                        : Tesla, Inc.  - Common Stock
bidPrice                           : 692.89
bidSize                            : 100
bidId                              : P
askPrice                           : 693.29
askSize                            : 100
askId                              : P
lastPrice                          : 693.29
lastSize                           : 0
lastId                             : D
openPrice                          : 696.41
highPrice                          : 708.5
lowPrice                           : 693.6
bidTick                            :
closePrice                         : 704.74
netChange                          : -11.45
totalVolume                        : 22182537
quoteTimeInLong                    : 1619646633155
tradeTimeInLong                    : 1619646635637
mark                               : 693.29
exchange                           : q
exchangeName                       : NASD
marginable                         : True
shortable                          : True
volatility                         : 0.0377
digits                             : 4
52WkHigh                           : 900.4
52WkLow                            : 136.608
nAV                                : 0.0
peRatio                            : 997.57
divAmount                          : 0.0
divYield                           : 0.0
divDate                            :
securityStatus                     : Normal
regularMarketLastPrice             : 694.4
regularMarketLastSize              : 2677
regularMarketNetChange             : -10.34
regularMarketTradeTimeInLong       : 1619640000441
netPercentChangeInDouble           : -1.6247
markChangeInDouble                 : -11.45
markPercentChangeInDouble          : -1.6247
regularMarketPercentChangeInDouble : -1.4672
delayed                            : False
realtimeEntitled                   : True
```

	
