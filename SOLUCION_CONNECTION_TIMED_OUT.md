# 🔧 Solución: ERR_CONNECTION_TIMED_OUT

## 🎯 Problema

El puerto 30002 no es accesible desde fuera del servidor. Esto puede ser por:
1. Firewall bloqueando el puerto
2. El puerto no está correctamente publicado
3. Problema de configuración de red

## ✅ Solución 1: Verificar Configuración del Puerto en EasyPanel

### Paso 1: Verificar Puerto Publicado

1. En EasyPanel, ve a la pestaña **"Puertos"**
2. Verifica que el puerto `30002` esté configurado como:
   - **Protocolo**: `tcp` o `HTTP`
   - **Publicado**: `30002`
   - **Destino**: `80`

### Paso 2: Verificar que el Servicio Esté en Verde

1. Verifica que el servicio `dashboard` esté en **verde** (running)
2. Si está amarillo o rojo, hay un problema con el servicio

---

## ✅ Solución 2: Probar desde el Servidor (Si tienes SSH)

Si tienes acceso SSH, prueba desde dentro del servidor:

```bash
# Conectarse al servidor
ssh root@72.61.58.240

# Probar acceso local
curl http://localhost:30002/

# O probar desde dentro del contenedor
docker ps | grep dashboard
docker exec <container_id> curl http://localhost/
```

Si esto funciona, el problema es el firewall o la configuración de red.

---

## ✅ Solución 3: Verificar Firewall

El puerto 30002 puede estar bloqueado por el firewall. Necesitas:

1. **Abrir el puerto en el firewall del servidor**
2. O **usar el dominio** que ya está configurado (más simple)

---

## ✅ Solución 4: Usar el Dominio (Recomendado)

En lugar de usar el puerto directo, usa el dominio que ya está configurado:

1. El dominio `dashboard.checkin24hs.com` ya está configurado
2. Debería funcionar a través del proxy (Traefik)
3. Prueba: `https://dashboard.checkin24hs.com/`

Si el dominio tampoco funciona, el problema puede ser:
- El nombre del servicio interno no coincide
- El proxy no está enrutando correctamente
- Hay un problema con la configuración del dominio

---

## 🔍 Verificación: Nombre del Servicio

El dominio apunta a: `http://checkin24hs_dashboard:80/`

Verifica que el nombre del servicio sea exactamente `checkin24hs_dashboard`:

1. En EasyPanel, ve al servicio `dashboard`
2. Busca el nombre del servicio (puede estar en la URL o en la configuración)
3. Debe coincidir exactamente con `checkin24hs_dashboard`

---

## 📋 Próximos Pasos

1. **Probar el dominio**: `https://dashboard.checkin24hs.com/`
2. **Si no funciona**, verificar el nombre del servicio interno
3. **Si tienes SSH**, probar acceso local para confirmar que nginx funciona

---

¿Puedes probar acceder a `https://dashboard.checkin24hs.com/` y decirme qué pasa?
