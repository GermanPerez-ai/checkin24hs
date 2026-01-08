# 📋 Configuración EasyPanel - Copiar y Pegar

## ✅ Verificación: El archivo está en GitHub

✅ El archivo `whatsapp-server/whatsapp-server.js` está en tu repositorio de GitHub.

---

## 📝 Configuración para whatsapp-1

### 1. FUENTE (Sección "Fuente")

**Propietario:**
```
GermanPerez-ai
```

**Repositorio:**
```
checkin24hs
```

**Rama:**
```
main
```

**Ruta de compilación:**
```
/whatsapp-server
```

**Haz clic en "Guardar"**

---

### 2. VARIABLES DE ENTORNO (Sección "Entorno")

Copia y pega esto completo en el campo de texto grande:

```
INSTANCE_NUMBER=1
PORT=3001
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

**Haz clic en "Guardar"**

---

### 3. PUERTOS (Sección "Avanzado" → "Puertos")

**Protocolo:**
```
TCP
```

**Publicado:**
```
3001
```

**Destino:**
```
3001
```

**Haz clic en "Crear"**

---

### 4. COMPILACIÓN (Sección "Compilación")

**Comando de inicio:**
```
node whatsapp-server.js
```

**Haz clic en "Guardar"**

---

### 5. IMPLEMENTAR

1. Ve a la sección **"Implementaciones"** o busca el botón **"Implementar"**
2. Haz clic en **"Implementar"** o **"Deploy"**
3. Espera a que el servicio inicie (debe ponerse en verde)

---

## 📝 Configuración para whatsapp-2

Repite los mismos pasos, pero cambia:

**Variables de entorno:**
```
INSTANCE_NUMBER=2
PORT=3002
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

**Puerto:**
- Publicado: `3002`
- Destino: `3002`

---

## 📝 Configuración para whatsapp-3

**Variables de entorno:**
```
INSTANCE_NUMBER=3
PORT=3003
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

**Puerto:**
- Publicado: `3003`
- Destino: `3003`

---

## 📝 Configuración para whatsapp-4

**Variables de entorno:**
```
INSTANCE_NUMBER=4
PORT=3004
SUPABASE_URL=https://lmoeuyasuvoqhtvhkyia.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxtb2V1eWFzdXZvcWh0dmhreWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNjE5NjAsImV4cCI6MjA3OTkzNzk2MH0.28xpqAqAa7rkeT3Ma5fPmbzYnetlq2wOPOgh9XBF3g4
```

**Puerto:**
- Publicado: `3004`
- Destino: `3004`

---

## ✅ Checklist Final

Para cada servicio (whatsapp-1, whatsapp-2, whatsapp-3, whatsapp-4):

- [ ] Fuente configurada (Propietario, Repositorio, Rama, Ruta: `/whatsapp-server`)
- [ ] Variables de entorno agregadas (INSTANCE_NUMBER, PORT, SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Puerto creado (Publicado y Destino iguales: 3001, 3002, 3003, 3004)
- [ ] Comando de inicio configurado (`node whatsapp-server.js`)
- [ ] Servicio implementado (botón verde "Running")
- [ ] Sin errores en los logs

---

## 🆘 Si Algo No Funciona

1. **Revisa los logs** del servicio en EasyPanel
2. **Verifica que la ruta de compilación** sea `/whatsapp-server`
3. **Verifica que todas las variables** estén sin espacios extra
4. **Reinicia el servicio** después de cada cambio

