# Instrucciones para Verificar el Archivo

## Ejecuta este comando en el servidor:

```bash
cd /root/checkin24hs
chmod +x VERIFICAR_ARCHIVO.sh
bash VERIFICAR_ARCHIVO.sh
```

## O ejecuta estos comandos manualmente:

```bash
cd /root/checkin24hs

# 1. Número de líneas
wc -l deploy/dashboard.html

# 2. Tamaño del archivo
ls -lh deploy/dashboard.html

# 3. Contenido línea 5148-5152
sed -n '5148,5152p' deploy/dashboard.html

# 4. Verificar función showWhatsAppConfig
grep -n "async function showWhatsAppConfig" deploy/dashboard.html

# 5. Verificar modal adminModal
grep -n "adminModal" deploy/dashboard.html | head -3

# 6. Línea 5150 específicamente
sed -n '5150p' deploy/dashboard.html

# 7. Verificar caracteres especiales
sed -n '5148,5152p' deploy/dashboard.html | cat -A
```

## Qué buscar:

1. **Número de líneas**: Debe ser aproximadamente 23313 líneas
2. **Línea 5150**: Debe contener `email: 'german@checkin24hs.com',`
3. **Función showWhatsAppConfig**: Debe ser `async function showWhatsAppConfig()`
4. **Modal adminModal**: Debe existir en el archivo
5. **Caracteres especiales**: No debe haber caracteres invisibles o corruptos










