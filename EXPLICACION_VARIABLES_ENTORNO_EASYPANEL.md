# 📋 Explicación: Variables de Entorno en EasyPanel

## 🎯 ¿Qué es esta página?

Esta es la sección **"Variables de entorno"** (Environment Variables) del servicio **"checkin24hs"** en EasyPanel.

Las **variables de entorno** son configuraciones que se pasan al servicio cuando se inicia. Son como "configuraciones" que el código del servicio lee para saber cómo comportarse.

## 📝 Variables que Estás Viendo

### 1. `INSTANCE_NUMBER=1`
- **Qué es**: Número de instancia del servicio
- **Para qué sirve**: Identifica qué instancia de WhatsApp es esta (1, 2, 3, o 4)
- **Ejemplo**: Si tienes 4 servicios de WhatsApp, cada uno tiene un número diferente (1, 2, 3, 4)

### 2. `PORT=3001`
- **Qué es**: Puerto donde el servicio escucha
- **Para qué sirve**: Define en qué puerto el servicio acepta conexiones
- **Ejemplo**: 
  - Instancia 1 → Puerto 3001
  - Instancia 2 → Puerto 3002
  - Instancia 3 → Puerto 3003
  - Instancia 4 → Puerto 3004

### 3. `SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co`
- **Qué es**: URL de tu base de datos Supabase
- **Para qué sirve**: Le dice al servicio dónde está la base de datos para guardar chats, interacciones, etc.

### 4. `SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **Qué es**: Clave de autenticación para Supabase
- **Para qué sirve**: Permite que el servicio se conecte a Supabase de forma segura
- **⚠️ Importante**: Esta clave es pública (anon key), pero aún así no la compartas públicamente

## 🔍 ¿Qué Servicio Es Este?

Basándome en la configuración:
- **Nombre del servicio**: `checkin24hs`
- **Puerto**: `3001`
- **Instancia**: `1`

Este parece ser el **primer servicio de WhatsApp** (whatsapp-1 o whatsapp).

## 🎯 ¿Para Qué Se Usa?

Este servicio:
1. **Conecta WhatsApp** con el chatbot Flor
2. **Guarda chats** en Supabase
3. **Responde automáticamente** a mensajes usando Flor IA
4. **Genera códigos QR** para conectar WhatsApp desde el teléfono

## ✅ ¿Está Bien Configurado?

Sí, la configuración se ve correcta:
- ✅ `INSTANCE_NUMBER=1` - Primera instancia
- ✅ `PORT=3001` - Puerto correcto para la primera instancia
- ✅ `SUPABASE_URL` - Configurado
- ✅ `SUPABASE_ANON_KEY` - Configurado

## 🔧 ¿Qué Puedes Hacer Aquí?

1. **Editar variables**: Puedes cambiar los valores y hacer clic en "Guardar"
2. **Agregar nuevas variables**: Puedes agregar más variables si las necesitas
3. **Eliminar variables**: Puedes eliminar variables que no necesites

## ⚠️ Importante

- **No cambies** estas variables a menos que sepas qué estás haciendo
- **Guarda** los cambios después de editar
- **Reinicia** el servicio después de cambiar variables para que los cambios surtan efecto

## 🔗 Relación con el Dashboard

Este servicio es diferente del **"dashboard"** que estábamos configurando antes:
- **dashboard**: Puerto 3000, sirve la aplicación React (interfaz web)
- **checkin24hs** (este): Puerto 3001, servicio backend de WhatsApp

---

**¿Necesitas cambiar algo aquí o solo querías saber qué era?**

