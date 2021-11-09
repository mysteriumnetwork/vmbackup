# vmbackup
Victoria Metrics backup to remote S3 storage controller by crond.  
This image is based on Victoria Metrics provided [here]|(https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/app/vmbackup/README.md).  
This image need to be run on the same pod where vmstorage runs if Victoria Metrics cluster version is used.

## Workflow

1. Creates a local snapshot under <storage path>/snapshots directory by calling url
2. Indicates the Heartbeat url to call on success
3. Makes an upload of files to remote S3
4. Sends a heartbeat upon successful completion of work cycle

## Installation

#### Binaries

Pre-built binaries are available [here](https://github.com/mysteriumnetwork/vmbackup/releases/latest).

#### Build from source

Alternatively, you may run it locally by building an image under the root directory

```
docker build . -t vmbackup
```

## Usage

Intended to be used as an extra container on the vmstorage pods.
Please, create S3 credentials (secret 'any-s3-secret') in the correct format like below and mount it under the '/creds' path.

```csv
[default]
aws_access_key_id=<S3 key id>
aws_secret_access_key=<S3 access key>
region=<S3 Region>
```

### Example how it can be used for Victoria Metrics cluster Helm chart version

It needs to be under *vmstorage* pod section
```yaml

  # Extra Volumes for the pod
  extraVolumes:
    - name: any-s3-secret
      secret:
        secretName: any-s3-secret
        
  extraContainers:
    - name: vmbackup
      image: mysteriumnetwork/vmbackup:0.0.1
#      command: ["/bin/sh", "-ec", "sleep 1000"]
      imagePullPolicy: "Always"
      env:
        - name: HEARTBEAT_CALLBACK_0
          valueFrom:
            secretKeyRef:
              name: backup-secret
              key: HEARTBEAT_CALLBACK_0
        - name: HEARTBEAT_CALLBACK_1
          valueFrom:
            secretKeyRef:
              name: backup-secret
              key: HEARTBEAT_CALLBACK_1
        - name: HEARTBEAT_CALLBACK_2
          valueFrom:
            secretKeyRef:
              name: backup-secret
              key: HEARTBEAT_CALLBACK_2
        - name: SNAPSHOT_CREATE_URL
          valueFrom:
            secretKeyRef:
              name: backup-secret
              key: SNAPSHOT_CREATE_URL
        - name: CUSTOM_S3_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: backup-secret
              key: CUSTOM_S3_ENDPOINT
        - name: CUSTOM_S3_BASEPATH
          valueFrom:
            secretKeyRef:
              name: backup-secret
              key: CUSTOM_S3_BASEPATH
      volumeMounts:
      - name: vmstorage-volume
        mountPath: /storage
      - name: any-s3-secret
        mountPath: /creds
        subPath: creds

```

## Recognized environment variables

* `SNAPSHOT_CREATE_URL` - gets called on first step to prepare a snapshot (on Victoria Metrics cluster setup usually it's 'http://localhost:8482/snapshot/create')
* `CUSTOM_S3_ENDPOINT` - Remote S3 endpoint (should be prefixed with 'https://' or 'http://')
* `CUSTOM_S3_BASEPATH` - Remote S3 basepath, that conforms the format 's3://<bucket name>/<base backup path dir>'. Under that directory per replica directory would be created automatically.
* `HEARTBEAT_CALLBACK_0` - Url to call on successful backup action for first replica
* ...
* `HEARTBEAT_CALLBACK_<N replica>` - Url to call on successful backup action for <N> replica

