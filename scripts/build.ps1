#requires -Version 7.2
[CmdletBinding()]
param([switch]$Open)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$markdown = Get-Content -Raw -Encoding utf8 (Join-Path $projectRoot 'index.md')
$template = Get-Content -Raw -Encoding utf8 (Join-Path $projectRoot 'src/template.html')

# Load the Markdown parser bundled with PowerShell; no package installation needed.
ConvertFrom-Markdown -InputObject '' | Out-Null
$builder = [Markdig.MarkdownPipelineBuilder]::new()
[Markdig.MarkdownExtensions]::UseAutoIdentifiers($builder, [Markdig.Extensions.AutoIdentifiers.AutoIdentifierOptions]::GitHub) | Out-Null
$pipeline = $builder.Build()
$linksSection = [regex]::Match($markdown, '(?ms)^## リンク集[ \t]*\r?\n(?<links>.*?)(?=^## |\z)')
$links = ''
if ($linksSection.Success) {
    $links = [Markdig.Markdown]::ToHtml($linksSection.Groups['links'].Value, $pipeline, $null).Trim()
    $markdown = $markdown.Remove($linksSection.Index, $linksSection.Length)
}
$content = [Markdig.Markdown]::ToHtml($markdown, $pipeline, $null)

if (-not $template.Contains('{{content}}')) {
    throw 'The template must contain {{content}}.'
}
$html = $template.Replace('{{content}}', $content.Trim()).Replace('{{links}}', $links)
$outputPath = Join-Path $projectRoot 'index.html'
[System.IO.File]::WriteAllText($outputPath, $html, [System.Text.UTF8Encoding]::new($false))
Write-Host "Built $outputPath"

if ($Open) {
    Start-Process -FilePath $outputPath
}
