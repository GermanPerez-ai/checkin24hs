const XLSX = require('xlsx');
const path = process.argv[2] || 'c:/Users/German/Downloads/Reporte FLEXIPASS ARG. 2026.xlsx';

function normalizeHeader(str) {
    return String(str || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}
function getCellByAliases(rowObj, aliases) {
    const normalizedKeys = Object.keys(rowObj || {}).map(k => ({ raw: k, norm: normalizeHeader(k) }));
    for (const alias of aliases) {
        const k = normalizeHeader(alias);
        if (rowObj[k] != null && String(rowObj[k]).trim() !== '') return String(rowObj[k]).trim();
        const aliasTokens = k.split(' ').filter(Boolean);
        const keyMatch = normalizedKeys.find(({ norm }) => aliasTokens.every(t => norm.includes(t)));
        if (keyMatch && rowObj[keyMatch.raw] != null && String(rowObj[keyMatch.raw]).trim() !== '') return String(rowObj[keyMatch.raw]).trim();
    }
    return '';
}

function parseDateMaybe(raw) {
    const v = String(raw || '').trim();
    if (!v) return '';
    const m = v.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})$/);
    if (m) {
        const dd = m[1].padStart(2, '0');
        const mm = m[2].padStart(2, '0');
        const yyyy = m[3].length === 2 ? `20${m[3]}` : m[3];
        return `${yyyy}-${mm}-${dd}`;
    }
    if (/^\d{4}-\d{2}-\d{2}$/.test(v)) return v;
    const serial = Number(v);
    if (Number.isFinite(serial) && serial > 20000 && serial < 80000) {
        const date = new Date(new Date(1899, 11, 30).getTime() + serial * 86400000);
        if (!isNaN(date.getTime())) return date.toISOString().slice(0, 10);
    }
    return '';
}

function parseMontoPesosAR(raw) {
    let s = String(raw == null ? '' : raw).replace(/\s/g, '').trim();
    if (!s) return 0;
    s = s.replace(/[^\d,.\-]/g, '');
    if (!s) return 0;
    const lastComma = s.lastIndexOf(',');
    const lastDot = s.lastIndexOf('.');
    if (lastComma > lastDot) {
        const n = parseFloat(s.slice(0, lastComma).replace(/\./g, '') + '.' + s.slice(lastComma + 1));
        return Number.isFinite(n) ? Math.round(n) : 0;
    }
    if (s.includes('.') && !s.includes(',')) {
        const parts = s.split('.');
        if (parts.length > 1 && parts[parts.length - 1].length === 3) {
            return parseInt(parts.join(''), 10) || 0;
        }
    }
    if (lastDot > lastComma && lastDot !== -1) {
        const intPart = s.slice(0, lastDot).replace(/,/g, '');
        const decPart = s.slice(lastDot + 1).replace(/,/g, '');
        const n = decPart ? parseFloat(intPart + '.' + decPart) : parseFloat(intPart);
        return Number.isFinite(n) ? Math.round(n) : 0;
    }
    return Math.round(Number(s.replace(/\./g, '').replace(',', '.'))) || 0;
}

function resolveCorralcoClienteNombre(r) {
    return getCellByAliases(r, ['cliente', 'nombre cliente']) ||
        [getCellByAliases(r, ['nombre']), getCellByAliases(r, ['apellidos'])].filter(Boolean).join(' ').trim();
}

function resolveCorralcoVoucherCodigo(r, rowIndex) {
    const tbk = getCellByAliases(r, ['codigo tbk', 'codigo tkb']);
    if (tbk) return `TBK-${String(tbk).replace(/\s+/g, '').toUpperCase()}`;
    const boleta = getCellByAliases(r, ['n boleta', 'nº boleta', 'boleta']);
    if (boleta) return `FP-BOL-${String(boleta).replace(/\s+/g, '')}`;
    const num = getCellByAliases(r, ['#']);
    if (num && String(num).trim()) return `FP-${String(num).replace(/\s+/g, '').toUpperCase()}`;
    return `FP-CLI-${rowIndex + 1}`;
}

function corralcoRowDedupeKey(r) {
    return [
        resolveCorralcoVoucherCodigo(r, 0),
        getCellByAliases(r, ['email', 'correo']).toLowerCase(),
        getCellByAliases(r, ['#']),
        getCellByAliases(r, ['codigo tbk']),
        getCellByAliases(r, ['n boleta', 'nº boleta']),
        getCellByAliases(r, ['monto']),
        parseDateMaybe(getCellByAliases(r, ['fecha transaccion', 'fecha transacción'])),
        getCellByAliases(r, ['n tarjeta', 'nº tarjeta'])
    ].join('|');
}

const wb = XLSX.readFile(path);
const json = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], { defval: '' });
const dataRows = json.map(r => {
    const o = {};
    Object.keys(r).forEach(k => { o[normalizeHeader(k)] = r[k]; });
    return o;
});

let rows = dataRows.filter(r => /flexipass|flexi pass|flexi/i.test(getCellByAliases(r, ['tipo ticket 2026', 'tipo ticket']) || ''));
const seen = new Set();
let skipped = 0;
const out = [];
for (const r of rows) {
    const email = getCellByAliases(r, ['email', 'correo']);
    const nombre = resolveCorralcoClienteNombre(r);
    if (!email && !nombre) continue;
    const key = corralcoRowDedupeKey(r);
    if (seen.has(key)) { skipped++; continue; }
    seen.add(key);
    out.push(r);
}

const senia = 92000;
let packs = 0;
const clients = {};
out.forEach(r => {
    const m = parseMontoPesosAR(getCellByAliases(r, ['monto']));
    const p = m > 0 ? Math.max(1, Math.round(m / senia)) : 1;
    packs += p;
    const e = getCellByAliases(r, ['email', 'correo']).toLowerCase();
    if (!clients[e]) clients[e] = { nombre: resolveCorralcoClienteNombre(r), packs: 0 };
    clients[e].packs += p;
});

console.log('Archivo:', path);
console.log('Filas Excel:', dataRows.length);
console.log('Filas FlexiPass:', rows.length);
console.log('Tras deduplicar:', out.length, '(omitidas:', skipped + ')');
console.log('PACKs vendidos:', packs);
console.log('Clientes unicos:', Object.keys(clients).filter(Boolean).length);
console.log('Clientes con +1 PACK:', Object.values(clients).filter(c => c.packs > 1).length);
console.log('Monto $92.000 parseado:', parseMontoPesosAR('$ 92.000'));
console.log('\nTop multi-pack:');
Object.values(clients).filter(c => c.packs > 1).sort((a, b) => b.packs - a.packs).slice(0, 10)
    .forEach(c => console.log(`  ${c.nombre}: ${c.packs} PACKs`));
