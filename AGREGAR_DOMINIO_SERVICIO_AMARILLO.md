# 🔧 Agregar Dominio Aunque el Servicio Esté en Amarillo

## 🎯 Situación Actual

- ✅ Nginx inicia correctamente
- ⚠️ El servicio se reinicia cada 5 minutos (probablemente health check)
- ⚠️ Punto amarillo (pero el servicio funciona)

## ✅ Solución: Agregar el Dominio de Todos Modos

Aunque el servicio esté en amarillo, podemos agregar el dominio y probar si funciona. El problema del health check no impide que el servicio responda a peticiones.

### Paso 1: Agregar el Dominio

1. Ve a la pestaña **"Dominios"** (en el menú lateral izquierdo)
2. Haz clic en **"Agregar dominio"** (botón en la parte inferior)
3. Ingresa: `dashboard.checkin24hs.com`
4. **IMPORTANTE**: Verifica qué destino genera EasyPanel automáticamente
   - ¿Es `http://dashboard-new:80/` o `http://dashboard2:80/`?
   - O ¿es `http://checkin24hs_dashboard-new:80/` (con guión bajo)?
5. **Comparte qué destino aparece**

### Paso 2: Probar el Dominio

1. Espera 30-60 segundos después de agregar el dominio
2. Abre tu navegador
3. Ve a: `https://dashboard.checkin24hs.com/`
4. **¿Funciona?** Si funciona, el problema es solo el health check

### Paso 3: Si el Dominio Genera un Destino con Guión Bajo

Si EasyPanel genera `http://checkin24hs_dashboard-new:80/` (con guión bajo), necesitamos verificar el alias en Docker.

En el servidor, ejecuta:
```bash
docker service ls | grep dashboard
```

Luego, para el nuevo servicio (reemplaza `dashboard-new` con el nombre real):
```bash
docker service inspect checkin24hs_dashboard-new --format '{{json .Spec.TaskTemplate.Networks}}' | jq
```

---

## 🔍 Sobre el Health Check

El servicio se reinicia cada 5 minutos probablemente porque:
1. El health check de EasyPanel está fallando
2. O hay alguna configuración que causa reinicios periódicos

**Pero esto no impide que el servicio responda a peticiones HTTP.**

---

**Agrega el dominio y comparte:**
1. **¿Qué destino genera EasyPanel?**
2. **¿El dominio funciona cuando accedes desde el navegador?**
