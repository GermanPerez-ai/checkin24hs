# 🔄 Probar Otro Commit - Guía Rápida

## 🎯 Objetivo

Restaurar `dashboard.html` desde un commit diferente que pueda ser más estable.

---

## 📋 Commits Recomendados

### Opción 1: Commit Más Antiguo (Más Estable)

**Commit:** `258e39e` - "Agregar nueva pestaña WhatsApp separada con funcionalidad completa"

Este commit es anterior a los problemas de `saveHotelChanges` y puede ser más estable.

### Opción 2: Commit de Bad Gateway (Antes de Problemas)

**Commit:** `266b8b0` - "Agregar script completo para corregir Bad Gateway en dashboard"

Este commit es específico para Bad Gateway y puede tener correcciones.

### Opción 3: Commit Más Reciente (Con Correcciones)

**Commit:** `f6989f4` - "Corregir modales: hacer funciones globales y agregar validaciones"

Este commit tiene correcciones de funciones globales.

---

## 🚀 Restaurar desde Otro Commit

### Paso 1: En tu Máquina Local (PowerShell)

```powershell
# Ir a la carpeta
cd C:\Users\German\Downloads\Checkin24hs

# Hacer backup del archivo actual
copy dashboard.html dashboard.html.backup_antes_cambio_commit

# Restaurar desde commit 258e39e (más antiguo)
git checkout 258e39e -- dashboard.html

# Verificar que cambió
git status

# Subir a GitHub
git add dashboard.html
git commit -m "Restaurar dashboard.html desde commit 258e39e (mas estable)"
git push origin main
```

### Paso 2: Aplicar en el Servidor

**Opción A: Desde GitHub (Rama main)**

Después del push, el archivo estará disponible en GitHub. Desde EasyPanel:

1. **Haz clic en el servicio "dashboard"**
2. **Busca "Redeploy" o "Redesplegar"**
3. **Haz clic y espera 2-3 minutos**
4. **Prueba el dashboard**

**Opción B: Desde Commit Específico (SSH)**

Si prefieres aplicar directamente desde el commit:

```bash
# Conectarte al servidor
ssh usuario@tu-servidor

# Encontrar el contenedor (si existe)
docker ps | grep dashboard

# Descargar desde commit específico
curl -o /tmp/dashboard_commit_258e39e.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/258e39e/dashboard.html

# Copiar al contenedor (si encuentras el contenedor)
CONTAINER_NAME="NOMBRE_DEL_CONTENEDOR"
docker cp /tmp/dashboard_commit_258e39e.html $CONTAINER_NAME:/usr/share/nginx/html/dashboard.html
docker restart $CONTAINER_NAME
```

---

## 🔄 Probar Diferentes Commits

### Commit 1: 258e39e (Más Antiguo)

```powershell
git checkout 258e39e -- dashboard.html
git add dashboard.html
git commit -m "Restaurar desde commit 258e39e"
git push origin main
```

### Commit 2: 266b8b0 (Bad Gateway)

```powershell
git checkout 266b8b0 -- dashboard.html
git add dashboard.html
git commit -m "Restaurar desde commit 266b8b0"
git push origin main
```

### Commit 3: f6989f4 (Correcciones)

```powershell
git checkout f6989f4 -- dashboard.html
git add dashboard.html
git commit -m "Restaurar desde commit f6989f4"
git push origin main
```

---

## 📋 Comandos Completos (Copia y Pega)

### Para Probar Commit 258e39e:

```powershell
cd C:\Users\German\Downloads\Checkin24hs
copy dashboard.html dashboard.html.backup_commit_258e39e
git checkout 258e39e -- dashboard.html
git add dashboard.html
git commit -m "Restaurar dashboard.html desde commit 258e39e"
git push origin main
```

Luego en EasyPanel:
1. Ve al servicio "dashboard"
2. Haz clic en "Redeploy" o "Redesplegar"
3. Espera 2-3 minutos
4. Prueba el dashboard

---

## ✅ Verificación

Después de restaurar y desplegar:

1. **Espera 2-3 minutos** después del deploy
2. **Abre el dashboard:** `https://dashboard.checkin24hs.com`
3. **Presiona Ctrl+F5** (limpiar caché)
4. **Abre la consola (F12)**
5. **Verifica:**
   - ¿NO hay errores de `saveHotelChanges`?
   - ¿NO hay Bad Gateway?
   - ¿El dashboard carga correctamente?

---

## 🆘 Si un Commit No Funciona

Si un commit no funciona:

1. **Vuelve al commit anterior:**
   ```powershell
   git checkout main -- dashboard.html
   git add dashboard.html
   git commit -m "Revertir a main"
   git push origin main
   ```

2. **O prueba otro commit** de la lista

---

## 💡 Recomendación

**Empieza con el commit más antiguo (258e39e):**
- Es anterior a los problemas de `saveHotelChanges`
- Puede ser más estable
- Si no funciona, prueba el siguiente

---

## 📞 Próximos Pasos

1. **Elige un commit** (recomiendo empezar con `258e39e`)
2. **Restaura el archivo** desde ese commit
3. **Sube a GitHub**
4. **Despliega desde EasyPanel** (Redeploy)
5. **Prueba el dashboard**
6. **Dime qué pasa**

¿Quieres que te guíe para restaurar desde el commit `258e39e`?

