# 📦 Proceso de Despliegue: Mejoras de Manejo de Errores

## 📊 Estado Actual

**✅ Mejoras implementadas localmente:**
- ✅ `saveHotelChanges()` - Mejorado
- ✅ `saveReservationChanges()` - Mejorado
- ✅ `saveEditedQuote()` - Mejorado
- ✅ `saveUserChanges()` - Mejorado

**❌ Estado en servidor:**
- ⚠️ Los cambios están solo en tu computadora local
- ⚠️ NO están en el servidor aún
- ⚠️ NO están en GitHub aún

---

## 🚀 Pasos para Subir al Servidor

### Paso 1: Commitear cambios localmente

```bash
cd "c:\Users\German\Downloads\Checkin24hs"
git add dashboard.html
git commit -m "feat: Mejorar manejo de errores en funciones críticas (saveHotel, saveReservation, saveQuote, saveUser)"
```

**Esto:**
- ✅ Incrementará automáticamente el build number (gracias al pre-commit hook)
- ✅ Guardará los cambios en Git local

---

### Paso 2: Subir a GitHub

```bash
git push origin main
```

**Esto:**
- ✅ Subirá los cambios a GitHub
- ✅ El servidor podrá descargar la versión actualizada

---

### Paso 3: Desplegar al Servidor

Tienes dos opciones:

#### Opción A: Usando el script de deployment (RECOMENDADO)

```bash
# En el servidor (SSH)
cd /root/checkin24hs
bash scripts/deploy/actualizar-dashboard.sh
```

#### Opción B: Manual

```bash
# En el servidor (SSH)
# 1. Descargar desde GitHub
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html

# 2. Verificar Build Number
grep "DASHBOARD_BUILD_NUMBER" /root/checkin24hs/dashboard.html | head -1

# 3. Reiniciar servicio Docker
docker service update --force checkin24hs_dashboard
```

---

## ⚠️ Importante

**El pre-commit hook automáticamente:**
- ✅ Incrementará `DASHBOARD_BUILD_NUMBER` (de 39 a 40)
- ✅ Actualizará `DASHBOARD_BUILD` con la fecha/hora actual

**Entonces después de hacer commit, el Build Number será:**
- Build #40 (en lugar de #39)

---

## 🔍 Verificación

Después de desplegar, verifica en el navegador:

1. Abre el dashboard
2. Abre la consola (F12)
3. Ejecuta:
   ```javascript
   console.log('Build:', window.DASHBOARD_BUILD_NUMBER);
   ```
4. Debe mostrar: `Build: 40`

---

## 📋 Resumen de Comandos

```bash
# LOCAL (en tu computadora)
cd "c:\Users\German\Downloads\Checkin24hs"
git add dashboard.html
git commit -m "feat: Mejorar manejo de errores en funciones críticas"
git push origin main

# SERVIDOR (SSH al servidor)
cd /root/checkin24hs
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
docker service update --force checkin24hs_dashboard

# VERIFICAR
# En el navegador, consola (F12):
console.log('Build:', window.DASHBOARD_BUILD_NUMBER); // Debe mostrar: 40
```

---

**¿Quieres que te ayude a ejecutar estos comandos ahora?**
