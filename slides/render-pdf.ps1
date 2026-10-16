# Renders a revealjs deck in this folder and prints it to PDF with headless
# Chrome, in Reveal's print mode (?print-pdf), so slide backgrounds are kept.
#
# Usage, from any folder:
#   powershell -ExecutionPolicy Bypass -File slides\render-pdf.ps1
#   powershell -ExecutionPolicy Bypass -File slides\render-pdf.ps1 -Deck OtherDeck
#
# Writes <Deck>.html and <Deck>.pdf next to <Deck>.qmd.

param(
  [string]$Deck = "MS2_methods_meeting"
)

$ErrorActionPreference = "Stop"

# Quarto ships inside RStudio on this machine; R is needed for the knitr chunks
$env:PATH = "C:\Program Files\R\R-4.6.0\bin;" +
  "C:\Program Files\RStudio\resources\app\bin\quarto\bin;" +
  $env:PATH
$env:RENV_CONFIG_USER_LIBRARY = "TRUE"

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"

$dir  = $PSScriptRoot
$qmd  = Join-Path $dir "$Deck.qmd"
$html = Join-Path $dir "$Deck.html"
$pdf  = Join-Path $dir "$Deck.pdf"

quarto render $qmd

# A throwaway Chrome profile, so this does not touch the everyday one
$profile = Join-Path $env:TEMP "render-pdf-chrome"
$url     = "file:///" + ($html -replace '\\', '/') + "?print-pdf"

# --window-size matches the Reveal slide size (1050 x 700); with Chrome's
# default window the title block is laid out higher and its first line clips.
# Start-Process keeps Chrome's harmless stderr chatter from stopping the script.
$chromeArgs = @(
  "--headless=new",
  "--disable-gpu",
  "--no-pdf-header-footer",
  "--window-size=1050,700",
  "--virtual-time-budget=20000",
  "--run-all-compositor-stages-before-draw",
  "`"--user-data-dir=$profile`"",
  "`"--print-to-pdf=$pdf`"",
  "`"$url`""
)

$before = if (Test-Path $pdf) { (Get-Item $pdf).LastWriteTime } else { [datetime]::MinValue }

Start-Process `
  -FilePath $chrome `
  -ArgumentList $chromeArgs `
  -Wait `
  -NoNewWindow `
  -RedirectStandardError (Join-Path $env:TEMP "render-pdf-chrome.log")

if ((Test-Path $pdf) -and (Get-Item $pdf).LastWriteTime -gt $before) {
  Write-Host "Wrote $pdf"
} else {
  throw "Chrome did not write $pdf; see $env:TEMP\render-pdf-chrome.log"
}
