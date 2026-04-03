# Instrucciones Post-Deploy

## 📋 Proceso Completo

Después de hacer push a GitHub y que Easypanel haga el deploy, ejecuta estos pasos en el servidor:

### Opción 1: Proceso Automático (Recomendado)

```bash
cd ~/checkin24hs
bash PROCESO_DEPLOY_COMPLETO.sh
```

Este script ejecuta automáticamente todos los pasos necesarios.

### Opción 2: Pasos Manuales

Si prefieres ejecutar los pasos uno por uno:

#### 1. Actualizar archivo dashboard.html en el servidor

```bash
cd ~/checkin24hs
bash ACTUALIZAR_ARCHIVO_SERVIDOR.sh
```

Este script:
- Descarga el archivo desde GitHub
- Crea un backup del archivo actual
- Copia el nuevo archivo al contenedor
- Verifica el build number

#### 2. Reaplicar Traefik Labels

```bash
cd ~/checkin24hs
bash REAPLICAR_TRAEFIK_LABELS.sh
```

Este script:
- Reaplica todas las labels de Traefik al servicio
- Verifica que se aplicaron correctamente
- Espera a que el servicio esté listo

#### 3. Verificar que todo esté correcto

```bash
cd ~/checkin24hs
bash VERIFICAR_POST_DEPLOY_COMPLETO.sh
```

Este script verifica:
- ✅ Que el archivo existe y tiene contenido
- ✅ El build number en el contenedor
- ✅ Las labels de Traefik
- ✅ HTTP (http://dashboard.checkin24hs.com)
- ✅ HTTPS (https://dashboard.checkin24hs.com)
- ✅ Build number en HTTP y HTTPS

## 🔧 Scripts Disponibles

### `PROCESO_DEPLOY_COMPLETO.sh`
Ejecuta todos los pasos automáticamente.

### `ACTUALIZAR_ARCHIVO_SERVIDOR.sh`
Actualiza el archivo `dashboard.html` en el servidor desde GitHub.

### `REAPLICAR_TRAEFIK_LABELS.sh`
Reaplica las labels de Traefik al servicio Docker.

### `VERIFICAR_POST_DEPLOY_COMPLETO.sh`
Verifica que todo esté funcionando correctamente después del deploy.

## 📝 Notas Importantes

1. **Build Number**: Actualiza el `EXPECTED_BUILD_NUMBER` en `VERIFICAR_POST_DEPLOY_COMPLETO.sh` según el build actual.

2. **Tiempo de espera**: Después de reaplicar Traefik labels, espera 30-60 segundos para que Traefik actualice la configuración.

3. **Backups**: Los backups se guardan en `/tmp/dashboard.html.backup.YYYYMMDD_HHMMSS`

4. **Verificación**: Si alguna verificación falla, revisa los mensajes de error y ejecuta los scripts individuales según sea necesario.

## 🚀 Comando Rápido

```bash
cd ~/checkin24hs && bash PROCESO_DEPLOY_COMPLETO.sh
```
