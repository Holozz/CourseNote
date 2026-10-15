param(
  [Parameter(Mandatory=$true)][string]$Src,
  [Parameter(Mandatory=$true)][string]$OutFile
)
$ErrorActionPreference = 'Continue'
$sb = New-Object System.Text.StringBuilder
$ppt = $null
try {
  $ppt = New-Object -ComObject PowerPoint.Application
  $ppt.Visible = -1
  $pres = $ppt.Presentations.Open($Src, $true, $false, $false)
  $n = $pres.Slides.Count
  [void]$sb.AppendLine("TOTAL SLIDES: $n")
  for ($i = 1; $i -le $n; $i++) {
    $sl = $pres.Slides.Item($i)
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("===== SLIDE $i =====")
    try {
      if ($sl.HasNotesPage -eq -1) {
        foreach ($ns in $sl.NotesPage.Shapes) {
          try {
            if ($ns.HasTextFrame -eq -1 -and $ns.TextFrame.HasText -eq -1) {
              $t = $ns.TextFrame.TextRange.Text
              if ($t.Trim().Length -gt 0 -and $t -notmatch '^\d+$') { [void]$sb.AppendLine("[NOTES] " + $t) }
            }
          } catch {}
        }
      }
    } catch {}
    foreach ($sh in $sl.Shapes) {
      try {
        if ($sh.Type -eq 6) {
          [void]$sb.AppendLine("[GROUP " + $sh.Name + "]")
          foreach ($g in $sh.GroupItems) {
            try {
              if ($g.HasTextFrame -eq -1 -and $g.TextFrame.HasText -eq -1) { [void]$sb.AppendLine("  (grp) " + $g.TextFrame.TextRange.Text) }
              elseif ($g.Type -eq 13) { [void]$sb.AppendLine("  (grp)[PICTURE " + $g.Name + "]") }
            } catch {}
          }
          continue
        }
        if ($sh.HasTextFrame -eq -1 -and $sh.TextFrame.HasText -eq -1) {
          [void]$sb.AppendLine("[" + $sh.Name + "] " + $sh.TextFrame.TextRange.Text)
          continue
        }
        if ($sh.Type -eq 19) {
          [void]$sb.AppendLine("[TABLE " + $sh.Name + "]")
          try {
            $tb = $sh.Table
            for ($r=1; $r -le $tb.Rows.Count; $r++) {
              $row = @()
              for ($c=1; $c -le $tb.Columns.Count; $c++) { $row += $tb.Cell($r,$c).Shape.TextFrame.TextRange.Text }
              [void]$sb.AppendLine("  | " + ($row -join " | ") + " |")
            }
          } catch {}
          continue
        }
        if ($sh.Type -eq 13) { [void]$sb.AppendLine("[PICTURE " + $sh.Name + "]"); continue }
        if ($sh.Type -eq 3)  { [void]$sb.AppendLine("[CHART " + $sh.Name + "]"); continue }
        [void]$sb.AppendLine("[SHAPE " + $sh.Name + " type=" + $sh.Type + "]")
      } catch {}
    }
  }
  $pres.Close()
  [System.IO.File]::WriteAllText($OutFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
  Write-Output "DONE chars=$($sb.Length) slides=$n"
} catch {
  Write-Output "ERROR: $($_.Exception.Message)"
  [System.IO.File]::WriteAllText($OutFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
} finally {
  if ($ppt) { try { $ppt.Quit() } catch {} }
}
