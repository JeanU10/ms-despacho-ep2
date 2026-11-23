# EP3 — Lista de evidencia para la entrega

## Resultados observados el 23-11-2026

- `mvn --batch-mode --no-transfer-progress verify`: compilación correcta; 20 pruebas sin fallas, errores ni omisiones; la regla JaCoCo configurada alcanzó 100% de cobertura de líneas.
- `docker compose --profile observability config --quiet`: configuración válida. En la prueba integrada local, CRUD completado, recurso inexistente respondió 404, los dos destinos de API aparecieron activos en Prometheus y Grafana cargó el dashboard y sus fuentes Prometheus/Loki.
- Nginx respondió 404 a `/actuator/prometheus`; el endpoint de métricas quedó interno. Alloy envió logs del proyecto Compose a Loki, sin mezclar contenedores de otros proyectos.
- `kubectl kustomize deploy/k8s | kubeconform -strict -summary -`: 33 recursos válidos. Trivy reportó cero misconfigurations HIGH/CRITICAL en los siete archivos de manifiestos. Actionlint y `git diff --check` terminaron sin errores.
- Despliegue real en AWS EKS: el workflow [CI/CD, ejecución 45248550867](https://github.com/JeanU10/ms-despacho-ep2/actions/runs/45248550867) terminó correctamente en la rama `ep3/observabilidad-kubernetes`, commit `df420bffd2c713881a109e39820ed220c5a74cd4`. El rollout duró 92 segundos y el smoke test confirmó `/actuator/health/readiness` y `GET /api/despachos`.
- En EKS, el nodo `t3.large` quedó `Ready`; la API quedó `2/2`, PostgreSQL `1/1`, y Grafana, Prometheus, Pushgateway, Loki y Alloy `1/1`. Los PVC de PostgreSQL, Prometheus, Grafana y Loki quedaron `Bound`.
- Verificación posterior: los dos targets `despacho` de Prometheus y el target `pushgateway` respondieron `up`; Grafana reportó su base de datos `ok`. El workflow publicó duración y cobertura en Pushgateway.

El despliegue de Compose de CI es efímero y se elimina al terminar. El clúster EKS de evaluación permanece activo hasta que se detenga manualmente.

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

### Resultado comprobado

- Cuenta académica y región: `891376964683`, `us-east-1`; clúster `ms-despacho-ep3`, Kubernetes `1.36`.
- Imagen inmutable publicada en ECR: `891376964683.dkr.ecr.us-east-1.amazonaws.com/ms-despacho-ep3:df420bffd2c713881a109e39820ed220c5a74cd4`.
- El job `Deploy to the academic EKS cluster` completó sus pasos de rollout y smoke test. El detalle y el resumen están disponibles en la [ejecución de GitHub Actions](https://github.com/JeanU10/ms-despacho-ep2/actions/runs/45248550867).
- Los servicios se exponen como `ClusterIP`; no se creó un balanceador público. Para abrir las vistas desde el equipo, usa `kubectl port-forward`.

El runner efímero usó AWS CLI local y se eliminó al terminar; las credenciales AWS no se guardaron como secretos de GitHub. El job requiere `KUBE_DB_PASSWORD` y `GRAFANA_ADMIN_PASSWORD`; no necesita `KUBE_CONFIG` ni `GHCR_PULL_TOKEN`, ya que la imagen vive en ECR y el runner obtiene el kubeconfig desde EKS.

### Acceso y comandos de comprobación

Con credenciales temporales vigentes de AWS Academy:

```powershell
aws eks update-kubeconfig --region us-east-1 --name ms-despacho-ep3
kubectl get pods,pvc -n despacho
kubectl port-forward -n despacho service/grafana 3000:3000
```

Abre `http://localhost:3000`; usa el usuario `admin`. Para leer la contraseña que el workflow montó en el clúster, ejecuta localmente:

```powershell
$encoded = kubectl get secret grafana-admin -n despacho -o jsonpath='{.data.admin_password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
```

En otra terminal, `kubectl port-forward -n despacho service/prometheus 9090:9090` permite revisar `http://localhost:9090/targets`.

### Costos y límites conocidos

La estimación del clúster activo es de aproximadamente **US$0,192 por hora**, **US$4,60 por día** y **US$9,21 por 48 horas**, suponiendo un nodo `t3.large`, el control plane EKS, una IPv4 pública y 30 GiB gp3; no incluye transferencia de datos, almacenamiento de ECR ni otros recursos del laboratorio. Referencias: [EKS](https://aws.amazon.com/eks/pricing/), [EC2 T3](https://aws.amazon.com/ec2/instance-types/t3/), [IPv4 pública de VPC](https://aws.amazon.com/vpc/pricing/) y [EBS](https://aws.amazon.com/ebs/pricing/). Es una proyección, no un corte automático de gasto. Para el diseño de costo mínimo se usa un solo nodo: no hay alta disponibilidad y los datos de `local-path` residen en el disco del nodo; una sustitución del nodo no migra esos volúmenes.

## Cierre de la entrega

- Confirma que el repositorio contiene manifiestos, dashboard, configuración de Alloy, documentación y workflow.
- Adjunta el enlace del repositorio en AVA y envíalo al docente según las instrucciones de la evaluación.
- La IA se usó como consultor técnico de errores y apoyo de configuración; revisa la declaración en el README y ajústala si el equipo hizo otros usos.
- Cada integrante debe revisar que su reflexión individual represente su experiencia y contribución reales.
