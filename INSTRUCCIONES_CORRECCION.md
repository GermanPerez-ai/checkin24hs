# 🔧 Corrección Final: Nombres de Tablas

## ⚠️ Problema Detectado

Veo que ejecutaste el script de renombrado, pero algunas tablas quedaron con nombres incorrectos:

| ❌ Nombre Actual Incorrecto | ✅ Nombre Correcto Esperado |
|---------------------------|---------------------------|
| `costs` | `expenses` |
| `usuarios_del_sistema` | `system_users` |

El código JavaScript espera estos nombres exactos en inglés.

---

## ✅ Solución: Script de Corrección

He creado un script SQL que corrige estos nombres. Está en el archivo: **`corregir-nombres-tablas.sql`**

### Pasos:

1. **Abre el archivo** `corregir-nombres-tablas.sql` (ya lo abrí en Notepad)
2. **Copia todo** (`Ctrl+A`, luego `Ctrl+C`)
3. **Ve a Supabase SQL Editor**
4. **Pega el SQL** (`Ctrl+V`)
5. **Ejecuta** (botón "Run" o `Ctrl+Enter`)

---

## 📋 Verificación Final

Después de ejecutar el script, ve al **Table Editor** y deberías ver estas 6 tablas con estos nombres exactos:

- ✅ `hotels`
- ✅ `reservations`
- ✅ `quotes`
- ✅ `expenses` (no `costs`)
- ✅ `system_users` (no `usuarios_del_sistema`)
- ✅ `dashboard_admins`

---

## 🎯 Importante

Estos nombres DEBEN coincidir exactamente con lo que espera el código JavaScript. Si no coinciden, el dashboard no podrá guardar datos en Supabase.

¡Avísame cuando ejecutes el script de corrección! 🚀

