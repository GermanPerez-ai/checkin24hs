# 🧹 Limpiar localStorage del Navegador

## 🎯 Problema

El `localStorage` del navegador está lleno, causando errores `QuotaExceededError`. Esto puede afectar la carga de datos en el dashboard.

## ✅ Solución: Limpiar localStorage

### Opción 1: Desde la Consola del Navegador (Recomendado)

1. **Presiona `F12`** para abrir las herramientas de desarrollador
2. **Ve a la pestaña "Console"**
3. **Ejecuta este comando:**

```javascript
// Limpiar solo datos específicos (recomendado)
localStorage.removeItem('hotelsDB');
localStorage.removeItem('reservationsDB');
localStorage.removeItem('usersDB');
localStorage.removeItem('quotesDB');
localStorage.removeItem('expensesDB');

// O limpiar TODO (más agresivo)
localStorage.clear();

console.log('✅ localStorage limpiado');
```

4. **Recarga la página** (`F5`)

### Opción 2: Limpiar Todo el localStorage

Si quieres limpiar TODO:

```javascript
localStorage.clear();
sessionStorage.clear();
location.reload();
```

---

## 🔍 Verificar Espacio Disponible

Para ver cuánto espacio está usando localStorage:

```javascript
let total = 0;
for (let key in localStorage) {
    if (localStorage.hasOwnProperty(key)) {
        total += localStorage[key].length + key.length;
    }
}
console.log(`Espacio usado: ${(total / 1024).toFixed(2)} KB`);
console.log(`Límite aproximado: 5-10 MB`);
```

---

## ⚠️ Advertencia

**NO limpies localStorage si:**
- Tienes datos importantes guardados localmente
- No tienes conexión a Supabase
- Necesitas datos offline

**SÍ limpia localStorage si:**
- Ves errores de `QuotaExceededError`
- El dashboard está lento
- Los datos se cargan desde Supabase de todas formas

---

## 🎯 Después de Limpiar

1. **Recarga el dashboard** (`F5`)
2. **Ve a Flor IA → Conocimiento**
3. **Deberías ver los hoteles en el dropdown**
4. **Los datos se cargarán automáticamente desde Supabase**

---

**¡Ejecuta el comando en la consola y recarga la página!** 🚀


