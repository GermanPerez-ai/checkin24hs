# 🔍 Verificar Puertos WhatsApp - Guía Completa

## 🎯 Objetivo

Verificar que los puertos 3001, 3002, 3003 y 3004 estén disponibles y no entren en conflicto con otros servicios.

---

## 📋 Puertos Requeridos

| Servicio | Puerto | Uso |
|----------|--------|-----|
| WhatsApp Instancia 1 | **3001** | Servidor principal |
| WhatsApp Instancia 2 | **3002** | Segunda instancia |
| WhatsApp Instancia 3 | **3003** | Tercera instancia |
| WhatsApp Instancia 4 | **3004** | Cuarta instancia |

---

## 🔧 Método 1: Script Automático (Recomendado)

### En el servidor (SSH):

```bash
# Dar permisos de ejecución
chmod +x whatsapp-server/verificar_puertos.sh

# Ejecutar verificación
./whatsapp-server/verificar_puertos.sh
```

El script mostrará:
- ✅ Puertos disponibles
- ❌ Puertos en uso
- 📊 Servicios Docker activos
- 📋 Servicios Docker Swarm

---

## 🔧 Método 2: Verificación Manual

### Paso 1: Verificar Puertos en el Servidor

```bash
# Verificar puerto 3001
netstat -tuln | grep 3001
# O con ss:
ss -tuln | grep 3001

# Verificar puerto 3002
netstat -tuln | grep 3002

# Verificar puerto 3003
netstat -tuln | grep 3003

# Verificar puerto 3004
netstat -tuln | grep 3004
```

**Resultado esperado**: No debe mostrar nada (puerto disponible)

**Si muestra algo**: El puerto está en uso. Anota qué servicio lo está usando.

---

### Paso 2: Verificar Servicios Docker

```bash
# Ver todos los servicios Docker
docker ps

# Ver servicios Docker Swarm
docker service ls

# Ver servicios que usan puertos específicos
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "3001|3002|3003|3004"
```

---

### Paso 3: Verificar en EasyPanel

1. **Abre EasyPanel** en tu navegador
2. **Ve a "Services"** o **"Servicios"**
3. **Revisa cada servicio** y verifica:
   - **Puerto configurado**: ¿Qué puerto está usando?
   - **Estado**: ¿Está corriendo (verde)?
   - **Nombre**: ¿Hay algún servicio llamado `whatsapp`, `whatsapp2`, etc.?

---

## ⚠️ Conflictos Comunes

### ✅ Puerto 80 usado por Webmail (NORMAL)

**Situación**: Webmail (Roundcube) usa puerto 80 internamente.

**¿Es un problema?**: 
- ✅ **NO es un problema** - Webmail puede usar puerto 80 (es normal)
- ✅ **NO hay conflicto** - Cada servicio corre en su propio contenedor
- ✅ **Los servicios WhatsApp usan 3001-3004**, no 80

**Importante**:
- Webmail puerto 80 = ✅ CORRECTO (no cambiar)
- WhatsApp puerto 80 = ❌ INCORRECTO (debe ser 3001-3004)

### ❌ Puerto 80 configurado en WhatsApp (INCORRECTO)

**Problema**: EasyPanel está configurando `PORT=80` para WhatsApp.

**Solución**: 
- ⚠️ **Cámbialo a `PORT=3001`** (o 3002, 3003, 3004 según la instancia)
- ✅ Webmail puede seguir usando puerto 80 (no hay conflicto)

---

### ❌ Puerto 3001 ya en uso

**Problema**: Otro servicio está usando el puerto 3001

**Solución**:
1. **Identificar el servicio**:
   ```bash
   docker ps | grep 3001
   # O
   netstat -tulpn | grep 3001
   ```

2. **Detener el servicio** (si no es necesario):
   ```bash
   docker stop <nombre_servicio>
   # O en EasyPanel: detener el servicio
   ```

3. **O usar otro puerto**: Cambiar a 3005, 3006, etc. (pero también actualizar la configuración)

---

### ❌ Múltiples servicios usando el mismo puerto

**Problema**: Varios servicios intentan usar el mismo puerto

**Solución**:
- Cada servicio WhatsApp debe usar un puerto **único**:
  - Servicio 1: `PORT=3001`
  - Servicio 2: `PORT=3002`
  - Servicio 3: `PORT=3003`
  - Servicio 4: `PORT=3004`

---

## ✅ Verificación Final

Antes de configurar los servicios WhatsApp, verifica:

- [ ] Puerto 3001: ✅ Disponible
- [ ] Puerto 3002: ✅ Disponible
- [ ] Puerto 3003: ✅ Disponible
- [ ] Puerto 3004: ✅ Disponible
- [ ] No hay otros servicios usando estos puertos
- [ ] Variables de entorno `PORT` están configuradas correctamente en EasyPanel

---

## 🚨 Problema Actual Detectado

Según los logs que compartiste:

```
📡 Servidor corriendo en puerto 80
```

**Problema**: El servicio está usando el puerto **80** en lugar de **3001**.

**Causa**: EasyPanel está configurando `PORT=80` en lugar de `PORT=3001`.

**Solución**:

1. **En EasyPanel**, ve al servicio `checkin24hs_whatsapp`
2. **Edita las variables de entorno**
3. **Verifica/Cambia**:
   ```
   PORT=3001  ← Debe ser 3001, NO 80
   INSTANCE_NUMBER=1
   ```
4. **Guarda y reinicia** el servicio

---

## 📝 Notas Importantes

1. **Puerto interno vs externo**:
   - **Puerto interno** (en el contenedor): 3001, 3002, 3003, 3004
   - **Puerto externo** (en EasyPanel): Puede ser el mismo o diferente, pero debe mapear correctamente

2. **Puerto 80**:
   - El puerto 80 es usado por servicios web (HTTP)
   - Los servicios WhatsApp **NO deben usar el puerto 80**
   - Si ves `PORT=80` en los logs, **cámbialo a PORT=3001** (o el puerto correspondiente)

3. **Verificación continua**:
   - Después de configurar cada servicio, verifica que esté usando el puerto correcto
   - Revisa los logs para confirmar: `📡 Servidor corriendo en puerto 3001`

---

## 🔗 Referencias

- [Guía Paso a Paso WhatsApp EasyPanel](./GUIA_PASO_A_PASO_WHATSAPP_EASYPANEL.md)
- [Resumen Rápido WhatsApp](./RESUMEN_RAPIDO_WHATSAPP.md)

