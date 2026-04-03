# 📦 Instalar Docker Compose

## 🔍 Paso 1: Verificar Docker

```bash
# Verificar si Docker está instalado
docker --version

# Si no está instalado, instalar Docker primero
```

## 🚀 Opción 1: Instalar docker-compose (Recomendado)

```bash
# Instalar docker-compose
apt update
apt install -y docker-compose

# Verificar instalación
docker-compose --version
```

## 🚀 Opción 2: Usar Docker Compose Plugin (Más Moderno)

Si tienes Docker instalado pero no docker-compose, puedes usar el plugin:

```bash
# Verificar si tienes docker compose (sin guión)
docker compose version

# Si funciona, usa "docker compose" en lugar de "docker-compose"
docker compose up -d
docker compose logs -f evolution-api
```

## 🔧 Si Docker No Está Instalado

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Agregar usuario al grupo docker
usermod -aG docker $USER

# Instalar docker-compose
apt update
apt install -y docker-compose

# Verificar
docker --version
docker-compose --version
```

## ✅ Después de Instalar

```bash
cd ~/evolution-api

# Iniciar Evolution API
docker-compose up -d
# O si usas el plugin:
docker compose up -d

# Ver logs
docker-compose logs -f evolution-api
# O:
docker compose logs -f evolution-api
```


