# Despacho — Resumen del microservicio

## Propósito

administra los datos y la lógica del dominio de Despacho del caso caso10 (CargoClick).

## Contexto

- **Caso**: caso10 — CargoClick (Logística / courier)
- **Microservicio**: despacho
- **Base path**: `/api/despachos`

## Responsabilidad única (SRP)

El servicio atiende un único dominio de negocio y tiene una sola razón de cambio. Expone su API REST de forma independiente y utiliza H2 al ejecutarse de manera local; el entorno Compose conecta dos réplicas a una base PostgreSQL propia y persistente.

## Stack tecnológico

| Componente | Tecnología |
|---|---|
| Framework | Spring Boot 3.3 |
| Lenguaje | Java 21 |
| Build | Maven |
| Persistencia | Spring Data JPA + H2 local / PostgreSQL en Compose |
| Validación | Bean Validation (`jakarta.validation`) |
| API/Docs | springdoc-openapi — Swagger UI + OpenAPI yaml + ReDoc |
| Calidad | JaCoCo (cobertura LINE 100%) + Cucumber (BDD REST) |
| Contenedores | Docker + Docker Compose + Nginx (balanceo de dos réplicas) |

## Entradas disponibles desde la web (`/`)

La página raíz presenta el servicio y enlaza Swagger UI, OpenAPI yaml y ReDoc. La consola H2 está disponible solo con el perfil local.
