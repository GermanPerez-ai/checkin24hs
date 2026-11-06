# Número real del contacto (LID vs teléfono)

## Qué se hizo

1. **Servidor (whatsapp-server-baileys.js)**  
   - Se intenta **resolver LID a número real** cuando WhatsApp envía un JID tipo `280671952093251@lid` en lugar de `5492944411580@s.whatsapp.net`.  
   - Si Baileys expone el mapeo LID→número (API `getLIDMappingStore().getPNForLID()`), se usa ese número para:
     - Guardar en **whatsapp_chats.phone** y **whatsapp_messages.sender/recipient/phone**.
     - Actualizar chats que ya existían con LID para que pasen a tener el número real en `phone`.
   - Si la API no existe (Baileys &lt; 6.8) o no devuelve número, se sigue guardando el LID como hasta ahora.

2. **Dashboard (dashboard.html)**  
   - En Chats se muestra el **número del contacto** (quien envía/recibe), no el de Flor.  
   - Si el valor es número real (solo dígitos), se muestra con `+`.  
   - Si es un ID (ej. `@lid`), se muestra "ID: …" o "Número no disponible".

## Requisito para que aparezca el número real

- **Baileys 7.x** (actualizado desde 6.7.24): Incluye rework completo de LID/PN session mapping en el signal repository.
  - Soporte mejorado para `lidMapping` y manejo de sesiones Signal para cuentas LID-migrated.
  - Soluciona errores "Bad MAC", "No session found to decrypt message", "SessionError: No matching sessions" en línea 4.
  - La API `signalRepository.getLIDMappingStore().getPNForLID(lid)` está disponible.
- Con **Baileys 6.7.x** (versión anterior) esa API puede no existir completamente; causaba problemas de descifrado en cuentas LID-migrated.

## Cómo comprobar

1. Reiniciar el servidor WhatsApp (Baileys).  
2. Recibir un mensaje de un contacto que antes salía como LID.  
3. En Supabase, revisar **whatsapp_chats** y **whatsapp_messages**: si la resolución funcionó, `phone` y `sender`/`recipient` tendrán el número real (ej. `5492944411580`).  
4. En el dashboard, en Chats, debería mostrarse ese número con `+` debajo del nombre.

## Referencia

- [Baileys issue #1832](https://github.com/WhiskeySockets/Baileys/issues/1832) – LID vs @s.whatsapp.net.  
- WhatsApp no siempre expone el número real para todos los tipos de contacto (@lid); cuando no lo hace, no se puede guardar más que el ID.
