# Purchases API

This section details how to create card payments (purchases) using the Fat Zebra API.

## Overview

The Purchase endpoint is the primary way to process a one-off payment from a customer's credit or debit card. It typically performs an Authorization and Capture in a single step (an 'Auth-Capture').

- **Functionality:** Charges a specified amount to a provided card or token.
- **Idempotency:** Use the unique `reference` field to safely retry requests in case of network errors or timeouts without risking duplicate charges. If a purchase request with a previously used `reference` is received, Fat Zebra will return the original transaction result instead of processing it again.

## API Endpoint `[API_ENDPOINT:/purchases]`

_(Confirm endpoint path and details from documentation)_

- **Method:** `POST`
- **Path:** `/v1.0/purchases`

## Request Payload `[API_EXAMPLE]`

_(Verify all fields and requirements against official documentation)_

**Required Fields:**

- `amount`: (Integer) The transaction amount in the smallest currency unit (e.g., cents for AUD/USD).
- `reference`: (String) Your unique identifier for this transaction (e.g., order ID, invoice number). Max length typically 64 characters.
- `currency`: (String) The three-letter ISO 4217 currency code (e.g., `AUD`, `USD`, `GBP`).
- `customer_ip`: (String) The IP address of the customer initiating the transaction. Crucial for fraud prevention.
- **Either** Raw Card Details:
  - `card_holder`: (String) Cardholder's full name as it appears on the card.
  - `card_number`: (String) The Primary Account Number (PAN).
  - `card_expiry`: (String) Expiry date in `MM/YYYY` format.
  - `cvv`: (String) Card Verification Value/Code.
- **Or** Card Token:
  - `card`: (Object) Containing:
    - `token`: (String) The card token obtained from a previous tokenization. _(See [Card On File](./card-on-file.md))_

**Optional Fields (Common):**

- `metadata`: (Object) Key-value pairs for storing custom data (max key/value lengths apply, often 255 chars).
- `capture`: (Boolean, Default: `true`) Set to `false` to perform an Authorization only (Auth), which reserves the funds but requires a separate Capture step later.
- **Address Fields (for AVS):**
  - `address_line1`: (String) Cardholder's street address.
  - `address_line2`: (String) Optional second line of address.
  - `address_city`: (String) Cardholder's city.
  - `address_state`: (String) Cardholder's state/province.
  - `address_postcode`: (String) Cardholder's postal/ZIP code.
  - `address_country`: (String) Cardholder's two-letter ISO 3166 country code (e.g., `AU`, `US`).
- _(Other fields for 3DS, MOTO, etc. - see relevant sections)_

```json
// Example Request with Raw Card Data
{
  "card_holder": "Jane Doe",
  "card_number": "4111111111111111",
  "card_expiry": "12/2029",
  "cvv": "123",
  "amount": 5000,
  "currency": "AUD",
  "reference": "ORDER-ABC123",
  "customer_ip": "192.168.1.100",
  "address_line1": "123 Test St",
  "address_postcode": "2000",
  "address_country": "AU",
  "metadata": {
    "product_id": "PROD-XYZ",
    "user_id": "USER-456"
  }
}
```

## Response Payload `[API_EXAMPLE]`

_(Verify all fields against official documentation)_

```json
{
  "successful": true, // Boolean: Overall success indicator
  "authorized": true, // Boolean: Was the authorization successful?
  "captured": true, // Boolean: Was the capture successful? (false for Auth-only)
  "id": "txn_abc123xyz789", // String: Fat Zebra's unique transaction ID
  "amount": 5000,
  "currency": "AUD",
  "reference": "ORDER-ABC123",
  "message": "Approved", // String: Human-readable result message
  "response_code": "00", // String: Specific acquirer/FZ response code
  "transaction_time": "2023-10-27T10:30:00Z", // ISO 8601 Timestamp
  "card": {
    "holder": "Jane Doe",
    "number": "411111......1111", // String: Masked PAN
    "scheme": "Visa", // String: Card scheme
    "token": "tok_def456uvw789", // String: Card token (if generated/used)
    "expiry_month": 12,
    "expiry_year": 2029
  },
  "avs_result": "M", // String: AVS result code (See AVS section)
  "cvv_result": "M", // String: CVV result code (M=Match, N=No Match, P=Not Processed, S=Should be present, U=Unsupported/Unavailable)
  "metadata": {
    // Echos back metadata sent in request
    "product_id": "PROD-XYZ",
    "user_id": "USER-456"
  }
  // Add other fields like 3DS results, settlement details etc. as specified
}
```

## Response Codes `[API_RESPONSE_CODE]`

_(Specific Fat Zebra response codes and their meanings should be verified against the 'Response Codes' sub-page)_

Fat Zebra uses specific codes in the `response_code` field, often passed through from the acquirer, to indicate the detailed outcome.

**Common Codes:**

- `00`: Approved or completed successfully
- `01`: Refer to card issuer
- `05`: Do not honor / Declined (Generic)
- `08`: Honor with identification
- `12`: Invalid transaction
- `14`: Invalid card number (no such number)
- `30`: Format error
- `41`: Lost card, pick up
- `43`: Stolen card, pick up
- `51`: Insufficient funds
- `54`: Expired card
- `55`: Incorrect PIN
- `57`: Transaction not permitted to cardholder
- `58`: Transaction not permitted on terminal
- `62`: Restricted card (e.g., invalid region or usage)
- `75`: Allowable number of PIN tries exceeded
- `91`: Issuer or switch is unavailable
- `96`: System malfunction

_(This list is illustrative, consult the official Fat Zebra documentation for a complete and accurate list)_

Refer to [Getting Started](./getting-started.md#errors--timeouts) for handling general HTTP status codes (like 4xx/5xx errors).

## Metadata

You can include custom key-value pairs (strings) in the `metadata` object within the request payload.

- **Purpose:** Store additional information relevant to the transaction (e.g., internal IDs, product details, customer segments).
- **Storage:** This data is stored alongside the transaction details within Fat Zebra.
- **Retrieval:** Metadata is returned in the API response for the transaction and is usually included in corresponding webhook payloads.
- **Limitations:** Be aware of potential limits on the number of keys, key length, and value length (often around 64 keys, 255 characters per key/value - _confirm limits_).

## Addendum Data

_(Explanation of Addendum Data needs to be extracted)_

## Extra and Extended Fields

_(Details on fields for specific use cases need to be extracted from sub-pages)_

- **Card On File:** Using tokens. _(See [Card On File](./card-on-file.md))_.
- **3D Secure Card Payments:** Fields related to 3DS authentication. _(See [3DS2 Integration](./3ds2.md))_.
- **Mail Order / Telephone Order (MOTO):** Specific flags or fields for MOTO transactions.
- **Dynamic Descriptors:** How to set custom statement descriptors.
- **Payment Aggregators:** Fields relevant for aggregators.
- **Remittance Merchants:** Fields relevant for remittance.

## Chargebacks and Fraud

_(Summary of information on chargebacks and fraud prevention needs to be extracted)_

## Supported Currencies `[DATA:CURRENCY]`

_(List or link to the supported currencies needs to be extracted from the 'Supported Currencies' page)_

Common examples: AUD, USD, GBP, EUR, NZD. Refer to the documentation for the full list and ISO codes.

## AVS (Address Verification System)

AVS checks the numeric portions of the cardholder's billing address (street number and postal code) against the information on file with the issuing bank. It's primarily used in the US, UK, and Canada.

- **Request:** Include the cardholder's billing address fields (`address_line1`, `address_postcode`, etc.) in the Purchase request.
- **Response:** The outcome is returned in the `avs_result` field of the response payload.

**Common AVS Result Codes (Illustrative - _confirm actual codes used by FZ_):**

- `X`: Exact match (Address and 9-digit ZIP)
- `Y`: Exact match (Address and 5-digit ZIP)
- `A`: Address matches, ZIP does not
- `W`: 9-digit ZIP matches, Address does not
- `Z`: 5-digit ZIP matches, Address does not
- `N`: No match on Address or ZIP
- `U`: Address information is unavailable
- `S`: AVS not supported by issuer
- `R`: Retry - System unavailable
- `G`: Global non-AVS participant

* **Note:** AVS is a verification tool, not an authorization factor. A transaction might be approved even with an AVS mismatch, depending on your risk settings and the issuer.

## Merchant Advice Codes (Retries)

_(Explanation of MACs and how they appear in responses needs to be extracted from the 'Merchant Advice Codes (Retries)' page)_

---

_See also: [Getting Started](./getting-started.md), [Testing](./testing.md), [Card On File](./card-on-file.md), [3DS2 Integration](./3ds2.md)_
