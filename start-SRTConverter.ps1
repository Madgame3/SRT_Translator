function Test-MyPath ($path, $string){
    If(!Test-Path $path){
        $path = Read-Host -Prompt "Enter path to $string Folder, ex 'C:\Movies'" 
        test-Mypath
    }
}

<#
 .Synopsis
    Convert SRT Files to Desired Languages
 .DESCRIPTION
    1)SRT Files for certain movies and Languages can sometime be a pain to track down, with this powershell function, you'll be able to translate an existing SRT to your desired language using powershell and bing API's.
    2) I'm kind of lazy and I don't want to have to manually convert each file, so this program is supposed to figure out which files will need translating
 .EXAMPLE
    Start-SRTConverter -AzureKey 123456677889 -MovieFolder "C:\Movies" -FromLangCode "en" -ToLangCode "ja" -SaveFolder "C:\Subtitles"
 .EXAMPLE
    Start-SRTConverter -AzureKey 123456677889 -MovieFolder "C:\Movies" -FromLangCode "en" -ToLangCode "ja" -SaveFolder "C:\Subtitles"
 #>
 function Start-SRTConverter
 {
     [CmdletBinding()]
     [Alias()]
     [OutputType([int])]
     Param
     (
         # Ocp-Apim-Subscription-Key to use Bing Translation API
         [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
         $AzureKey,
 
         #Path to Movie Folder, Z:\Movies
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=1)]
         $MovieFolder, 
         
         #Translate from Language Code, example English = en
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=2)]
         $FromLangCode,

         #Translate to Language Code, example Japanese = ja
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=3)]
         $ToLangCode, 

         #Path to save translations to, I didnt' want to put them in the Movie Directory in case they were terrible.
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=4)]
         $SaveFolder
     )
 
} 

#Recursive Calls until path checks out!
Test-MyPath -path $MovieFolder -string "Movie"
Test-MyPath -path $SaveFolder -string "Save"
#Folders Are Valid, Proceed with Script!
Set-Location $MovieFolder
#I use Radarr to organize my Media, so all movies are in there own folder, if this is not true for you....go download Radarr.
$Folders = Get-ChildItem -Recurse -Directory | Sort-Object Name
$Queue = @()
Foreach($Folder in $Folders){
    $Files = $Folder.GetFiles() | ?{$_.name -match ".srt"}
    if($Files.count -ge 1 -and $Files.name -match ".$FromLangCode.srt" -and $Files.name -notmatch ".$ToLangCode.srt"){
        $Queue += $Files
    }
}
Write-Host -ForegroundColor Yellow "You have $($Queue.count) Movie Subtitles pending Translation"
Foreach($SRT in $Queue){
    $Lines = Get-Content $SRT.FullName
    Write-Host -ForegroundColor Yellow "Begin Translation for $($SRT.name)"
    $OutFile = $SRT.Name -replace(".$FromLangCode.srt", ".$ToLangCode.srt")
    $N = 1
    $Time = $False
    Foreach($Line in $Lines){
        <# 
          SRT Files should follow a basic format
          1. A number indicating which subtitle it is in the sequence.
          2. The time that the subtitle should appear on the screen, and then disappear.
          3. The subtitle itself.
          4. A blank line indicating the start of a new subtitle. 

          Each of the if, elseif, and else statements are designed to handle each line 1-4 differently.
        #>
        if($Line -eq $N){
            $N | Out-File -FilePath "$saveFolder\$OutFile" -Append -Force
            $N++
            $Time = $True #next line will be the time line
        }elseif($Time -eq $True){
            $Line | Out-File -FilePath "$saveFolder\$OutFile" -Append -Force
            $Time = $False #turn Time flag off
        }elseif($Line -eq ""){
           "" | Out-File -FilePath "$saveFolder\$OutFile" -Append -Force
        }else{
            $Text = $Line
            $URI = "https://api.microsofttranslator.com/v2/Http.svc/Translate?text=$Text&from=$FromLangCode&to=$ToLangCode" 
            $XML = Invoke-RestMethod `
                -Method Get `
                -Uri $URI `
                -Headers @{"Ocp-Apim-Subscription-Key" = $AzureKey }
        
            $XML.FirstChild.'#text' | Out-File -FilePath "$saveFolder\$OutFile" -Append -Force
        }
    }
    Write-Host -ForegroundColor Green "Translation Complete for $($SRT.name)"         
} 