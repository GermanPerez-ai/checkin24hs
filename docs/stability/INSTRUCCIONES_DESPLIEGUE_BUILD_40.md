# 🚀 Instrucciones de Despliegue - Build #40

## 📊 Cambios Incluidos

**Build #40** incluye mejoras importantes de estabilidad y seguridad:

### ✅ Mejoras de Manejo de Errores
- Funciones críticas mejoradas: `saveHotelChanges()`, `saveReservationChanges()`, `saveEditedQuote()`, `saveUserChanges()`
- Try/catch completo con fallback a localStorage
- Mensajes claros al usuario con `showNotification()`
- Validaciones mejoradas

### ✅ Sistema de Autenticación Robusto
- Prevención de acceso sin login (incluso en modo incógnito)
- Verificación de sesión mejorada en `showDashboard()`
- Múltiples verificaciones de autenticación

### ✅ Botón de Cerrar Sesión
- Agregado al sidebar
- Función `logout()` mejorada con limpieza completa

### ✅ Timeout de Inactividad (30 minutos)
- Detección automática de actividad del usuario
- Cierre automático de sesión después de 30 minutos sin actividad
- Actualización de timestamp de última actividad

---

## 🚀 Desplegar en el Servidor

### Opción 1: Desde el Servidor (RECOMENDADO)

```bash
# Conectarse al servidor por SSH
ssh root@72.61.58.240

# Ir al directorio del dashboard
cd /root/checkin24hs

# Descargar desde GitHub
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# Verificar Build Number
grep "DASHBOARD_BUILD_NUMBER" /root/checkin24hs/dashboard.html | head -1
# Debe mostrar: window.DASHBOARD_BUILD_NUMBER = 40;

# Reiniciar servicio Docker
docker service update --force checkin24hs_dashboard

# Verificar que el servicio se reinició correctamente
docker service ps checkin24hs_dashboard
```

---

### Opción 2: Usando el Script de Deployment

```bash
# En el servidor (SSH)
cd /root/checkin24hs

# Ejecutar script de deployment
bash scripts/deploy/actualizar-dashboard.sh
```

---

## ✅ Verificación

Después de desplegar, verifica en el navegador:

1. Abre el dashboard
2. Abre la consola (F12)
3. Ejecuta:
   ```javascript
   console.log('Build:', window.DASHBOARD_BUILD_NUMBER);
   ```
4. **Debe mostrar:** `Build: 40`

---

## 🔍 Verificar Funcionalidades

### 1. Autenticación
- ✅ Abre en modo incógnito → Debe pedir login
- ✅ Inicia sesión → Debe mostrar dashboard
- ✅ Botón "Cerrar Sesión" visible en sidebar

### 2. Timeout de Inactividad
- ✅ Deja el dashboard abierto 30 minutos sin actividad
- ✅ Debe cerrar sesión automáticamente
- ✅ Debe mostrar mensaje de timeout

### 3. Manejo de Errores
- ✅ Intenta guardar un hotel con Supabase desconectado
- ✅ Debe mostrar mensaje y guardar en localStorage
- ✅ Debe mostrar notificación al usuario

---

## 📋 Comandos Completos

```bash
# LOCAL (ya ejecutado)
✅ git add dashboard.html
✅ git commit -m "feat: Mejorar estabilidad..."
✅ git push origin main

# SERVIDOR (ejecutar estos comandos)
cd /root/checkin24hs
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
grep "DASHBOARD_BUILD_NUMBER" /root/checkin24hs/dashboard.html | head -1
docker service update --force checkin24hs_dashboard

# VERIFICAR (en navegador, consola F12)
console.log('Build:', window.DASHBOARD_BUILD_NUMBER); // Debe mostrar: 40
```

---

**Última actualización:** 2026-01-17
**Build:** #40
