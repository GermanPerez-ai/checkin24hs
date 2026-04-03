#!/bin/bash

echo "=========================================="
echo "🔧 CORRECCIÓN CONFIGURACIÓN IMAP WEBMAIL"
echo "=========================================="
echo ""

SERVICE_NAME="checkin24hs_webmail"

# Verificar que el servicio existe
if ! docker service inspect "$SERVICE_NAME" >/dev/null 2>&1; then
    echo "❌ Error: El servicio '$SERVICE_NAME' no existe"
    echo "   Verifica el nombre del servicio en EasyPanel"
    exit 1
fi

echo "✅ Servicio encontrado: $SERVICE_NAME"
echo ""

# Obtener configuración actual
echo "📋 Configuración actual:"
CURRENT_HOST=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_DEFAULT_HOST"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)
CURRENT_PORT=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_DEFAULT_PORT"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)
CURRENT_SSL=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_DEFAULT_HOST_SSL"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)
CURRENT_SMTP=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_SMTP_SERVER"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)

echo "   ROUNDCUBEMAIL_DEFAULT_HOST: $CURRENT_HOST"
echo "   ROUNDCUBEMAIL_DEFAULT_PORT: $CURRENT_PORT"
echo "   ROUNDCUBEMAIL_DEFAULT_HOST_SSL: $CURRENT_SSL"
echo "   ROUNDCUBEMAIL_SMTP_SERVER: $CURRENT_SMTP"
echo ""

# Determinar la mejor configuración
# Verificar si mail.checkin24hs.com resuelve y es accesible
if timeout 3 bash -c "echo > /dev/tcp/mail.checkin24hs.com/993" 2>/dev/null; then
    IMAP_HOST="mail.checkin24hs.com"
    echo "✅ Usando mail.checkin24hs.com (accesible externamente)"
elif timeout 3 bash -c "echo > /dev/tcp/localhost/993" 2>/dev/null; then
    IMAP_HOST="localhost"
    echo "✅ Usando localhost (servidor local)"
else
    IMAP_HOST="mail.checkin24hs.com"
    echo "⚠️  Usando mail.checkin24hs.com (por defecto)"
fi

echo ""
echo "🔧 Aplicando configuración correcta..."
echo ""

# Obtener todas las variables de entorno actuales
ALL_ENV=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{printf "%s\n" .}}{{end}}' 2>/dev/null)

# Crear lista de variables actualizadas
UPDATED_ENV=()

# Procesar cada variable de entorno
while IFS= read -r env_var; do
    if [ -z "$env_var" ]; then
        continue
    fi
    
    var_name=$(echo "$env_var" | cut -d= -f1)
    var_value=$(echo "$env_var" | cut -d= -f2-)
    
    case "$var_name" in
        ROUNDCUBEMAIL_DEFAULT_HOST)
            # Remover prefijo ssl:// si existe y usar el host correcto
            NEW_VALUE="$IMAP_HOST"
            echo "   Actualizando $var_name: '$var_value' -> '$NEW_VALUE'"
            UPDATED_ENV+=("$var_name=$NEW_VALUE")
            ;;
        ROUNDCUBEMAIL_DEFAULT_HOST_SSL)
            # Cambiar 'ssl' a 'true' si es necesario
            if [ "$var_value" = "ssl" ] || [ "$var_value" != "true" ]; then
                NEW_VALUE="true"
                echo "   Actualizando $var_name: '$var_value' -> '$NEW_VALUE'"
                UPDATED_ENV+=("$var_name=$NEW_VALUE")
            else
                UPDATED_ENV+=("$env_var")
            fi
            ;;
        ROUNDCUBEMAIL_SMTP_SERVER)
            # Cambiar localhost a mail.checkin24hs.com si es necesario
            if [ "$var_value" = "localhost" ]; then
                NEW_VALUE="mail.checkin24hs.com"
                echo "   Actualizando $var_name: '$var_value' -> '$NEW_VALUE'"
                UPDATED_ENV+=("$var_name=$NEW_VALUE")
            else
                UPDATED_ENV+=("$env_var")
            fi
            ;;
        ROUNDCUBEMAIL_DEFAULT_PORT)
            # Asegurar que el puerto esté configurado
            if [ -z "$var_value" ] || [ "$var_value" != "993" ]; then
                NEW_VALUE="993"
                echo "   Actualizando $var_name: '$var_value' -> '$NEW_VALUE'"
                UPDATED_ENV+=("$var_name=$NEW_VALUE")
            else
                UPDATED_ENV+=("$env_var")
            fi
            ;;
        *)
            # Mantener otras variables sin cambios
            UPDATED_ENV+=("$env_var")
            ;;
    esac
done <<< "$ALL_ENV"

# Verificar si ROUNDCUBEMAIL_DEFAULT_PORT existe, si no agregarlo
PORT_EXISTS=false
for env_var in "${UPDATED_ENV[@]}"; do
    if [[ "$env_var" == ROUNDCUBEMAIL_DEFAULT_PORT=* ]]; then
        PORT_EXISTS=true
        break
    fi
done

if [ "$PORT_EXISTS" = false ]; then
    echo "   Agregando ROUNDCUBEMAIL_DEFAULT_PORT=993"
    UPDATED_ENV+=("ROUNDCUBEMAIL_DEFAULT_PORT=993")
fi

# Verificar si ROUNDCUBEMAIL_DEFAULT_HOST_SSL existe, si no agregarlo
SSL_EXISTS=false
for env_var in "${UPDATED_ENV[@]}"; do
    if [[ "$env_var" == ROUNDCUBEMAIL_DEFAULT_HOST_SSL=* ]]; then
        SSL_EXISTS=true
        break
    fi
done

if [ "$SSL_EXISTS" = false ]; then
    echo "   Agregando ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true"
    UPDATED_ENV+=("ROUNDCUBEMAIL_DEFAULT_HOST_SSL=true")
fi

echo ""
echo "📝 Configuración que se aplicará:"
echo "----------------------------------------"
for env_var in "${UPDATED_ENV[@]}"; do
    if [[ "$env_var" == ROUNDCUBE* ]] || [[ "$env_var" == *HOST* ]] || [[ "$env_var" == *PORT* ]] || [[ "$env_var" == *SSL* ]]; then
        echo "   $env_var"
    fi
done
echo ""

# Confirmar antes de aplicar
read -p "¿Deseas aplicar estos cambios? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo "❌ Operación cancelada"
    exit 0
fi

echo ""
echo "🔄 Actualizando servicio..."

# Construir comando docker service update
UPDATE_CMD="docker service update"

# Agregar cada variable de entorno
for env_var in "${UPDATED_ENV[@]}"; do
    UPDATE_CMD="$UPDATE_CMD --env-add \"$env_var\""
done

# Primero, remover todas las variables de entorno existentes (solo las que vamos a actualizar)
echo "   Removiendo variables antiguas..."
docker service update \
    --env-rm "ROUNDCUBEMAIL_DEFAULT_HOST" \
    --env-rm "ROUNDCUBEMAIL_DEFAULT_HOST_SSL" \
    --env-rm "ROUNDCUBEMAIL_DEFAULT_PORT" \
    --env-rm "ROUNDCUBEMAIL_SMTP_SERVER" \
    "$SERVICE_NAME" 2>/dev/null || true

# Esperar un momento
sleep 2

# Agregar las nuevas variables
echo "   Agregando variables nuevas..."
for env_var in "${UPDATED_ENV[@]}"; do
    var_name=$(echo "$env_var" | cut -d= -f1)
    if [[ "$var_name" == ROUNDCUBEMAIL_* ]]; then
        docker service update --env-add "$env_var" "$SERVICE_NAME" 2>/dev/null || echo "   ⚠️  No se pudo agregar $var_name (puede que ya exista)"
    fi
done

echo ""
echo "✅ Servicio actualizado"
echo ""
echo "⏳ Esperando 10 segundos para que el servicio se reinicie..."
sleep 10

echo ""
echo "📊 Verificando nueva configuración:"
echo "----------------------------------------"
NEW_HOST=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_DEFAULT_HOST"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)
NEW_PORT=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_DEFAULT_PORT"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)
NEW_SSL=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_DEFAULT_HOST_SSL"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)
NEW_SMTP=$(docker service inspect "$SERVICE_NAME" --format '{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{if eq (index (split . "=") 0) "ROUNDCUBEMAIL_SMTP_SERVER"}}{{index (split . "=") 1}}{{end}}{{end}}' 2>/dev/null)

echo "   ROUNDCUBEMAIL_DEFAULT_HOST: $NEW_HOST"
echo "   ROUNDCUBEMAIL_DEFAULT_PORT: $NEW_PORT"
echo "   ROUNDCUBEMAIL_DEFAULT_HOST_SSL: $NEW_SSL"
echo "   ROUNDCUBEMAIL_SMTP_SERVER: $NEW_SMTP"
echo ""

echo "=========================================="
echo "✅ CORRECCIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📝 Próximos pasos:"
echo "   1. Espera 30 segundos más para que el servicio se reinicie completamente"
echo "   2. Intenta iniciar sesión en https://webmail.checkin24hs.com"
echo "   3. Si el problema persiste, verifica los logs:"
echo "      docker service logs $SERVICE_NAME --tail 50"
echo ""
