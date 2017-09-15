# Instant RADOS

This repository contains extremely simplistic, rather clumsy bash scripts for
bringing up a Ceph/RADOS cluster in a docker container.

Running these scripts requires Docker to be installed.

## Commands

```
./start.sh         # Start RADOS.
./stop.sh          # Stop the cluster.
./rgw.sh           # Run radosgw-admin commands inside the running test container.
```
