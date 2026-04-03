# 🔄 Sincronizar Build #41 por GitHub

## 📊 Situación Actual

- **Local**: Build #41 ✅
- **Servidor**: Build #40 ⚠️
- **GitHub**: Necesita verificar si tiene Build #41

---

## 🚀 Proceso Completo (2 Pasos)

### Paso 1: Subir a GitHub (Desde tu Computadora)

**Abre PowerShell** y ejecuta:

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Verificar cambios
git status

# Agregar dashboard.html
git add dashboard.html

# Commit con mensaje descriptivo
git commit -m "Actualizar dashboard a Build #41 - Mejoras de estabilidad"

# Subir a GitHub
git push origin main
```

**Espera a que termine** (puede tardar 1-2 minutos).

---

### Paso 2: Actualizar en el Servidor desde GitHub

**Conéctate al servidor:**

```bash
ssh root@72.61.58.240
```

**Luego ejecuta:**

```bash
cd /root/checkin24hs

# Opción A: Usar el script existente
./ACTUALIZAR_DASHBOARD_SERVIDOR.sh

# Opción B: Comando directo
curl -L -o /root/checkin24hs/dashboard.html https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
docker service update --force checkin24hs_dashboard
```

---

### Paso 3: Verificar en el Navegador

1. Abre: https://dashboard.checkin24hs.com/
2. **Ctrl+Shift+R** (hard refresh para limpiar caché)
3. **F12** → Console → Escribe:
   ```javascript
   window.DASHBOARD_BUILD_NUMBER
   ```
4. Debe mostrar: `41` ✅

---

## ✅ Verificación de GitHub

Antes de actualizar el servidor, verifica que GitHub tiene Build #41:

1. Abre en el navegador:
   ```
   https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
   ```
2. Presiona **Ctrl+F** y busca: `DASHBOARD_BUILD_NUMBER`
3. Debe mostrar: `window.DASHBOARD_BUILD_NUMBER = 41;`

Si GitHub muestra Build #40, significa que falta hacer `git push`.

---

## 🔍 Verificar Estado de Git

**Antes de hacer push, verifica:**

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Ver qué archivos tienen cambios
git status

# Ver diferencias (opcional)
git diff dashboard.html | Select-String "BUILD_NUMBER"
```

---

## ⚠️ Si hay problemas

### Git no está configurado

```powershell
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### No puedes hacer push

```powershell
# Verificar remoto
git remote -v

# Si falta el remoto
git remote add origin https://github.com/GermanPerez-ai/checkin24hs.git
```

### El servidor no descarga desde GitHub

**Verifica la URL en el servidor:**

```bash
# Verificar que el script existe
cat /root/checkin24hs/ACTUALIZAR_DASHBOARD_SERVIDOR.sh | grep github
```

**Debe mostrar:**
```
https://raw.githubusercontent.com/GermanPerez-ai/checkin24hs/main/dashboard.html
```

---

## 📝 Resumen del Flujo

```
Local (Build #41)
    ↓
git add + commit + push
    ↓
GitHub (Build #41)
    ↓
Servidor ejecuta script
    ↓
Servidor descarga desde GitHub
    ↓
Servidor actualiza contenedor
    ↓
Dashboard en línea (Build #41) ✅
```

---

**Este es el método correcto: siempre por GitHub.** ✅
