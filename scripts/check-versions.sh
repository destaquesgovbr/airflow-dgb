#!/bin/bash
# Verifica a versão do template airflow-dgb em cada repo DGB com DAGs.
# Requer: gh CLI autenticado.

set -euo pipefail

repos="scraper activitypub-server data-science embeddings data-publishing"

printf "%-25s %s\n" "REPO" "VERSÃO"
printf "%-25s %s\n" "----" "------"

for repo in $repos; do
  version=$(gh api "repos/destaquesgovbr/$repo/contents/.copier-answers.yml" \
    --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | grep '_commit:' | awk '{print $2}') || true
  printf "%-25s %s\n" "$repo" "${version:-sem template}"
done
