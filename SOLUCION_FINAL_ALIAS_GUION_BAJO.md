# 🔧 Solución Final: Agregar Alias con Guión Bajo

## 🎯 Problema Confirmado

- EasyPanel genera: `http://checkin24hs_dashboard:80/` (guión bajo)
- Alias real: `checkin24hs-dashboard` (guión)
- 404 persistente

## ✅ Solución: Modificar Servicio Docker con Configuración Completa

Docker Swarm no permite agregar aliases fácilmente, pero podemos intentar recrear las redes con todos los aliases.

### Opción 1: Usar docker service update con sintaxis correcta

En el servidor, ejecuta:

```bash
# Obtener nombres de las redes (no solo IDs)
docker network ls | grep -E "xmv09tpxwryie79b0jv531623|nvhtv52umzihypz8u7adejvpo"
```

Luego intenta:

```bash
# Para la primera red
docker service update \
  --network-rm xmv09tpxwryie79b0jv531623 \
  --network-add name=xmv09tpxwryie79b0jv531623,alias=checkin24hs-dashboard,alias=checkin24hs_dashboard \
  checkin24hs_dashboard
```

**Nota**: Esta sintaxis puede no funcionar. Docker Swarm tiene limitaciones para modificar aliases después de crear el servicio.

### Opción 2: Recrear el Servicio Completamente (Recomendado)

La forma más confiable es recrear el servicio con la configuración correcta desde el inicio:

1. **En EasyPanel**:
   - Elimina el servicio `dashboard` actual
   - Crea un nuevo servicio con un nombre que genere el alias correcto

2. **O renombra el servicio** a algo que funcione:
   - Si renombras el servicio a `dash` o `app`, EasyPanel generaría `checkin24hs_dash` o `checkin24hs_app`
   - Pero necesitaríamos verificar qué alias se crea

### Opción 3: Contactar Soporte de EasyPanel

Si nada funciona, contacta soporte de EasyPanel con:
- El problema: EasyPanel genera `checkin24hs_dashboard` (guión bajo) pero el alias real es `checkin24hs-dashboard` (guión)
- Solicita: Opción para especificar el alias manualmente o que EasyPanel use guiones en lugar de guiones bajos

---

## 🎯 Recomendación Final

**Intenta primero la Opción 2**: Elimina el servicio actual y créalo de nuevo, pero esta vez:

1. **Renombra el servicio** a algo simple como `dash` o `app`
2. Verifica qué alias se crea en Docker
3. Configura el dominio para que use ese alias

O si prefieres mantener el nombre `dashboard`, necesitarías que EasyPanel permita especificar el alias manualmente, lo cual puede requerir contacto con soporte.

---

**¿Quieres intentar recrear el servicio con un nombre diferente, o prefieres contactar soporte de EasyPanel?**
