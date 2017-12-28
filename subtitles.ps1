Cd Z:\movies
$Folders = Get-ChildItem -Recurse -Directory | Sort-Object Name
$Queue = @()
$Queue.GetType()
Foreach($Folder in $Folders){
    $Files = $Folder.GetFiles() | ?{$_.name -match ".srt"}
    if($Files.count -eq 1 -and $Files.name -match ".en.srt"){
        $Queue += $Files
    }
}
$Queue
Foreach($file in $Queue){
    $Lines = Get-Content $file.FullName
    $OutFile = $file.Name -replace(".en.srt", ".ja.srt")
    $n = 1
    $time = $false
    Foreach($line in $lines){
        if($line -eq $n){
            $n | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
            $n++
            $time = $true #next line will be the time line
        }elseif($time -eq $true){
            $line | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
            $time = $false #turn flag off
        }elseif($line -eq ""){
           "" | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
        }else{
            $text = $line
            $from = "en";
            $to = "ja";
            $uri = "https://api.microsofttranslator.com/v2/Http.svc/Translate?text=$text&from=$from&to=$to" 
            $Key = "dd2f868f157c41058ea01cac84bc9045"
            $XML = Invoke-RestMethod `
                -Method Get `
                -Uri $uri `
                -Headers @{"Ocp-Apim-Subscription-Key" = $Key } `
                -verbose
        
            $XML.FirstChild.'#text' | Out-File -FilePath C:\Users\sharrington\$OutFile -Append -Force
        }
    }         
} 