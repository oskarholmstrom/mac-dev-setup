#!/usr/bin/env bash
#
# backup-transcripts.sh — archive Claude Code chat transcripts forever.
#
# Claude prunes ~/.claude/projects after `cleanupPeriodDays`. This rsyncs them
# (and history.jsonl) to a durable archive WITHOUT --delete, so anything Claude
# later prunes is still kept here permanently. Idempotent; safe to run often.
#
# Run on demand with the `claude-backup` alias, and daily via the LaunchAgent.
# Override the destination with CLAUDE_TRANSCRIPT_BACKUP.
#
set -uo pipefail

SRC="$HOME/.claude"
DEST="${CLAUDE_TRANSCRIPT_BACKUP:-$HOME/Documents/Claude-Transcripts}"

mkdir -p "$DEST/projects"
# -a archive; NO --delete so the archive only ever grows.
rsync -a "$SRC/projects/" "$DEST/projects/"
[ -f "$SRC/history.jsonl" ] && rsync -a "$SRC/history.jsonl" "$DEST/history.jsonl"

echo "$(date '+%Y-%m-%d %H:%M:%S')  transcripts archived -> $DEST"
