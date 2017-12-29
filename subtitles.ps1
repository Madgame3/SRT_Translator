Cd Z:\movies
$Key = ""
$Folders = Get-ChildItem -Recurse -Directory | Sort-Object Name
$Queue = @()
$Queue.GetType()
Foreach($Folder in $Folders){
    $Files = $Folder.GetFiles() | ?{$_.name -match ".srt"}
    if($Files.count -eq 1 -and $Files.name -match ".en.srt"){
        $Queue += $Files
    }
}
Write-Host -ForegroundColor Yellow "You have $($Queue.count) Subtitles pending Translation"
Foreach($SRT in $Queue){
    $Lines = Get-Content $SRT.FullName
    Write-Host -ForegroundColor Yellow "Begin Translation for $($SRT.name)"
    $OutFile = $SRT.Name -replace(".en.srt", ".ja.srt")
    $N = 1
    $Time = $False
    Foreach($Line in $Lines){
        if($Line -eq $N){
            $N | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
            $N++
            $Time = $True #next line will be the time line
        }elseif($Time -eq $True){
            $Line | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
            $Time = $False #turn flag off
        }elseif($Line -eq ""){
           "" | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
        }else{
            $Text = $Line
            $From = "en";
            $To = "ja";
            $URI = "https://api.microsofttranslator.com/v2/Http.svc/Translate?text=$Text&from=$From&to=$To" 
            $XML = Invoke-RestMethod `
                -Method Get `
                -Uri $URI `
                -Headers @{"Ocp-Apim-Subscription-Key" = $Key }
        
            $XML.FirstChild.'#text' | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
        }
    }
    Write-Host -ForegroundColor Green "Translation Complete for $($SRT.name)"         
} 