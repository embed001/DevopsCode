# https://github.com/thanos-io/kube-thanos
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/component: query-layer
    app.kubernetes.io/instance: thanos-query
    app.kubernetes.io/name: thanos-query
    app.kubernetes.io/version: v0.31.0
  name: thanos-query
  namespace: thanos
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/component: query-layer
      app.kubernetes.io/instance: thanos-query
      app.kubernetes.io/name: thanos-query
  template:
    metadata:
      labels:
        app.kubernetes.io/component: query-layer
        app.kubernetes.io/instance: thanos-query
        app.kubernetes.io/name: thanos-query
        app.kubernetes.io/version: v0.31.0
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                  - thanos-query
              namespaces:
              - thanos
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - args:
        - query
        - --grpc-address=0.0.0.0:10901
        - --http-address=0.0.0.0:9090
        - --log.level=info
        - --log.format=logfmt
        - --query.replica-label=prometheus_replica
        - --query.replica-label=rule_replica
        - --endpoint=dnssrv+_grpc._tcp.thanos-store:10901
        - --endpoint=dnssrv+_grpc._tcp.thanos-receive-ingestor-default:10901
        - --endpoint=dnssrv+_grpc._tcp.kube-prometheus-stack-thanos-discovery.monitoring:10901
        - --endpoint=${public_ip}:30901
        - --query.auto-downsampling
        env:
        - name: HOST_IP_ADDRESS
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        image: quay.io/thanos/thanos:v0.31.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 4
          httpGet:
            path: /-/healthy
            port: 9090
            scheme: HTTP
          periodSeconds: 30
        name: thanos-query
        ports:
        - containerPort: 10901
          name: grpc
        - containerPort: 9090
          name: http
        readinessProbe:
          failureThreshold: 20
          httpGet:
            path: /-/ready
            port: 9090
            scheme: HTTP
          periodSeconds: 5
        resources: {}
        terminationMessagePolicy: FallbackToLogsOnError
      nodeSelector:
        kubernetes.io/os: linux
      securityContext:
        fsGroup: 65534
        runAsUser: 65534
      serviceAccountName: thanos-query
      terminationGracePeriodSeconds: 120
