# EP3 — Lista de evidencia para la entrega

## Resultados observados el 23-11-2026

- `mvn --batch-mode --no-transfer-progress verify`: compilación correcta; 20 pruebas sin fallas, errores ni omisiones; la regla JaCoCo configurada alcanzó 100% de cobertura de líneas.
- `docker compose --profile observability config --quiet`: configuración válida. En la prueba integrada local, CRUD completado, recurso inexistente respondió 404, los dos destinos de API aparecieron activos en Prometheus y Grafana cargó el dashboard y sus fuentes Prometheus/Loki.
- Nginx respondió 404 a `/actuator/prometheus`; el endpoint de métricas quedó interno. Alloy envió logs del proyecto Compose a Loki, sin mezclar contenedores de otros proyectos.
- `kubectl kustomize deploy/k8s | kubeconform -strict -summary -`: 33 recursos válidos. Trivy reportó cero misconfigurations HIGH/CRITICAL en los siete archivos de manifiestos. Actionlint y `git diff --check` terminaron sin errores.
- No se ejecutó un despliegue en nube: este equipo no tiene un contexto Kubernetes ni los secretos del clúster configurados. No presentes la validación local ni la estática como despliegue real.

El entorno Compose temporal se detuvo después de la validación. Estos resultados describen esta revisión local; las capturas y el artefacto del workflow deben corresponder a la ejecución que el equipo entregue.

## Validación local

```powershell
Copy-Item .env.example .env
docker compose --profile observability config --quiet
docker compose --profile observability up --build --wait --scale despacho-svc=2
```

1. Abre `http://localhost:3000` y valida que aparezca `Despacho · Observabilidad EP3`.
2. Abre `http://localhost:9090/targets` y confirma que Prometheus detecta `despacho` como `UP`.
3. Genera una solicitud válida y otra que responda 404. El dashboard debe reflejar solicitudes y estados HTTP; Alloy debe enviar logs disponibles a Loki.
4. Guarda evidencia del dashboard y de los targets. No incluyas contraseñas, kubeconfig ni tokens en capturas.
5. Al terminar, detén el stack con `docker compose --profile observability down`.

Las series de cobertura y duración se cargan automáticamente en las ejecuciones de integración del workflow. Si haces una demostración local manual, publica solo valores medidos; no reemplaces los indicadores con datos de ejemplo como si fueran resultados reales.

## Prueba controlada del gate

Desde GitHub Actions, ejecuta manualmente `CI/CD` con `simulate_critical_failure=true`. La etapa de calidad debe fallar con el mensaje de demostración y los jobs `deploy-compose` y `deploy-kubernetes` deben quedar omitidos por su dependencia de `quality`. Esta prueba no cambia el código ni el estado de `main`.

## Evidencia del despliegue Kubernetes

Cuando se configuren los secretos del clúster, conserva la salida del job `deploy-kubernetes`, el rollout de los dos pods de `despacho-svc`, los PVC enlazados y el artefacto `deployment-metadata`. Si faltan secretos, el workflow solo prueba la simulación Compose y la validación estática; no demuestra un despliegue en nube.

## Cierre de la entrega

- Confirma que el repositorio contiene manifiestos, dashboard, configuración de Alloy, documentación y workflow.
- Adjunta el enlace del repositorio en AVA y envíalo al docente según las instrucciones de la evaluación.
- La IA se usó como consultor técnico de errores y apoyo de configuración; revisa la declaración en el README y ajústala si el equipo hizo otros usos.
- Cada integrante debe revisar que su reflexión individual represente su experiencia y contribución reales.
