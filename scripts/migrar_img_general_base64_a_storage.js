#!/usr/bin/env node
/**
 * Migración: convertir flor_info.img_general de Base64 a URL de Supabase Storage.
 * Así Flor IA no recibe Base64 en el payload y "enviar imagen del hotel" sigue funcionando con URL.
 *
 * Uso:
 *   1. Crear bucket "flor-ficha" en Supabase Storage (público) si no existe.
 *   2. Ejecutar migración RLS: supabase-migrations/009_storage_flor_ficha_rls.sql
 *   3. Desde la raíz: (cd whatsapp-server && node ../scripts/migrar_img_general_base64_a_storage.js)
 *      O instalar en raíz: npm install @supabase/supabase-js && node scripts/migrar_img_general_base64_a_storage.js
 *
 * Variables de entorno:
 *   SUPABASE_URL    (requerido)
 *   SUPABASE_SERVICE_ROLE_KEY  (recomendado para poder actualizar hotels; si no, usar SUPABASE_ANON_KEY y RLS que permita update)
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;
const BUCKET = 'flor-ficha';

function isBase64Image(val) {
    if (typeof val !== 'string' || !val.trim()) return false;
    return /^data:image\/[^;]+;base64,/i.test(val.trim());
}

async function main() {
    if (!SUPABASE_URL || !SUPABASE_KEY) {
        console.error('❌ Definí SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY (o SUPABASE_ANON_KEY)');
        process.exit(1);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    const { data: hotels, error: listError } = await supabase
        .from('hotels')
        .select('id, name, flor_info');

    if (listError) {
        console.error('❌ Error listando hoteles:', listError.message);
        process.exit(1);
    }

    const conBase64 = (hotels || []).filter(h => {
        const fi = h.flor_info || {};
        const img = fi.img_general;
        return img && isBase64Image(img);
    });

    if (conBase64.length === 0) {
        console.log('✅ No hay hoteles con img_general en Base64. Nada que migrar.');
        return;
    }

    console.log(`📋 ${conBase64.length} hotel(es) con img_general en Base64. Migrando a Storage...`);

    for (const hotel of conBase64) {
        const fi = hotel.flor_info || {};
        const dataUrl = fi.img_general;
        const match = dataUrl.match(/^data:image\/(\w+);base64,(.+)$/);
        if (!match) {
            console.warn(`⚠️ Hotel ${hotel.name} (${hotel.id}): img_general no es Base64 válido, omitiendo.`);
            continue;
        }
        const mimeExt = match[1].toLowerCase() === 'png' ? 'png' : 'jpg';
        const base64Data = match[2];
        let buffer;
        try {
            buffer = Buffer.from(base64Data, 'base64');
        } catch (e) {
            console.warn(`⚠️ Hotel ${hotel.name}: error decodificando Base64`, e.message);
            continue;
        }

        const path = `hotel-images/${hotel.id}/img_general.${mimeExt}`;
        const { error: uploadError } = await supabase.storage
            .from(BUCKET)
            .upload(path, buffer, {
                contentType: `image/${mimeExt}`,
                upsert: true
            });

        if (uploadError) {
            console.error(`❌ Hotel ${hotel.name} (${hotel.id}): error subiendo a Storage:`, uploadError.message);
            continue;
        }

        const { data: urlData } = supabase.storage.from(BUCKET).getPublicUrl(path);
        const publicUrl = urlData.publicUrl;

        const newFlorInfo = { ...fi, img_general: publicUrl };
        const { error: updateError } = await supabase
            .from('hotels')
            .update({ flor_info: newFlorInfo })
            .eq('id', hotel.id);

        if (updateError) {
            console.error(`❌ Hotel ${hotel.name} (${hotel.id}): error actualizando flor_info:`, updateError.message);
            continue;
        }

        console.log(`✅ ${hotel.name}: img_general migrado a ${publicUrl.substring(0, 60)}...`);
    }

    console.log('✅ Migración finalizada.');
}

main().catch(e => {
    console.error(e);
    process.exit(1);
});
