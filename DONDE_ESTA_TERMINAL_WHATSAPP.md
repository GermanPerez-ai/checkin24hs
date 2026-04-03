# 🔍 Dónde Está la Terminal en WhatsApp - EasyPanel

## 📍 Estás en la Pestaña "Avanzado"

Actualmente estás viendo la pestaña **"Avanzado"** (Advanced) de la aplicación WhatsApp. La terminal **NO está en esta pestaña**.

---

## 🎯 Busca las Pestañas en la Parte Superior

**Mira arriba**, en la parte superior de la página (arriba de donde dice "Implementar" y "Réplicas"), deberías ver pestañas como:

- **"Resumen"** o **"Overview"**
- **"Logs"**
- **"Terminal"** o **"Shell"** o **"Console"** ← **¡AQUÍ ESTÁ!**
- **"Archivos"** o **"Files"**
- **"Configuración"** o **"Settings"**
- **"Dominios"** o **"Domains"**

**Haz clic en "Terminal"** o **"Shell"** → Se abrirá la consola web.

---

## ✅ Solución Más Fácil: Usar Git (Sin Terminal)

**Si no ves la pestaña "Terminal"**, puedes hacerlo todo desde tu máquina:

### Paso 1: Desde tu PowerShell

```powershell
cd C:\Users\German\Downloads\Checkin24hs

# Verificar cambios
git status

# Agregar cambios
git add whatsapp-server/

# Commit
git commit -m "Actualizar whatsapp-server para nueva configuración simple"

# Push
git push origin main
```

### Paso 2: Configurar EasyPanel para Usar GitHub

1. **En la página que estás viendo**, busca la pestaña **"Fuente"** o **"Source"** (arriba, junto a "Avanzado")
2. **Haz clic en "Fuente"**
3. **Configura**:
   - Tipo: **"GitHub"** o **"Git Repository"**
   - Repositorio: `GermanPerez-ai/checkin24hs`
   - Rama: `main`
   - Build path: `/whatsapp-server`
4. **Guarda los cambios**
5. **Haz clic en "Implementar"** o **"Deploy"**

EasyPanel construirá la imagen automáticamente desde GitHub.

---

## 🔍 Alternativa: Terminal desde Otra Aplicación

Si la aplicación `whatsapp` no tiene terminal (porque está detenida), prueba con otra:

1. **Vuelve al panel principal** (haz clic en "Panel" en la barra lateral)
2. **Haz clic en `dashboard`** (tiene punto verde - está funcionando)
3. **Busca la pestaña "Terminal"** en la parte superior
4. **Abre la terminal** → Desde ahí puedes navegar a `/root/checkin24hs`

---

## 📝 Comandos para la Terminal (Cuando la Encuentres)

```bash
cd /root/checkin24hs
git pull origin main
cd whatsapp-server
docker build -t whatsapp-server:latest .
docker images | grep whatsapp-server
```

---

## 🚀 Recomendación

**La forma más fácil es usar Git**:

1. **Haz `git push` desde tu PowerShell** (no necesitas terminal)
2. **Configura EasyPanel para usar GitHub** (pestaña "Fuente")
3. **Haz clic en "Implementar"**

¿Prefieres buscar la terminal o usar Git directamente?
