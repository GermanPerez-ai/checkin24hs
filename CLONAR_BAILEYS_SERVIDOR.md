# 📥 Clonar Baileys en el Servidor

## 🔍 Paso 1: Encontrar o Clonar el Repositorio

### Opción A: Si ya tienes el repositorio en otro lugar

```bash
# Buscar el repositorio
find ~ -name ".git" -type d 2>/dev/null | grep -i checkin

# O buscar en ubicaciones comunes
ls -la ~/Checkin24hs
ls -la /root/Checkin24hs
ls -la /home/*/Checkin24hs
```

### Opción B: Clonar el repositorio completo

```bash
# Ir a home
cd ~

# Clonar el repositorio
git clone https://github.com/GermanPerez-ai/checkin24hs.git

# O si ya existe, actualizar
cd checkin24hs
git pull origin main
```

### Opción C: Solo clonar la carpeta de Baileys (si GitHub lo permite)

```bash
cd ~
mkdir -p checkin24hs
cd checkin24hs
git init
git remote add origin https://github.com/GermanPerez-ai/checkin24hs.git
git config core.sparseCheckout true
echo "whatsapp-server-baileys/*" >> .git/info/sparse-checkout
git pull origin main
```

---

## 🚀 Paso 2: Instalar Baileys

Una vez que tengas la carpeta:

```bash
# Ir a la carpeta de Baileys
cd ~/checkin24hs/whatsapp-server-baileys

# O si clonaste directamente:
cd ~/checkin24hs/whatsapp-server-baileys

# Instalar dependencias
npm install
```

---

## 🔧 Paso 3: Configurar e Iniciar

```bash
# Configurar variables (opcional)
export GEMINI_API_KEY="tu-gemini-key"
export SUPABASE_URL="https://lmoeuyasuvoqhtvhkyia.supabase.co"
export SUPABASE_ANON_KEY="tu-supabase-key"

# Instalar PM2
npm install -g pm2

# Crear carpeta para logs
mkdir -p logs

# Iniciar las 4 instancias
pm2 start ecosystem.config.js

# Guardar configuración
pm2 save
```

---

## 📋 Comandos Rápidos

```bash
# Todo en uno (si clonas el repositorio completo)
cd ~
git clone https://github.com/GermanPerez-ai/checkin24hs.git
cd checkin24hs/whatsapp-server-baileys
npm install
npm install -g pm2
mkdir -p logs
pm2 start ecosystem.config.js
pm2 save
```


