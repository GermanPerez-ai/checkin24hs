# 🔍 Script para Verificar Hoteles en Flor IA

## 📋 Ejecuta este código en la consola del navegador

1. **Presiona `F12`** para abrir las herramientas de desarrollador
2. **Ve a la pestaña "Console"**
3. **Copia y pega este código completo:**

```javascript
// Script completo para verificar y cargar hoteles en Flor IA
(async function() {
    console.log('🔍 Iniciando verificación de hoteles...');
    
    // 1. Verificar que la función existe
    console.log('1. Función loadHotelsForFlor existe?', typeof loadHotelsForFlor);
    
    // 2. Verificar que Supabase está disponible
    console.log('2. Supabase disponible?', typeof window.supabaseClient !== 'undefined');
    console.log('3. getHotels disponible?', typeof window.supabaseClient?.getHotels === 'function');
    
    // 3. Cargar hoteles directamente desde Supabase
    let hotels = [];
    try {
        if (window.supabaseClient && typeof window.supabaseClient.getHotels === 'function') {
            console.log('4. Cargando hoteles desde Supabase...');
            hotels = await window.supabaseClient.getHotels();
            console.log('5. Hoteles cargados:', hotels.length);
            console.log('6. Lista de hoteles:', hotels.map(h => h.name || h.nombre));
        }
    } catch (error) {
        console.error('❌ Error cargando hoteles:', error);
    }
    
    // 4. Verificar selectores
    const knowledgeSelector = document.getElementById('knowledge-hotel-selector');
    const policySelector = document.getElementById('policy-hotel-select');
    
    console.log('7. Selector conocimiento existe?', knowledgeSelector !== null);
    console.log('8. Selector políticas existe?', policySelector !== null);
    
    // 5. Si los selectores existen, actualizarlos manualmente
    if (knowledgeSelector || policySelector) {
        const selectors = [];
        if (knowledgeSelector) selectors.push({ id: 'knowledge-hotel-selector', element: knowledgeSelector });
        if (policySelector) selectors.push({ id: 'policy-hotel-select', element: policySelector });
        
        // Filtrar solo hoteles activos
        const activeHotels = hotels.filter(hotel => hotel.active !== false && hotel.activo !== false);
        console.log('9. Hoteles activos:', activeHotels.length);
        
        // Actualizar cada selector
        selectors.forEach(({ id, element }) => {
            console.log(`10. Actualizando selector: ${id}`);
            element.innerHTML = '<option value="">-- Seleccione un hotel --</option>';
            activeHotels.forEach(hotel => {
                const option = document.createElement('option');
                option.value = hotel.id;
                option.textContent = hotel.name || hotel.nombre || 'Hotel sin nombre';
                element.appendChild(option);
            });
            console.log(`11. ✅ Selector ${id} actualizado con ${activeHotels.length} hoteles`);
        });
        
        console.log('✅ VERIFICACIÓN COMPLETA');
        console.log(`📊 Total hoteles: ${hotels.length}`);
        console.log(`📊 Hoteles activos: ${activeHotels.length}`);
        console.log(`📊 Selectores actualizados: ${selectors.length}`);
    } else {
        console.warn('⚠️ Los selectores no existen. ¿Estás en la pestaña correcta?');
        console.warn('   Ve a: Flor IA → Pestaña "Conocimiento" o "Políticas"');
    }
})();
```

---

## ✅ Qué deberías ver

Si todo funciona correctamente, deberías ver:

```
🔍 Iniciando verificación de hoteles...
1. Función loadHotelsForFlor existe? function
2. Supabase disponible? true
3. getHotels disponible? true
4. Cargando hoteles desde Supabase...
5. Hoteles cargados: 8
6. Lista de hoteles: ['Llao Llao', 'Amonite Apart y Spa', ...]
7. Selector conocimiento existe? true
8. Selector políticas existe? true
9. Hoteles activos: 8
10. Actualizando selector: knowledge-hotel-selector
11. ✅ Selector knowledge-hotel-selector actualizado con 8 hoteles
10. Actualizando selector: policy-hotel-select
11. ✅ Selector policy-hotel-select actualizado con 8 hoteles
✅ VERIFICACIÓN COMPLETA
📊 Total hoteles: 8
📊 Hoteles activos: 8
📊 Selectores actualizados: 2
```

---

## 🎯 Después de ejecutar el script

1. **Ve a la pestaña "Conocimiento"** en Flor IA
2. **Haz clic en el dropdown** "Seleccione un hotel"
3. **Deberías ver tus 8 hoteles listados**

---

## 🆘 Si no ves los hoteles

### Verificación 1: ¿Estás en la pestaña correcta?

- Debes estar en: **Flor IA** → Pestaña **"📚 Conocimiento"**
- O en: **Flor IA** → Pestaña **"📋 Políticas"**

### Verificación 2: ¿Los selectores existen?

Ejecuta en la consola:

```javascript
document.getElementById('knowledge-hotel-selector')
```

Si devuelve `null`, no estás en la pestaña correcta.

### Verificación 3: ¿Hay hoteles activos?

Ejecuta en la consola:

```javascript
window.supabaseClient.getHotels().then(hotels => {
    const active = hotels.filter(h => h.active !== false);
    console.log('Hoteles activos:', active.length);
    console.log('Lista:', active.map(h => h.name || h.nombre));
});
```

---

**¡Ejecuta el script y dime qué resultado obtienes!** 🚀


