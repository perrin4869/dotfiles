#!/bin/sh

MPD_MUSIC_PATH="/media/storage/Multimedia/Music"
TMP_COVER_PATH="/tmp/mpd-track-cover"

exiftool -b -Picture "$MPD_MUSIC_PATH/$(mpc --format "%file%" current)" > "$TMP_COVER_PATH"
