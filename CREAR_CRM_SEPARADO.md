# Crear CRM Separado en crm.checkin24hs.com

## Objetivo
Crear una página web separada en `crm.checkin24hs.com` que contenga solo las funcionalidades de:
- Interacciones
- Chats
- Flor IA

Esto aislará estas funcionalidades problemáticas y evitará que afecten al dashboard principal.

## Plan de Implementación

### 1. Extraer código relevante
- Extraer el HTML/CSS/JS de las secciones:
  - `interactions-section`
  - `chats-section`
  - `flor-config-section` (Flor IA)

### 2. Crear nuevo archivo `crm.html`
- Crear un archivo HTML independiente
- Incluir solo las dependencias necesarias:
  - Supabase client
  - Estilos básicos
  - JavaScript de las funcionalidades CRM

### 3. Configurar en EasyPanel
- Crear nuevo servicio `crm` en EasyPanel
- Configurar dominio `crm.checkin24hs.com`
- Configurar Traefik labels para el nuevo dominio

### 4. Ventajas
- Dashboard principal (`dashboard.checkin24hs.com`) funcionará sin problemas
- CRM (`crm.checkin24hs.com`) será independiente
- Si hay errores en CRM, no afectarán el dashboard principal
- Más fácil de mantener y depurar

## Pasos para Implementar

1. **Extraer código del dashboard.html actual**
2. **Crear crm.html con estructura mínima**
3. **Configurar servicio en EasyPanel**
4. **Configurar Traefik para crm.checkin24hs.com**
5. **Probar y verificar**

¿Procedemos con la creación de la página separada?


