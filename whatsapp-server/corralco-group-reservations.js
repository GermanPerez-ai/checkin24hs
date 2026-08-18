/**
 * Grupo WhatsApp "Reservas Corralco Paz" (Línea 2).
 * No responde. Solo anula o modifica reservas Corralco en Supabase.
 * Las altas nuevas entran por email (IMAP reservas@).
 */
const { parseCorralcoConfirmation, extractCorralcoCodes } = require('./corralco-parse');

const GROUP_NAME_DEFAULT = 'Reservas Corralco Paz';
const groupNameCache = new Map();
let hotelCache = { at: 0, value: null };

function isCorralcoGroupFeatureEnabled(instanceNumber) {
    const flag = process.env.CORRALCO_WA_GROUP_ENABLED;
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

function isCancelIntent(text) {
    return /\b(anulad[aos]?|anular|anulación|anulacion|cancelad[aos]?|cancelar|cancelación|cancelacion|suspender|suspendida)\b/i.test(
        String(text || '')
    );
}

function isModificationIntent(text) {
    return /\b(modific\w*|cambio de fecha|cambiar fecha|x esta|reagend\w*|reprogram\w*)\b/i.test(
        String(text || '')
    );
}

async function resolveGroupName(sock, jid) {
    if (groupNameCache.has(jid)) return groupNameCache.get(jid);
    try {
        const meta = await sock.groupMetadata(jid);
        const name = (meta?.subject || '').trim();
        groupNameCache.set(jid, name);
        return name;
    } catch (e) {
        console.warn('⚠️ Corralco grupo: no se pudo leer metadata', jid, e.message || e);
        groupNameCache.set(jid, '');
        return '';
    }
}

async function isTargetCorralcoGroup(sock, jid) {
    const wantJid = (process.env.CORRALCO_WA_GROUP_JID || '').trim().toLowerCase();
    if (wantJid) return String(jid).toLowerCase() === wantJid;
    const wantName = (process.env.CORRALCO_WA_GROUP_NAME || GROUP_NAME_DEFAULT).trim().toLowerCase();
    const name = (await resolveGroupName(sock, jid)).toLowerCase();
    if (!name) return false;
    if (name === wantName) return true;
    return name.includes('corralco') && (name.includes('reserva') || name.includes('paz'));
}

async function findCorralcoHotel(supabase) {
    if (hotelCache.value && Date.now() - hotelCache.at < 10 * 60 * 1000) return hotelCache.value;
    const { data } = await supabase.from('hotels').select('id,name').ilike('name', '%corralco%').limit(8);
    const list = data || [];
    const preferred =
        list.find((h) => /corralco/i.test(h.name || '') && !/pack/i.test(h.name || '')) || list[0];
    const value = preferred
        ? { id: preferred.id || null, name: preferred.name || 'Hotel Corralco Resort' }
        : { id: null, name: 'Hotel Corralco Resort' };
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
        .select('id,reservation_code,status,check_in,check_out,total_amount,hotel_name')
        .or(orParts.join(','));
    if (error) throw error;
    return data || [];
}

async function upsertModification(supabase, parsed) {
    const hotel = await findCorralcoHotel(supabase);
    const existing = await findReservationsByCodes(supabase, extractCorralcoCodes(parsed.reservation_code));
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
        agent_name: 'WhatsApp Corralco Paz',
        status: 'Modificada',
        total_amount: parsed.total_amount || 0,
        notes: parsed.notes || 'Origen: WhatsApp grupo Reservas Corralco Paz',
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
        return { action: 'updated', status: 'Modificada', code: parsed.reservation_code };
    }
    const { error } = await supabase.from('reservations').upsert([row], { onConflict: 'reservation_code' });
    if (error) {
        if (/notes|column/i.test(error.message || '')) {
            delete row.notes;
            const { error: e2 } = await supabase.from('reservations').upsert([row], { onConflict: 'reservation_code' });
            if (e2) throw e2;
        } else throw error;
    }
    return { action: 'upserted', status: 'Modificada', code: parsed.reservation_code };
}

async function cancelByCodes(supabase, codes) {
    const rows = await findReservationsByCodes(supabase, codes);
    if (!rows.length) return { action: 'not_found', codes };
    for (const r of rows) {
        const { error } = await supabase
            .from('reservations')
            .update({ status: 'Cancelada', agent_name: 'WhatsApp Corralco Paz' })
            .eq('id', r.id);
        if (error) throw error;
    }
    return { action: 'cancelled', codes: rows.map((r) => r.reservation_code) };
}

async function handleCorralcoGroupMessage(sock, msg, { supabase, instanceNumber }) {
    if (!isCorralcoGroupFeatureEnabled(instanceNumber)) return { handled: false };
    if (!supabase) return { handled: false };
    const jid = msg?.key?.remoteJid;
    if (!String(jid || '').includes('@g.us')) return { handled: false };
    if (!(await isTargetCorralcoGroup(sock, jid))) {
        return { handled: false, skipped: 'other_group' };
    }

    const { text, quoted } = extractTexts(msg);
    const blob = `${text}\n${quoted}`.trim();
    if (!blob) return { handled: true, skipped: 'empty' };

    if (isCancelIntent(text) || (isCancelIntent(quoted) && text)) {
        const codes = extractCorralcoCodes(blob);
        if (!codes.length) {
            console.log('⛷️ Corralco grupo: anulación sin número de reserva');
            return { handled: true, skipped: 'cancel_no_code' };
        }
        const res = await cancelByCodes(supabase, codes);
        console.log('⛷️ Corralco grupo: cancelación', JSON.stringify(res));
        return { handled: true, result: res };
    }

    const parsed = parseCorralcoConfirmation({
        from: 'whatsapp-corralco',
        subject: /confirmaci[oó]n|reserva|corralco/i.test(blob) ? 'Confirmación Corralco' : '',
        text: blob,
    });
    if (parsed) {
        const res = await upsertModification(supabase, parsed);
        console.log('⛷️ Corralco grupo: modificación', JSON.stringify(res));
        return { handled: true, result: res };
    }

    return { handled: true, skipped: 'no_op' };
}

module.exports = {
    handleCorralcoGroupMessage,
    isCorralcoGroupFeatureEnabled,
    extractCorralcoCodes,
    isCancelIntent,
    isModificationIntent,
    parseCorralcoConfirmation,
};
