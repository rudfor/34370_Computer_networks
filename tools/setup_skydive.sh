#!/usr/bin/env bash
curl -Lo - https://github.com/skydive-project/skydive-binaries/raw/jenkins-builds/skydive-latest.gz | gzip -d > skydive && chmod +x skydive && sudo mv skydive /usr/local/bin/

SKYDIVE_ETCD_DATA_DIR=/tmp SKYDIVE_ANALYZER_LISTEN=0.0.0.0:8082 sudo -E /usr/local/bin/skydive allinone