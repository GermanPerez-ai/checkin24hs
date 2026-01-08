// Sistema de Aprendizaje Continuo para Flor
// Checkin24hs - Mejora Automática de Respuestas

const FlorLearningSystem = {
    // Configuración
    config: {
        enabled: true,
        minInteractionsForLearning: 3, // Mínimo de interacciones similares para aprender
        maxStoredInteractions: 1000, // Máximo de interacciones guardadas
        learningThreshold: 0.7, // Umbral de confianza para aplicar aprendizaje
        autoUpdateKnowledge: true // Actualizar base de conocimiento automáticamente
    },

    // Inicializar el sistema
    init() {
        this.loadConfig();
        console.log('[Flor Learning] ✅ Sistema de aprendizaje inicializado');
    },

    // Cargar configuración guardada
    loadConfig() {
        try {
            const saved = localStorage.getItem('flor_learning_config');
            if (saved) {
                this.config = { ...this.config, ...JSON.parse(saved) };
            }
        } catch (e) {
            console.error('[Flor Learning] Error al cargar configuración:', e);
        }
    },

    // Guardar configuración
    saveConfig() {
        try {
            localStorage.setItem('flor_learning_config', JSON.stringify(this.config));
        } catch (e) {
            console.error('[Flor Learning] Error al guardar configuración:', e);
        }
    },

    // Guardar una interacción
    saveInteraction(interaction) {
        if (!this.config.enabled) {
            console.log('[Flor Learning] ⚠️ Sistema de aprendizaje deshabilitado');
            return null;
        }

        if (!interaction || !interaction.userMessage) {
            console.warn('[Flor Learning] ⚠️ Interacción inválida:', interaction);
            return null;
        }

        try {
            const interactions = this.getInteractions();
            
            // Asegurar que botResponse sea un string
            const botResponseText = interaction.botResponse 
                ? (typeof interaction.botResponse === 'string' ? interaction.botResponse : JSON.stringify(interaction.botResponse))
                : '';
            
            // Agregar metadatos a la interacción
            const enrichedInteraction = {
                userMessage: String(interaction.userMessage || ''),
                botResponse: botResponseText,
                id: this.generateId(),
                timestamp: new Date().toISOString(),
                intent: interaction.intent || this.detectIntent(interaction.userMessage),
                hotelId: interaction.hotelId || null,
                success: interaction.success !== undefined ? interaction.success : true,
                responseLength: botResponseText.length,
                userSatisfaction: interaction.userSatisfaction || null,
                usedAI: interaction.usedAI || false
            };

            interactions.push(enrichedInteraction);

            // Limitar el número de interacciones guardadas
            if (interactions.length > this.config.maxStoredInteractions) {
                interactions.shift(); // Eliminar la más antigua
            }

            localStorage.setItem('flor_learning_interactions', JSON.stringify(interactions));
            
            console.log('[Flor Learning] 💾 Interacción guardada:', enrichedInteraction.id, {
                intent: enrichedInteraction.intent,
                messageLength: enrichedInteraction.userMessage.length,
                responseLength: enrichedInteraction.responseLength
            });
            
            // Analizar y aprender de la interacción (asíncrono para no bloquear)
            setTimeout(() => {
                try {
                    this.analyzeAndLearn(enrichedInteraction);
                } catch (e) {
                    console.error('[Flor Learning] Error al analizar interacción:', e);
                }
            }, 100);
            
            return enrichedInteraction.id;
        } catch (e) {
            console.error('[Flor Learning] ❌ Error al guardar interacción:', e, interaction);
            return null;
        }
    },

    // Obtener todas las interacciones guardadas
    getInteractions() {
        try {
            const stored = localStorage.getItem('flor_learning_interactions');
            return stored ? JSON.parse(stored) : [];
        } catch (e) {
            console.error('[Flor Learning] Error al cargar interacciones:', e);
            return [];
        }
    },

    // Detectar intención básica del mensaje
    detectIntent(message) {
        const messageLower = message.toLowerCase();
        
        if (messageLower.match(/\b(cotizar|precio|tarifa|costo|cuánto)\b/)) return 'precios';
        if (messageLower.match(/\b(reservar|reserva|booking|reservación)\b/)) return 'reservar';
        if (messageLower.match(/\b(ubicación|dónde|donde|ubicado|localización)\b/)) return 'ubicacion';
        if (messageLower.match(/\b(servicio|servicios|amenidades|amenidad)\b/)) return 'servicios';
        if (messageLower.match(/\b(disponibilidad|disponible|libre|vacante)\b/)) return 'disponibilidad';
        if (messageLower.match(/\b(hola|buenos días|buenas tardes|saludos)\b/)) return 'saludar';
        if (messageLower.match(/\b(gracias|ok|perfecto|excelente|genial)\b/)) return 'positivo';
        if (messageLower.match(/\b(no|incorrecto|mal|error|equivocado)\b/)) return 'negativo';
        
        return 'consulta_general';
    },

    // Analizar y aprender de una interacción
    analyzeAndLearn(interaction) {
        if (!this.config.enabled) return;

        try {
            const interactions = this.getInteractions();
            
            // Buscar interacciones similares
            const similarInteractions = this.findSimilarInteractions(interaction, interactions);
            
            // Si hay suficientes interacciones similares, analizar patrones
            if (similarInteractions.length >= this.config.minInteractionsForLearning) {
                const patterns = this.identifyPatterns(similarInteractions);
                
                // Aplicar aprendizaje si el patrón es suficientemente claro
                if (patterns.confidence >= this.config.learningThreshold) {
                    this.applyLearning(patterns, interaction);
                }
            }

            // Actualizar estadísticas
            this.updateStatistics(interaction);
            
        } catch (e) {
            console.error('[Flor Learning] Error al analizar interacción:', e);
        }
    },

    // Encontrar interacciones similares
    findSimilarInteractions(interaction, allInteractions) {
        return allInteractions.filter(inter => {
            // Misma intención
            if (inter.intent !== interaction.intent) return false;
            
            // Mismo hotel (si aplica)
            if (interaction.hotelId && inter.hotelId !== interaction.hotelId) return false;
            
            // Mensaje similar (similitud básica)
            const similarity = this.calculateSimilarity(
                inter.userMessage.toLowerCase(),
                interaction.userMessage.toLowerCase()
            );
            
            return similarity > 0.5; // 50% de similitud
        });
    },

    // Calcular similitud entre dos mensajes (método simple)
    calculateSimilarity(message1, message2) {
        const words1 = message1.split(/\s+/);
        const words2 = message2.split(/\s+/);
        
        const commonWords = words1.filter(word => words2.includes(word));
        const totalWords = new Set([...words1, ...words2]).size;
        
        return totalWords > 0 ? commonWords.length / totalWords : 0;
    },

    // Identificar patrones en interacciones similares
    identifyPatterns(interactions) {
        const patterns = {
            intent: interactions[0].intent,
            commonKeywords: [],
            successfulResponses: [],
            averageResponseLength: 0,
            successRate: 0,
            confidence: 0
        };

        // Extraer palabras clave comunes
        const allWords = {};
        interactions.forEach(inter => {
            const words = inter.userMessage.toLowerCase().split(/\s+/);
            words.forEach(word => {
                if (word.length > 3) { // Ignorar palabras muy cortas
                    allWords[word] = (allWords[word] || 0) + 1;
                }
            });
        });

        // Obtener palabras más comunes
        patterns.commonKeywords = Object.entries(allWords)
            .filter(([word, count]) => count >= 2)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 5)
            .map(([word]) => word);

        // Analizar respuestas exitosas
        const successful = interactions.filter(inter => inter.success !== false);
        patterns.successfulResponses = successful.map(inter => inter.botResponse);
        patterns.successRate = successful.length / interactions.length;

        // Calcular longitud promedio de respuesta
        const responseLengths = interactions
            .map(inter => inter.responseLength)
            .filter(len => len > 0);
        patterns.averageResponseLength = responseLengths.length > 0
            ? responseLengths.reduce((a, b) => a + b, 0) / responseLengths.length
            : 0;

        // Calcular confianza basada en consistencia
        patterns.confidence = Math.min(
            patterns.successRate,
            patterns.commonKeywords.length / 5,
            successful.length / this.config.minInteractionsForLearning
        );

        return patterns;
    },

    // Aplicar aprendizaje identificado
    applyLearning(patterns, currentInteraction) {
        if (!this.config.autoUpdateKnowledge) return;

        try {
            console.log('[Flor Learning] 🧠 Aplicando aprendizaje:', patterns.intent);

            // Actualizar intenciones en la base de conocimiento
            if (patterns.commonKeywords.length > 0) {
                this.updateIntentKeywords(patterns.intent, patterns.commonKeywords);
            }

            // Guardar respuestas exitosas como ejemplos
            if (patterns.successfulResponses.length > 0) {
                this.saveSuccessfulResponses(patterns.intent, patterns.successfulResponses);
            }

            // Actualizar estadísticas de aprendizaje
            this.updateLearningStats(patterns);

        } catch (e) {
            console.error('[Flor Learning] Error al aplicar aprendizaje:', e);
        }
    },

    // Actualizar palabras clave de intenciones
    updateIntentKeywords(intent, newKeywords) {
        try {
            if (typeof FlorKnowledgeBase === 'undefined') return;

            const currentKeywords = FlorKnowledgeBase.intents[intent] || [];
            const updatedKeywords = [...new Set([...currentKeywords, ...newKeywords])];
            
            // Guardar en localStorage
            const intents = { ...FlorKnowledgeBase.intents };
            intents[intent] = updatedKeywords;
            
            localStorage.setItem('flor_learned_intents', JSON.stringify(intents));
            
            console.log('[Flor Learning] ✅ Palabras clave actualizadas para:', intent);
        } catch (e) {
            console.error('[Flor Learning] Error al actualizar palabras clave:', e);
        }
    },

    // Guardar respuestas exitosas como ejemplos
    saveSuccessfulResponses(intent, responses) {
        try {
            const stored = localStorage.getItem('flor_learned_responses');
            const learnedResponses = stored ? JSON.parse(stored) : {};
            
            if (!learnedResponses[intent]) {
                learnedResponses[intent] = [];
            }

            // Agregar respuestas únicas
            responses.forEach(response => {
                if (!learnedResponses[intent].includes(response)) {
                    learnedResponses[intent].push(response);
                }
            });

            // Limitar a 10 respuestas por intención
            if (learnedResponses[intent].length > 10) {
                learnedResponses[intent] = learnedResponses[intent].slice(-10);
            }

            localStorage.setItem('flor_learned_responses', JSON.stringify(learnedResponses));
            
            console.log('[Flor Learning] ✅ Respuestas exitosas guardadas para:', intent);
        } catch (e) {
            console.error('[Flor Learning] Error al guardar respuestas:', e);
        }
    },

    // Actualizar estadísticas de aprendizaje
    updateLearningStats(patterns) {
        try {
            const stored = localStorage.getItem('flor_learning_stats');
            const stats = stored ? JSON.parse(stored) : {
                totalPatterns: 0,
                patternsByIntent: {},
                lastUpdate: null
            };

            stats.totalPatterns++;
            stats.patternsByIntent[patterns.intent] = (stats.patternsByIntent[patterns.intent] || 0) + 1;
            stats.lastUpdate = new Date().toISOString();

            localStorage.setItem('flor_learning_stats', JSON.stringify(stats));
        } catch (e) {
            console.error('[Flor Learning] Error al actualizar estadísticas:', e);
        }
    },

    // Actualizar estadísticas generales
    updateStatistics(interaction) {
        try {
            const stored = localStorage.getItem('flor_learning_statistics');
            const stats = stored ? JSON.parse(stored) : {
                totalInteractions: 0,
                interactionsByIntent: {},
                interactionsByHotel: {},
                averageResponseTime: 0,
                successRate: 0,
                lastInteraction: null
            };

            stats.totalInteractions++;
            
            // Por intención
            if (interaction.intent) {
                stats.interactionsByIntent[interaction.intent] = 
                    (stats.interactionsByIntent[interaction.intent] || 0) + 1;
            }

            // Por hotel
            if (interaction.hotelId) {
                stats.interactionsByHotel[interaction.hotelId] = 
                    (stats.interactionsByHotel[interaction.hotelId] || 0) + 1;
            }

            // Tasa de éxito
            const interactions = this.getInteractions();
            const successful = interactions.filter(inter => inter.success !== false).length;
            stats.successRate = interactions.length > 0 ? successful / interactions.length : 0;

            stats.lastInteraction = new Date().toISOString();

            localStorage.setItem('flor_learning_statistics', JSON.stringify(stats));
        } catch (e) {
            console.error('[Flor Learning] Error al actualizar estadísticas:', e);
        }
    },

    // Obtener estadísticas
    getStatistics() {
        try {
            const stored = localStorage.getItem('flor_learning_statistics');
            return stored ? JSON.parse(stored) : null;
        } catch (e) {
            return null;
        }
    },

    // Obtener respuestas aprendidas para una intención
    getLearnedResponses(intent) {
        try {
            const stored = localStorage.getItem('flor_learned_responses');
            const learnedResponses = stored ? JSON.parse(stored) : {};
            return learnedResponses[intent] || [];
        } catch (e) {
            return [];
        }
    },

    // Obtener palabras clave aprendidas para una intención
    getLearnedKeywords(intent) {
        try {
            const stored = localStorage.getItem('flor_learned_intents');
            const intents = stored ? JSON.parse(stored) : {};
            return intents[intent] || [];
        } catch (e) {
            return [];
        }
    },

    // Registrar feedback del usuario
    recordFeedback(interactionId, feedback) {
        try {
            const interactions = this.getInteractions();
            const interaction = interactions.find(inter => inter.id === interactionId);
            
            if (interaction) {
                interaction.userSatisfaction = feedback; // 'positive', 'negative', 'neutral'
                interaction.feedbackTimestamp = new Date().toISOString();
                
                // Si es negativo, marcar como no exitoso
                if (feedback === 'negative') {
                    interaction.success = false;
                }
                
                localStorage.setItem('flor_learning_interactions', JSON.stringify(interactions));
                
                // Re-analizar con el nuevo feedback
                this.analyzeAndLearn(interaction);
                
                console.log('[Flor Learning] ✅ Feedback registrado:', feedback);
                return true;
            }
            
            return false;
        } catch (e) {
            console.error('[Flor Learning] Error al registrar feedback:', e);
            return false;
        }
    },

    // Generar ID único
    generateId() {
        return 'interaction_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    },

    // Obtener recomendaciones de mejora
    getImprovementRecommendations() {
        try {
            const stats = this.getStatistics();
            const interactions = this.getInteractions();
            
            if (!stats || interactions.length === 0) {
                return [];
            }

            const recommendations = [];

            // Analizar intenciones con baja tasa de éxito
            Object.entries(stats.interactionsByIntent).forEach(([intent, count]) => {
                const intentInteractions = interactions.filter(inter => inter.intent === intent);
                const successRate = intentInteractions.filter(inter => inter.success !== false).length / intentInteractions.length;
                
                if (successRate < 0.7 && count >= 5) {
                    recommendations.push({
                        type: 'low_success_rate',
                        intent: intent,
                        successRate: (successRate * 100).toFixed(1) + '%',
                        recommendation: `La intención "${intent}" tiene una tasa de éxito baja. Considera revisar las respuestas para esta intención.`
                    });
                }
            });

            // Analizar respuestas muy largas o muy cortas
            const avgLength = interactions
                .map(inter => inter.responseLength)
                .filter(len => len > 0)
                .reduce((a, b) => a + b, 0) / interactions.filter(inter => inter.responseLength > 0).length;

            if (avgLength > 500) {
                recommendations.push({
                    type: 'long_responses',
                    recommendation: 'Las respuestas son muy largas. Considera hacerlas más concisas para mejor experiencia del usuario.'
                });
            } else if (avgLength < 50) {
                recommendations.push({
                    type: 'short_responses',
                    recommendation: 'Las respuestas son muy cortas. Considera proporcionar más información útil.'
                });
            }

            return recommendations;
        } catch (e) {
            console.error('[Flor Learning] Error al obtener recomendaciones:', e);
            return [];
        }
    },

    // Limpiar datos antiguos
    cleanupOldData(daysToKeep = 30) {
        try {
            const interactions = this.getInteractions();
            const cutoffDate = new Date();
            cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

            const filtered = interactions.filter(inter => {
                const interDate = new Date(inter.timestamp);
                return interDate >= cutoffDate;
            });

            localStorage.setItem('flor_learning_interactions', JSON.stringify(filtered));
            console.log('[Flor Learning] 🧹 Datos antiguos limpiados. Interacciones restantes:', filtered.length);
        } catch (e) {
            console.error('[Flor Learning] Error al limpiar datos:', e);
        }
    }
};

// Inicializar automáticamente cuando se carga el script
if (typeof window !== 'undefined') {
    FlorLearningSystem.init();
}

