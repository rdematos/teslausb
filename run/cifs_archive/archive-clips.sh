#!/bin/bash -eu

log "Moving clips to archive..."

NUM_FILES_MOVED=0

function copy_file () {

 if cp -f -t "$ARCHIVE_MOUNT" -- "$file_name" >> "$LOG_FILE" 2>&1
      then
        log "Copied $file_name."
        NUM_FILES_MOVED=$((NUM_FILES_MOVED + 1))
      else
        log "Failed to move $file_name."
      fi

}

for file_name in "$CAM_SNAP_MOUNT"/TeslaCam/saved*; do
  [ -e "$file_name" ] || continue
  log "Copying $file_name ..."
  # Get base file name without path 
  TARGET_FILE_NAME=$(echo $file_name | cut -d'/' -f5)

  # If the file exists in the archive already...
  if [ -e "${ARCHIVE_MOUNT}/${TARGET_FILE_NAME}" ]
  then 
    # Get source and target file sizes (faster than hash or rsync)
    SOURCE_FILE_SIZE=$(stat --printf="%s" "${file_name}")
    TARGET_FILE_SIZE=$(stat --printf="%s" "${ARCHIVE_MOUNT}/${TARGET_FILE_NAME}")
    
    # If they are not the same size then copy
    if [ $SOURCE_FILE_SIZE -ne $TARGET_FILE_SIZE ]
    then
     copy_file
    else
      log "File $file_name alrea"
    fi
  else
    # The file didn't exist in the target so just copy away
    copy_file
  fi

done
log "Moved $NUM_FILES_MOVED file(s)."

if [ $NUM_FILES_MOVED -gt 0 ]
then
/root/bin/send-pushover "$NUM_FILES_MOVED"
fi

log "Finished moving clips to archive."
