# 🔧 Solución: Webmail Reiniciándose Constantemente

## 🔍 Problema Identificado

Los logs muestran que el servicio se está reiniciando varias veces:
- `caught SIGWINCH, shutting down gracefully` (Apache se cierra)
- `ROUNDCUBEMAIL has been successfully copied` (se reinicia)
- `Apache configured -- resuming normal operations` (vuelve a iniciar)

Esto causa **Bad Gateway** porque Nginx intenta conectarse mientras Apache se está reiniciando.

## ✅ Soluciones

### Solución 1: Esperar a que se Estabilice

El servicio puede estar reiniciándose después de cambios. Espera:

1. **Espera 2-3 minutos** desde el último reinicio
2. **Observa los logs** - deben dejar de aparecer mensajes de reinicio
3. **Verifica que el último mensaje sea**: `Apache configured -- resuming normal operations`
4. **Intenta acceder** al webmail después de que se estabilice

---

### Solución 2: Verificar que el Servicio Esté Estable

1. En EasyPanel, ve a **"Registros"**
2. **Espera 1-2 minutos** sin hacer nada
3. **Observa si siguen apareciendo** mensajes de reinicio
4. Si **NO aparecen más mensajes**, el servicio está estable
5. Si **SIGUEN apareciendo**, hay un problema (ver Solución 3)

---

### Solución 3: Si Sigue Reiniciándose

Si el servicio se reinicia constantemente, puede ser por:

**A) Falta de memoria:**
- Ve a **"Recursos"**
- Aumenta **Límite de memoria** a **2048 MB** (2 GB)
- **Guarda** y **Implementa**

**B) Problema de configuración:**
- Ve a **"Entorno"**
- Verifica que todas las variables estén correctas
- **Guarda** y **Implementa**

**C) Problema con la imagen Docker:**
- Ve a **"Fuente"**
- Verifica que la imagen sea: `roundcube/roundcubemail:1.6.11-apache`
- Si es diferente, cámbiala y **Implementa**

---

### Solución 4: Verificar Estado Actual

1. **Espera 30 segundos** sin hacer nada
2. **Actualiza los logs** (botón refresh)
3. **Observa el último mensaje**:
   - ✅ Si dice `Apache configured -- resuming normal operations` → Servicio estable
   - ❌ Si sigue apareciendo `shutting down gracefully` → Sigue reiniciándose

---

## 🎯 Pasos Recomendados (Ahora)

1. **Espera 2-3 minutos** desde ahora
2. **Actualiza los logs** en EasyPanel
3. **Verifica el último mensaje**:
   - Si es `Apache configured -- resuming normal operations` → Intenta acceder al webmail
   - Si sigue reiniciándose → Aumenta memoria a 2048 MB y vuelve a implementar

---

## 📋 Checklist

- [ ] ¿El servicio dejó de reiniciarse? (espera 2-3 minutos)
- [ ] ¿El último mensaje es "Apache configured -- resuming normal operations"?
- [ ] ¿Intentaste acceder al webmail después de esperar?
- [ ] ¿Sigue dando Bad Gateway después de esperar?

---

## 🆘 Si Sigue Reiniciándose Después de 3 Minutos

1. Ve a **"Recursos"**
2. Aumenta **Límite de memoria** a **2048 MB**
3. **Guarda** los cambios
4. Haz clic en **"Implementar"**
5. Espera 2-3 minutos
6. Verifica que el servicio esté estable
7. Intenta acceder al webmail



