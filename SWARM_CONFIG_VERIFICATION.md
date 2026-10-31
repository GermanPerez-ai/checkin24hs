# ✅ Verificación: Configuración Docker Swarm para WhatsApp

## 🎯 Objetivo

Verificar que las 4 líneas WhatsApp tienen configuración correcta para evitar acceso concurrente a `auth_info_baileys_N` que causa "Esperando mensaje" / Bad MAC.

## 📋 Configuración Actual

### Línea 1 (whatsapp.checkin24hs.com)
**Archivo**: `docker-compose-whatsapp-only.yml`
```yaml
services:
  whatsapp:
    deploy:
      replicas: 1                    ✅ CORRECTO
      update_config:
        order: stop-first            ✅ CORRECTO
    volumes:
      - whatsapp-auth:/app/auth_info_baileys_1
```

**Estado**: ✅ Configuración correcta

### Línea 2 (whatsapp2.checkin24hs.com)
**Archivo**: `docker-compose-whatsapp2-only.yml`
```yaml
services:
  whatsapp2:
    environment:
      INSTANCE_NUMBER: "2"
      PORT: "3002"
    deploy:
      replicas: 1                    ✅ CORRECTO
      update_config:
        order: stop-first            ✅ CORRECTO
    volumes:
      - whatsapp2-auth:/app/auth_info_baileys_2
```

**Estado**: ✅ Configuración correcta

### Líneas 3 y 4 (whatsapp3/4.checkin24hs.com)
**Estado**: ⚠️ No encontrados archivos docker-compose específicos

**Acción necesaria**: Verificar en servidor que existan servicios Swarm con:
```bash
docker service ls | grep whatsapp
docker service inspect checkin24hs_whatsapp3 --format '{{json .Spec.TaskTemplate.ContainerSpec.Env}}' | jq
docker service inspect checkin24hs_whatsapp3 --format '{{json .Spec.Mode.Replicated.Replicas}}'
docker service inspect checkin24hs_whatsapp3 --format '{{json .Spec.UpdateConfig.Order}}'
```

## ✅ Requisitos Críticos

### 1. Replicas = 1 (OBLIGATORIO)
```yaml
deploy:
  replicas: 1
```

**Por qué**: Si replicas > 1:
- Múltiples containers acceden mismo volumen `/app/auth_info_baileys_N`
- Baileys detecta "session in use elsewhere"
- Resultado: Bad MAC instantáneo en TODOS los mensajes
- Cliente: "Esperando mensaje" permanente

### 2. Update Order = stop-first (OBLIGATORIO)
```yaml
deploy:
  update_config:
    order: stop-first
```

**Por qué**: Durante `Implementar` en Easypanel:
- `stop-first`: Detiene container viejo ANTES de iniciar nuevo → solo 1 accede auth
- `start-first` (default): Inicia nuevo ANTES de detener viejo → 2 acceden auth simultáneamente durante ~30 segundos → corrupción de sesión

### 3. Volumen Único por Línea (OBLIGATORIO)
```yaml
volumes:
  - whatsapp-auth:/app/auth_info_baileys_1    # Línea 1
  - whatsapp2-auth:/app/auth_info_baileys_2   # Línea 2
  - whatsapp3-auth:/app/auth_info_baileys_3   # Línea 3
  - whatsapp4-auth:/app/auth_info_baileys_4   # Línea 4
```

**Por qué**: Cada línea necesita su propio directorio de auth (claves de sesión WhatsApp independientes).

### 4. Variable INSTANCE_NUMBER Correcta
```yaml
environment:
  INSTANCE_NUMBER: "1"  # Línea 1
  INSTANCE_NUMBER: "2"  # Línea 2
  INSTANCE_NUMBER: "3"  # Línea 3
  INSTANCE_NUMBER: "4"  # Línea 4
```

**Por qué**: El código usa `auth_info_baileys_${CONFIG.INSTANCE_NUMBER}` para saber qué directorio de auth usar.

## 🔍 Comandos de Verificación

### En el servidor

```bash
#!/bin/bash
# Verificar configuración Swarm de las 4 líneas WhatsApp

echo "=== Verificación Configuración Swarm WhatsApp ==="
echo ""

for LINE in 1 2 3 4; do
  SERVICE="checkin24hs_whatsapp"
  [[ $LINE -gt 1 ]] && SERVICE="${SERVICE}${LINE}"
  
  echo "=== Línea $LINE: $SERVICE ==="
  
  if ! docker service inspect "$SERVICE" >/dev/null 2>&1; then
    echo "❌ Servicio NO existe"
    echo ""
    continue
  fi
  
  # Replicas
  REPLICAS=$(docker service inspect "$SERVICE" --format '{{.Spec.Mode.Replicated.Replicas}}')
  if [[ "$REPLICAS" == "1" ]]; then
    echo "✅ Replicas: $REPLICAS (correcto)"
  else
    echo "❌ Replicas: $REPLICAS (debe ser 1)"
  fi
  
  # Update order
  ORDER=$(docker service inspect "$SERVICE" --format '{{.Spec.UpdateConfig.Order}}')
  if [[ "$ORDER" == "stop-first" ]]; then
    echo "✅ Update order: $ORDER (correcto)"
  else
    echo "❌ Update order: $ORDER (debe ser stop-first)"
  fi
  
  # Instance number
  INSTANCE=$(docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' | grep INSTANCE_NUMBER || echo "")
  if [[ -n "$INSTANCE" ]]; then
    echo "✅ $INSTANCE"
  else
    [[ $LINE == 1 ]] && echo "ℹ️  INSTANCE_NUMBER no set (línea 1 usa default 1)"
  fi
  
  # Mounts
  echo "Volúmenes:"
  docker service inspect "$SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Mounts}}  - {{.Source}} → {{.Target}}{{"\n"}}{{end}}'
  
  echo ""
done

echo "=== Resumen ==="
echo "Para corregir si hay errores:"
echo "1. Editar docker-compose correspondiente"
echo "2. docker stack deploy -c docker-compose-XXXX.yml checkin24hs"
echo "3. Verificar: docker service ls | grep whatsapp"
```

### Salvar como script
```bash
cat > /root/checkin24hs/scripts/verificar_swarm_config_whatsapp.sh << 'EOF'
[contenido del script de arriba]
EOF
chmod +x /root/checkin24hs/scripts/verificar_swarm_config_whatsapp.sh
```

### Ejecutar
```bash
cd /root/checkin24hs
bash scripts/verificar_swarm_config_whatsapp.sh
```

## 🚨 Señales de Configuración Incorrecta

### Replicas > 1
```bash
$ docker service ls | grep whatsapp
ID           NAME                    MODE         REPLICAS   IMAGE
abc123       checkin24hs_whatsapp    replicated   2/2        ...
```
**Problema**: `2/2` significa 2 réplicas → 2 containers acceden misma auth

### Update order = start-first
Durante `Implementar`:
```
Logs: "⚠️ Socket creado con gen obsoleta — cerrando"
Logs: "Bad MAC" repetidos
Health: florSessionCryptoIssuesLastWindow sube rápidamente
```

### Volumen compartido
```bash
$ docker service inspect checkin24hs_whatsapp --format '{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}'
[{"Type":"volume","Source":"whatsapp-auth","Target":"/app/auth_info_baileys_1"}]

$ docker service inspect checkin24hs_whatsapp2 --format '{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}'
[{"Type":"volume","Source":"whatsapp-auth","Target":"/app/auth_info_baileys_2"}]  # ❌ Mismo volumen!
```

## 🔧 Corrección si Hay Errores

### Editar docker-compose
```yaml
services:
  whatsapp3:
    image: easypanel/checkin24hs/whatsapp:latest
    environment:
      INSTANCE_NUMBER: "3"
      PORT: "3003"
    deploy:
      replicas: 1                # ← ASEGURAR QUE SEA 1
      update_config:
        order: stop-first        # ← ASEGURAR QUE SEA stop-first
        parallelism: 1
    volumes:
      - whatsapp3-auth:/app/auth_info_baileys_3  # ← Volumen único
```

### Redesplegar
```bash
docker stack deploy -c docker-compose-whatsapp3-only.yml checkin24hs
```

### Verificar
```bash
docker service ps checkin24hs_whatsapp3
docker service inspect checkin24hs_whatsapp3 --format '{{.Spec.Mode.Replicated.Replicas}}'
docker service inspect checkin24hs_whatsapp3 --format '{{.Spec.UpdateConfig.Order}}'
```

## 📊 Monitoreo Post-Corrección

### Inmediatamente después
```bash
# Debe estar estable en 1/1
docker service ls | grep whatsapp

# No debe haber containers "shutdown"
docker ps -a | grep whatsapp
```

### Durante próximo deploy
```bash
# Observar que solo hay 1 container activo a la vez
watch -n 0.5 'docker ps | grep whatsapp'
```

### Health check
```bash
for LINE in 1 2 3 4; do
  HOST="whatsapp.checkin24hs.com"
  [[ $LINE -gt 1 ]] && HOST="whatsapp${LINE}.checkin24hs.com"
  
  echo "=== Línea $LINE ==="
  curl -s "https://${HOST}/api/health" | jq '.florSessionCryptoIssuesLastWindow, .florCryptoProtection.level'
  echo ""
done
```

Debe mostrar:
```json
{
  "florSessionCryptoIssuesLastWindow": 0,  // o <10
  "florCryptoProtection": {
    "level": "none"  // o "soft" ocasionalmente
  }
}
```

## ✅ Checklist Post-Implementación

- [ ] Línea 1: replicas=1, stop-first, volumen whatsapp-auth
- [ ] Línea 2: replicas=1, stop-first, volumen whatsapp2-auth
- [ ] Línea 3: replicas=1, stop-first, volumen whatsapp3-auth
- [ ] Línea 4: replicas=1, stop-first, volumen whatsapp4-auth
- [ ] Cada línea responde en /api/health
- [ ] florSessionCryptoIssuesLastWindow < 10 en todas
- [ ] Durante Implementar: solo 1 container activo por línea
- [ ] Logs: sin "Bad MAC" / "gen obsoleta" / "session in use"

## 📝 Notas

### Por qué esto es CRÍTICO

Una configuración incorrecta de Swarm puede causar el 100% de los fallos de desencriptación, incluso si el código tiene todas las mejoras del PR #7.

Prioridad: **CRÍTICA** - Verificar ANTES de implementar cambios de código.

### Líneas 3 y 4

Si no existen archivos docker-compose para líneas 3 y 4, pueden estar:
1. Desplegadas manualmente con `docker service create`
2. En otro repositorio / configuración
3. Comentadas en docker-compose.easypanel.yml
4. No en uso actualmente

**Acción**: Ejecutar script de verificación en servidor para confirmar estado real.
