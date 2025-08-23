# --- Etapa 1: Builder ---
# Usamos una imagen base completa para instalar dependencias
FROM node:18-slim AS builder
WORKDIR /app

# Copiamos los archivos de dependencias y las instalamos
# Usamos 'npm ci' que es más rápido y seguro para builds
COPY package*.json ./
RUN npm ci

# Copiamos el resto del código fuente
COPY . .

# --- Etapa 2: Production ---
# Usamos una imagen mínima para la versión final
FROM node:18-slim AS production
WORKDIR /app

# [cite_start]Creamos un usuario no-root para correr la aplicación por seguridad [cite: 40]
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser
USER appuser

# Copiamos solo las dependencias de producción desde la etapa 'builder'
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/ .

# Exponemos el puerto en el que correrá la aplicación
EXPOSE 3000

# Comando para iniciar el servicio
CMD [ "node", "server.js" ]
