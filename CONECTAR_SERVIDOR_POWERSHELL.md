# 🔌 Conectar al Servidor desde PowerShell

## Método 1: SSH Directo (Recomendado)

### Paso 1: Abrir PowerShell
- Presiona `Win + X` y selecciona "Windows PowerShell" o "Terminal"
- O busca "PowerShell" en el menú de inicio

### Paso 2: Conectarte por SSH
```powershell
ssh root@72.61.58.240
```

### Paso 3: Ingresar contraseña
- Te pedirá la contraseña del servidor
- Al escribir la contraseña, **no verás caracteres** (es normal por seguridad)
- Presiona Enter después de escribirla

---

## Método 2: SSH con Puerto Específico (si es necesario)

Si el servidor usa un puerto diferente al 22:
```powershell
ssh -p 22 root@72.61.58.240
```

---

## Método 3: SSH con Clave Privada

Si tienes una clave SSH configurada:
```powershell
ssh -i ruta/a/tu/clave_privada root@72.61.58.240
```

---

## Comandos Útiles una vez Conectado

### Ver estado de PM2
```bash
pm2 status
```

### Ver logs del dashboard
```bash
pm2 logs dashboard --lines 50 --nostream
```

### Actualizar código desde GitHub
```bash
cd ~/checkin24hs
git pull origin main
pm2 restart dashboard
```

### Salir del servidor
```bash
exit
```

---

## Solución de Problemas

### Error: "ssh: command not found"
**Solución:** Instala OpenSSH en Windows:
1. Configuración → Aplicaciones → Características opcionales
2. Busca "OpenSSH Client" e instálalo

### Error: "Permission denied"
**Solución:** Verifica que estás usando el usuario correcto (`root`) y la contraseña correcta

### Error: "Connection timed out"
**Solución:** 
- Verifica que la IP es correcta: `72.61.58.240`
- Verifica que el firewall permite conexiones SSH (puerto 22)
- Verifica que el servidor está encendido

---

## Ejemplo Completo

```powershell
# 1. Abrir PowerShell
# 2. Conectarte
ssh root@72.61.58.240

# 3. Ingresar contraseña (no verás caracteres)
# 4. Una vez conectado, ejecutar:
cd ~/checkin24hs
git pull origin main
pm2 restart dashboard
pm2 status

# 5. Salir cuando termines
exit
```

---

## 💡 Tip: Guardar Conexión

Puedes crear un alias en PowerShell para conectarte más rápido:

```powershell
# Agregar al perfil de PowerShell (ejecutar una vez)
notepad $PROFILE

# Agregar esta línea:
function Connect-Server { ssh root@72.61.58.240 }

# Guardar y cerrar
# Luego solo ejecuta:
Connect-Server
```


