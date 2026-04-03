# Solucionar Autenticación de GitHub

## Problema

GitHub rechazó la autenticación porque:
- El token no es válido
- El token expiró
- El token no se copió correctamente
- GitHub ya no acepta contraseñas normales

## Solución

### Opción 1: Crear un Nuevo Token y Usarlo

1. **Crear un nuevo token:**
   - Ve a: https://github.com/settings/tokens
   - Click en "Generate new token" → "Generate new token (classic)"
   - Nombre: `Servidor Checkin24hs`
   - Expiración: `90 days` o `No expiration`
   - Permisos: Marca ✅ `repo` (Full control)
   - Click en "Generate token"
   - **COPIA el token completo** (solo se muestra una vez)

2. **Usar el token:**
   ```bash
   git push origin main
   ```
   - Username: `GermanPerez-ai`
   - Password: [Pega el token completo]

### Opción 2: Guardar el Token en Git Credential Helper (Recomendado)

Esto guardará el token para que no tengas que ingresarlo cada vez:

```bash
# Configurar Git para guardar credenciales
git config --global credential.helper store

# Ahora hacer push (te pedirá credenciales una vez)
git push origin main
# Username: GermanPerez-ai
# Password: [Tu token]

# Las próximas veces no te pedirá credenciales
```

### Opción 3: Usar SSH en lugar de HTTPS (Más Seguro)

```bash
# Generar clave SSH
ssh-keygen -t ed25519 -C "tu-email@ejemplo.com"
# Presiona Enter para aceptar ubicación por defecto
# Presiona Enter para no poner contraseña (o pon una si quieres)

# Ver la clave pública
cat ~/.ssh/id_ed25519.pub

# Copiar la salida completa y agregarla en GitHub:
# https://github.com/settings/keys
# Click en "New SSH key"
# Pega la clave y guarda

# Cambiar la URL remota a SSH
git remote set-url origin git@github.com:GermanPerez-ai/checkin24hs.git

# Ahora hacer push (no pedirá credenciales)
git push origin main
```

## Verificar Token Actual

Si creaste un token antes pero no funciona:

1. Ve a: https://github.com/settings/tokens
2. Verifica que el token exista y no haya expirado
3. Si expiró o no funciona, crea uno nuevo

## Errores Comunes

### "Invalid username or token"
- El token no es válido o expiró
- Solución: Crea un nuevo token

### "Password authentication is not supported"
- Estás usando tu contraseña normal en lugar del token
- Solución: Usa un Personal Access Token

### El token parece no funcionar
- Verifica que copiaste el token completo (es muy largo)
- Verifica que el token tenga permisos `repo`
- Verifica que el token no haya expirado


