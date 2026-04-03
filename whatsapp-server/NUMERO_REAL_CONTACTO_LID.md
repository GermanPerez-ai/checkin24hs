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

- **Baileys 6.8 o superior** suele exponer `signalRepository.getLIDMappingStore().getPNForLID(lid)`.  
- Con **Baileys 6.7.x** (como en tu `package.json`: `^6.7.4`) esa API puede no existir; en ese caso:
  - Opción A: Actualizar a `@whiskeysockets/baileys@^6.8.0` o superior y reiniciar el servidor.  
  - Opción B: Dejar como está; se seguirá guardando el LID y en el dashboard seguirá "Número no disponible" o "ID: …" para esos contactos.

## Cómo comprobar

1. Reiniciar el servidor WhatsApp (Baileys).  
2. Recibir un mensaje de un contacto que antes salía como LID.  
3. En Supabase, revisar **whatsapp_chats** y **whatsapp_messages**: si la resolución funcionó, `phone` y `sender`/`recipient` tendrán el número real (ej. `5492944411580`).  
4. En el dashboard, en Chats, debería mostrarse ese número con `+` debajo del nombre.

## Referencia

- [Baileys issue #1832](https://github.com/WhiskeySockets/Baileys/issues/1832) – LID vs @s.whatsapp.net.  
- WhatsApp no siempre expone el número real para todos los tipos de contacto (@lid); cuando no lo hace, no se puede guardar más que el ID.
