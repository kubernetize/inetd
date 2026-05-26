# inetd

A minimal Docker image running [OpenBSD inetd](https://manpages.debian.org/inetd.8) on Debian, suitable for use in Kubernetes.

## Usage

### Custom services via `inetd.conf`

Mount your own `/etc/inetd.conf` to define services:

```
docker run --rm -v ./assets/etc/inetd.conf:/etc/inetd.conf ghcr.io/euronetzrt/inetd
```

If no internal services are enabled (see below), inetd is invoked with `/etc/inetd.conf` directly, so a mounted config is used as-is.

### Built-in internal services

inetd has several services implemented internally (no external process is spawned). These can be enabled individually via environment variables. When any of them is set to `1`, the entrypoint script generates a combined config at `/tmp/inetd.conf` — starting from `/etc/inetd.conf` (which may be your mounted config) — and appends the enabled internal service entries. inetd is then invoked with that file.

| Environment variable | Service  | Port | Description                               |
|----------------------|----------|------|-------------------------------------------|
| `INETD_ECHO=1`       | echo     | 7    | Echoes back every byte received           |
| `INETD_DISCARD=1`    | discard  | 9    | Silently discards all received data       |
| `INETD_DAYTIME=1`    | daytime  | 13   | Returns the current date and time as text |
| `INETD_CHARGEN=1`    | chargen  | 19   | Continuously generates character data     |
| `INETD_TIME=1`       | time     | 37   | Returns the current time as a 32-bit int  |

Each enabled service is registered for both TCP (stream) and UDP (dgram).

Boolean values can be: `0`, `1`, `false`, `true`, `no`, or `yes` (case-sensitive).

Example enabling echo and daytime:

```
docker run --rm -e INETD_ECHO=1 -e INETD_DAYTIME=1 kubernetize-inetd
```

## Binding to privileged ports

The internal services listed above all bind to ports below 1024, which are privileged ports on Linux. The container process runs as UID 65534 (`nobody`). To allow binding to these ports, you can use the sysctl `net.ipv4.ip_unprivileged_port_start` to lower the threshold of unprivileged ports.

### Docker

```
docker run --rm --sysctl net.ipv4.ip_unprivileged_port_start=0 -e INETD_ECHO=1 kubernetize-inetd
```

### Kubernetes

Add a sysctl in the pod's `securityContext`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inetd
spec:
  selector:
    matchLabels:
      app: inetd
  template:
    metadata:
      labels:
        app: inetd
    spec:
      securityContext:
        sysctls:
          - name: net.ipv4.ip_unprivileged_port_start
            value: "0"
      containers:
        - name: inetd
          image: kubernetize-inetd
          env:
            - name: INETD_ECHO
              value: "1"
            - name: INETD_DAYTIME
              value: "1"
          ports:
            - containerPort: 7
              name: echo
            - containerPort: 13
              name: daytime
```

> **Note:** Some Kubernetes cluster policies may restrict the use of unsafe sysctls. Consult your cluster administrator if the pod fails to start due to security policy violations.
