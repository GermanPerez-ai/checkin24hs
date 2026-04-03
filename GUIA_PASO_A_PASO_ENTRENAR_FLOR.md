# 🎓 Guía Paso a Paso: Entrenar Flor IA hasta la Independencia Total

## 🎯 Objetivo

Hacer que Flor sea completamente independiente, educativa y capaz de responder el 90%+ de consultas sin escalar a humano.

---

## 📋 PASO 1: Subir Archivos Mejorados

### 1.1 Subir archivos al servidor

**En PowerShell (Windows):**
```powershell
cd C:\Users\German\Downloads\Checkin24hs
powershell -ExecutionPolicy Bypass -File SUBIR_FLOR_MEJORADA.ps1
```

**O manualmente:**
```powershell
scp flor-ai-service.js root@72.61.58.240:/root/checkin24hs/flor-ai-service.js
scp deploy/flor-ai-service.js root@72.61.58.240:/root/checkin24hs/deploy/flor-ai-service.js
```

### 1.2 Verificar que se subieron correctamente

**En el servidor:**
```bash
cd /root/checkin24hs
grep -n "TU MISIÓN PRINCIPAL" flor-ai-service.js
grep -n "TU MISIÓN PRINCIPAL" deploy/flor-ai-service.js
```

Si aparece la línea, los archivos están correctos ✅

### 1.3 Reiniciar servicio de WhatsApp

**En el servidor:**
```bash
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
docker restart $CONTAINER
```

Espera 30 segundos y verifica que esté funcionando:
```bash
docker logs $CONTAINER --tail 20
```

---

## 📋 PASO 2: Configurar API Key de Gemini

### 2.1 Obtener API Key gratuita

1. Ve a: https://makersuite.google.com/app/apikey
2. Inicia sesión con tu cuenta de Google
3. Haz clic en **"Create API Key"**
4. Copia la clave (empieza con `AIza...`)

### 2.2 Configurar en el Dashboard

1. Abre: `https://dashboard.checkin24hs.com`
2. Ve a: **Flor IA** (menú lateral)
3. Haz clic en la pestaña **"🤖 IA"**
4. Marca: ✅ **"Habilitar respuestas con IA"**
5. Selecciona: **"Google Gemini"**
6. Pega tu API Key en el campo **"API Key"**
7. Modelo: `gemini-2.5-flash` (o `gemini-2.0-flash`)
8. Haz clic en **"Guardar"**
9. Haz clic en **"Probar Conexión"** para verificar

### 2.3 Verificar que funciona

Envía un mensaje de prueba por WhatsApp:
```
Hola, ¿qué hoteles tienen?
```

Verifica en los logs del servidor:
```bash
CONTAINER=$(docker ps --filter "name=whatsapp.1" --format "{{.Names}}" | head -1)
docker logs $CONTAINER -f | grep -i "gemini\|respuesta\|flor"
```

---

## 📋 PASO 3: Completar Base de Conocimiento

### 3.1 Acceder a la configuración

1. Dashboard → **Flor IA** → Pestaña **"📚 Conocimiento"**
2. Selecciona un hotel del dropdown
3. Completa TODOS los campos usando la plantilla

### 3.2 Para cada hotel, completa:

#### ✅ Descripción Detallada
- 2-3 párrafos educativos
- Explica qué hace especial al hotel
- Incluye contexto sobre la ubicación/región
- Usa lenguaje que ayude a visualizar la experiencia

**Ejemplo:**
```
El Hotel Terma de Puyehue es un refugio de bienestar en el corazón de la Patagonia chilena. 
Sus aguas termales naturales, reconocidas por sus propiedades terapéuticas, provienen de 
fuentes volcánicas a más de 80°C y se enfrían naturalmente para crear un ambiente único de 
relajación.

El hotel combina lujo y naturaleza, ofreciendo una experiencia donde los huéspedes pueden 
conectarse con el entorno mientras disfrutan de comodidades de primera clase. Su ubicación 
estratégica permite acceso fácil a actividades al aire libre y excursiones en la región de 
Los Lagos.

¿Sabías que las aguas termales ayudan a aliviar dolores musculares, mejorar la circulación 
y reducir el estrés? Por eso es ideal para viajeros que buscan recuperación después de 
actividades físicas o simplemente un momento de relajación profunda.
```

#### ✅ Servicios e Instalaciones
- Lista cada servicio
- Explica QUÉ incluye
- Explica POR QUÉ es beneficioso
- Indica CUÁNDO es útil

**Formato:**
```
Spa Termal (INCLUIDO)
- Acceso ilimitado a 3 piscinas termales de diferentes temperaturas
- Beneficio: Las diferentes temperaturas permiten alternar entre relajación y activación circulatoria
- Ideal para: Después de excursiones o al final del día

Restaurante Gourmet
- Cocina de autor con productos locales de la región
- Beneficio: Experiencia gastronómica única que conecta con la cultura local
- Ideal para: Cenas especiales y descubrir sabores patagónicos
```

#### ✅ Excursiones y Actividades
- Qué hacer
- Por qué es especial
- Duración y dificultad
- Mejor época para hacerlo

#### ✅ Información de Precios
- Cómo funcionan las tarifas
- Qué incluye y qué no
- Consejos para obtener mejores precios
- Qué información necesitas para cotizar

#### ✅ Políticas
- Condiciones de reserva (explicadas)
- Políticas de cancelación (con contexto)
- Check-in/Check-out
- Métodos de pago

#### ✅ Cómo Llegar
- Instrucciones claras
- Opciones de transporte
- Distancias y tiempos
- Consejos prácticos

#### ✅ Tips y Consejos
- Mejor época para visitar
- Qué traer
- Consejos de experiencia
- Información práctica

### 3.3 Guardar para cada hotel

1. Completa todos los campos
2. Haz clic en **"Guardar"**
3. Repite para cada hotel activo

---

## 📋 PASO 4: Configurar Respuestas Personalizadas

### 4.1 Respuestas Generales

Dashboard → **Flor IA** → Pestaña **"💬 Respuestas"**

Personaliza:
- **Cuando no entiende**: Mensaje educativo que guíe al cliente
- **Transferir a humano**: Mensaje claro y amable
- **Despedida**: Mensaje que invite a volver

### 4.2 Respuestas Multimodales

Configura mensajes para:
- Audio muy largo o de mala calidad
- Imagen no reconocida
- Imagen procesándose
- Antes de enviar imagen de hotel

---

## 📋 PASO 5: Configurar Políticas por Hotel

Dashboard → **Flor IA** → Pestaña **"📋 Políticas"**

Para cada hotel:
1. Selecciona el hotel
2. Completa **"Condiciones para la Reserva"** (explicadas)
3. Completa **"Políticas de Cancelación"** (con contexto)
4. Guarda

**Ejemplo de política educativa:**
```
Para confirmar tu reserva:
- Se requiere un depósito del 30% del total
- El depósito es reembolsable hasta 72 horas antes del check-in
- Métodos de pago aceptados: Tarjeta de crédito, transferencia bancaria

¿Por qué pedimos depósito? Nos permite garantizar tu habitación y preparar todo 
para tu llegada. Además, te protege en caso de cancelación dentro del plazo permitido.
```

---

## 📋 PASO 6: Probar y Ajustar

### 6.1 Casos de Prueba

Prueba con estos mensajes:

1. **Consulta general:**
   ```
   ¿Qué hoteles tienen?
   ```
   ✅ Debe: Listar todos con ubicación y explicar qué hace especial cada uno

2. **Consulta específica:**
   ```
   Cuéntame sobre el Hotel Terma de Puyehue
   ```
   ✅ Debe: Dar información educativa, explicar beneficios, incluir contexto

3. **Comparación:**
   ```
   ¿Cuál es mejor para relajación, Puyehue o Huilo-Huilo?
   ```
   ✅ Debe: Comparar características, explicar diferencias, ayudar a decidir

4. **Consulta de servicios:**
   ```
   ¿Qué incluye el spa termal?
   ```
   ✅ Debe: Explicar qué hay, por qué es beneficioso, cuándo es útil

5. **Consulta de precios:**
   ```
   ¿Cuánto cuesta una noche?
   ```
   ✅ Debe: Explicar cómo funcionan las tarifas, qué incluye, qué información necesita

### 6.2 Revisar Respuestas

Para cada respuesta, verifica:
- ✅ ¿Es educativa? (explica el "por qué")
- ✅ ¿Incluye contexto útil?
- ✅ ¿Anticipa preguntas relacionadas?
- ✅ ¿Compara opciones cuando es relevante?
- ✅ ¿Es clara y fácil de entender?

### 6.3 Ajustar según Resultados

Si las respuestas no son lo suficientemente educativas:

1. Revisa la base de conocimiento del hotel
2. Agrega más contexto educativo
3. Incluye más explicaciones de beneficios
4. Prueba nuevamente

---

## 📋 PASO 7: Monitoreo Continuo

### 7.1 Revisar Interacciones

Dashboard → **Flor IA** → Pestaña **"💬 Chats"**

Revisa:
- Qué preguntas hacen los clientes
- Cómo responde Flor
- Si escaló a humano cuando no debería
- Si no escaló cuando debería

### 7.2 Mejorar Continuamente

Basado en las interacciones:
1. Identifica preguntas frecuentes
2. Agrega esa información a la base de conocimiento
3. Ajusta respuestas personalizadas si es necesario
4. Mejora el prompt del sistema si hay patrones

---

## 📋 PASO 8: Optimización Avanzada

### 8.1 Ajustar Parámetros de la IA

Si necesitas ajustar creatividad o longitud:

Edita `flor-ai-service.js`:
```javascript
// En callGemini o callOpenAI
temperature: 0.7,  // 0.0-1.0 (más bajo = más consistente)
maxTokens: 500,    // Longitud máxima (200-1000)
```

**Recomendaciones:**
- Temperature: 0.7-0.8 (balance entre creatividad y consistencia)
- Max Tokens: 300-500 (respuestas concisas pero completas)

### 8.2 Agregar Ejemplos al Prompt

Puedes agregar ejemplos de respuestas ideales en el prompt del sistema.

---

## ✅ Checklist Final

Flor estará lista cuando:

- [ ] Archivos mejorados subidos al servidor
- [ ] API Key de Gemini configurada y funcionando
- [ ] Base de conocimiento completa para TODOS los hoteles activos
- [ ] Respuestas personalizadas configuradas
- [ ] Políticas por hotel completas
- [ ] Probado con casos reales
- [ ] Respuestas son educativas y útiles
- [ ] 90%+ de consultas se resuelven sin escalar
- [ ] Sistema de monitoreo funcionando

---

## 🎯 Métricas de Éxito

### Indicadores de que Flor está lista:

1. **Tasa de Escalación**: < 10% de consultas escalan a humano
2. **Calidad de Respuestas**: Clientes entienden mejor sus opciones
3. **Satisfacción**: Los clientes hacen preguntas de seguimiento (señal de que entienden)
4. **Independencia**: Flor maneja consultas complejas sin ayuda

---

## 🆘 Solución de Problemas

### Problema: La IA no responde
- Verifica que la API Key esté configurada
- Revisa los logs del servidor
- Prueba la conexión desde el dashboard

### Problema: Las respuestas no son educativas
- Verifica que la base de conocimiento esté completa
- Revisa que el prompt del sistema tenga las mejoras
- Agrega más contexto educativo a la base de conocimiento

### Problema: Escala demasiado a humano
- Revisa qué tipo de consultas escalan
- Agrega esa información a la base de conocimiento
- Ajusta las reglas de escalación en el prompt

---

## 📚 Recursos

- **Plantilla de conocimiento**: `PLANTILLA_BASE_CONOCIMIENTO_HOTEL.md`
- **Guía de configuración**: `GUIA_CONFIGURAR_IA_MEJOR_ENSENANZA.md`
- **Plan completo**: `PLAN_ENTRENAMIENTO_FLOR_COMPLETO.md`
- **Scripts de ayuda**: `SUBIR_FLOR_MEJORADA.ps1`, `VERIFICAR_CONFIGURACION_FLOR.sh`

---

**¡Vamos paso a paso! Te guiaré en cada etapa.** 🚀


