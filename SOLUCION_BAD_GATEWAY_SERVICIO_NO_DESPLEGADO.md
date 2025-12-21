# 🔧 Solución: Bad Gateway - Servicio No Desplegado

## 🚨 Problema Confirmado

- ✅ Docker está instalado
- ❌ No hay contenedores corriendo
- ❌ No hay servicios Docker Swarm
- ❌ El servicio del dashboard NO está desplegado

**Por eso aparece Bad Gateway:** Traefik está configurado para redirigir a un servicio que no existe.

---

## ✅ Solución: Desplegar el Servicio desde EasyPanel

### Paso 1: Entrar a EasyPanel

1. Ve a tu panel de EasyPanel
2. Inicia sesión con tus credenciales

### Paso 2: Verificar si Existe el Servicio

1. Busca en la lista de servicios:
   - "dashboard"
   - "checkin24hs"
   - "checkin24hs-dashboard"

2. **Si NO existe el servicio:**
   - Ve al Paso 3 (Crear Servicio)

3. **Si existe el servicio:**
   - Verifica el estado:
     - 🟢 **Verde** = Corriendo (pero puede tener problemas)
     - 🟡 **Amarillo** = Iniciando (espera)
     - 🔴 **Rojo** = Detenido (reinícialo)
     - ⚪ **Gris** = No desplegado (despliégalo)

---

### Paso 3: Crear el Servicio (Si No Existe)

1. **Haz clic en "Nuevo Servicio" o "Add Service"**

2. **Configuración básica:**
   - **Nombre:** `dashboard` o `checkin24hs-dashboard`
   - **Tipo:** `Docker` o `Node.js` (según tu configuración)

3. **Configuración del repositorio:**
   - **Repositorio:** `https://github.com/GermanPerez-ai/checkin24hs.git`
   - **Rama:** `main`
   - **Build Path:** `/` (raíz del repositorio)

4. **Configuración del puerto:**
   - **Puerto interno:** `3000`
   - **Puerto externo:** `3000` (o déjalo automático)

5. **Comando de inicio:**
   - Si usas Docker: Déjalo vacío (usa el Dockerfile)
   - Si usas Node.js: `node server.js` o según tu configuración

6. **Variables de entorno (si las necesitas):**
   - Agrega las variables que necesite tu aplicación

7. **Red:**
   - Asegúrate de que esté en la red `traefik` o la red correcta

8. **Dominio:**
   - **Dominio:** `dashboard.checkin24hs.com`
   - **HTTPS:** Activar (Let's Encrypt)

9. **Guarda y despliega**

---

### Paso 4: Reiniciar el Servicio (Si Existe pero Está Detenido)

1. **Haz clic en el servicio "dashboard"**

2. **Busca el botón:**
   - "Restart" / "Reiniciar"
   - "Start" / "Iniciar"
   - "Deploy" / "Desplegar"

3. **Haz clic y espera** a que se despliegue (1-2 minutos)

---

### Paso 5: Verificar el Estado

1. **Espera 1-2 minutos** después de crear/reiniciar

2. **Verifica que el servicio esté en verde** 🟢

3. **Haz clic en el servicio** para ver los logs:
   - Busca errores en los logs
   - Verifica que el contenedor se inició correctamente

---

### Paso 6: Probar el Dashboard

1. **Abre el navegador:**
   - Ve a: `https://dashboard.checkin24hs.com`

2. **Limpia el caché:**
   - Presiona **Ctrl+F5**

3. **Verifica que carga correctamente**

---

## 🔍 Si el Servicio Existe pero Sigue dando Bad Gateway

### Verificar los Logs desde EasyPanel

1. **Haz clic en el servicio "dashboard"**
2. **Ve a la pestaña "Logs"**
3. **Revisa los últimos logs:**
   - Busca errores
   - Verifica que el servidor se inició correctamente

### Verificar la Configuración

1. **Verifica el puerto:**
   - Debe ser `3000` (o el que uses)
   - Debe estar expuesto correctamente

2. **Verifica la red:**
   - Debe estar en la red `traefik` o la red correcta

3. **Verifica el dominio:**
   - Debe estar configurado como `dashboard.checkin24hs.com`

4. **Verifica Traefik:**
   - Traefik debe estar corriendo
   - Debe tener la configuración correcta para el dashboard

---

## 🆘 Si No Puedes Acceder a EasyPanel

### Desplegar Manualmente desde SSH

```bash
# 1. Clonar el repositorio
cd /tmp
git clone https://github.com/GermanPerez-ai/checkin24hs.git
cd checkin24hs

# 2. Verificar el Dockerfile
cat Dockerfile

# 3. Construir la imagen
docker build -t dashboard:latest .

# 4. Ejecutar el contenedor
docker run -d \
  --name dashboard \
  -p 3000:3000 \
  --network traefik_default \
  --restart unless-stopped \
  dashboard:latest

# 5. Verificar que está corriendo
docker ps | grep dashboard
```

**Nota:** Esto es una solución temporal. Lo ideal es desplegar desde EasyPanel.

---

## 📋 Checklist Final

- [ ] Entré a EasyPanel
- [ ] Verifiqué si existe el servicio "dashboard"
- [ ] Si no existe, creé el servicio con la configuración correcta
- [ ] Si existe pero está detenido, lo reinicié
- [ ] Esperé 1-2 minutos a que se despliegue
- [ ] Verifiqué que el servicio esté en verde 🟢
- [ ] Revisé los logs para verificar que no hay errores
- [ ] Probé el dashboard en el navegador (Ctrl+F5)
- [ ] El dashboard carga correctamente

---

## 💡 Recomendación

**La solución más rápida y segura es desplegar desde EasyPanel.**

1. Ve a EasyPanel
2. Crea o reinicia el servicio "dashboard"
3. Espera a que se despliegue
4. Prueba el dashboard

Si necesitas ayuda con algún paso específico de EasyPanel, dime en qué paso estás y te guío.

