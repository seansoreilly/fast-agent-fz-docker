# Card On File

This section covers storing card details securely (tokenization) and using these tokens for various payment types.

## Tokenized Credit Cards `[API_ENDPOINT:/tokens]`

_(Verify endpoint and process against official documentation)_

Tokenization replaces sensitive card details with a unique, non-sensitive identifier (`token`) that can be stored and used for future payments, significantly reducing your PCI DSS scope.

- **Purpose:** Securely store customer card details for repeat purchases, subscriptions, customer checkouts etc.
- **Process:** Tokens can typically be created in several ways:
  - **During a Purchase:** A token is often automatically generated and returned in the response of a successful purchase made with raw card details (check the `card.token` field in the Purchase response).
  - **Via SDKs:** Client-side SDKs ([React](./sdk.md#react-sdk), [Javascript](./sdk.md#javascript-sdk)) usually handle tokenization directly, sending card details from the user's browser to Fat Zebra and returning a token to your frontend code, which you then send to your server.
  - **Dedicated Token Endpoint (if available):** Some gateways provide a specific API endpoint (e.g., `POST /v1.0/tokens`) to create a token directly from raw card details sent from your server (this increases your PCI scope compared to SDK methods).
- **API Endpoint (Example):** `POST /v1.0/tokens` (if a dedicated server-side endpoint exists)
- **Request Payload (for dedicated endpoint):** Likely includes `card_holder`, `card_number`, `card_expiry`. CVV might not be stored.
  ```json
  // Example for dedicated token endpoint (Confirm actual fields)
  {
    "card_holder": "Jane Doe",
    "card_number": "4111111111111111",
    "card_expiry": "12/2029"
  }
  ```
- **Response Payload (Token Creation):**
  ```json
  {
    "token": "tok_def456uvw789",
    "card": {
      "scheme": "Visa",
      "holder": "Jane Doe",
      "number": "411111......1111",
      "expiry_month": 12,
      "expiry_year": 2029
    }
  }
  ```

**Using Tokens:**

Once a token is created, use it in place of raw card details in subsequent API calls (e.g., Purchases). Reference the `token` within the `card` object:

```json
{
  // ... other purchase details like amount, reference ...
  "card": {
    "token": "tok_xxxxxxxxxxxxxxxx"
  }
}
```

## Recurring / Installment Payments `[API_RECURRING]`

_(Verify implementation against official documentation - Fat Zebra might use specific flags, a separate API, or rely on merchant scheduling)_

Card tokens are essential for implementing recurring (subscription) or installment payments.

- **Mechanism:** Typically involves storing the card token after the initial customer-present transaction (which should ideally be authenticated, e.g., with 3DS) and then initiating subsequent payments using the token without direct cardholder interaction (Merchant Initiated Transactions - MIT).
- **Scheduling:** Fat Zebra might offer a built-in scheduling feature (Payment Plans via Dashboard/API) or require the merchant to manage the schedule and initiate API calls using the token on the due dates.
- **API Request (Merchant Scheduled):** Initiate a standard [Purchase](./purchases.md) using the stored card token. It's crucial to indicate that this is a recurring or installment payment, often via specific fields, to ensure correct processing and potentially benefit from different interchange rates or MIT rules.
  ```json
  // Example Purchase using Token for Recurring (Confirm actual fields)
  {
    "card": {
      "token": "tok_def456uvw789"
    },
    "amount": 2500,
    "currency": "AUD",
    "reference": "SUB-XYZ-202311",
    "customer_ip": "(Your Server IP or original customer IP)",
    "recurring_flag": true, // Example flag - check FZ docs
    "mit_type": "recurring" // Example flag - check FZ docs for MIT details
    // Potentially add original transaction ID reference
  }
  ```
- **Management:** If Fat Zebra provides a specific Payment Plan API/feature, there would be endpoints to create, view, update, and cancel these plans.

## Merchant Initiated Transaction (MIT)

_(Verify implementation against official MIT documentation)_

MITs are payments initiated by the merchant using stored credentials (tokens) without the active participation of the cardholder at the time of the transaction.

- **Requirements:**
  - **Agreement:** A clear agreement (mandate) must exist between the merchant and the cardholder authorizing the merchant to initiate payments.
  - **Initial Authentication:** The initial transaction where the card was stored/tokenized should have been strongly authenticated (e.g., 3DS).
- **API Usage:** When making an MIT purchase using a token, you must typically include specific flags or fields in the API request to indicate:
  - That it is an MIT.
  - The reason for the MIT (e.g., `recurring`, `installment`, `unscheduled_card_on_file`).
  - Potentially a reference to the initial transaction ID where authentication occurred.
  - _(Check FZ docs for specific fields like `mit_type`, `initial_transaction_id`, `stored_credential_indicator`)_

## Incremental Authorization

_(Details on incremental authorizations need to be extracted from the 'Incremental Authorization' page)_

Incremental authorizations allow increasing the amount of a previously authorized transaction (common in hospitality/rental industries).

- **Process:** (Explain the workflow and API calls involved).
- **Use Cases:** (Mention typical scenarios).

---

_See also: [Purchases](./purchases.md), [SDKs](./sdk.md), [Security](./security.md)_
