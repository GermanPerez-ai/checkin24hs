#!/usr/bin/env python3
"""Tests del parser Huilo (texto plano + tablas HTML + fechas cortas)."""
import datetime as dt
from parse_huilo import (
    parse_huilo_confirmation,
    parse_huilo_confirmations,
    parse_huilo_date,
    html_to_text,
)

assert parse_huilo_date("04-noviembre-2026") == "2026-11-04"
assert parse_huilo_date("06-11-26") == "2026-11-06"
assert parse_huilo_date("03-feb-27") == "2027-02-03"
assert parse_huilo_date("16-07", ref_date=dt.date(2026, 5, 22)) == "2026-07-16"
assert parse_huilo_date("13-06", ref_date=dt.date(2026, 5, 22)) == "2026-06-13"

sample1 = """
Estimados, Envío confirmación de reserva según lo solicitado.
Confirmación de reserva
Nombre: Mariana Carla Peralta
Alojamiento: Nothofagus
Número de confirmación: 599088009
Pasajeros: 2 adultos + 01 niño
Categoría de habitación: Estándar Triple
Tipo de habitación: Cama mat + individual
Plan de alimentación: Pensión completa
Fechas: In: 04-noviembre-2026 Out: 07-noviembre-2026
Tarifa final a pagar: USD 1200
"""
p1 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación Mariana Carla Peralta",
        "text": sample1,
    }
)
assert p1, "sample1 debe parsear"
assert p1["reservation_code"] == "599088009"
assert p1["client_name"] == "Mariana Carla Peralta"
assert p1["check_in"] == "2026-11-04"
assert p1["check_out"] == "2026-11-07"
assert p1["adults"] == 2
assert p1["children"] == 1

html_table = """
<html><body>
<table>
<tr><td>Nombre</td><td>Alvite Merino Federico Agustin</td></tr>
<tr><td>Alojamiento</td><td>Nothofagus</td></tr>
<tr><td>Número de confirmación</td><td>597001111</td></tr>
<tr><td>Pasajeros</td><td>2 adultos</td></tr>
<tr><td>Categoría de habitación</td><td>Estándar</td></tr>
<tr><td>Tipo de habitación</td><td>Matrimonial</td></tr>
<tr><td>Plan de alimentación</td><td>Pensión completa</td></tr>
<tr><td>Fechas</td><td>In: 12-septiembre-2026 Out: 14-septiembre-2026</td></tr>
<tr><td>Tarifa final a pagar</td><td>USD 800</td></tr>
</table>
</body></html>
"""
p2 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación Alvite Merino Federico Agustin",
        "text": "Este mensaje está en HTML.",
        "html": html_table,
    }
)
assert p2, "tabla HTML debe parsear"
assert p2["reservation_code"] == "597001111"
assert p2["client_name"] == "Alvite Merino Federico Agustin"
assert p2["check_in"] == "2026-09-12"
assert p2["check_out"] == "2026-09-14"

html_stacked = """
<table>
<tr><td>Nombre</td></tr><tr><td>agencia Caupolican</td></tr>
<tr><td>Número de confirmación</td></tr><tr><td>597002222</td></tr>
<tr><td>In</td></tr><tr><td>21-10-26</td></tr>
<tr><td>Out</td></tr><tr><td>24-10-26</td></tr>
<tr><td>Tarifa final a pagar</td></tr><tr><td>USD 1500</td></tr>
</table>
"""
converted = html_to_text(html_stacked)
assert "Nombre:" in converted
p3 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación agencia Caupolican",
        "html": html_stacked,
    }
)
assert p3, "filas apiladas deben parsear"
assert p3["reservation_code"] == "597002222"
assert p3["client_name"] == "agencia Caupolican"
assert p3["check_in"] == "2026-10-21"
assert p3["check_out"] == "2026-10-24"

html_codes_only = """
<p>Confirmación de reserva</p>
<table>
<tr><td>Número de confirmación</td><td>598111111 y 598111112</td></tr>
<tr><td>Fechas</td><td>In: 11-septiembre-2026 Out: 12-septiembre-2026</td></tr>
<tr><td>Tarifa final a pagar</td><td>USD 400</td></tr>
</table>
"""
p4 = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación José Luis Mansilla",
        "html": html_codes_only,
    }
)
assert p4, "nombre desde asunto"
assert p4["client_name"] == "José Luis Mansilla"
assert "598111111" in p4["reservation_code"]

skip_tarifas = parse_huilo_confirmation(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "RV: consulta tarifas para grupo diciembre 2026",
        "text": "Consulta de tarifas sin confirmación.",
    }
)
assert skip_tarifas is None

alvite = """
Confirmación de reserva
Nombre: Alvite Merino Federico Agustin
Alojamiento: Nothofagus
Número de confirmación: 596318402
Pasajeros: 02 adultos
Fechas: IN 13-06 OUT 15-06
Tarifa final a pagar: USD $680.-
"""
p_alvite = parse_huilo_confirmation(
    {
        "from": "laura.duarte@huilohuilo.com",
        "subject": "Confirmación Alvite Merino Federico Agustin",
        "text": alvite,
        "date": dt.date(2026, 5, 22),
    }
)
assert p_alvite, "Alvite fechas IN 13-06"
assert p_alvite["reservation_code"] == "596318402"
assert p_alvite["check_in"] == "2026-06-13"
assert p_alvite["check_out"] == "2026-06-15"
assert p_alvite["total_amount"] == 680

carpineti = """
1.- Confirmación de reserva
Nombre: Adriana Carpineti
Número de confirmación: 597391343, 597391675, 597391696 y 597391590
Pasajeros: 8 adultos
Fechas: In: 03-feb-27 Out:08-feb-27
Tarifa final a pagar: USD 7600
2.- Confirmación de reserva
Nombre: Adriana Carpineti
Número de confirmación: 597392330 y 597392502
Pasajeros: 4 adultos + 2 niños
Fechas: In: 03-feb-27 Out:08-feb-27
Tarifa final a pagar: USD 4800
"""
rows_c = parse_huilo_confirmations(
    {
        "from": "paz.galvez@huilohuilo.com",
        "subject": "Confirmación Adriana Carpineti",
        "text": carpineti,
    }
)
assert len(rows_c) == 2
assert rows_c[0]["check_in"] == "2027-02-03"
assert rows_c[0]["check_out"] == "2027-02-08"
assert "597391343" in rows_c[0]["reservation_code"]
assert rows_c[1]["total_amount"] == 4800
assert rows_c[1]["children"] == 2

caupolican = """
Confirmación de reserva
Nombre: Ana Mabel Benedicti
Número de confirmación: 596101564
Pasajeros: 02 adultos
Fechas: IN 16-07 OUT 18-07
Tarifa final a pagar: USD $760.-
Confirmación de reserva
Nombre: Bahnmuller, Alan Facundo
Número de confirmación: 596101630
Pasajeros: 01 adulto
Fechas: IN 16-07 OUT 18-07
Tarifa final a pagar: USD $440.-
Confirmación de reserva
Nombre: Erwin Juniors Bahnmuller
Número de confirmación: 596102017
Pasajeros: 02 adultos + 01 niño
Fechas: IN 16-07 OUT 18-07
Tarifa final a pagar: USD $960.-
De: Laura Duarte
Enviado el: viernes, 22 de mayo de 2026 17:27
Confirmación de reserva
Nombre: NO DEBE APARECER
Número de confirmación: 599999999
Fechas: IN 16-07 OUT 18-07
Tarifa final a pagar: USD $1.-
"""
rows_k = parse_huilo_confirmations(
    {
        "from": "laura.duarte@huilohuilo.com",
        "subject": "Confirmación agencia Caupolican",
        "text": caupolican,
        "date": dt.date(2026, 5, 22),
    }
)
assert len(rows_k) == 3, rows_k
assert rows_k[0]["client_name"] == "Ana Mabel Benedicti"
assert rows_k[1]["client_name"] == "Bahnmuller, Alan Facundo"
assert rows_k[2]["children"] == 1
assert rows_k[0]["check_in"] == "2026-07-16"

print("OK parse_huilo tests")
