# ForestGuard — Production Deployment Architecture

This document describes how ForestGuard transitions from local MVP to high-availability multi-zone cloud infrastructure.

## ☁️ Architecture Topology

```
                  ┌──────────────────────┐
                  │ Cloudflare / Route53 │
                  └──────────┬───────────┘
                             │
                  ┌──────────▼───────────┐
                  │ Traefik / Nginx SSL  │
                  └──────────┬───────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
    ┌───────────────────┐         ┌───────────────────┐
    │ FastAPI Backend 1 │         │ FastAPI Backend 2 │
    └─────────┬─────────┘         └─────────┬─────────┘
              │                             │
              ├──────────────┬──────────────┤
              ▼              ▼              ▼
       ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
       │ Redis Hub   │ │ MongoDB     │ │ S3 Bucket   │
       │ (Pub/Sub WS)│ │ Replica Set │ │ (Snapshots) │
       └─────────────┘ └─────────────┘ └─────────────┘
```

1. **Horizontal Backend Scaling:** Deploy FastAPI as containerized pods on AWS ECS or Kubernetes.
2. **WebSocket Clustering:** Use Redis Pub/Sub backplane for distributing WebSocket events across multiple backend workers.
3. **MongoDB Replica Set:** 3-node replica set with automated failover and managed daily backups.
4. **Field Camera Edge Deployment:** AI Camera instances run on Nvidia Jetson Nano edge nodes or Raspberry Pi 5 with Coral TPU accelerators deployed at forest boundary towers.
