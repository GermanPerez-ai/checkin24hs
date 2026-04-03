# 📋 Paso 2: Crear Servicio en EasyPanel

## 🎯 Objetivo
Crear un nuevo servicio en EasyPanel que manejará las 4 instancias de WhatsApp a través de rutas.

---

## 📝 Instrucciones Detalladas

### 2.1. Acceder a "Nuevo Servicio"

1. En el panel principal de EasyPanel, busca el botón:
   - **"Nuevo Servicio"** o
   - **"Add Service"** o
   - **"Create Service"** o
   - Un botón **"+"** o **"Crear"**

2. Haz clic en ese botón

---

### 2.2. Seleccionar Tipo de Servicio

Cuando te pida el tipo de servicio, tienes varias opciones:

**Opción Recomendada: "Reverse Proxy" o "Proxy"**
- ✅ Esta es la mejor opción porque solo necesitamos redirigir tráfico
- ✅ No necesitamos ejecutar código, solo enrutar

**Si no hay opción "Proxy", usa:**
- **"Static"** o **"Static Site"** → Si tu WhatsApp es una aplicación web estática
- **"Node.js"** → Si tu WhatsApp es una aplicación Node.js
- **"Custom"** → Si ninguna de las anteriores aplica

**⚠️ IMPORTANTE:** 
- Si ves una opción que dice **"Reverse Proxy"**, **"Proxy"**, **"Nginx Proxy"** o **"Traefik"**, esa es la mejor opción.

---

### 2.3. Configurar el Servicio

Completa los siguientes campos:

**Nombre del Servicio:**
```
whatsapp-api
```

**Descripción (opcional):**
```
Servicio proxy para WhatsApp API con 4 instancias
```

**Puerto Interno (si te lo pide):**
```
3001
```
*(Este es el puerto de la primera instancia, pero luego configuraremos rutas)*

---

### 2.4. Guardar el Servicio

1. Haz clic en **"Crear"**, **"Guardar"**, **"Save"** o **"Create"**
2. Espera a que se cree el servicio (puede tardar unos segundos)

---

## ✅ Verificación

Después de crear el servicio, deberías ver:
- ✅ El servicio `whatsapp-api` en tu lista de servicios
- ✅ Estado: "Running" o "Activo" (o similar)
- ✅ Opciones para editar/configurar el servicio

---

## 🆘 Si Tienes Problemas

### Problema: No encuentro el botón "Nuevo Servicio"
**Solución:** 
- Busca en el menú lateral o superior
- Puede estar en un menú desplegable
- Algunos paneles tienen un botón flotante "+" en la esquina

### Problema: No sé qué tipo de servicio elegir
**Solución:**
- Toma una captura de pantalla de las opciones disponibles
- O elige "Custom" o "Reverse Proxy" si está disponible

### Problema: El servicio no se crea
**Solución:**
- Verifica que tengas permisos de administrador
- Revisa los logs de EasyPanel
- Intenta con otro nombre si hay conflicto

---

## ➡️ Siguiente Paso

Una vez que hayas creado el servicio `whatsapp-api`, avísame y pasamos al **Paso 3: Configurar el Dominio**.

---

## 📸 Ayuda Visual

Si puedes, toma una captura de pantalla de:
1. La pantalla donde seleccionas el tipo de servicio
2. El formulario de creación del servicio
3. El servicio creado en la lista

Esto me ayudará a guiarte mejor si hay algún problema.


