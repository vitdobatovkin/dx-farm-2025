#!/usr/bin/env bash
set -euo pipefail

# ===== ПАРАМЕТРЫ =====
COUNT="${1:-3}"                     # сколько PR сделать за запуск
DIR="${DIR:-src/utils}"             # куда кладём js-файлы
PREFIX="${PREFIX:-util}"            # префикс имени файла
BASE_BRANCH="${BASE_BRANCH:-main}"  # базовая ветка
AUTO_MERGE="${AUTO_MERGE:-true}"    # true|false — сразу мёржить PR
LABELS="${LABELS:-docs,chore}"      # лейблы для issue
# =====================

need() { command -v "$1" >/dev/null 2>&1 || { echo "Need '$1' in PATH"; exit 1; }; }
need git
need gh

# Проверим репозиторий
git rev-parse --is-inside-work-tree >/dev/null

# Хелперы для stash, если грязное дерево мешает switch
has_changes() { test -n "$(git status --porcelain)"; }
stash_used=false
ensure_clean() {
  if has_changes; then
    git stash push -u -m "farm-autostash-$(date +%s)" >/dev/null
    stash_used=true
  fi
}
restore_stash() {
  if $stash_used; then
    git stash pop || echo "⚠️  Stash pop had conflicts — resolve manually"
    stash_used=false
  fi
}

# Автокоммит самого скрипта, если он изменён
if git status --porcelain | grep -qE '(^|\s)farm-prs\.sh$'; then
  git add farm-prs.sh
  git commit -m "chore: add/update farming script" >/dev/null || true
fi

# Обновим base ветку
ensure_clean
git fetch origin "$BASE_BRANCH" >/dev/null 2>&1 || true
git switch "$BASE_BRANCH" >/dev/null 2>&1 || git checkout "$BASE_BRANCH" >/dev/null 2>&1
git pull --ff-only || true
restore_stash

mkdir -p "$DIR"

summary=()

for i in $(seq 1 "$COUNT"); do
  RAND=$((RANDOM%9000+1000))
  TS="$(date +'%Y-%m-%d %H:%M:%S')"
  FILE="$PREFIX-$RAND.js"
  PATH_JS="$DIR/$FILE"
  BR="feat/$PREFIX-$RAND"
  ISSUE_TITLE="Feat: add $FILE"
  ISSUE_BODY="Add small helper $FILE with tiny function.
DX farming / clarity.
Random: $RAND"
  PR_TITLE="feat: add $FILE ($RAND)"

  # 1) генерим маленький JS
  cat > "$PATH_JS" <<JS
/**
 * Auto-generated helper ($FILE)
 * Created: $TS
 * Random: $RAND
 */
function ${PREFIX}${RAND}(input){
  return { id: $RAND, input };
}
if (typeof module !== 'undefined') {
  module.exports = { ${PREFIX}${RAND} };
}
JS

  # 2) создаём issue (для старого gh — парсим номер из последней строки)
  ISSUE_OUT="$(gh issue create -t "$ISSUE_TITLE" -b "$ISSUE_BODY" -l "$LABELS" 2>/dev/null || true)"
  ISSUE_URL="$(printf '%s\n' "$ISSUE_OUT" | tail -n1 | tr -d '\r')"
  if printf '%s' "$ISSUE_URL" | grep -Eq '/issues/[0-9]+$'; then
    ISSUE_NUMBER="${ISSUE_URL##*/}"
  else
    echo "⚠️  Не удалось получить номер issue. gh output:"
    echo "$ISSUE_OUT"
    ISSUE_NUMBER=""
  fi

  # 3) создаём ветку
  ensure_clean
  git switch -c "$BR"
  restore_stash

  # 4) коммит
  git add -- "$PATH_JS"
  if [ -n "$ISSUE_NUMBER" ]; then
    git commit -m "feat: add $FILE $RAND (#$ISSUE_NUMBER)"
  else
    git commit -m "feat: add $FILE $RAND"
  fi

  # 5) push
  git push -u origin "$BR"

  # 6) PR (парсим URL из вывода gh)
  PR_BODY=$'What\n- Add small helper '"$FILE"$'\n\nWhy\n- DX farming / clarity.\n\nNote\n- Random ID: '"$RAND"
  if [ -n "$ISSUE_NUMBER" ]; then
    PR_BODY+=$'\n\nLinks\n- Closes #'"$ISSUE_NUMBER"
  fi

  PR_OUT="$(gh pr create -t "$PR_TITLE" -b "$PR_BODY" -B "$BASE_BRANCH" -H "$BR" 2>/dev/null || true)"
  PR_URL="$(printf '%s\n' "$PR_OUT" | tr -d '\r' | grep -Eo 'https?://[^ ]+/pull/[0-9]+' | tail -n1)"

  if [ -z "$PR_URL" ]; then
    echo "⚠️  PR для ветки '$BR' не создан. gh output:"
    echo "$PR_OUT"
  else
    echo "▶ PR created: $PR_URL"
    if [ "$AUTO_MERGE" = "true" ]; then
      if gh pr merge --squash --delete-branch "$PR_URL"; then
        echo "   merged (squash) & branch deleted."
      else
        echo "⚠️  Не удалось смержить $PR_URL — проверь checks/права."
      fi
    fi
  fi

  summary+=("• $FILE → ${PR_URL:-<no-pr>}")

  # 7) назад на base
  ensure_clean
  git switch "$BASE_BRANCH" >/dev/null 2>&1 || git checkout "$BASE_BRANCH" >/devnull 2>&1
  git pull --ff-only >/dev/null 2>&1 || true
  restore_stash
done

echo
echo "✅ Done. Created $COUNT JS file(s) and PR(s):"
for line in "${summary[@]}"; do echo "$line"; done
