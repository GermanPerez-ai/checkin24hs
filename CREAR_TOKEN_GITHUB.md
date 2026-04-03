# 🔐 Cómo Crear un Personal Access Token de GitHub

## 📋 Pasos para Crear el Token

### Paso 1: Ir a Configuración de GitHub
1. Abre tu navegador y ve a: **https://github.com**
2. Inicia sesión con tu cuenta (`GermanPerez-ai`)
3. Haz clic en tu **avatar** (esquina superior derecha)
4. Selecciona **"Settings"** (Configuración)

### Paso 2: Ir a Developer Settings
1. En el menú lateral izquierdo, desplázate hacia abajo
2. Haz clic en **"Developer settings"** (al final del menú)

### Paso 3: Crear Personal Access Token
1. En el menú lateral izquierdo, haz clic en **"Personal access tokens"**
2. Selecciona **"Tokens (classic)"** o **"Fine-grained tokens"**
   - **Recomendado**: "Tokens (classic)" es más simple
3. Haz clic en **"Generate new token"** → **"Generate new token (classic)"**

### Paso 4: Configurar el Token
1. **Note** (Nota): Escribe algo descriptivo como:
   - `Servidor Checkin24hs - Git Push`
   - `Deploy Scripts`
   
2. **Expiration** (Expiración): Selecciona:
   - **90 days** (90 días) - Recomendado
   - O **No expiration** (Sin expiración) - Solo si es seguro

3. **Select scopes** (Seleccionar permisos): Marca estas casillas:
   - ✅ **`repo`** (Full control of private repositories)
     - Esto incluye: `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`
   - ✅ **`workflow`** (Update GitHub Action workflows) - Opcional, solo si usas Actions

4. Haz clic en **"Generate token"** (Generar token) al final de la página

### Paso 5: Copiar el Token
⚠️ **IMPORTANTE**: GitHub solo te mostrará el token **UNA VEZ**. Cópialo inmediatamente.

1. Verás una pantalla con tu token (una cadena larga de letras y números)
2. **Copia el token completo** (haz clic en el ícono de copiar o selecciona y Ctrl+C)
3. **Guárdalo en un lugar seguro** (no lo compartas)

### Paso 6: Usar el Token
Cuando Git te pida la contraseña:
- **Username**: `GermanPerez-ai`
- **Password**: Pega el token que acabas de copiar (NO tu contraseña de GitHub)

---

## 🔄 Alternativa: Usar SSH (Más Seguro)

Si prefieres no usar tokens, puedes configurar SSH:

### Configurar SSH Key

1. **Generar SSH Key** (en el servidor):
```bash
ssh-keygen -t ed25519 -C "tu-email@ejemplo.com"
# Presiona Enter para usar la ubicación por defecto
# Presiona Enter para no usar contraseña (o pon una si quieres)
```

2. **Copiar la clave pública**:
```bash
cat ~/.ssh/id_ed25519.pub
# Copia todo el contenido que aparece
```

3. **Agregar a GitHub**:
   - Ve a: https://github.com/settings/keys
   - Haz clic en **"New SSH key"**
   - **Title**: `Servidor Checkin24hs`
   - **Key**: Pega la clave que copiaste
   - Haz clic en **"Add SSH key"**

4. **Cambiar URL del repositorio a SSH**:
```bash
cd ~/checkin24hs
git remote set-url origin git@github.com:GermanPerez-ai/checkin24hs.git
```

5. **Probar conexión**:
```bash
ssh -T git@github.com
# Deberías ver: "Hi GermanPerez-ai! You've successfully authenticated..."
```

---

## ✅ Verificación Rápida

Después de configurar el token o SSH, prueba:

```bash
cd ~/checkin24hs
git push origin main
```

Si funciona, verás algo como:
```
Enumerating objects: X, done.
Counting objects: 100% (X/X), done.
Writing objects: 100% (X/X), done.
To https://github.com/GermanPerez-ai/checkin24hs.git
   abc1234..def5678  main -> main
```

---

## 🆘 Solución de Problemas

### Error: "Authentication failed"
- Verifica que el token esté copiado correctamente (sin espacios)
- Verifica que el token no haya expirado
- Verifica que tengas permisos `repo` en el token

### Error: "Permission denied"
- Verifica que el repositorio sea tuyo o tengas acceso
- Verifica que el token tenga el scope `repo`

### Error: "Repository not found"
- Verifica que el nombre del repositorio sea correcto: `checkin24hs`
- Verifica que el usuario sea correcto: `GermanPerez-ai`

---

## 💡 Recomendación

**Para uso en servidor**: Usa **SSH** (más seguro y no expira)
**Para uso rápido**: Usa **Personal Access Token** (más fácil de configurar)