// Servicio Multimodal para Flor - Procesamiento de Audio e Imágenes
// Checkin24hs - Asistente Virtual Inteligente

class FlorMultimodalService {
    constructor() {
        this.config = {
            audio: {
                enabled: true,
                provider: 'browser', // 'browser', 'google', 'azure'
                apiKey: null,
                maxDuration: 45, // segundos
                fallbackMessage: 'Disculpa, el audio no fue del todo claro. Para atenderte con la rapidez que mereces, ¿podrías enviarme tu consulta por escrito, o prefieres que te conecte con un agente ahora mismo?'
            },
            image: {
                enabled: true,
                provider: 'browser', // 'browser', 'google', 'azure', 'openai'
                apiKey: null,
                maxSize: 10 * 1024 * 1024, // 10MB
            }
        };
        
        // Cargar configuración desde localStorage
        this.loadConfig();
    }

    // Cargar configuración guardada
    loadConfig() {
        try {
            const saved = localStorage.getItem('flor_multimodal_config');
            if (saved) {
                const parsed = JSON.parse(saved);
                this.config = { ...this.config, ...parsed };
            }
        } catch (e) {
            console.error('[Flor Multimodal] Error al cargar configuración:', e);
        }
    }

    // Guardar configuración
    saveConfig() {
        try {
            localStorage.setItem('flor_multimodal_config', JSON.stringify(this.config));
            console.log('[Flor Multimodal] ✅ Configuración guardada');
        } catch (e) {
            console.error('[Flor Multimodal] Error al guardar configuración:', e);
        }
    }

    // Configurar el servicio multimodal
    configure(options) {
        this.config = { ...this.config, ...options };
        this.saveConfig();
        console.log('[Flor Multimodal] 🔧 Configuración actualizada:', this.config);
    }

    // ==================== PROCESAMIENTO DE AUDIO ====================

    /**
     * Procesa un archivo de audio y lo transcribe a texto
     * @param {File|Blob} audioFile - Archivo de audio a procesar
     * @returns {Promise<{success: boolean, text: string, error?: string}>}
     */
    async processAudio(audioFile) {
        if (!this.config.audio.enabled) {
            return { success: false, error: 'Procesamiento de audio deshabilitado' };
        }

        try {
            // Verificar duración del audio
            const duration = await this.getAudioDuration(audioFile);
            if (duration > this.config.audio.maxDuration) {
                console.warn(`[Flor Multimodal] ⚠️ Audio excede ${this.config.audio.maxDuration}s (${duration}s)`);
                return {
                    success: false,
                    error: 'audio_too_long',
                    text: this.config.audio.fallbackMessage
                };
            }

            // Verificar calidad básica (tamaño mínimo)
            if (audioFile.size < 1000) { // Menos de 1KB probablemente está corrupto
                console.warn('[Flor Multimodal] ⚠️ Audio muy pequeño, posiblemente corrupto');
                return {
                    success: false,
                    error: 'audio_poor_quality',
                    text: this.config.audio.fallbackMessage
                };
            }

            // Procesar según el proveedor configurado
            let transcription;
            switch (this.config.audio.provider) {
                case 'google':
                    transcription = await this.transcribeWithGoogle(audioFile);
                    break;
                case 'azure':
                    transcription = await this.transcribeWithAzure(audioFile);
                    break;
                case 'browser':
                default:
                    transcription = await this.transcribeWithBrowser(audioFile);
                    break;
            }

            if (!transcription || !transcription.success) {
                return {
                    success: false,
                    error: transcription?.error || 'transcription_failed',
                    text: this.config.audio.fallbackMessage
                };
            }

            return {
                success: true,
                text: transcription.text
            };

        } catch (error) {
            console.error('[Flor Multimodal] ❌ Error al procesar audio:', error);
            return {
                success: false,
                error: error.message,
                text: this.config.audio.fallbackMessage
            };
        }
    }

    /**
     * Obtiene la duración de un archivo de audio
     */
    async getAudioDuration(audioFile) {
        return new Promise((resolve, reject) => {
            const audio = new Audio();
            const url = URL.createObjectURL(audioFile);
            
            audio.addEventListener('loadedmetadata', () => {
                URL.revokeObjectURL(url);
                resolve(audio.duration);
            });
            
            audio.addEventListener('error', () => {
                URL.revokeObjectURL(url);
                reject(new Error('No se pudo cargar el audio'));
            });
            
            audio.src = url;
        });
    }

    /**
     * Transcribe audio usando Web Speech API del navegador
     * NOTA: Web Speech API solo funciona con audio en tiempo real, no con archivos.
     * Para procesar archivos de audio, se requiere configurar un proveedor externo (Google o Azure).
     */
    async transcribeWithBrowser(audioFile) {
        return new Promise((resolve) => {
            console.warn('[Flor Multimodal] ⚠️ Web Speech API no puede procesar archivos de audio directamente.');
            console.warn('[Flor Multimodal] 💡 Para procesar archivos, configura un proveedor externo (Google Cloud o Azure) en la configuración.');
            
            // Web Speech API solo funciona con audio en tiempo real desde el micrófono
            // Para archivos, necesitamos una API externa
            resolve({ 
                success: false, 
                error: 'browser_api_requires_realtime',
                message: 'Para procesar archivos de audio, por favor configura Google Cloud Speech-to-Text o Azure Speech Services en la configuración.'
            });
        });
    }

    /**
     * Transcribe audio usando Google Cloud Speech-to-Text
     */
    async transcribeWithGoogle(audioFile) {
        if (!this.config.audio.apiKey) {
            return { success: false, error: 'API key no configurada' };
        }

        try {
            // Convertir audio a base64
            const base64Audio = await this.fileToBase64(audioFile);
            
            const response = await fetch(
                `https://speech.googleapis.com/v1/speech:recognize?key=${this.config.audio.apiKey}`,
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        config: {
                            encoding: 'WEBM_OPUS', // Ajustar según el formato del audio
                            sampleRateHertz: 16000,
                            languageCode: 'es-ES'
                        },
                        audio: {
                            content: base64Audio.split(',')[1] // Remover prefijo data:audio/...
                        }
                    })
                }
            );

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            const transcription = data.results?.[0]?.alternatives?.[0]?.transcript;

            if (!transcription) {
                return { success: false, error: 'no_transcription' };
            }

            return { success: true, text: transcription };

        } catch (error) {
            console.error('[Flor Multimodal] Error con Google Speech:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Transcribe audio usando Azure Speech Services
     */
    async transcribeWithAzure(audioFile) {
        if (!this.config.audio.apiKey) {
            return { success: false, error: 'API key no configurada' };
        }

        try {
            // Azure requiere autenticación con token primero
            const tokenResponse = await fetch(
                `https://${this.config.audio.region || 'eastus'}.api.cognitive.microsoft.com/sts/v1.0/issueToken`,
                {
                    method: 'POST',
                    headers: {
                        'Ocp-Apim-Subscription-Key': this.config.audio.apiKey
                    }
                }
            );

            if (!tokenResponse.ok) {
                throw new Error('Error al obtener token de Azure');
            }

            const token = await tokenResponse.text();

            // Convertir audio a formato requerido
            const audioBlob = await audioFile.arrayBuffer();
            
            const response = await fetch(
                `https://${this.config.audio.region || 'eastus'}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=es-ES`,
                {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'audio/wav' // Ajustar según formato
                    },
                    body: audioBlob
                }
            );

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            const transcription = data.DisplayText;

            if (!transcription) {
                return { success: false, error: 'no_transcription' };
            }

            return { success: true, text: transcription };

        } catch (error) {
            console.error('[Flor Multimodal] Error con Azure Speech:', error);
            return { success: false, error: error.message };
        }
    }

    // ==================== PROCESAMIENTO DE IMÁGENES ====================

    /**
     * Procesa una imagen y extrae información relevante
     * @param {File|Blob} imageFile - Archivo de imagen a procesar
     * @returns {Promise<{success: boolean, description: string, objects?: Array, error?: string}>}
     */
    async processImage(imageFile) {
        if (!this.config.image.enabled) {
            return { success: false, error: 'Procesamiento de imágenes deshabilitado' };
        }

        try {
            // Verificar tamaño
            if (imageFile.size > this.config.image.maxSize) {
                return {
                    success: false,
                    error: 'image_too_large',
                    description: 'La imagen es demasiado grande. Por favor, envía una imagen más pequeña.'
                };
            }

            // Procesar según el proveedor configurado
            let analysis;
            switch (this.config.image.provider) {
                case 'google':
                    analysis = await this.analyzeWithGoogleVision(imageFile);
                    break;
                case 'azure':
                    analysis = await this.analyzeWithAzureVision(imageFile);
                    break;
                case 'openai':
                    analysis = await this.analyzeWithOpenAI(imageFile);
                    break;
                case 'browser':
                default:
                    analysis = await this.analyzeWithBrowser(imageFile);
                    break;
            }

            if (!analysis || !analysis.success) {
                return {
                    success: false,
                    error: analysis?.error || 'analysis_failed',
                    description: 'No pude analizar la imagen. ¿Podrías describir lo que necesitas?'
                };
            }

            return analysis;

        } catch (error) {
            console.error('[Flor Multimodal] ❌ Error al procesar imagen:', error);
            return {
                success: false,
                error: error.message,
                description: 'Hubo un error al procesar la imagen. ¿Podrías describir lo que necesitas?'
            };
        }
    }

    /**
     * Análisis básico de imagen usando APIs del navegador (limitado)
     */
    async analyzeWithBrowser(imageFile) {
        // Análisis básico: solo podemos obtener dimensiones y crear una descripción básica
        return new Promise((resolve) => {
            const img = new Image();
            const url = URL.createObjectURL(imageFile);

            img.onload = () => {
                URL.revokeObjectURL(url);
                
                // Análisis muy básico - en producción necesitarías una API de visión
                const description = `Imagen recibida (${img.width}x${img.height}px). Para un análisis detallado, por favor describe lo que necesitas o configura una API de visión.`;
                
                resolve({
                    success: true,
                    description: description,
                    width: img.width,
                    height: img.height
                });
            };

            img.onerror = () => {
                URL.revokeObjectURL(url);
                resolve({ success: false, error: 'invalid_image' });
            };

            img.src = url;
        });
    }

    /**
     * Analiza imagen usando Google Cloud Vision API
     */
    async analyzeWithGoogleVision(imageFile) {
        if (!this.config.image.apiKey) {
            return { success: false, error: 'API key no configurada' };
        }

        try {
            const base64Image = await this.fileToBase64(imageFile);
            
            const response = await fetch(
                `https://vision.googleapis.com/v1/images:annotate?key=${this.config.image.apiKey}`,
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        requests: [{
                            image: {
                                content: base64Image.split(',')[1]
                            },
                            features: [
                                { type: 'LABEL_DETECTION', maxResults: 10 },
                                { type: 'TEXT_DETECTION', maxResults: 10 },
                                { type: 'OBJECT_LOCALIZATION', maxResults: 10 }
                            ]
                        }]
                    })
                }
            );

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            const annotations = data.responses?.[0];

            if (!annotations) {
                return { success: false, error: 'no_annotations' };
            }

            // Construir descripción
            const labels = annotations.labelAnnotations?.map(l => l.description).join(', ') || '';
            const text = annotations.textAnnotations?.[0]?.description || '';
            const objects = annotations.localizedObjectAnnotations?.map(o => o.name) || [];

            let description = '';
            if (text) description += `Texto detectado: ${text}\n`;
            if (labels) description += `Elementos: ${labels}\n`;
            if (objects.length > 0) description += `Objetos: ${objects.join(', ')}\n`;

            return {
                success: true,
                description: description.trim() || 'Imagen analizada',
                labels: labels.split(', '),
                text: text,
                objects: objects
            };

        } catch (error) {
            console.error('[Flor Multimodal] Error con Google Vision:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Analiza imagen usando Azure Computer Vision
     */
    async analyzeWithAzureVision(imageFile) {
        if (!this.config.image.apiKey) {
            return { success: false, error: 'API key no configurada' };
        }

        try {
            const imageBlob = await imageFile.arrayBuffer();
            
            const response = await fetch(
                `https://${this.config.image.region || 'eastus'}.api.cognitive.microsoft.com/vision/v3.2/analyze?visualFeatures=Categories,Description,Objects,Tags&language=es`,
                {
                    method: 'POST',
                    headers: {
                        'Ocp-Apim-Subscription-Key': this.config.image.apiKey,
                        'Content-Type': imageFile.type || 'application/octet-stream'
                    },
                    body: imageBlob
                }
            );

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            
            const description = data.description?.captions?.[0]?.text || '';
            const tags = data.description?.tags || [];
            const objects = data.objects?.map(o => o.object) || [];

            return {
                success: true,
                description: description || tags.join(', '),
                tags: tags,
                objects: objects
            };

        } catch (error) {
            console.error('[Flor Multimodal] Error con Azure Vision:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Analiza imagen usando OpenAI Vision API (GPT-4 Vision)
     */
    async analyzeWithOpenAI(imageFile) {
        if (!this.config.image.apiKey) {
            return { success: false, error: 'API key no configurada' };
        }

        try {
            const base64Image = await this.fileToBase64(imageFile);
            
            const response = await fetch('https://api.openai.com/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.config.image.apiKey}`
                },
                body: JSON.stringify({
                    model: 'gpt-4o', // o gpt-4-vision-preview
                    messages: [{
                        role: 'user',
                        content: [
                            {
                                type: 'text',
                                text: 'Describe esta imagen en detalle, especialmente si muestra un hotel, habitación, o algún problema relacionado con reservas. Responde en español de forma concisa.'
                            },
                            {
                                type: 'image_url',
                                image_url: {
                                    url: base64Image
                                }
                            }
                        ]
                    }],
                    max_tokens: 300
                })
            });

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            const description = data.choices?.[0]?.message?.content;

            if (!description) {
                return { success: false, error: 'no_description' };
            }

            return {
                success: true,
                description: description
            };

        } catch (error) {
            console.error('[Flor Multimodal] Error con OpenAI Vision:', error);
            return { success: false, error: error.message };
        }
    }

    // ==================== UTILIDADES ====================

    /**
     * Convierte un archivo a base64
     */
    async fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    /**
     * Verifica si el servicio está disponible
     */
    isAvailable() {
        return this.config.audio.enabled || this.config.image.enabled;
    }
}

// Crear instancia global
const florMultimodalService = new FlorMultimodalService();

// Exportar para uso en otros archivos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FlorMultimodalService;
}

