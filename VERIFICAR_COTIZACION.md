# 🔍 Cómo Verificar una Cotización Recién Enviada

## 📋 Pasos para Encontrar tu Cotización

### 1️⃣ Verificar en el Dashboard

1. **Abre el Dashboard**
   - Ve a la sección **"Cotizaciones"** en el menú lateral

2. **Actualizar la lista**
   - Haz clic en el botón **"Actualizar"** (ícono de refresh 🔄)
   - O recarga la página (F5)

3. **Buscar en la tabla**
   - Usa el cuadro de búsqueda en la parte superior
   - Busca por:
     - Nombre del cliente
     - Código de la cotización (si tiene)
     - Hotel
     - Fecha

4. **Verificar la consola del navegador**
   - Presiona `F12` para abrir las herramientas de desarrollador
   - Ve a la pestaña **"Console"**
   - Busca mensajes como:
     - `✅ Cotización guardada en localStorage:`
     - `✅ Cotización guardada en Supabase:`
     - `📋 Cargando tabla de cotizaciones...`

---

### 2️⃣ Verificar en localStorage (Navegador)

1. **Abre la consola del navegador** (F12)

2. **Ejecuta este comando:**
   ```javascript
   const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
   console.log('Total de cotizaciones:', quotes.length);
   console.log('Últimas 5 cotizaciones:', quotes.slice(-5));
   ```

3. **Buscar por código o nombre:**
   ```javascript
   const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
   const ultima = quotes[quotes.length - 1];
   console.log('Última cotización:', ultima);
   ```

4. **Buscar por código específico:**
   ```javascript
   const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
   const encontrada = quotes.find(q => q.code === 'TU_CODIGO_AQUI');
   console.log('Cotización encontrada:', encontrada);
   ```

---

### 3️⃣ Verificar en Supabase

1. **Accede a Supabase:**
   - Ve a https://app.supabase.com
   - Selecciona tu proyecto
   - Ve a **"Table Editor"** → **"quotes"**

2. **O ejecuta esta consulta SQL:**
   ```sql
   SELECT 
       id,
       code,
       customer_name,
       customer_phone,
       status,
       created_at
   FROM quotes
   ORDER BY created_at DESC
   LIMIT 10;
   ```

3. **Buscar por código:**
   ```sql
   SELECT *
   FROM quotes
   WHERE code = 'TU_CODIGO_AQUI';
   ```

4. **Buscar por teléfono:**
   ```sql
   SELECT *
   FROM quotes
   WHERE customer_phone LIKE '%NUMERO_TELEFONO%'
   ORDER BY created_at DESC;
   ```

---

### 4️⃣ Verificar Logs en la Consola

1. **Abre la consola** (F12 → Console)

2. **Busca estos mensajes:**
   - `📋 Creando y enviando cotización...`
   - `✅ Cotización guardada en localStorage:`
   - `✅ Cotización guardada en Supabase:`
   - `📋 Cargando tabla de cotizaciones...`
   - `✅ X cotizaciones cargadas desde Supabase`

3. **Si hay errores, busca:**
   - `❌ Error creando cotización:`
   - `⚠️ Error guardando en Supabase:`

---

## 🚨 Problemas Comunes y Soluciones

### ❌ No aparece en el Dashboard

**Posibles causas:**
1. **No se recargó la tabla**
   - Solución: Haz clic en "Actualizar" o recarga la página

2. **Error al guardar**
   - Solución: Revisa la consola del navegador (F12) para ver errores

3. **Filtro activo**
   - Solución: Limpia el cuadro de búsqueda

4. **Supabase no configurado**
   - Solución: Verifica que Supabase esté inicializado correctamente

### ❌ No se guardó en Supabase

**Verificar:**
```javascript
// En la consola del navegador
if (window.supabaseClient && window.supabaseClient.isInitialized) {
    console.log('✅ Supabase está inicializado');
    window.supabaseClient.isInitialized().then(result => {
        console.log('Estado de Supabase:', result);
    });
} else {
    console.log('❌ Supabase no está disponible');
}
```

**Si Supabase no está inicializado:**
- Verifica que `supabase-config.js` esté configurado
- Verifica que `supabase-client.js` esté cargado
- Revisa la consola para errores de carga

### ❌ Aparece en localStorage pero no en Supabase

**Solución:**
1. La cotización se guardó correctamente en localStorage (respaldo)
2. Para sincronizarla con Supabase, ejecuta:
   ```javascript
   // En la consola del navegador
   const quotes = JSON.parse(localStorage.getItem('quotesDB') || '[]');
   const ultima = quotes[quotes.length - 1];
   if (window.supabaseClient && window.supabaseClient.isInitialized()) {
       window.supabaseClient.createQuote(ultima)
           .then(() => console.log('✅ Sincronizada con Supabase'))
           .catch(err => console.error('❌ Error:', err));
   }
   ```

---

## ✅ Checklist de Verificación

- [ ] ¿Aparece en la tabla del Dashboard?
- [ ] ¿Está en localStorage? (verificar con consola)
- [ ] ¿Está en Supabase? (verificar con SQL Editor)
- [ ] ¿Tiene código generado? (si es nueva)
- [ ] ¿Hay errores en la consola?
- [ ] ¿Supabase está inicializado?

---

## 📞 Si Aún No la Encuentras

1. **Comparte estos datos:**
   - Mensajes de la consola (F12 → Console)
   - Si aparece en localStorage (ejecuta el código de verificación)
   - Si aparece en Supabase (ejecuta la consulta SQL)

2. **Información útil:**
   - ¿Desde dónde la enviaste? (cotizador-cliente o dashboard)
   - ¿Qué datos ingresaste? (nombre, teléfono, hotel)
   - ¿Viste algún mensaje de éxito o error?
