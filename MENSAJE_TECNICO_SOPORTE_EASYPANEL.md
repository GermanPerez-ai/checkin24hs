# 📧 Mensaje Técnico para Soporte de EasyPanel

## 🎯 Mensaje Completo

```
Hola,

Gracias por la respuesta anterior. He investigado más a fondo y el problema 
NO es la configuración del servidor. El servicio está funcionando 
perfectamente.

PROBLEMA REAL:

EasyPanel genera automáticamente el destino del dominio usando guión bajo:
- Genera: http://checkin24hs_dashboard:3000/ (con guión bajo)

Pero Docker Swarm crea aliases con guión:
- Alias real: checkin24hs-dashboard (con guión)
- También existe: dashboard

EVIDENCIA TÉCNICA:

1. Servicio funcionando correctamente:
   - docker exec <container> ps aux | grep node
   - Resultado: node server.js (proceso corriendo)
   - docker exec <container> netstat -tlnp | grep 3000
   - Resultado: tcp 0.0.0.0:3000 LISTEN (escuchando correctamente)

2. Aliases reales del servicio:
   - docker service inspect checkin24hs_dashboard --format '{{json .Spec.TaskTemplate.Networks}}' | jq
   - Resultado: ["checkin24hs-dashboard", "dashboard"] (con guión, NO guión bajo)

3. El proxy (Traefik) intenta conectar a checkin24hs_dashboard (guión bajo) 
   pero ese alias no existe, solo existe checkin24hs-dashboard (guión).

SOLICITUD:

Necesito una de estas opciones:
1. Poder especificar el alias manualmente en la configuración del dominio
2. Que EasyPanel use guiones en lugar de guiones bajos al generar el destino
3. Poder editar el destino del dominio manualmente después de crearlo

Stack: Docker Swarm, Node.js, EasyPanel con Traefik como proxy inverso.
Servicio: dashboard en proyecto checkin24hs
```

---

## 📋 Información Adicional para Incluir

Si el soporte pregunta más detalles, puedes compartir:

- **Nombre del servicio**: `dashboard`
- **Nombre del proyecto**: `checkin24hs`
- **Puerto interno**: `3000`
- **Tipo de servicio**: Node.js
- **Comando**: `node server.js`
- **Aliases reales**: `checkin24hs-dashboard` (guión) y `dashboard`
- **Destino generado por EasyPanel**: `http://checkin24hs_dashboard:3000/` (guión bajo)

---

**Copia y pega este mensaje al soporte de EasyPanel. Esto debería ayudarles a entender el problema real.**
