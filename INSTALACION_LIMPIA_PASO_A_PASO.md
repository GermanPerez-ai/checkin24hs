# 🧹 Instalación Limpia - Paso a Paso

## 🎯 Objetivo
Limpiar todo y dejar funcionando solo:
- ✅ `dashboard.checkin24hs.com`
- ✅ `webmail.checkin24hs.com`

---

## ⚠️ IMPORTANTE ANTES DE EMPEZAR

**Esto eliminará servicios y configuraciones que no necesitas.**
**Tus datos en Supabase NO se perderán.**
**Solo se eliminarán servicios de EasyPanel.**

---

## 📋 PASO 1: Verificar Código en tu Computadora

### 1.1. Verificar que dashboard.html existe y funciona

1. Abre: `C:\Users\German\Downloads\Checkin24hs\dashboard.html`
2. Verifica que se abre en el navegador
3. Verifica que tiene todos los menús (95% completo como dijiste)

### 1.2. Verificar archivos necesarios

En `C:\Users\German\Downloads\Checkin24hs`, verifica que existan:

**Archivos principales:**
- ✅ `dashboard.html`
- ✅ `server.js`
- ✅ `Dockerfile`
- ✅ `package.json`

**Archivos JavaScript:**
- ✅ `supabase-client.js`
- ✅ `supabase-config.js`
- ✅ `database.js`
- ✅ `dashboard-integration.js`
- ✅ `flor-agent.js`
- ✅ `flor-ai-service.js`
- ✅ `flor-knowledge-base.js`
- ✅ `flor-learning-system.js`
- ✅ `flor-multimodal-service.js`
- ✅ `flor-widget.js`
- ✅ `puppeteer-real-cotizacion.js`

**Recursos:**
- ✅ `logo.png` o logos SVG
- ✅ Carpeta `hotel-images/`

**Si falta algo, avísame antes de continuar.**

---

## 📋 PASO 2: Subir Código a GitHub

### 2.1. Abrir Terminal

1. Presiona `Windows + R`
2. Escribe: `cmd` y presiona Enter
3. O abre PowerShell

### 2.2. Ir a la Carpeta

```cmd
cd C:\Users\German\Downloads\Checkin24hs
```

### 2.3. Verificar Estado

```cmd
git status
```

### 2.4. Agregar Archivos

```cmd
git add dashboard.html server.js Dockerfile package.json
git add supabase-client.js supabase-config.js database.js dashboard-integration.js
git add flor-agent.js flor-ai-service.js flor-knowledge-base.js flor-learning-system.js flor-multimodal-service.js flor-widget.js
git add puppeteer-real-cotizacion.js
git add logo*.png logo*.svg
git add hotel-images/
```

### 2.5. Hacer Commit

```cmd
git commit -m "Código completo del dashboard para instalación limpia"
```

### 2.6. Subir a GitHub

```cmd
git push origin working-version
```

**Espera a que termine.**

---

## 📋 PASO 3: Listar Servicios Actuales en EasyPanel

### 3.1. Abrir EasyPanel

1. Abre tu navegador
2. Ve a tu panel de EasyPanel
3. Inicia sesión

### 3.2. Ver Todos los Servicios

1. Ve a tu proyecto `checkin24hs`
2. **Anota en un papel o archivo de texto** todos los servicios que ves:
   - Ejemplo: `checkin24hs-dashboard`, `webmail`, `whatsapp`, etc.

### 3.3. Ver Todos los Dominios

1. En EasyPanel, busca la sección **"Dominios"** o **"Domains"** (puede estar en el menú principal)
2. **Anota todos los dominios** que ves:
   - Ejemplo: `dashboard.checkin24hs.com`, `panel.checkin24hs.com`, `webmail.checkin24hs.com`, etc.

**Guarda esta lista, la necesitarás después.**

---

## 📋 PASO 4: Eliminar Servicios que NO Necesitas

### 4.1. Servicios a ELIMINAR

**Elimina estos servicios (si existen):**
- ❌ `checkin24hs-dashboard` (lo recrearemos después)
- ❌ `checkin24hs_checkin24hs-dashboard` (duplicado)
- ❌ `dashboard` (si existe)
- ❌ `whatsapp` o `whatsapp-server` (si no lo necesitas)
- ❌ `crm` (si no lo necesitas)
- ❌ Cualquier otro servicio que NO sea `webmail`

**⚠️ NO ELIMINES:**
- ✅ `webmail` o `checkin24hs_webmail` (lo necesitamos)

### 4.2. Cómo Eliminar un Servicio

Para cada servicio a eliminar:

1. Haz clic en el servicio
2. Si está corriendo, busca el botón **"Detener"** o **"Stop"** y haz clic
3. Espera a que se detenga
4. Busca el botón **"Eliminar"** o **"Delete"** (icono de basura 🗑️)
5. Haz clic y confirma

**Repite esto para cada servicio que quieras eliminar.**

---

## 📋 PASO 5: Eliminar Dominios que NO Necesitas

### 5.1. Dominios a ELIMINAR

**Elimina estos dominios (si existen):**
- ❌ `panel.checkin24hs.com` (si existe)
- ❌ Cualquier otro dominio que NO sea:
  - ✅ `dashboard.checkin24hs.com`
  - ✅ `webmail.checkin24hs.com`

### 5.2. Cómo Eliminar un Dominio

1. Ve a la sección **"Dominios"** o **"Domains"** en EasyPanel
2. Busca el dominio que quieres eliminar
3. Haz clic en el dominio
4. Busca el botón **"Eliminar"** o **"Delete"**
5. Haz clic y confirma

**O si el dominio está dentro de un servicio:**
1. Abre el servicio
2. Ve a la pestaña **"Dominios"**
3. Haz clic en el dominio
4. Elimínalo

---

## 📋 PASO 6: Limpiar Puertos Confusos (SSH)

### 6.1. Conectarse por SSH

1. Abre tu terminal SSH (PuTTY, Terminal, etc.)
2. Conéctate a tu servidor

### 6.2. Ver Todos los Servicios Docker

Ejecuta este comando:

```bash
docker service ls
```

**Anota todos los servicios que ves.**

### 6.3. Ver Puertos en Uso

Ejecuta:

```bash
sudo netstat -tuln | grep -E ':(300[0-9]|301[0-9]|302[0-9])' | sort
```

**Anota qué puertos están en uso.**

### 6.4. Eliminar Puertos de Servicios Eliminados

Si eliminaste servicios pero los puertos siguen en uso, ejecuta:

```bash
# Ver todos los servicios
docker service ls

# Para cada servicio que ya eliminaste pero sigue apareciendo:
# (Reemplaza NOMBRE_SERVICIO con el nombre real)
docker service rm NOMBRE_SERVICIO
```

**⚠️ Solo elimina servicios que ya eliminaste en EasyPanel pero siguen apareciendo aquí.**

---

## 📋 PASO 7: Verificar Servicio Webmail

### 7.1. Verificar que Webmail Existe

1. En EasyPanel, busca el servicio `webmail` o `checkin24hs_webmail`
2. Verifica que está corriendo (verde)

### 7.2. Verificar Dominio de Webmail

1. Abre el servicio webmail
2. Ve a la pestaña **"Dominios"**
3. Verifica que tiene el dominio: `webmail.checkin24hs.com`
4. Si NO lo tiene, agrégalo:
   - Haz clic en **"Agregar Dominio"**
   - Dominio: `webmail.checkin24hs.com`
   - Puerto interno: `80` (o el que tenga configurado el servicio)
   - Guarda

### 7.3. Probar Webmail

1. Abre tu navegador
2. Ve a: `http://webmail.checkin24hs.com`
3. Verifica que funciona

**Si no funciona, avísame y lo arreglamos después.**

---

## 📋 PASO 8: Crear Servicio Dashboard Nuevo

### 8.1. Crear Nuevo Servicio

1. En EasyPanel, en tu proyecto `checkin24hs`
2. Haz clic en **"+"** o **"Crear Servicio"** o **"New Service"**

### 8.2. Nombre del Servicio

1. Nombre: `dashboard`
   - **⚠️ IMPORTANTE: Usa solo `dashboard`, NO `checkin24hs-dashboard`**
2. Tipo: Selecciona `Docker` o `Node.js`
3. Haz clic en **"Crear"**

---

## 📋 PASO 9: Configurar Fuente del Dashboard

### 9.1. Ir a la Pestaña "Fuente"

1. En el servicio `dashboard` que acabas de crear
2. Haz clic en **"Fuente"** o **"Source"**

### 9.2. Seleccionar GitHub

1. Haz clic en la pestaña **"Github"**

### 9.3. Configurar Repositorio

1. **Propietario**: `GermanPerez-ai`
2. **Repositorio**: `checkin24hs`
3. **Rama**: `working-version`
4. **Ruta de compilación**: `/` (solo una barra, raíz)

### 9.4. Guardar

1. Haz clic en **"Guardar"**

---

## 📋 PASO 10: Configurar Compilación del Dashboard

### 10.1. Ir a Compilación

1. En la misma página de "Fuente"
2. Desplázate hacia abajo
3. Busca **"Compilación"** o **"Build"**

### 10.2. Seleccionar Dockerfile

1. Selecciona **"Dockerfile"**
2. Archivo: `Dockerfile`

### 10.3. Guardar

1. Haz clic en **"Guardar"**

---

## 📋 PASO 11: Configurar Puerto del Dashboard

### 11.1. Ir a Puertos

1. En el servicio `dashboard`
2. Haz clic en **"Puertos"** o **"Ports"**

### 11.2. Agregar Puerto

1. Haz clic en **"Agregar Puerto"** o **"Add Port"**

### 11.3. Configurar Puerto

1. **Protocolo**: `TCP`
2. **Publicado**: `3000`
3. **Destino**: `3000`
4. **Modo**: `Ingress` (si hay opción)

### 11.4. Guardar

1. Haz clic en **"Guardar"**

---

## 📋 PASO 12: Configurar Dominio del Dashboard

### 12.1. Ir a Dominios

1. En el servicio `dashboard`
2. Haz clic en **"Dominios"** o **"Domains"**

### 12.2. Agregar Dominio

1. Haz clic en **"Agregar Dominio"** o **"Add Domain"**

### 12.3. Configurar Dominio

1. **Dominio**: `dashboard.checkin24hs.com`
2. **Puerto interno**: `3000`
3. **Target Service** (si hay): `dashboard`

### 12.4. Guardar

1. Haz clic en **"Guardar"**

---

## 📋 PASO 13: Implementar el Dashboard

### 13.1. Implementar

1. En la parte superior del servicio `dashboard`
2. Haz clic en **"Implementar"** o **"Deploy"** (botón verde grande)

### 13.2. Esperar Construcción

1. El servicio cambiará a estado **"Building"** o **"Construyendo"**
2. **Espera 2-5 minutos**
3. Puedes ver el progreso en la pestaña **"Logs"**

### 13.3. Verificar Logs

Cuando termine, ve a la pestaña **"Logs"** y verifica que ves:

```
🚀 Servidor iniciado en http://0.0.0.0:3000/
📊 API disponible en http://0.0.0.0:3000/api/puyehue-quote
🌐 Frontend disponible en http://0.0.0.0:3000
```

**Si ves estos mensajes, está funcionando correctamente.**

---

## 📋 PASO 14: Configurar DNS

### 14.1. Obtener IP del Servidor

En SSH, ejecuta:

```bash
curl ifconfig.me
```

**Anota la IP que aparece (ejemplo: `72.61.58.240`)**

### 14.2. Configurar DNS en tu Panel de DNS

1. Abre tu panel de DNS (donde gestionas los registros DNS de `checkin24hs.com`)
2. Ve a la sección de **"Registros A"** o **"A Records"**

### 14.3. Agregar Registros A

**Agrega estos registros:**

1. **Nombre**: `dashboard`
   - **Tipo**: `A`
   - **Valor**: `72.61.58.240` (la IP de tu servidor)
   - **TTL**: `3600` (o el que tengas por defecto)

2. **Nombre**: `webmail`
   - **Tipo**: `A`
   - **Valor**: `72.61.58.240` (la misma IP)
   - **TTL**: `3600`

### 14.4. Eliminar Registros que NO Necesitas

**Elimina estos registros (si existen):**
- ❌ `panel` (si existe)
- ❌ Cualquier otro subdominio que no necesites

### 14.5. Guardar

1. Guarda los cambios en tu panel de DNS
2. **Espera 5-10 minutos** para que se propaguen los cambios

---

## 📋 PASO 15: Probar Todo

### 15.1. Probar Dashboard

1. Abre tu navegador
2. Ve a: `http://dashboard.checkin24hs.com`
3. Verifica que:
   - ✅ Se carga el dashboard completo
   - ✅ Tiene todos los menús
   - ✅ Puedes navegar entre secciones

### 15.2. Probar Webmail

1. Abre tu navegador
2. Ve a: `http://webmail.checkin24hs.com`
3. Verifica que funciona

---

## 🆘 Si Algo Sale Mal

### Problema: Dashboard no carga

1. Ve a la pestaña **"Logs"** del servicio `dashboard`
2. Copia los últimos mensajes
3. Avísame qué dice

### Problema: Error 502 Bad Gateway

1. Verifica que el servicio está corriendo (verde)
2. Verifica que el puerto interno es `3000`
3. Verifica que el dominio apunta al puerto `3000`
4. Avísame y lo corregimos

### Problema: DNS no resuelve

1. Espera 10-15 minutos más
2. Prueba desde otro navegador o modo incógnito
3. Verifica en tu panel de DNS que los registros están guardados

---

## ✅ Checklist Final

Antes de terminar, verifica:

- [ ] Código subido a GitHub (rama `working-version`)
- [ ] Servicios innecesarios eliminados
- [ ] Dominios innecesarios eliminados
- [ ] Servicio `dashboard` creado y corriendo (verde)
- [ ] Servicio `webmail` corriendo (verde)
- [ ] Dominio `dashboard.checkin24hs.com` configurado
- [ ] Dominio `webmail.checkin24hs.com` configurado
- [ ] DNS configurado (registros A para `dashboard` y `webmail`)
- [ ] Dashboard accesible desde `http://dashboard.checkin24hs.com`
- [ ] Webmail accesible desde `http://webmail.checkin24hs.com`
- [ ] Dashboard muestra todos los menús correctamente

---

## 🎉 ¡Listo!

Si completaste todos los pasos y todo funciona, ¡estás listo!

**Solo tienes funcionando:**
- ✅ `dashboard.checkin24hs.com`
- ✅ `webmail.checkin24hs.com`

**Todo lo demás está limpio.**

Si tienes algún problema en cualquier paso, avísame y te ayudo.

