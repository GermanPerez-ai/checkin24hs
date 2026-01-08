# Backup en Google Drive - Checkin24hs

## 📋 Descripción
Sistema de backup exclusivo en Google Drive para el proyecto Checkin24hs. Automático, seguro y fácil de usar.

## 🚀 Instalación y Configuración

### 1. Instalar Google Drive
```powershell
# Abrir página de descarga
Start-Process "https://www.google.com/drive/download/"
```

**Pasos:**
1. Descarga Google Drive desde el enlace
2. Instala la aplicación
3. Inicia sesión con tu cuenta de Google
4. Configura la carpeta de sincronización

### 2. Verificar instalación
```powershell
# Verificar si Google Drive está instalado
.\backup_google_drive.ps1 -Status
```

## 🔧 Cómo usar

### Probar Google Drive
```powershell
.\backup_google_drive.ps1 -Test
```

### Ver estado actual
```powershell
.\backup_google_drive.ps1 -Status
```

### Backup manual
```powershell
.\backup_google_drive.ps1 -Manual
```

### Configurar backup automático (diario)
```powershell
.\backup_google_drive.ps1 -Setup
```

## 📁 Estructura de Backups

### Local
```
backups/
├── backup_2024-01-15_14-30-25/
│   ├── index.html
│   ├── dashboard.html
│   └── ...
└── ...
```

### Google Drive
```
Google Drive/
└── Checkin24hs_Backups/
    ├── Checkin24hs_Backup_2024-01-15_14-30-25.zip
    ├── Checkin24hs_Backup_2024-01-15_15-00-25.zip
    └── ...
```

## 🔧 Características

### ✅ Funcionalidades:
- **Backup comprimido** para ahorrar espacio
- **Subida automática** a Google Drive
- **Backup automático diario** a las 9:00 AM
- **Pruebas de conectividad** antes de subir
- **Manejo de errores** y limpieza automática
- **Estado detallado** de backups locales y en la nube

### 📦 Archivos respaldados:
- `index.html` - Aplicación principal
- `dashboard.html` - Panel de administración
- `*.css` - Archivos de estilos
- `*.js` - Archivos JavaScript
- `*.json` - Archivos de configuración
- `*.md` - Documentación
- `*.txt` - Archivos de texto

## 📊 Monitoreo

### Verificar backups locales:
```powershell
Get-ChildItem -Path ".\backups" -Directory | Sort-Object CreationTime -Descending
```

### Verificar backups en Google Drive:
```powershell
Get-ChildItem -Path "$env:USERPROFILE\Google Drive\Checkin24hs_Backups" -File | Sort-Object CreationTime -Descending
```

## 🔄 Restaurar desde Google Drive

### Descargar backup específico:
```powershell
# Copiar desde Google Drive a local
$googleBackupPath = "$env:USERPROFILE\Google Drive\Checkin24hs_Backups"
$backupFile = "Checkin24hs_Backup_2024-01-15_14-30-25.zip"
Copy-Item -Path "$googleBackupPath\$backupFile" -Destination ".\restore.zip"

# Extraer backup
Expand-Archive -Path ".\restore.zip" -DestinationPath ".\restore" -Force
```

## ⚙️ Configuración Avanzada

### Cambiar hora del backup automático:
```powershell
# Editar la tarea programada
schtasks /query /tn "Checkin24hs_GoogleDrive_Backup"
schtasks /change /tn "Checkin24hs_GoogleDrive_Backup" /tr "PowerShell.exe -ExecutionPolicy Bypass -File `"C:\ruta\backup_google_drive.ps1`" -Auto"
```

### Backup manual con parámetros:
```powershell
# Forzar backup completo
.\backup_script.ps1
.\backup_google_drive.ps1 -Manual
```

## 🛡️ Seguridad

- **Backups comprimidos** para ahorrar espacio
- **Sincronización automática** con Google Drive
- **Acceso desde cualquier dispositivo** via Google Drive
- **Historial de versiones** en Google Drive
- **Recuperación fácil** desde la nube

## 📈 Ventajas

1. **Seguridad**: Protección contra pérdida de datos local
2. **Acceso remoto**: Puedes acceder desde cualquier lugar
3. **Sincronización**: Automática con Google Drive
4. **Espacio**: No ocupa espacio adicional en tu disco
5. **Compartir**: Fácil compartir con equipo de trabajo
6. **Historial**: Google Drive mantiene versiones anteriores

## 🚨 Solución de Problemas

### Google Drive no detectado:
```powershell
# Verificar instalación
Test-Path "$env:USERPROFILE\Google Drive"
```

### Error de permisos:
```powershell
# Ejecutar como administrador
Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File backup_google_drive.ps1"
```

### Error de conexión:
1. Verificar conexión a internet
2. Verificar que Google Drive esté sincronizado
3. Reiniciar Google Drive

## 📞 Soporte

Si tienes problemas:
1. Verifica que Google Drive esté instalado y funcionando
2. Comprueba que haya espacio suficiente en Google Drive
3. Revisa los logs en la consola
4. Ejecuta `.\backup_google_drive.ps1 -Test` para diagnosticar

---

**Desarrollado para Checkin24hs** - Sistema de backup exclusivo en Google Drive
