# 🛠️ Scripts del Proyecto

## 📁 Estructura

```
scripts/
├── deploy/          # Scripts de deployment
│   └── actualizar-dashboard.sh
├── utils/           # Utilidades
└── README.md        # Este archivo
```

## 🚀 Scripts Disponibles

### Deployment
- `deploy/actualizar-dashboard.sh` - Actualiza el dashboard en el servidor desde GitHub

## 💡 Uso

### Instalar Script en Servidor

Copiar script al servidor:
```bash
# En el servidor SSH
cat > /usr/local/bin/actualizar-dashboard.sh << 'EOF'
[contenido del script]
EOF

chmod +x /usr/local/bin/actualizar-dashboard.sh
```

Luego ejecutar:
```bash
actualizar-dashboard.sh
```
