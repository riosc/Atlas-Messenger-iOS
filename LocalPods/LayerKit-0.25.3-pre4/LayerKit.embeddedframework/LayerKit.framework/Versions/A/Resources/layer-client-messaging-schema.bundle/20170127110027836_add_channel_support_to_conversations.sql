-- Adding the `read_receipts_enabled` to the `conversations` table.
ALTER TABLE conversations ADD read_receipts_enabled BOOLEAN DEFAULT 1;
