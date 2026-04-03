# Cambiar Puerto del CRM de 80 a 3005

## Problema
El CRM está usando el puerto 80, que ya está ocupado por el webmail (`webmail.checkin24hs.com`).

## Solución: Cambiar CRM al Puerto 3005

### Paso 1: Verificar Puertos Disponibles

Ejecuta en el servidor:

```bash
# Ver qué puertos están en uso
docker service ls --format "table {{.Name}}\t{{.Ports}}"

# Verificar puertos específicos
for port in 80 3000 3001 3002 3003 3004 3005; do
    if ss -tuln | grep -q ":$port "; then
        echo "Puerto $port: OCUPADO"
    else
        echo "Puerto $port: DISPONIBLE"
    fi
done
```

### Paso 2: Cambiar Puerto en EasyPanel

1. **Ve a EasyPanel → Servicio `crm`**
2. **Ve a la sección "Puertos" o "Ports"**
3. **Cambia el puerto interno de `80` a `3005`**
4. **Guarda los cambios**
5. **Espera a que se actualice el servicio**

### Paso 3: Actualizar serve-crm.js (si es necesario)

El archivo `serve-crm.js` ya está configurado para usar el puerto 3005 por defecto:

```javascript
const PORT = process.env.PORT || 3005;
```

Si EasyPanel está pasando `PORT=80` como variable de entorno, necesitas:

**Opción A:** Cambiar el puerto en EasyPanel (recomendado)
**Opción B:** Cambiar el código para forzar 3005:

```javascript
const PORT = process.env.PORT || 3005;
// Forzar puerto 3005 si viene 80
const FINAL_PORT = PORT === 80 ? 3005 : PORT;
```

Pero es mejor cambiar el puerto en EasyPanel.

### Paso 4: Verificar

Después de cambiar el puerto:

```bash
# Ver logs del servicio
docker service logs checkin24hs_crm --tail 20

# Deberías ver: "CRM corriendo en http://0.0.0.0:3005"
```

### Paso 5: Actualizar Dominio en EasyPanel

1. **Ve a la sección "Dominios"**
2. **Edita el dominio `crm.checkin24hs.com`**
3. **Asegúrate de que apunte al puerto correcto (3005)**
4. **Guarda los cambios**

## Nota Importante

**SIEMPRE verifica los puertos antes de asignar uno nuevo:**

```bash
# Script rápido para verificar puertos
docker service ls --format "table {{.Name}}\t{{.Ports}}"
```

## Puertos Recomendados

- **80**: Webmail (ya ocupado)
- **3000**: Dashboard (verificar si está ocupado)
- **3001-3004**: WhatsApp (probablemente ocupados)
- **3005**: CRM ✅ (RECOMENDADO)
- **3006-3010**: Disponibles para otros servicios


















