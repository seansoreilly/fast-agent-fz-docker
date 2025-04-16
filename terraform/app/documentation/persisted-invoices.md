# Persisted Invoices

This section describes the specification for uploading persisted invoices to Fat Zebra.

## Overview

_(Verify purpose against official documentation)_

This feature likely allows merchants to upload detailed invoice information to Fat Zebra. Potential use cases include:

- **Linking Payments:** Associating specific payments (e.g., Purchases, Direct Debits) with detailed invoice records stored within Fat Zebra.
- **Hosted Invoice Presentment:** Fat Zebra might offer a service to display these invoices to customers, potentially with a payment link.
- **Reporting/Reconciliation:** Providing more detailed data for reporting and reconciliation purposes within the Fat Zebra system.
- **Level 2/3 Data:** For B2B transactions, uploaded invoice line items might contribute to Level 2 or Level 3 card processing data, which can sometimes result in lower interchange fees.

## Upload Specification

_(Verify upload method and data format against official documentation)_

- **Upload Method:** Could be via:
  - A specific API endpoint (e.g., `POST /v1.0/invoices`).
  - SFTP upload.
  - Manual upload in the Merchant Dashboard.
- **Data Format:** Most likely JSON for API uploads, potentially CSV for batch/SFTP uploads.
- **Required Fields (Example):** `invoice_id` (unique identifier), `customer_reference` (linking to a customer record), `amount` (total amount in cents), `currency` (ISO code), `issue_date`, `due_date`.
- **Optional Fields (Example):** `status` (e.g., `open`, `paid`, `overdue`), `line_items` (array of objects with description, quantity, unit_price, total), `tax_amount`, `shipping_amount`, `notes`, `metadata`.
- **Schema/Example:** The example below shows a plausible JSON structure.

```json
// Example Invoice Data (Illustrative - confirm actual structure)
{
  "invoice_id": "INV-12345",
  "customer_reference": "CUST-001",
  "amount": 5500, // In cents
  "currency": "AUD",
  "issue_date": "2023-10-27",
  "due_date": "2023-11-10",
  "line_items": [
    {
      "description": "Widget A",
      "quantity": 2,
      "unit_price": 2000,
      "total": 4000
    },
    {
      "description": "Service Fee",
      "quantity": 1,
      "unit_price": 1500,
      "total": 1500
    }
  ],
  "metadata": {
    "order_id": "SO-987"
  }
}
```

## Linking to Transactions

_(Verify linking mechanism against official documentation)_

If used for payment linking, you might reference the `invoice_id` within the `metadata` or a dedicated `invoice_reference` field when creating a [Purchase](./purchases.md) or other transaction.

```json
// Example Purchase request linking to an invoice
{
  // ... other purchase details (amount, card info, etc.) ...
  "reference": "PAYMENT-FOR-INV-12345",
  "metadata": {
    "invoice_id": "INV-12345",
    "customer_internal_ref": "CUST-001"
  }
}
```

Alternatively, if Fat Zebra hosts the invoice with a payment button, paying via that link would automatically associate the payment.

---

_See also: (Link to relevant sections like Purchases or Metadata if applicable)_
