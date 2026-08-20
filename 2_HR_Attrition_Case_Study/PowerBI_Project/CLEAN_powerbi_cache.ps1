# Run this if Power BI Desktop starts crashing on open.
# Each crash leaves an orphaned Analysis Services workspace behind; enough of them
# will stop new sessions from starting. This clears them. Nothing in the project is touched.
Get-Process PBIDesktop -ErrorAction SilentlyContinue | Stop-Process -Force -Confirm:$false
Start-Sleep -Seconds 3
$ws = "$env:LOCALAPPDATA\Microsoft\Power BI Desktop\AnalysisServicesWorkspaces"
$n = @(Get-ChildItem $ws -Directory -ErrorAction SilentlyContinue).Count
foreach ($d in @(Get-ChildItem $ws -Directory -ErrorAction SilentlyContinue)) {
    try { Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop } catch { }
}
Write-Output "Cleared $n orphaned Power BI workspace folder(s). Re-open the project."
