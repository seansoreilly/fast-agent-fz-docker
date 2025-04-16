# Direct Entries (Direct Debits & Credits)

This section details how to perform Direct Debits (pulling funds from bank accounts) and Direct Credits (pushing funds to bank accounts) via the Fat Zebra API or batch uploads.

## Overview

_(High-level description of Direct Entries needs to be extracted from the 'Direct Entries > Overview' page)_

Direct Entries allow for bank-to-bank transfers, typically used for scenarios like subscription billing (debits) or payouts (credits) in supported regions (e.g., Australia - BECS).

## Direct Debits `[API_ENDPOINT:/direct_debits]`

_(Verify endpoint and fields against official documentation)_

- **Purpose:** To pull funds from a customer's bank account (requires prior authorization/mandate).
- **Prerequisites:** Valid customer authorization (DDR) and bank details.
- **API Endpoint:** `POST /v1.0/direct_debits` (Example, confirm path)
- **Request Payload:**
  ```json
  {
    "amount": 5000, // Integer: Amount in cents
    "reference": "INV-789-DD", // String: Your unique reference for this debit
    "bsb": "123-456", // String: BSB number (e.g., Australian format)
    "account_number": "123456789", // String: Account number
    "account_name": "John Smith", // String: Account holder name
    "lodgement_reference": "Subscription Fee", // String (Max ~18 chars): Text appearing on customer's statement
    "metadata": {
      // Object: Optional custom data
      "customer_id": "CUST-JS789"
    }
  }
  ```
- **Response Payload (Success):** Indicates acceptance for processing. The actual success/failure comes later.
  ```json
  {
    "successful": true,
    "id": "dd_xyz789abc123", // String: Unique ID for this Direct Debit transaction
    "amount": 5000,
    "reference": "INV-789-DD",
    "status": "pending", // String: Initial status (e.g., pending, processing)
    "bank_account": {
      "bsb": "123-456",
      "account_number_preview": "...6789", // Masked account number
      "account_name": "John Smith"
    },
    "metadata": {
      "customer_id": "CUST-JS789"
    },
    "created_at": "2023-10-27T11:00:00Z"
  }
  ```
- **Response Payload (Failure - Initial Validation):** e.g., invalid BSB format.
  ```json
  {
    "successful": false,
    "errors": [
      {
        "message": "BSB format is invalid.",
        "field": "bsb",
        "code": "invalid_format"
      }
    ]
  }
  ```
- **Processing Time:** Direct Debits are processed in batches through the banking network (e.g., BECS in Australia). Clearance typically takes **1-3 business days**. Do not assume success based on the initial API response. Use [Webhooks](./webhooks.md) (`direct_debit.cleared`, `direct_debit.failed`) or polling (if necessary) to get the final status.

## Direct Credits `[API_ENDPOINT:/direct_credits]`

_(Verify endpoint and fields against official documentation)_

- **Purpose:** To push funds to a payee's bank account (e.g., payouts, refunds).
- **API Endpoint:** `POST /v1.0/direct_credits` (Example, confirm path)
- **Request Payload:** Similar structure to Direct Debits.
  ```json
  {
    "amount": 2500,
    "reference": "PAYOUT-OCT23-JS",
    "bsb": "987-654",
    "account_number": "987654321",
    "account_name": "Jane Supplier",
    "remitter_name": "Your Company Name", // Optional: Name appearing on payee's statement
    "metadata": { ... }
  }
  ```
- **Response Payload (Success):** Indicates acceptance for processing.
  ```json
  {
    "successful": true,
    "id": "dc_pqr456stu789",
    "amount": 2500,
    "reference": "PAYOUT-OCT23-JS",
    "status": "pending",
    // ... bank account details ...
    "created_at": "..."
  }
  ```
- **Processing Time:** Similar to Direct Debits, Direct Credits rely on bank clearing cycles and are **not instant**. Funds typically arrive in the payee's account within **1-2 business days**.

## Batch Processing

Direct Debits can also be processed in bulk via file upload. _(See [Batches](./batches.md#direct-debit-batch-file-columns))_.

---

_See also: [Batches](./batches.md), [Webhooks](./webhooks.md), [Glossary](./glossary.md)_
