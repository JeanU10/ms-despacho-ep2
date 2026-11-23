# Despacho — Despliegue y operación

## Requisitos

- Java 21, Maven 3.9 (build local)
- Docker + Docker Compose (despliegue)
- kubectl con un clúster Kubernetes y una clase de almacenamiento predeterminada (EP3)

## Ejecución local

```bash
mvn spring-boot:run
```

URLs en `http://localhost:8080`:

| Recurso | URL |
|---------|-----|
| Página de presentación | `/` |
| Swagger UI | `/swagger-ui/index.html` |
| OpenAPI yaml | `/v3/api-docs.yaml` |
| ReDoc | `/redoc.html` |
| H2 Console | `/h2-console` (solo con el perfil local) |
| API base | `/api/despachos` |

## Docker

```bash
docker build -t duoc/jv0101-caso10-despacho:1.0.0 .
docker run -p 8080:8080 duoc/jv0101-caso10-despacho:1.0.0
```

La imagen usa dos etapas de construcción, ejecuta la aplicación como usuario no root y declara un healthcheck sobre `/api/despachos`.

## Docker Compose

```bash
Copy-Item .env.example .env
docker compose up --build --wait
docker compose ps
```

El puerto publicado por defecto es `8080`; las solicitudes pasan por Nginx hacia las dos réplicas del servicio. Si otro programa ya usa ese puerto, cambia `HOST_PORT` en `.env` (por ejemplo, a `18080`) o define `$env:HOST_PORT="9090"` antes de iniciar Compose.

### Observabilidad local

El perfil `observability` añade Prometheus, Grafana, Pushgateway, Loki y Alloy:

```powershell
Copy-Item .env.example .env
docker compose --profile observability up --build --wait --scale despacho-svc=2
```

| Herramienta | Dirección local | Uso |
|-------------|-----------------|-----|
| Grafana | `http://localhost:3000` | Dashboard `Despacho · Observabilidad EP3`; admin y contraseña definida en `.env` |
| Prometheus | `http://localhost:9090` | Métricas de Actuator y Pushgateway |
| Loki | `http://localhost:3100` | Logs recibidos por Alloy |
| Pushgateway | `http://localhost:9091` | Métricas de duración y cobertura del CI |

El endpoint `/actuator/prometheus` es interno. Nginx responde 404 para `/actuator`; Prometheus llega al endpoint mediante la red de Compose. Alloy necesita acceso al socket Docker para leer los logs, limitados al proyecto Compose de esta aplicación; por eso no se debe usar esta configuración local como agente de producción.

### Kubernetes

Los manifiestos Kustomize están en `deploy/k8s/`. Crea los secretos fuera del repositorio; no guardes contraseñas ni kubeconfig en archivos versionados:

```powershell
kubectl create namespace despacho
kubectl create secret generic db-credentials -n despacho --from-literal=POSTGRES_PASSWORD='<clave-local-fuerte>'
kubectl create secret generic grafana-admin -n despacho --from-literal=admin_password='<clave-local-fuerte>'
docker build -t ms-despacho:local .
kubectl apply -k deploy/k8s
kubectl get pods,services,pvc -n despacho
```

En Docker Desktop/Kubernetes, la imagen `ms-despacho:local` debe estar disponible para el nodo. Para EKS, el workflow construye una imagen etiquetada por SHA y la publica en ECR. El runner autohospedado efímero del equipo usa el perfil AWS local para autenticarse ante AWS y el clúster; los nodos descargan ECR con su propio rol. Solo se guardan `KUBE_DB_PASSWORD` y `GRAFANA_ADMIN_PASSWORD` como secretos de Actions. El pipeline crea los secretos en el namespace y aplica el despliegue; las claves AWS no se versionan ni se guardan en GitHub.

Las cuatro PVC usan `local-path`, aprovisionado en el nodo EKS y respaldado por el volumen EBS raíz. Este modo conserva datos ante reinicios de pods durante la evaluación, pero no replica ni mueve los datos si se reemplaza el nodo. El clúster académico usa un único nodo para limitar el costo.

Para abrir el dashboard sin exponer Grafana públicamente:

```powershell
kubectl port-forward -n despacho service/grafana 3000:3000
```

En producción, usa un gestor de secretos, PVC con respaldo, TLS/ingress con autenticación y una política de retención acorde al entorno. Los puertos de Prometheus, Loki y Pushgateway permanecen como `ClusterIP`.

## Base de datos y escalamiento

Al iniciar Spring Boot directamente, se usa H2 en memoria (se pierde al detener el proceso). La consola web está desactivada por defecto. Para habilitarla solo al ejecutar localmente:

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

Compose define PostgreSQL con un volumen persistente, dos réplicas de la API y un proxy Nginx. La contraseña de `.env.example` es solo para uso local; reemplázala antes de usar el entorno en otro contexto. El servicio de base de datos no publica puertos al host. Las imágenes de aplicación se ejecutan como usuario no root y los servicios aplican healthchecks, límites de recursos, reinicio automático y restricciones de privilegios.

## Variables de entorno

| Variable | Defecto | Descripción |
|----------|---------|-------------|
| `HOST_PORT` | `8080` | Puerto publicado en el host; el servidor escucha en 8080 dentro del contenedor |
| `PORT` | `8080` | Puerto del servidor al ejecutarlo localmente; el contenedor mantiene 8080 |
| `POSTGRES_PASSWORD` | `despacho_local` en desarrollo local | Contraseña de PostgreSQL; usa un secreto en CI y producción |
| `IMAGE_TAG` | `local` | Etiqueta de la imagen de aplicación |
| `GRAFANA_ADMIN_PASSWORD` | `change_me_local_only` | Contraseña temporal para el perfil local de observabilidad |
