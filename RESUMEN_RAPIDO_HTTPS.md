# ⚡ Resumen Rápido: HTTPS con EasyPanel

## 🎯 Objetivo
Configurar HTTPS para 4 servicios WhatsApp en 10 minutos.

---

## 📝 Checklist

### ✅ Paso 1: DNS (5 minutos)
- [ ] Ir a Hostinger → DNS
- [ ] Agregar 4 registros A:
  - `api1` → `72.61.58.240`
  - `api2` → `72.61.58.240`
  - `api3` → `72.61.58.240`
  - `api4` → `72.61.58.240`
- [ ] Esperar 5-10 minutos

### ✅ Paso 2: EasyPanel (5 minutos)
Para cada servicio (`whatsapp`, `whatsapp2`, `whatsapp3`, `whatsapp4`):

- [ ] Servicio 1 (`whatsapp`):
  - [ ] Dominios → Agregar
  - [ ] Dominio: `api1.checkin24hs.com`
  - [ ] Puerto: `3001`
  - [ ] ✅ Activar SSL/TLS
  - [ ] Guardar

- [ ] Servicio 2 (`whatsapp2`):
  - [ ] Dominio: `api2.checkin24hs.com`
  - [ ] Puerto: `3002`
  - [ ] ✅ Activar SSL/TLS
  - [ ] Guardar

- [ ] Servicio 3 (`whatsapp3`):
  - [ ] Dominio: `api3.checkin24hs.com`
  - [ ] Puerto: `3003`
  - [ ] ✅ Activar SSL/TLS
  - [ ] Guardar

- [ ] Servicio 4 (`whatsapp4`):
  - [ ] Dominio: `api4.checkin24hs.com`
  - [ ] Puerto: `3004`
  - [ ] ✅ Activar SSL/TLS
  - [ ] Guardar

### ✅ Paso 3: Verificar (2 minutos)
- [ ] Abrir en navegador:
  - https://api1.checkin24hs.com
  - https://api2.checkin24hs.com
  - https://api3.checkin24hs.com
  - https://api4.checkin24hs.com
- [ ] Debe mostrar candado 🔒

---

## 🎉 Resultado Final

```
✅ https://api1.checkin24hs.com → Puerto 3001
✅ https://api2.checkin24hs.com → Puerto 3002
✅ https://api3.checkin24hs.com → Puerto 3003
✅ https://api4.checkin24hs.com → Puerto 3004
```

---

## 📖 Guía Detallada

Para instrucciones paso a paso completas, ver: `GUIA_HTTPS_EASYPANEL_PASO_A_PASO.md`

---

**Cuando termines, avísame y actualizamos el dashboard para usar HTTPS.**









