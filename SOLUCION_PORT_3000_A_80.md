# 🔧 Solución: Cambiar PORT de 3000 a 80

## 🎯 Problema Identificado

En la pestaña "Entorno" hay una variable:
```
PORT=3000
```

**Esto es el problema:**
- Nginx dentro del contenedor escucha en el puerto **80**
- El dominio apunta a `http://checkin24hs_dashboard:80/`
- Pero EasyPanel puede estar intentando conectar al puerto **3000** debido a esta variable

## ✅ Solución

### Opción 1: Cambiar PORT a 80 (Recomendado)

1. En la pestaña "Entorno", cambia:
   ```
   PORT=3000
   ```
   Por:
   ```
   PORT=80
   ```

2. Haz clic en **"Guardar"** (botón verde)

3. Reinicia el servicio:
   - Ve a la pestaña "Resumen"
   - Haz clic en el icono de **"Reiniciar"** (flecha circular)

4. Espera 30-60 segundos

5. Prueba acceder a: `https://dashboard.checkin24hs.com/`

### Opción 2: Eliminar la Variable PORT

Si Nginx siempre escucha en el puerto 80 por defecto, puedes eliminar la variable completamente:

1. En la pestaña "Entorno", elimina la línea `PORT=3000`
2. Deja el editor vacío o sin esa variable
3. Haz clic en **"Guardar"**
4. Reinicia el servicio
5. Prueba acceder

---

## 🔍 ¿Por qué esto soluciona el problema?

La variable `PORT=3000` es un remanente de cuando el servicio usaba Node.js. Ahora que usamos Nginx:
- Nginx siempre escucha en el puerto **80** por defecto
- El dominio está configurado para apuntar al puerto **80**
- Pero EasyPanel puede estar usando la variable `PORT=3000` para determinar a qué puerto conectar

Al cambiar a `PORT=80` o eliminarla, EasyPanel usará el puerto correcto (80) que coincide con la configuración del dominio.

---

**Cambia `PORT=3000` a `PORT=80`, guarda, reinicia el servicio y prueba acceder.**
