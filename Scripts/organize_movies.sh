#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Script: organize_movies.sh
# Purpose: Put each movie file in its own folder named after the file (without extension)

# Usage: ./organize_movies.sh /path/to/movies

DRY_RUN=no
MODE=normal

# Parse flags in order: optional --dry-run, optional --undo
ARGS=("$@")
if [[ "${ARGS[0]:-}" == "--dry-run" ]]; then
  DRY_RUN=yes
  ARGS=("${ARGS[@]:1}")
fi
if [[ "${ARGS[0]:-}" == "--undo" ]]; then
  MODE=undo
  ARGS=("${ARGS[@]:1}")
fi

MOVIE_DIR="${ARGS[0]:-.}"
LOG_FILE="$MOVIE_DIR/.movie_moves.log"

if [[ "$MODE" == "undo" ]]; then
  if [[ ! -f "$LOG_FILE" ]]; then
    echo "No log file found to undo moves."
    exit 1
  fi
  while IFS='|' read -r src dst; do
    if [[ -f "$src" ]]; then
      if [[ "$DRY_RUN" == "yes" ]]; then
        echo "[DRY-RUN] Would move back '$(basename -- "$src")' to '$dst'"
      else
        mv "$src" "$dst"
      fi
    else
      echo "⚠️  Source file '$src' not found, skipping."
    fi
  done < "$LOG_FILE"

  exit 0
fi


# Define extensions to treat as movies (case-insensitive)
EXTS="mkv|mp4|avi|mov|wmv|flv|m4v|mpg|mpeg"

shopt -s nullglob nocaseglob

echo "Scanning for movie files in: $MOVIE_DIR"

for file in "$MOVIE_DIR"/*; do
  if [[ -f "$file" && "$file" =~ \.($EXTS)$ ]]; then
    filename=$(basename -- "$file")
    name_noext="${filename%.*}"
    target_dir="$MOVIE_DIR/$name_noext"

    if [[ "$DRY_RUN" == "yes" ]]; then
      echo "[DRY-RUN] Would create '$target_dir' and move '$filename' into it"
    else
      # Make the folder if it doesn’t exist
      mkdir -p "$target_dir"
      mv "$file" "$target_dir/"
      echo "✅ Moved '$filename' into '$target_dir/'"
    fi
  fi
done

echo "🎉 Done! All movies organized."
