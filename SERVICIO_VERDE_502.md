# ✅ Servicio en Verde pero Error 502

## 🎉 Estado Actual

El servicio **webmail** está:
- ✅ **Punto verde** (corriendo)
- ✅ **Memoria en uso**: 23.0 MB
- ✅ **Actividad de red**: 474.5 KB / 78.2 KB
- ⚠️ **Error 502** (Bad Gateway)

## 🔍 Qué Significa

El contenedor está corriendo, pero:
- Apache/Roundcube puede estar aún iniciando
- El puerto puede no estar completamente listo
- Hay un problema de conexión entre Nginx y el contenedor

## ✅ Soluciones

### Solución 1: Esperar un Momento (Más Probable)

Roundcube puede tardar 1-2 minutos en iniciar completamente:

1. **Espera 1-2 minutos más**
2. **Actualiza la página** del webmail (F5 o Ctrl+R)
3. El error 502 debería desaparecer cuando Roundcube termine de iniciar

### Solución 2: Verificar los Logs

1. Ve a **"Registros"** y actualiza
2. Busca mensajes como:
   - `Server started` o `Ready` → Roundcube está listo
   - `Starting Apache` → Aún está iniciando
   - `AH00558: apache2: Could not reliably determine the server's fully qualified domain name` → Normal, no es un error
   - `Listening on port 80` → Apache está escuchando

### Solución 3: Verificar el Puerto

1. Ve a **"Dominios"**
2. Verifica que el puerto sea `8080` (o el que configuraste)
3. Si es diferente, verifica que coincida con la configuración del contenedor

### Solución 4: Reiniciar el Servicio

Si después de 2-3 minutos sigue en 502:

1. Haz clic en el botón de **refresh/restart** (flecha circular)
2. Espera 1-2 minutos
3. Intenta acceder de nuevo

### Solución 5: Verificar la Configuración del Proxy

1. Ve a **"Dominios"**
2. Verifica que:
   - **Protocolo**: `HTTP`
   - **Puerto**: `8080` (o el que configuraste)
   - **Ruta**: `/`

## 🎯 Pasos Inmediatos

1. ✅ **Espera 1-2 minutos** (Roundcube puede estar iniciando)
2. ✅ **Actualiza la página** del webmail (F5)
3. ✅ **Revisa los logs** para ver si Apache está completamente iniciado
4. ✅ Si sigue en 502, **reinicia el servicio** (botón refresh)

## 📋 Qué Buscar en los Logs

Si ves estos mensajes en los logs, Roundcube está iniciando correctamente:

```
AH00558: apache2: Could not reliably determine the server's fully qualified domain name
Apache/2.4.x (Debian) configured -- resuming normal operations
```

Si ves errores como:
- `Port already in use`
- `Cannot bind to address`
- `Permission denied`

Entonces hay un problema de configuración.

## 💡 Nota Importante

El hecho de que:
- ✅ El punto esté en verde
- ✅ Haya memoria en uso (23 MB)
- ✅ Haya actividad de red

Significa que el contenedor **está funcionando**. El error 502 probablemente desaparecerá en 1-2 minutos cuando Roundcube termine de iniciar completamente.

## 🆘 Si Sigue en 502 Después de 3-5 Minutos

1. **Revisa los logs** y comparte los últimos mensajes
2. **Reinicia el servicio** (botón refresh)
3. **Verifica el puerto** en "Dominios"
4. **Intenta acceder** desde otro navegador o en modo incógnito

