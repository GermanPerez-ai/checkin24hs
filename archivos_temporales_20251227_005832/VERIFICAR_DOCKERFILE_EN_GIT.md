# Verificar que Dockerfile.crm esté en Git

## Verificación Rápida

Ejecuta en tu máquina local:

```bash
# Verificar que Dockerfile.crm esté en Git
git ls-files | grep Dockerfile.crm

# Debería mostrar: Dockerfile.crm
```

## Si NO está en Git

Agrégalo:

```bash
git add Dockerfile.crm
git commit -m "Agregar Dockerfile.crm para CRM"
git push
```

## Verificar Contenido del Dockerfile.crm

Asegúrate de que tenga estas líneas importantes:

```dockerfile
COPY deploy/crm.html ./crm.html
COPY serve-crm.js ./
COPY deploy/crm.js ./crm.js
CMD ["node", "serve-crm.js"]
```

## Después de Verificar

1. Asegúrate de que `Dockerfile.crm` esté en Git
2. Ve a EasyPanel y configura "Archivo Dockerfile" como `Dockerfile.crm`
3. Reconstruye la imagen






