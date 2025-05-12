$postsDir = "C:\Users\Zak\Documents\pestpolicy-hugo\content\posts"
$authorText = "author: Isaac"  
$authorValue = "Isaac"  

# EXACT disclaimer format with all formatting preserved
$disclaimerBlock = @'
> **`We may earn a commission when you click and buy from Amazon.com`.**
>

---
'@

Get-ChildItem -Path $postsDir -Filter "*.markdown" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -Raw -Path $file

    Write-Host "Processing file: $file"

    if ($content -match '(?s)^---\r?\n(.*?)\r?\n---(.*)') {
        $frontMatter = $matches[1]
        $postBody = $matches[2].TrimStart("`r`n")

        # 1. Update author if needed
        if ($frontMatter -notmatch '^\s*author:') {
            $updatedFrontMatter = "$authorText`n" + $frontMatter.Trim()
        } 
        else {
            $existingAuthor = ($frontMatter | Select-String -Pattern '^\s*author:\s*(.*)').Matches.Groups[1].Value.Trim()
            $updatedFrontMatter = $existingAuthor -eq $authorValue ? $frontMatter : ($frontMatter -replace '^\s*author:.*', $authorText)
        }

        # 2. Process disclaimer with EXACT formatting
        $exactDisclaimerPattern = [regex]::Escape('> **`We may earn a commission when you click and buy from Amazon.com`.**') + '(\r?\n){2}---'
        
        if (-not ($postBody -match "^$exactDisclaimerPattern")) {
            # Remove any existing disclaimer variations
            $postBody = $postBody -replace '(?s)^> \*\*.*?Amazon\.com.*?\r?\n>?\r?\n-{3,}\r?\n', ''
            # Add the perfectly formatted disclaimer
            $postBody = $disclaimerBlock + "`n" + $postBody.Trim()
        }

        # 3. Save changes
        $newContent = "---`n$updatedFrontMatter`n---`n$postBody"
        $newContent | Set-Content -Encoding UTF8 -Path $file -NoNewline

        Write-Host "✅ UPDATED: $file" -ForegroundColor Green
    } 
    else {
        Write-Host "❌ SKIPPED (No front matter found): $file" -ForegroundColor Red
    }
}

Write-Host "`n✅ PROCESSING COMPLETE!" -ForegroundColor Green