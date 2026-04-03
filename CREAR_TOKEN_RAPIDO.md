# 🔐 Crear Personal Access Token Rápido

## ⚡ Método Rápido (2 minutos)

### Paso 1: Ir Directamente a la Página
Abre esta URL en tu navegador:
**https://github.com/settings/tokens/new**

### Paso 2: Configurar el Token
1. **Note**: Escribe `Servidor Checkin24hs`
2. **Expiration**: Selecciona `90 days` (o `No expiration`)
3. **Select scopes**: Marca solo:
   - ✅ **`repo`** (Full control of private repositories)
4. Haz clic en **"Generate token"** (abajo)

### Paso 3: Copiar el Token
⚠️ **IMPORTANTE**: GitHub solo te mostrará el token **UNA VEZ**. 
- Copia todo el texto (es una cadena larga de letras y números)
- Pégala cuando Git te pida la contraseña

### Paso 4: Usar en Git
Cuando Git te pida:
- **Username**: `GermanPerez-ai`
- **Password**: Pega el token que acabas de copiar

---

## 🚀 Alternativa: Usar SSH (No Necesita Token)

Si prefieres no crear un token ahora, puedes cancelar y configurar SSH:

```bash
# En el servidor (presiona Ctrl+C para cancelar el pull)

# Generar SSH key
ssh-keygen -t ed25519 -C "servidor@checkin24hs.com"
# Presiona Enter 2 veces (sin contraseña)

# Copiar la clave pública
cat ~/.ssh/id_ed25519.pub
# Copia todo el texto que aparece
```

Luego:
1. Ve a: **https://github.com/settings/keys**
2. Haz clic en **"New SSH key"**
3. Pega la clave que copiaste
4. Guarda

Finalmente:
```bash
cd ~/checkin24hs
git remote set-url origin git@github.com:GermanPerez-ai/checkin24hs.git
git pull origin main
```

---

## 💡 Recomendación

**Para ahora**: Crea el token rápidamente (2 minutos) y úsalo
**Para futuro**: Configura SSH (más seguro, no expira)
