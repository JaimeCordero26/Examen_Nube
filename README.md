# Café Aurora S.R.L. - Sistema de Gestión en la Nube

## Información del Proyecto

**Universidad:** Universidad Técnica Nacional  
**Materia:** ITI-522 - Computación en la Nube  
**Profesor:** Andrés Joseph Jiménez  
**Estudiantes:** 
- Daniel Saborío
- Alejandro Cordero

**Repositorio:** https://github.com/JaimeCordero26/Examen_Nube.git

## Descripción

Sistema híbrido de gestión empresarial para Café Aurora S.R.L. que combina arquitectura de microservicios moderna con sistemas legados, implementando mejores prácticas de DevOps, seguridad y observabilidad.

## Arquitectura del Sistema

### Componentes Principales

- **Microservicios (Kubernetes):**
  - Catalog API: Gestión de productos (CRUD)
  - Orders API: Procesamiento de pedidos
  - Customers API: Gestión de clientes
  - Base de datos: PostgreSQL/MongoDB

- **Sistema Legado:**
  - Apache + PHP + MariaDB/MySQL (XAMPP/LAMPP)
  - Endpoint de inventario legacy

- **Infraestructura:**
  - Nginx como reverse proxy con HTTPS
  - Kubernetes local (minikube/k3s)
  - Observabilidad con Prometheus, Grafana y Loki

## Requisitos del Sistema

### VM Base
- **SO:** Debian 13
- **Hipervisor:** VirtualBox/VMware/Hyper-V
- **RAM:** Mínimo 8GB recomendado
- **Almacenamiento:** 50GB mínimo

### Software Requerido
- Docker & Docker Compose
- Kubernetes (minikube o k3s)
- Nginx
- XAMPP/LAMPP
- Prometheus, Grafana, Loki

## Instalación y Configuración

### 1. Obtener la VM

La máquina virtual preconfigurada está disponible en:
```
https://drive.google.com/drive/folders/1iJrQNB8cMogf6hqjPh9_dsdiZf7EDshu
```

### 2. Importar VM
```bash
# VirtualBox
VBoxManage import cafe-aurora-vm.ova

# VMware
# Usar la opción "Open a Virtual Machine" en VMware Workstation
```

### 3. Configuración Inicial
```bash
# Clonar repositorio
git clone https://github.com/JaimeCordero26/Examen_Nube.git
cd Examen_Nube

# Ejecutar script de inicialización
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## Estructura del Proyecto

```
Examen_Nube/
├── README.md
├── CHANGELOG.md
├── source/                    # https://drive.google.com/drive/folders/1iJrQNB8cMogf6hqjPh9_dsdiZf7EDshuCódigo fuente
│   ├── microservices/
│   │   ├── catalog-api/
│   │   ├── orders-api/
│   │   └── customers-api/
│   ├── legacy/
│   │   └── inventory/
│   └── frontend/
├── deploy/                    # Configuraciones de despliegue
│   ├── kubernetes/
│   ├── nginx/
│   └── scripts/
├── docs/                      # Documentación
│   ├── architecture/
│   ├── runbook/
│   ├── security/
│   └── technical/
└── evidence/                  # Evidencias y capturas
    ├── screenshots/
    ├── logs/
    └── tests/
```

## Endpoints Principales

### Microservicios (HTTPS)
- `https://localhost/api/catalog` - API de catálogo de productos
- `https://localhost/api/orders` - API de pedidos
- `https://localhost/api/customers` - API de clientes

### Sistema Legado
- `https://localhost/legacy/inventory` - Inventario legacy (solo lectura)

### Monitoreo
- `https://localhost/grafana` - Dashboard de Grafana
- `https://localhost/prometheus` - Métricas de Prometheus

## Funcionalidades Implementadas

### ✅ Infraestructura
- [x] Cluster Kubernetes operativo
- [x] Microservicios con health checks
- [x] ConfigMaps y Secrets
- [x] Ingress Controller
- [x] Límites de recursos

### ✅ Seguridad
- [x] HTTPS con certificados autofirmados
- [x] Cifrado de datos sensibles
- [x] Política de clasificación de datos
- [x] Threat modeling (STRIDE)
- [x] Hardening básico

### ✅ Observabilidad
- [x] Prometheus + cAdvisor
- [x] Grafana con dashboards
- [x] Loki para logs centralizados
- [x] SLAs y SLOs definidos

### ✅ Operaciones
- [x] Backup y restore automatizado
- [x] Pruebas de carga
- [x] CI/CD básico
- [x] Runbook operativo

## Comandos Rápidos

### Iniciar Servicios
```bash
# Iniciar cluster Kubernetes
minikube start

# Desplegar microservicios
kubectl apply -f deploy/kubernetes/

# Iniciar servicios legacy
sudo service apache2 start
sudo service mysql start

# Iniciar Nginx
sudo service nginx start
```

### Verificar Estado
```bash
# Estado de pods
kubectl get pods -A

# Estado de servicios
kubectl get services

# Logs de aplicación
kubectl logs -f deployment/catalog-api
```

### Pruebas de Carga
```bash
# Perfil 1: Carga normal
ab -n 1000 -c 10 https://localhost/api/catalog/

# Perfil 2: Carga intensiva
hey -n 5000 -c 50 -t 30 https://localhost/api/orders/
```

## SLAs y Métricas

### SLOs Definidos
- **Disponibilidad:** 99.5% uptime
- **Latencia P95:** < 500ms
- **MTTR:** < 30 minutos

### Métricas Monitoreadas
- CPU y memoria por pod
- Latencia de respuesta HTTP
- Tasa de errores 4xx/5xx
- Disponibilidad de base de datos

## Backup y Restauración

### Backup Automático
```bash
# Ejecutar backup completo
./scripts/backup.sh

# Backup específico de BD
./scripts/backup-db.sh postgresql
```

### Restauración
```bash
# Restaurar desde backup
./scripts/restore.sh backup-YYYYMMDD.tar.gz

# Verificar integridad
./scripts/verify-restore.sh
```

## Desarrollo Local

### Prerrequisitos
- Docker y Docker Compose
- kubectl configurado
- Node.js 18+ (para frontend)

### Configurar Entorno
```bash
# Variables de entorno
cp .env.example .env
vim .env

# Instalar dependencias
npm install

# Ejecutar en modo desarrollo
docker-compose up -d
```

## Documentación Técnica

La documentación técnica completa se encuentra en la carpeta `docs/`:

- **Arquitectura:** Diagramas y decisiones de diseño
- **RunBook:** Procedimientos operativos
- **Seguridad:** Políticas y threat model
- **SLAs:** Definición de niveles de servicio
- **BCP/DRP:** Plan de continuidad de negocio

## Evidencias

Todas las evidencias del cumplimiento de requisitos están disponibles en `evidence/`:
- Capturas de pantalla de funcionamiento
- Logs de pruebas de carga
- Consultas SQL de cifrado
- Métricas de Grafana
- Resultados de backup/restore

## Troubleshooting

### Problemas Comunes

**Error: CrashLoopBackOff**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
```

**Certificados HTTPS no válidos**
```bash
# Regenerar certificados
./scripts/generate-certs.sh
sudo service nginx reload
```

**Base de datos no conecta**
```bash
# Verificar secretos
kubectl get secrets
kubectl describe secret db-credentials
```

## Contribución

### Flujo de Trabajo
1. Fork del repositorio
2. Crear rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

### Tags de Versiones
- `v1.0.0-infrastructure` - Infraestructura básica
- `v1.1.0-microservices` - Microservicios implementados
- `v1.2.0-security` - Seguridad y cifrado
- `v1.3.0-observability` - Monitoreo completo
- `v2.0.0-production` - Versión final

