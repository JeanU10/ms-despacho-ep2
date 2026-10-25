# Despacho — Despliegue y operación

## Requisitos

- Java 21, Maven 3.9 (build local)
- Docker + Docker Compose (despliegue)

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
