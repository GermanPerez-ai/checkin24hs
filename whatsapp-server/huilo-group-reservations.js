/**
 * Grupo WhatsApp "Confirmaciones Huilo" (Línea 2).
 * No responde. Solo confirma / modifica / anula reservas en Supabase.
 */
const { parseHuiloConfirmation } = require('./huilo-parse');

const GROUP_NAME_DEFAULT = 'Confirmaciones Huilo';
const groupNameCache = new Map();
let hotelCache = { at: 0, value: null };

function isHuiloGroupFeatureEnabled(instanceNumber) {
    const flag = process.env.HUILO_WA_GROUP_ENABLED;
    if (flag === '0' || flag === 'false') return false;
    if (flag === '1' || flag === 'true') return true;
    return Number(instanceNumber) === 2;
}

function unwrapMessage(message) {
    if (!message || typeof message !== 'object') return message;
    return (
        message.ephemeralMessage?.message ||
        message.viewOnceMessage?.message ||
        message.viewOnceMessageV2?.message ||
        message.viewOnceMessageV2Extension?.message ||
        message.editedMessage?.message ||
        message
    );
}

function textFromInner(inner) {
    if (!inner) return '';
    return (
        inner.conversation ||
        inner.extendedTextMessage?.text ||
        inner.imageMessage?.caption ||
        inner.videoMessage?.caption ||
        inner.documentMessage?.caption ||
        inner.buttonsMessage?.contentText ||
        ''
    );
}

function extractQuotedText(inner) {
    const ctx =
        inner?.extendedTextMessage?.contextInfo ||
        inner?.imageMessage?.contextInfo ||
        inner?.videoMessage?.contextInfo ||
        inner?.documentMessage?.contextInfo ||
        null;
    if (!ctx?.quotedMessage) return '';
    return textFromInner(unwrapMessage(ctx.quotedMessage)) || '';
}

function extractTexts(msg) {
    const inner = unwrapMessage(msg?.message) || msg?.message;
    return {
        text: String(textFromInner(inner) || '').trim(),
        quoted: String(extractQuotedText(inner) || '').trim(),
    };
}

function extractHuiloCodes(text) {
    const s = String(text || '');
    const found = s.match(/\b\d{9}\b/g) || [];
    return [...new Set(found)];
}

function isCancelIntent(text) {
    return /\b(anulad[aos]?|anular|anulación|anulacion|cancelad[aos]?|cancelar|cancelación|cancelacion|suspender|suspendida)\b/i.test(
        String(text || '')
    );
}

function isModificationIntent(text) {
    return /\b(modific|cambio de fecha|cambiar fecha|x esta)\b/i.test(String(text || ''));
}

async function resolveGroupName(sock, jid) {
    if (groupNameCache.has(jid)) return groupNameCache.get(jid);
    try {
        const meta = await sock.groupMetadata(jid);
        const name = (meta?.subject || '').trim();
        groupNameCache.set(jid, name);
        return name;
    } catch (e) {
        console.warn('⚠️ Huilo grupo: no se pudo leer metadata', jid, e.message || e);
        groupNameCache.set(jid, '');
        return '';
    }
}

async function isTargetHuiloGroup(sock, jid) {
    const wantJid = (process.env.HUILO_WA_GROUP_JID || '').trim().toLowerCase();
    if (wantJid) return String(jid).toLowerCase() === wantJid;
    const wantName = (process.env.HUILO_WA_GROUP_NAME || GROUP_NAME_DEFAULT).trim().toLowerCase();
    const name = (await resolveGroupName(sock, jid)).toLowerCase();
    if (!name) return false;
    return name === wantName || (name.includes('confirmaciones') && name.includes('huilo'));
}

async function findHuiloHotel(supabase) {
    if (hotelCache.value && Date.now() - hotelCache.at < 10 * 60 * 1000) return hotelCache.value;
    const { data } = await supabase
        .from('hotels')
        .select('id,name')
        .or('name.ilike.*huilo*,name.ilike.*Huilo*')
        .limit(8);
    const list = data || [];
    const preferred =
        list.find((h) => /huilo/i.test(h.name || '') && !/pack/i.test(h.name || '')) || list[0];
    const value = preferred
        ? { id: preferred.id || null, name: preferred.name || 'Hotel Huilo-Huilo' }
        : { id: null, name: 'Hotel Huilo-Huilo' };
    hotelCache = { at: Date.now(), value };
    return value;
}

async function findReservationsByCodes(supabase, codes) {
    if (!codes.length) return [];
    const orParts = [];
    for (const c of codes) {
        orParts.push(`reservation_code.eq.${c}`);
        orParts.push(`reservation_code.ilike.*${c}*`);
    }
    const { data, error } = await supabase
        .from('reservations')
        .select('id,reservation_code,status,check_in,check_out,total_amount')
        .or(orParts.join(','));
    if (error) throw error;
    return data || [];
}

async function upsertFromConfirmation(supabase, parsed, { modified }) {
    const hotel = await findHuiloHotel(supabase);
    const existing = await findReservationsByCodes(supabase, extractHuiloCodes(parsed.reservation_code));
    const status = existing.length || modified ? 'Modificada' : 'Confirmada';
    const row = {
        reservation_code: parsed.reservation_code,
        client_name: parsed.client_name,
        client_email: '',
        client_phone: '',
        hotel_id: hotel.id,
        hotel_name: hotel.name,
        check_in: parsed.check_in,
        check_out: parsed.check_out,
        reservation_date: new Date().toISOString().slice(0, 10),
        agent_name: 'WhatsApp Huilo',
        status,
        total_amount: parsed.total_amount || 0,
        notes: (parsed.notes || '').replace('Origen: email Huilo (IMAP)', 'Origen: WhatsApp grupo Huilo'),
    };
    if (existing[0]?.id) {
        const { error } = await supabase.from('reservations').update(row).eq('id', existing[0].id);
        if (error) {
            if (/notes|column/i.test(error.message || '')) {
                delete row.notes;
                const { error: e2 } = await supabase.from('reservations').update(row).eq('id', existing[0].id);
                if (e2) throw e2;
            } else throw error;
        }
        return { action: 'updated', status, code: parsed.reservation_code };
    }
    const { error } = await supabase.from('reservations').upsert([row], { onConflict: 'reservation_code' });
    if (error) {
        if (/notes|column/i.test(error.message || '')) {
            delete row.notes;
            const { error: e2 } = await supabase.from('reservations').upsert([row], { onConflict: 'reservation_code' });
            if (e2) throw e2;
        } else throw error;
    }
    return { action: 'upserted', status, code: parsed.reservation_code };
}

async function cancelByCodes(supabase, codes) {
    const rows = await findReservationsByCodes(supabase, codes);
    if (!rows.length) return { action: 'not_found', codes };
    for (const r of rows) {
        const { error } = await supabase
            .from('reservations')
            .update({ status: 'Cancelada', agent_name: 'WhatsApp Huilo' })
            .eq('id', r.id);
        if (error) throw error;
    }
    return { action: 'cancelled', codes: rows.map((r) => r.reservation_code) };
}

/**
 * @returns {boolean} true si el JID es grupo (Flor no debe contestar, haya o no match de Huilo)
 */
function isWhatsAppGroupJid(jid) {
    return String(jid || '').includes('@g.us');
}

async function handleHuiloGroupMessage(sock, msg, { supabase, instanceNumber }) {
    if (!isHuiloGroupFeatureEnabled(instanceNumber)) return { handled: false };
    if (!supabase) return { handled: false };
    const jid = msg?.key?.remoteJid;
    if (!isWhatsAppGroupJid(jid)) return { handled: false };
    if (!(await isTargetHuiloGroup(sock, jid))) {
        return { handled: true, skipped: 'other_group' };
    }

    const { text, quoted } = extractTexts(msg);
    const blob = `${text}\n${quoted}`.trim();
    if (!blob) return { handled: true, skipped: 'empty' };

    if (isCancelIntent(text) || (isCancelIntent(quoted) && isCancelIntent(text))) {
        const codes = extractHuiloCodes(blob);
        if (!codes.length) {
            console.log('🏨 Huilo grupo: anulación sin número de confirmación');
            return { handled: true, skipped: 'cancel_no_code' };
        }
        const res = await cancelByCodes(supabase, codes);
        console.log('🏨 Huilo grupo: cancelación', JSON.stringify(res));
        return { handled: true, result: res };
    }

    const parsed = parseHuiloConfirmation({
        from: 'whatsapp-huilo',
        subject: /confirmaci[oó]n de reserva/i.test(blob) ? 'Confirmación' : '',
        text: blob,
    });
    if (parsed) {
        const modified = isModificationIntent(text) || isModificationIntent(quoted);
        const res = await upsertFromConfirmation(supabase, parsed, { modified });
        console.log('🏨 Huilo grupo: confirmación/modificación', JSON.stringify(res));
        return { handled: true, result: res };
    }

    return { handled: true, skipped: 'no_op' };
}

module.exports = {
    handleHuiloGroupMessage,
    isWhatsAppGroupJid,
    isHuiloGroupFeatureEnabled,
    extractHuiloCodes,
    isCancelIntent,
    parseHuiloConfirmation,
};
