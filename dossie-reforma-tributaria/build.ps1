# Monta o dossiê a partir do JSON de dados mais recente (versão Windows do build.py).
# Uso:  powershell -ExecutionPolicy Bypass -File dossie-reforma-tributaria\build.ps1
$ErrorActionPreference = 'Stop'
$base = $PSScriptRoot
$docs = Join-Path (Split-Path $base -Parent) 'docs'
$enc = New-Object System.Text.UTF8Encoding($false)

$fonte = Get-ChildItem $base -Filter 'dados-*.json' |
  Where-Object { $_.Name -match '^dados-\d{4}-\d{2}-\d{2}\.json$' } |
  Sort-Object Name | Select-Object -Last 1
if (-not $fonte) { throw 'Nenhum dados-AAAA-MM-DD.json encontrado.' }
$data = $fonte.BaseName.Substring(6)
$texto = [IO.File]::ReadAllText($fonte.FullName, $enc).Trim()
$o = $texto | ConvertFrom-Json
if ($texto -match '(?i)</script') { throw 'O JSON não pode conter </script.' }

$erros = @()
foreach ($l in 'pt', 'es') {
  if ($o.$l.ui.nav.Count -ne 11) { $erros += "${l}: ui.nav deve ter 11 itens" }
  foreach ($n in $o.$l.novidades) { if (-not $n.links) { $erros += "${l}: novidade sem links: $($n.titulo)" } }
}
$refs = @($o.refs.PSObject.Properties.Name)
foreach ($p in $o.fontesItens.PSObject.Properties) { foreach ($r in $p.Value) { if ($refs -notcontains $r) { $erros += "fontesItens $($p.Name): ref inexistente $r" } } }
$urls = @($o.refs.PSObject.Properties | ForEach-Object { $_.Value.u }) + @($o.legislacao.url) + @($o.pt.novidades.links.url) + @($o.es.novidades.links.url)
foreach ($u in $urls) { if ($u -notmatch '^https://') { $erros += "URL sem https: $u" } }
if ($erros.Count) { $erros | ForEach-Object { Write-Host " - $_" }; throw "$($erros.Count) erro(s) de validação." }

$tpl = [IO.File]::ReadAllText((Join-Path $base 'template.html'), $enc)
if (([regex]::Matches($tpl, '__DADOS__')).Count -ne 1) { throw 'template.html deve ter exatamente um __DADOS__.' }
$html = $tpl.Replace('__DADOS__', $texto)

[IO.File]::WriteAllText((Join-Path $base "dossie-reforma-tributaria-$data.html"), $html, $enc)
[IO.File]::WriteAllText((Join-Path $base 'dossie-reforma-tributaria-ATUAL.html'), $html, $enc)
New-Item -ItemType Directory -Force $docs | Out-Null
[IO.File]::WriteAllText((Join-Path $docs 'index.html'), $html, $enc)
[IO.File]::WriteAllText((Join-Path $docs '.nojekyll'), '', $enc)
Write-Host "OK: $($fonte.Name) -> dossie-reforma-tributaria-$data.html, ATUAL.html e docs/index.html"
