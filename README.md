¡Listo! Te dejo un **README** pensado para que cualquiera —aunque nunca haya usado Kubernetes— pueda poner a funcionar **todo el proyecto Cafe Boreal**: base de datos, APIs, Nginx con TLS, y observabilidad (Prometheus + cAdvisor + Grafana), además de cómo probar y depurar.

---

# ☕ Cafe Boreal — Guía de Uso (README)

Microservicios en **Kubernetes (minikube)** con **PostgreSQL**, **Nginx con TLS**, y **observabilidad** (Prometheus, cAdvisor, Grafana).
Incluye comandos para levantar, probar, recolectar evidencias y resolver problemas comunes.

---

## 0) Requisitos previos

* Sistema Linux con:

  * **Docker** (activo)
  * **kubectl**
  * **minikube**
  * **jq** (para procesar JSON en terminal)
  * **openssl** (para crear certificado TLS)
* Acceso al repositorio con esta estructura:

  ```
  cafe-boreal/
  ├── deploy/
  │   ├── kubernetes/         # YAMLs de K8s
  │   ├── nginx/              # TLS y conf (si usas Docker local de Nginx)
  │   └── scripts/            # Scripts auxiliares (opcional)
  ├── source/
  │   ├── api-catalog/
  │   ├── api-customers/
  │   └── api-orders/
  └── evidence/               # Salida de evidencias (se creará)
  ```

> Si no tienes `evidence/`, el README la crea cuando haga falta.

---

## 1) Arrancar minikube y preparar Docker

```bash
minikube start --cpus=4 --memory=6g
eval $(minikube docker-env)   # Muy importante para construir imágenes dentro del Docker que usa el cluster
```

---

## 2) Certificado TLS (autofirmado)

```bash
mkdir -p deploy/nginx/tls
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout deploy/nginx/tls/tls.key \
  -out deploy/nginx/tls/tls.crt \
  -subj "/CN=localhost"

# Crear secreto TLS en K8s:
kubectl create secret tls nginx-tls \
  --cert=deploy/nginx/tls/tls.crt \
  --key=deploy/nginx/tls/tls.key \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## 3) Base de datos: PostgreSQL + Secret

Aplica tu manifiesto (ej. `deploy/kubernetes/postgres.yaml`), o usa uno equivalente con:

* Deployment `postgres-deployment`
* Service `postgres-service`
* Secret `postgres-secret` con `POSTGRES_PASSWORD`

```bash
kubectl apply -f deploy/kubernetes/postgres.yaml
kubectl get pods
```

Cuando `postgres-deployment` esté **READY 1/1**, crea tablas/seed si tu manifiesto no lo hace automáticamente.
(En tu caso ya lo has hecho; si necesitas seed manual, conéctate con `psql` y ejecuta SQL).

---

## 4) Construir las imágenes de las APIs

> Asegúrate que estás bajo `eval $(minikube docker-env)`

```bash
docker build -t catalog-api:v1   source/api-catalog
docker build -t customers-api:v1 source/api-customers
docker build -t orders-api:v1    source/api-orders
```

---

## 5) Desplegar los microservicios

Aplica los YAML de cada servicio (Deployment + Service). Si no existen ya listos, usa los tuyos existentes:

```bash
kubectl apply -f deploy/kubernetes/catalog.yaml
kubectl apply -f deploy/kubernetes/customers.yaml
kubectl apply -f deploy/kubernetes/orders.yaml
```

Verifica:

```bash
kubectl get pods -o wide
kubectl get svc
```

Deberías ver `catalog-api-service`, `customers-api-service`, `orders-api-service` como **ClusterIP:80 → targetPort:3000**.

---

## 6) Nginx como entrada HTTPS (NodePort)

Aplica Deployment + Service con NodePort (ej. `80:30080`, `443:30443`) y ConfigMap con `nginx.conf` que enruta:

* `/api/catalog` → `catalog-api-service:80`
* `/api/customers` → `customers-api-service:80`
* `/api/orders` → `orders-api-service:80`
* `ssl_certificate` y `ssl_certificate_key` apuntando a `/etc/nginx/tls/…` (Secret `nginx-tls` montado)

Ejemplo de despliegue:

```bash
kubectl apply -f deploy/kubernetes/nginx-config.yaml
kubectl apply -f deploy/kubernetes/nginx-deployment.yaml
kubectl apply -f deploy/kubernetes/nginx-service.yaml
kubectl rollout restart deployment nginx-deployment
```

Obtén la IP:

```bash
MINI=$(minikube ip)
kubectl get svc nginx-service
# Debes ver 80:30080/TCP y 443:30443/TCP
```

Pruebas de salud:

```bash
curl -k https://$MINI:30443/api/catalog/healthz
curl -k https://$MINI:30443/api/customers/healthz
curl -k https://$MINI:30443/api/orders/healthz
```

---

## 7) Cifrado en Customers (pgcrypto)

* Secret `encryption-secret` con `ENCRYPTION_KEY` (ya lo tienes).
* Deployment de `api-customers` con:

  ```yaml
  env:
  - name: ENCRYPTION_KEY
    valueFrom:
      secretKeyRef:
        name: encryption-secret
        key: ENCRYPTION_KEY
  ```
* En DB, habilitar extensión:

  ```sql
  CREATE EXTENSION IF NOT EXISTS pgcrypto;
  ```
* Probar inserción por API:

  ```bash
  curl -ks -X POST https://$MINI:30443/api/customers \
    -H "Content-Type: application/json" \
    -d '{"full_name":"Alice Example","email":"alice@example.com","identity_number":"ID888"}'
  ```
* Ver en DB que `identity_number` está cifrado (`\x...` hex):

  ```bash
  kubectl exec -it deploy/postgres-deployment -- \
    psql -U admin -d cafeboreal -c "SELECT id, full_name, email, identity_number FROM customers LIMIT 5;"
  ```

---

## 8) Observabilidad

### 8.1 cAdvisor + Prometheus + Exporter de Nginx

Usa el script (si ya lo tienes) **setup\_observabilidad.sh** que:

* Crea/actualiza `nginx.conf` con `stub_status` (solo para métricas).
* Despliega `nginx-prometheus-exporter`.
* Crea/actualiza `prometheus-config` para scrapear:

  * `cadvisor`
  * `catalog` `/metrics`
  * `customers` `/metrics`
  * `orders` `/metrics`
  * `nginx-exporter`
* Despliega Prometheus y su Service.

> Si no tienes el script, aplica los YAML equivalentes según te compartí en la sesión.

Verifica targets:

```bash
kubectl port-forward svc/prometheus-service 9090:9090
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

### 8.2 Instrumentar `/metrics` en Node.js

En **cada** `server.js` (catalog/customers/orders):

```js
// npm i prom-client
const client = require('prom-client');
client.collectDefaultMetrics();

const hist = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'request latency',
  labelNames: ['method','route','code'],
  buckets: [0.01,0.05,0.1,0.25,0.5,1,2,5]
});

app.use((req, res, next) => {
  const end = hist.startTimer({ method: req.method, route: req.path });
  res.on('finish', () => end({ code: res.statusCode }));
  next();
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});
```

Reconstruir y reiniciar:

```bash
eval $(minikube docker-env)
docker build -t catalog-api:v1   ./source/api-catalog   && kubectl rollout restart deploy/catalog-api-deployment
docker build -t customers-api:v1 ./source/api-customers && kubectl rollout restart deploy/customers-api-deployment
docker build -t orders-api:v1    ./source/api-orders    && kubectl rollout restart deploy/orders-api-deployment
```

### 8.3 Grafana

Despliega con tu script **setup\_grafana.sh** o YAML equivalente que:

* Crea datasource apuntando a `http://prometheus-service.default.svc.cluster.local:9090`
* Carga un dashboard con:

  * CPU por pod (cAdvisor)
  * p95 de latencia HTTP (si ya expones histogramas)

Acceso:

```bash
kubectl port-forward svc/grafana-service 3000:3000
# http://localhost:3000
# Usuario: admin   Contraseña: admin123 (si no la cambiaste)
```

Si el dashboard sale vacío:

* Verifica que `up` tenga `cadvisor`, `catalog`, `customers`, `orders`.
* Genera tráfico:

  ```bash
  for i in $(seq 1 200); do curl -sk "https://$MINI:30443/api/catalog/products" >/dev/null; done
  ```

---

## 9) Pruebas funcionales rápidas

```bash
MINI=$(minikube ip)

# Catálogo
curl -ks https://$MINI:30443/api/catalog/products

# Customers (crear)
curl -ks -X POST https://$MINI:30443/api/customers \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Juan Perez","email":"juan@example.com","identity_number":"ID123"}'

# Orders (crear)
curl -ks -X POST https://$MINI:30443/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customer_id":1,"items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":1}]}'

# Orders (listar)
curl -ks https://$MINI:30443/api/orders
```

---

## 10) Evidencias (se guardan en `evidence/`)

```bash
mkdir -p evidence

kubectl get pods -o wide > evidence/pods.txt
kubectl get svc -o wide  > evidence/services.txt

# Healthz
curl -ki https://$MINI:30443/api/catalog/healthz   > evidence/catalog_healthz.txt
curl -ki https://$MINI:30443/api/customers/healthz > evidence/customers_healthz.txt
curl -ki https://$MINI:30443/api/orders/healthz    > evidence/orders_healthz.txt

# Prometheus targets
kubectl port-forward svc/prometheus-service 9090:9090 &
sleep 2
curl -s http://localhost:9090/api/v1/targets | jq . > evidence/prom_targets.json
```

---

## 11) Backup y Restore (PostgreSQL)

**Backup:**

```bash
kubectl exec -it deploy/postgres-deployment -- \
  pg_dump -U admin -d cafeboreal > evidence/backup.sql
```

**Restore (simulación de desastre):**

```bash
kubectl exec -it deploy/postgres-deployment -- \
  psql -U admin -d cafeboreal -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

kubectl exec -i deploy/postgres-deployment -- \
  psql -U admin -d cafeboreal < evidence/backup.sql
```

---

## 12) Solución de problemas (FAQ)

* **`ContainerCreating` que no termina**

  * Si montas volúmenes desde host (`hostPath`) en minikube, suele fallar por rutas/permiso. Evítalo o usa ConfigMap/imagen Docker.
* **`ImagePullBackOff`**

  * Asegúrate de **construir** imágenes con `eval $(minikube docker-env)` activo.
* **`404` en `/api/...` vía Nginx**

  * Revisa `nginx.conf` y que el Service de destino exista y apunte a `targetPort: 3000`.
* **`301 Moved Permanently` en POST**

  * No sigas redirecciones sin `-L`. Usa `curl -kL https://…` si fuese necesario.
* **No hay métricas en Grafana**

  * Verifica `up` en Prometheus, que tus APIs sirvan `/metrics`, que Prometheus tenga los jobs de `catalog/customers/orders`, y genera tráfico reciente.
* **TLS**

  * Certificado es self-signed: usa `curl -k` (ignora verificación) para pruebas.

---

## 13) Limpieza

```bash
kubectl delete -f deploy/kubernetes/nginx-service.yaml
kubectl delete -f deploy/kubernetes/nginx-deployment.yaml
kubectl delete -f deploy/kubernetes/nginx-config.yaml

kubectl delete -f deploy/kubernetes/orders.yaml
kubectl delete -f deploy/kubernetes/customers.yaml
kubectl delete -f deploy/kubernetes/catalog.yaml

kubectl delete -f deploy/kubernetes/postgres.yaml

# Observabilidad (si aplicaste con scripts/YAML)
kubectl delete deploy/prometheus svc/prometheus-service cm/prometheus-config
kubectl delete deploy/cadvisor svc/cadvisor
kubectl delete deploy/nginx-exporter svc/nginx-exporter-service
kubectl delete deploy/grafana svc/grafana-service cm/grafana-datasource cm/grafana-provisioning cm/grafana-dashboard-cafe

kubectl delete secret nginx-tls encryption-secret postgres-secret
```

---

## 14) Resumen

1. `minikube start` + `eval $(minikube docker-env)`
2. TLS + Secret
3. Postgres + tablas
4. Build de imágenes (3 APIs)
5. Deploy de APIs + Nginx (HTTPS NodePort 30443)
6. Probar `/healthz` y endpoints
7. Observabilidad (cAdvisor + Prometheus + Grafana)
8. Instrumentar `/metrics` en Node y generar tráfico
9. Evidencias y backup

Con esto, **cualquier persona** puede levantar, probar y observar el sistema sin conocimiento previo. Si quieres, lo empaqueto como PDF “Manual de implementación y operación” para entregar junto con las evidencias.
