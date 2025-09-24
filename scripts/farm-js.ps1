param(
  [int]$Count = 3,                 # сколько PR за запуск
  [string]$Dir = "src/utils",      # куда класть .js
  [string]$Prefix = "util",        # префикс имени файла
  [string]$BaseBranch = "main",    # базовая ветка
  [switch]$AutoMerge               # сразу мёржить PR
)

$ErrorActionPreference = 'Stop'

function Require($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Need '$name' in PATH. Install or add to PATH."
  }
}

Require git
Require gh

# Проверяем, что в git-репозитории
git rev-parse --is-inside-work-tree *> $null

# Обновим базовую ветку локально (по возможности)
try {
  git fetch origin $BaseBranch *> $null
  git switch $BaseBranch *> $null
  git pull --ff-only *> $null
} catch { }

# Папка для файлов
New-Item -ItemType Directory -Path $Dir -Force *> $null

$summary = @()

for ($i = 1; $i -le $Count; $i++) {
  $rand = Get-Random -Minimum 1000 -Maximum 9999
  $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $fileName = "$Prefix-$rand.js"
  $filePath = Join-Path $Dir $fileName
  $branch   = "feat/$Prefix-$rand"
  $issueTitle = "Feat: add $fileName"
  $issueBody  = "Add small helper $fileName with tiny function.`nDX farming / clarity.`nRandom: $rand"
  $prTitle    = "feat: add $fileName ($rand)"

  # 1) генерим маленький JS
  @"
/**
 * Auto-generated helper ($fileName)
 * Created: $ts
 * Random: $rand
 */
function ${Prefix}${rand}(input) {
  // tiny demo: echo payload with id
  return { id: $rand, input };
}
if (typeof module !== 'undefined') {
  module.exports = { ${Prefix}${rand} };
}
"@ | Set-Content -Encoding UTF8 -Path $filePath

  # 2) создаём issue
  $issueNumber = gh issue create --title "$issueTitle" --body "$issueBody" --label "chore,docs" --json number --jq .number

  # 3) ветка
  git switch -c "$branch"

  # 4) коммит
  git add -- "$filePath"
  git commit -m "feat: add $fileName $rand (#$issueNumber)"

  # 5) push
  git push -u origin "$branch"

  # 6) PR
  $prBody = "What`n- Add small helper $fileName.`n`nWhy`n- DX farming / clarity.`n`nNote`n- Random ID: $rand`n`nLinks`n- Closes #$issueNumber"
  $prUrl = gh pr create --title "$prTitle" --body $prBody --base "$BaseBranch" --head "$branch" --json url --jq .url
  Write-Host "▶ PR created: $prUrl"

  if ($AutoMerge) {
    gh pr merge --squash --delete-branch "$prUrl"
    Write-Host "   merged (squash) & branch deleted."
  }

  $summary += "• $fileName → $prUrl"
  # вернуться на базовую ветку перед следующим циклом
  git switch "$BaseBranch" *> $null
  git pull --ff-only *> $null
}

Write-Host "`n✅ Done. Created $Count JS file(s) and PR(s):"
$summary | ForEach-Object { Write-Host $_ }
