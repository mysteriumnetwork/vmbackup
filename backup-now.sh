#!/bin/sh

SNAPSHOT_NAME=$(curl $SNAPSHOT_CREATE_URL | jq -r '.snapshot')
sleep 5

REPLICA_COUNT=$(hostname | grep -Eo '[0-9]+$')
eval "HEARTBEAT_URL=\$HEARTBEAT_CALLBACK_${REPLICA_COUNT}"
eval "DST_URL=\$CUSTOM_S3_BASEPATH/$HOSTNAME/$SNAPSHOT_NAME"

echo $SNAPSHOT_CREATE_URL
echo $SNAPSHOT_NAME
echo $CUSTOM_S3_ENDPOINT
echo $CUSTOM_S3_BASEPATH
echo $HOSTNAME
echo $HEARTBEAT_URL
echo $DST_URL

sleeptime=10m # Sleep for 10 minutes after a failed try.
maxtries=5    # 5 * 10 minutes = about 50 minutes total of waiting,
              # not counting running and failing.

while ! /vmbackup-prod -storageDataPath=/storage -credsFilePath=/creds -snapshotName=$SNAPSHOT_NAME -customS3Endpoint=$CUSTOM_S3_ENDPOINT -dst=$DST_URL; do
  maxtries=$(( maxtries - 1 ))
  if [ "$maxtries" -eq 0 ]; then
    echo "Victoria metrics backup didn't succeed! Exiting." >&2
    exit 1
  fi

  sleep "$sleeptime" || break
done

STATUS=$(curl http://localhost:8482/snapshot/delete?snapshot=$SNAPSHOT_NAME | jq -r '.status')

if [ $STATUS == "ok" ]; then
  if [ -n "$HEARTBEAT_URL" ]; then
    curl $HEARTBEAT_URL
  fi
fi