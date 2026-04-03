# ⚠️ Corrección: Usar "Agregar montaje de enlace"

## 🔍 Problema

El modal que estás viendo ("Crear montaje de archivo") es para **crear un archivo nuevo** desde la interfaz de EasyPanel, no para montar un archivo existente del host.

## ✅ Solución Correcta

Debes usar **"Agregar montaje de enlace"** (la primera opción) en lugar de "Agregar montaje de archivo".

---

## 📝 Pasos Correctos

### 1. Cierra el Modal Actual

Haz clic en la **"X"** en la esquina superior derecha para cerrar el modal "Crear montaje de archivo".

### 2. Haz Clic en "Agregar montaje de enlace"

De las tres opciones en "Puntos de montaje":
- ✅ **"Agregar montaje de enlace"** ← **USA ESTA** (primera opción)
- ❌ "Agregar montaje de volumen"
- ❌ "Agregar montaje de archivo"

### 3. Configura el Bind Mount

El modal de "montaje de enlace" debería tener campos diferentes:
- **Ruta del host (Source/Host Path):** `/root/checkin24hs/dashboard.html`
- **Ruta del contenedor (Destination/Container Path):** `/app/dashboard.html`

---

## 💡 Diferencia

- **"Agregar montaje de archivo":** Crea un archivo nuevo desde la interfaz
- **"Agregar montaje de enlace":** Monta un archivo/directorio existente del host en el contenedor (lo que necesitas)

---

**Cierra el modal actual y haz clic en "Agregar montaje de enlace" en su lugar.**
