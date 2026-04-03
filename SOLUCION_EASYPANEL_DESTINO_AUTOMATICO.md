# 🔧 Solución: EasyPanel Genera Destino Automáticamente

## 🎯 Problema

EasyPanel genera el destino automáticamente basándose en el nombre del servicio, y no permite editarlo manualmente.

## ✅ Soluciones

### Solución 1: Verificar el Nombre del Servicio en EasyPanel

El destino se genera basándose en el nombre del servicio. Verifica:

1. En EasyPanel, ve al servicio `dashboard`
2. Busca el nombre del servicio (puede estar en la URL o en la configuración)
3. El nombre debe coincidir con uno de los aliases disponibles:
   - `checkin24hs-dashboard` (con guión)
   - `dashboard`

**Si el nombre del servicio en EasyPanel es `checkin24hs_dashboard` (con guión bajo), ese es el problema.**

### Solución 2: Renombrar el Servicio en EasyPanel

Si es posible renombrar el servicio en EasyPanel:

1. Ve a la configuración del servicio `dashboard`
2. Busca una opción para **"Renombrar"** o **"Editar nombre"**
3. Cambia el nombre a: `dashboard` (sin prefijo)
4. Guarda los cambios
5. Espera 30-60 segundos
6. El dominio debería regenerarse automáticamente con el destino correcto

### Solución 3: Verificar la Configuración del Puerto

Aunque el destino se genera automáticamente, el puerto puede estar mal configurado:

1. Ve a la pestaña **"Puertos"** del servicio `dashboard`
2. Verifica que el puerto interno sea **80**
3. Si no es 80, cámbialo a 80
4. Guarda y reinicia el servicio

### Solución 4: Verificar Variables de Entorno

1. Ve a la pestaña **"Entorno"**
2. Verifica que `PORT=80` esté configurado
3. Si hay otras variables relacionadas con el puerto o el destino, compártelas

### Solución 5: Crear un Nuevo Servicio con Nombre Correcto

Como último recurso:

1. Crea un **nuevo servicio** en EasyPanel
2. Nómbralo exactamente: `dashboard` (sin prefijo, sin guiones)
3. Configura:
   - Build Path: `/deploy`
   - Dockerfile: `Dockerfile`
   - Puerto: `80`
   - Variables de entorno: `PORT=80`
4. Agrega el dominio `dashboard.checkin24hs.com` a este nuevo servicio
5. EasyPanel debería generar el destino como `http://dashboard:80/` automáticamente

---

## 🔍 Información Necesaria

Para diagnosticar mejor, necesito saber:

1. **¿Cuál es el nombre exacto del servicio en EasyPanel?**
   - ¿Es `dashboard`, `checkin24hs_dashboard`, o algo más?

2. **¿Qué destino genera EasyPanel automáticamente?**
   - Cuando agregas el dominio, ¿qué destino aparece?

3. **¿Hay alguna opción para editar el nombre del servicio?**

---

**Comparte el nombre exacto del servicio en EasyPanel y qué destino genera automáticamente cuando agregas el dominio.**
