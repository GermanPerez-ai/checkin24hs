# ✅ Comandos para Verificar que Todo Está Subido

## 🔍 Verificación Rápida (Ejecuta estos comandos uno por uno)

### 1. Verificar archivo principal

```powershell
ssh root@72.61.58.240 "grep -n 'TU MISION PRINCIPAL' /root/checkin24hs/flor-ai-service.js"
```

**Resultado esperado:** Debe mostrar una línea con números, ejemplo:
```
136:TU MISIÓN PRINCIPAL:
```

### 2. Verificar archivo de deploy

```powershell
ssh root@72.61.58.240 "grep -n 'TU MISION PRINCIPAL' /root/checkin24hs/deploy/flor-ai-service.js"
```

**Resultado esperado:** Debe mostrar una línea con números, ejemplo:
```
136:TU MISIÓN PRINCIPAL:
```

### 3. Verificar que los archivos existen

```powershell
ssh root@72.61.58.240 "ls -lh /root/checkin24hs/flor-ai-service.js /root/checkin24hs/deploy/flor-ai-service.js"
```

**Resultado esperado:** Debe mostrar ambos archivos con sus tamaños (aproximadamente 40KB cada uno)

### 4. Verificar que el servicio está corriendo

```powershell
ssh root@72.61.58.240 "docker ps --filter 'name=whatsapp.1' --format '{{.Names}} {{.Status}}'"
```

**Resultado esperado:** Debe mostrar el nombre del contenedor y su estado (ej: "Up X minutes")

### 5. Verificar mejoras específicas

```powershell
ssh root@72.61.58.240 "grep -c 'EDUCACION Y UTILIDAD' /root/checkin24hs/flor-ai-service.js"
```

**Resultado esperado:** Debe mostrar un número mayor a 0 (ej: "1" o "2")

---

## ✅ Checklist de Verificación

Ejecuta cada comando y marca lo que funciona:

- [ ] **Archivo principal existe y tiene mejoras** (Comando 1 muestra línea con números)
- [ ] **Archivo deploy existe y tiene mejoras** (Comando 2 muestra línea con números)
- [ ] **Ambos archivos están en el servidor** (Comando 3 muestra ambos archivos)
- [ ] **Servicio de WhatsApp está corriendo** (Comando 4 muestra contenedor activo)
- [ ] **Mejoras educativas están presentes** (Comando 5 muestra número > 0)

---

## 🎯 Si Todo Está Correcto

Si todos los comandos muestran los resultados esperados, entonces:

✅ **Los archivos están subidos correctamente**
✅ **Las mejoras están presentes**
✅ **El servicio está funcionando**

**Próximo paso:** Configurar la API Key de Gemini en el dashboard

---

## 🆘 Si Hay Problemas

### Problema: "No such file or directory"
- Los archivos no se subieron correctamente
- Vuelve a ejecutar los comandos de subida

### Problema: No encuentra "TU MISION PRINCIPAL"
- Los archivos subidos son versiones antiguas
- Vuelve a subir los archivos mejorados

### Problema: Contenedor no encontrado
- El servicio de WhatsApp no está corriendo
- Reinicia el servicio con: `ssh root@72.61.58.240 "CONTAINER=`$(docker ps --filter 'name=whatsapp.1' --format '{{.Names}}' | head -1); docker restart `$CONTAINER"`

---

**Ejecuta estos comandos y dime qué resultados obtienes!** 🚀


