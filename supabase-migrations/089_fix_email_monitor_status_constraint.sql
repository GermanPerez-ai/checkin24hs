-- Fix email_monitor_notifications status constraint to include all statuses used by monitor.js
-- Issue: --mark-existing flag fails because 'marked_existing' status is not in the CHECK constraint

-- Drop the old constraint
ALTER TABLE public.email_monitor_notifications
DROP CONSTRAINT IF EXISTS email_monitor_notifications_status_check;

-- Recreate with all statuses actually used by the code:
-- - 'processing': set when email is being processed (before sending)
-- - 'notified': successfully sent to WhatsApp
-- - 'error': failed to send to WhatsApp
-- - 'skipped': legacy status (kept for backwards compatibility)
-- - 'marked_existing': set by --mark-existing flag (marks old emails without sending)
ALTER TABLE public.email_monitor_notifications
ADD CONSTRAINT email_monitor_notifications_status_check
CHECK (status IN ('processing', 'notified', 'error', 'skipped', 'marked_existing'));

COMMENT ON CONSTRAINT email_monitor_notifications_status_check ON public.email_monitor_notifications IS
  'Valid status values: processing (being processed), notified (sent), error (failed), skipped (legacy), marked_existing (seeded without sending)';
