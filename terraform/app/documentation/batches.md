# Batches `[BATCH_FORMAT]`

This section describes the process for submitting transactions in bulk using batch file uploads.

## Overview

_(High-level description of batch processing needs to be extracted from the 'Batches > Overview' page)_

Batch processing allows merchants to submit multiple transactions (Purchases, Refunds, Direct Debits) simultaneously by uploading a formatted file, typically in CSV format. This is useful for high-volume processing.

## Uploading Batches

_(Verify exact methods against official documentation)_

Batch files are typically uploaded via:

- **Merchant Dashboard:** A common method involves logging into the Fat Zebra Merchant Dashboard and navigating to a section like 'Direct Entries' or 'Batch Uploads' to manually upload the CSV file. _(See [Merchant Dashboard](./merchant-dashboard.md#direct-entries--batches))_
- **SFTP (Secure File Transfer Protocol):** For automated processing, Fat Zebra may provide SFTP credentials and a specific directory structure for uploading batch files.
- **API Endpoint:** Less common for traditional batches, but check if an API endpoint exists for submitting batch file content directly.

- **Format:** Usually CSV (Comma Separated Values). Pay close attention to required encoding (e.g., UTF-8), delimiters (comma), and whether a header row is expected or forbidden.

## File Formats

Files must contain specific columns in the correct order. Data formatting (e.g., date formats, amount in cents) must be precise.

### Purchase Batch File Columns

_(Verify columns against 'Purchase Batch File Columns' page)_

Likely columns include: `amount` (cents), `reference` (unique), `card_number`, `card_holder`, `card_expiry_month`, `card_expiry_year`, `cvv`, `customer_ip`, potentially address fields for AVS.

### Refund Batch File Columns

_(Verify columns against 'Refund Batch File Columns' page)_

Likely columns include: `original_transaction_id` (the ID of the purchase to refund), `amount` (optional, cents, defaults to full amount if omitted), `reference` (unique for the refund transaction).

### Direct Debit Batch File Columns

_(Verify columns against 'Direct Debit Batch File Columns' page)_

Likely columns include: `amount` (cents), `reference` (unique), `bsb`, `account_number`, `account_name`, `lodgement_reference`.

## Result Files

_(Verify result file process and format against 'Result Files' page)_

After Fat Zebra processes an uploaded batch file, a result file is generated detailing the outcome of each transaction.

- **Retrieval:**
  - **Merchant Dashboard:** Usually downloadable from the same area where batches are uploaded or a dedicated 'Reports'/'Batch Results' section.
  - **SFTP:** If using SFTP upload, result files might be placed in a designated 'results' or 'outbox' directory.
  - **Email:** Notification or the file itself might be sent to a configured email address.
  - **Webhook:** A webhook event `batch.processed` might be triggered, potentially containing a summary or a link to the full results.
- **Format:** Typically a CSV file mirroring the input file structure, with additional columns indicating the processing status.
  - **Example Columns:** `original_reference`, `transaction_id` (if successful), `status` (e.g., `approved`, `declined`, `failed`, `invalid_record`), `message` (details on success or failure), `response_code` (specific code for card/debit failures).

---

_See also: [Purchases](./purchases.md), [Direct Entries](./direct-entries.md), [Merchant Dashboard](./merchant-dashboard.md)_
