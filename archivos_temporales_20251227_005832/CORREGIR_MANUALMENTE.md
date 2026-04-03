# 🔧 Cómo Corregir Manualmente el Dashboard en el Servidor

## ❌ Problemas Detectados:

1. **Línea 5150**: Tiene `/*` (comentario) cuando debería ser `}` (cierre de función)
2. **Funciones globales faltantes**: No están en el `<head>` (líneas 1557-1700)
   - `window.showSection`
   - `window.searchUsers` 
   - `window.handleLogin`

## ✅ Solución Recomendada (Más Fácil):

**Reemplazar el archivo completo** es más rápido y seguro que corregir manualmente.

### Opción 1: Desde Windows (Recomendado)

```powershell
# Subir archivo correcto
scp deploy\dashboard.html root@72.61.58.240:/root/checkin24hs/deploy/dashboard.html

# Luego en el servidor:
cd /root/checkin24hs
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker restart $container
done
```

### Opción 2: Corregir Manualmente en el Servidor

Si quieres corregirlo manualmente, necesitas:

1. **Corregir línea 5150:**
   ```bash
   cd /root/checkin24hs
   sed -i '5150s/.*/        }/' deploy/dashboard.html
   ```

2. **Agregar funciones globales en el `<head>`:**
   - Buscar la línea que dice `</head>` (debería estar alrededor de línea 1556)
   - Antes de `</head>`, agregar un bloque `<script>` con las funciones globales
   - Esto es complicado porque requiere insertar ~150 líneas de código

**⚠️ ADVERTENCIA:** Corregir manualmente es propenso a errores. Es mejor reemplazar el archivo completo.

## 🎯 Comando Rápido para Corregir Todo:

```bash
cd /root/checkin24hs

# Crear backup
cp deploy/dashboard.html deploy/dashboard.html.backup.manual

# El archivo correcto debe estar en el servidor después de subirlo desde Windows
# Si no está, necesitas subirlo primero con scp desde Windows

# Aplicar a todos los contenedores
for container in $(docker ps --format '{{.Names}}' | grep "checkin24hs_dashboard"); do
    docker cp deploy/dashboard.html $container:/app/dashboard.html
    docker restart $container
done
```

