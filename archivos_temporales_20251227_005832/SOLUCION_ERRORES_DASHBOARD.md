# Solución para Errores del Dashboard

## Problemas Identificados

1. **`SyntaxError: Invalid or unexpected token` (línea 5150)**
   - **Causa:** Emojis en los `console.log` están causando errores de sintaxis
   - **Solución:** Eliminar todos los emojis de los `console.log`

2. **`window.showSection is not a function`**
   - **Causa:** La función `showSection` puede no estar disponible cuando se llama desde `onclick`
   - **Solución:** Verificar que `showSection` esté definida en el `<head>` antes de cualquier otro código

## Correcciones Aplicadas Localmente

✅ Se eliminaron emojis de múltiples `console.log` en el archivo local
✅ `showSection` está correctamente definida en las líneas 6-19 del `<head>`

## Pasos para Aplicar en el Servidor

### Opción 1: Usar el Script de Corrección (Recomendado)

1. **Subir el script al servidor:**
   ```bash
   scp CORREGIR_ERRORES_DASHBOARD.sh root@72.61.58.240:/root/checkin24hs/
   ```

2. **Ejecutar el script en el servidor:**
   ```bash
   ssh root@72.61.58.240
   cd /root/checkin24hs
   chmod +x CORREGIR_ERRORES_DASHBOARD.sh
   ./CORREGIR_ERRORES_DASHBOARD.sh
   ```

3. **Copiar el archivo corregido al contenedor:**
   ```bash
   CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
   docker cp /root/checkin24hs/dashboard.html ${CONTAINER_ID}:/app/dashboard.html
   docker service update --force checkin24hs_dashboard
   
   # Esperar a que el servicio se reinicie
   sleep 30
   
   # Copiar de nuevo al nuevo contenedor
   NEW_CONTAINER_ID=$(docker ps | grep checkin24hs_dashboard | awk '{print $1}' | head -1)
   docker cp /root/checkin24hs/dashboard.html ${NEW_CONTAINER_ID}:/app/dashboard.html
   ```

### Opción 2: Subir el Archivo Local Corregido

1. **Subir el archivo local al servidor:**
   ```bash
   scp dashboard.html root@72.61.58.240:/root/checkin24hs/
   ```

2. **Aplicar al contenedor (mismos comandos que arriba)**

## Verificación

Después de aplicar las correcciones:

1. **Abrir el dashboard en el navegador:**
   - `http://dashboard.checkin24hs.com`

2. **Abrir DevTools (F12) y verificar:**
   - No debe haber `SyntaxError` en la línea 5150
   - No debe haber `window.showSection is not a function`
   - Los botones del menú deben funcionar correctamente

3. **Verificar en la consola:**
   - Los `console.log` no deben tener emojis
   - `window.showSection` debe estar definida

## Notas Importantes

- El archivo en el servidor puede tener más líneas que el local (el error menciona líneas 23012-23013 que no existen localmente)
- Los cambios con `docker cp` son temporales y se pierden al recrear el contenedor
- Para una solución permanente, el archivo corregido debe estar en GitHub y reconstruirse la imagen Docker

## Definición de showSection

La función `showSection` está definida en el `<head>` del archivo (líneas 6-19):

```javascript
window.showSection = function(section, event) {
    try {
        if (event && event.preventDefault) event.preventDefault();
        var sections = document.querySelectorAll('[id$="-section"]');
        for (var i = 0; i < sections.length; i++) sections[i].style.display = 'none';
        var target = document.getElementById(section + '-section');
        if (target) {
            target.style.display = 'block';
            var items = document.querySelectorAll('.menu-item');
            for (var j = 0; j < items.length; j++) items[j].classList.remove('active');
            if (event && event.target) event.target.classList.add('active');
        }
    } catch(e) { console.error('showSection error:', e); }
};
```

Esta definición está en el `<head>`, por lo que debería estar disponible antes de que se ejecute cualquier código en el `<body>`.


