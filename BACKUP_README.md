# Sistema de Backup - Checkin24hs

## 📋 Descripción
Sistema de backup automático para el proyecto Checkin24hs que protege todos los archivos importantes del desarrollo.

## 🚀 Cómo usar

### 1. Backup Manual (Una sola vez)
```powershell
# Ejecutar backup manual
.\backup_script.ps1
```

### 2. Backup Automático (Cada 30 minutos)
```powershell
# Iniciar backup automático
.\auto_backup.ps1

# O ejecutar una sola vez
.\auto_backup.ps1 -RunOnce
```

### 3. Backup en la Nube 🌥️
```powershell
# Configurar servicios de nube
.\cloud_backup_config.ps1 -Setup

# Probar servicios configurados
.\cloud_backup_config.ps1 -Test

# Ver configuración actual
.\cloud_backup_config.ps1 -List

# Backup a Google Drive
.\cloud_backup.ps1 -CloudService GoogleDrive

# Backup a OneDrive
.\cloud_backup.ps1 -CloudService OneDrive

# Backup comprimido y encriptado
.\cloud_backup.ps1 -CloudService GoogleDrive -Compress -Encrypt -EncryptionPassword "miContraseña"
```

### 4. Backup con parámetros personalizados
```powershell
# Especificar directorio de backup
.\backup_script.ps1 -BackupPath "C:\MisBackups"

# Cambiar intervalo de backup automático (en minutos)
.\auto_backup.ps1 -IntervalMinutes 60
```

## 📁 Estructura de Backups

```
backups/
├── backup_2024-01-15_14-30-25/
│   ├── index.html
│   ├── dashboard.html
│   ├── BACKUP_INFO.txt
│   └── ...
├── backup_2024-01-15_15-00-25/
│   └── ...
└── ...
```

## 🔧 Características

### ✅ Archivos respaldados:
- `index.html` - Aplicación principal
- `dashboard.html` - Panel de administración
- `*.css` - Archivos de estilos
- `*.js` - Archivos JavaScript
- `*.json` - Archivos de configuración
- `*.md` - Documentación
- `*.txt` - Archivos de texto

### 🔄 Funcionalidades:
- **Backup automático** cada 30 minutos
- **Rotación automática** (mantiene solo los últimos 5 backups)
- **Información detallada** de cada backup
- **Restauración fácil** con comandos incluidos
- **Manejo de errores** y reintentos automáticos
- **🌥️ Backup en la nube** (Google Drive, OneDrive, Dropbox)
- **📦 Compresión automática** para ahorrar espacio
- **🔒 Encriptación opcional** para mayor seguridad
- **⚙️ Configuración automática** de servicios de nube

## 📊 Información del Backup

Cada backup incluye un archivo `BACKUP_INFO.txt` con:
- Fecha y hora del backup
- Número de archivos copiados
- Lista completa de archivos
- Comando para restaurar

## 🔄 Restaurar desde Backup

```powershell
# Restaurar desde el último backup
$latestBackup = Get-ChildItem -Path ".\backups" -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
Copy-Item -Path "$($latestBackup.FullName)\*" -Destination "." -Recurse -Force

# O restaurar desde un backup específico
Copy-Item -Path ".\backups\backup_2024-01-15_14-30-25\*" -Destination "." -Recurse -Force
```

## ⚙️ Configuración Avanzada

### Cambiar intervalo de backup:
```powershell
# Backup cada hora
.\auto_backup.ps1 -IntervalMinutes 60

# Backup cada 15 minutos
.\auto_backup.ps1 -IntervalMinutes 15
```

### Cambiar directorio de backup:
```powershell
# Usar directorio personalizado
.\backup_script.ps1 -BackupPath "D:\MisBackups\Checkin24hs"
```

### 🌥️ Configuración de Nube:
```powershell
# Configurar servicios de nube disponibles
.\cloud_backup_config.ps1 -Setup

# Ver qué servicios están instalados
.\cloud_backup_config.ps1 -List

# Probar conexión con servicios configurados
.\cloud_backup_config.ps1 -Test
```

## 🛡️ Seguridad

- **Backups incrementales**: Solo copia archivos modificados
- **Verificación de integridad**: Comprueba que los archivos se copien correctamente
- **Logs detallados**: Registra todas las operaciones
- **Manejo de errores**: Reintenta automáticamente si falla

## 📈 Monitoreo

### Verificar estado de backups:
```powershell
# Listar todos los backups
Get-ChildItem -Path ".\backups" -Directory | Sort-Object CreationTime -Descending

# Ver tamaño de backups
Get-ChildItem -Path ".\backups" -Directory | ForEach-Object {
    $size = (Get-ChildItem -Path $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{
        Backup = $_.Name
        Fecha = $_.CreationTime
        Tamaño = "$([math]::Round($size / 1MB, 2)) MB"
    }
}
```

## 🚨 Alertas

El sistema muestra:
- ✅ Backup completado exitosamente
- ❌ Error en el backup (con reintento automático)
- 📊 Estadísticas de tamaño y archivos
- ⏰ Próximo backup programado

## 📞 Soporte

Si tienes problemas con el backup:
1. Verifica que PowerShell tenga permisos de escritura
2. Comprueba que haya espacio suficiente en disco
3. Revisa los logs en la consola
4. Ejecuta un backup manual para diagnosticar

---

**Desarrollado para Checkin24hs** - Sistema de backup automático y confiable 