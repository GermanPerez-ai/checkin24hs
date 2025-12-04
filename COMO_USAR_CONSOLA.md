# 🔧 Cómo Usar la Consola del Navegador

## 📋 Paso a Paso

### Paso 1: Abrir la Consola

**Presiona la tecla `F12` en tu teclado**

O también puedes:
- **Click derecho** en la página → **"Inspeccionar"** o **"Inspect"**
- Luego haz clic en la pestaña **"Console"** o **"Consola"**

---

### Paso 2: Verás una Ventana

En la parte inferior o derecha de la pantalla verás una ventana con texto. Esta es la **consola**.

---

### Paso 3: Escribir el Código

1. **Haz clic** en el área de texto de la consola (donde dice "Console" o hay un símbolo `>`)
2. **Escribe** exactamente esto (sin comillas):
   ```
   abrirModalImagenesDirecto('main')
   ```
3. **Presiona** la tecla `Enter`

---

### Paso 4: Ver el Resultado

Si funciona, verás mensajes en la consola y el modal debería aparecer en pantalla.

---

## 🆘 Si No Funciona

Ejecuta esto en la consola:

```javascript
const modal = document.getElementById('imageManagerModal');
if (modal) {
    modal.style.display = 'block';
    console.log('✅ Modal abierto');
} else {
    console.error('❌ Modal no existe');
}
```

---

## 📸 Imágenes de Ayuda

**La consola se ve así:**

```
┌─────────────────────────────────┐
│ Console                          │
├─────────────────────────────────┤
│ > _                              │  ← Aquí escribes el código
│                                 │
│ [mensajes de la página...]      │
└─────────────────────────────────┘
```

---

## ✅ Test Rápido

Para verificar que la consola funciona, escribe:

```
console.log('Hola')
```

Y presiona Enter. Deberías ver "Hola" en la consola.

