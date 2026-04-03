-- Captura de pago (comprobante imagen) por voucher Flexi.
-- URL absoluta o data URL (JPEG comprimido desde el dashboard).
ALTER TABLE public.flexi_vouchers
  ADD COLUMN IF NOT EXISTS captura_pago_url TEXT;

COMMENT ON COLUMN public.flexi_vouchers.captura_pago_url IS 'URL o data URL de la captura/comprobante de pago del cliente';
