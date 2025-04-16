# Wallets (Apple Pay & Google Pay)

This section covers integration with digital wallets like Apple Pay and Google Pay.

## Apple Pay `[WALLET:APPLE_PAY]`

_(Verify details against official Fat Zebra Apple Pay documentation)_

Integrates Apple Pay for payments on websites (Safari) and within iOS apps.

### Onboarding

- **Process:** Requires setup in both your Apple Developer account and the Fat Zebra Merchant Dashboard.
  1.  **Apple:** Register Merchant IDs, configure payment processing certificates (CSR needed from FZ), and domain verification.
  2.  **Fat Zebra:** Upload certificates obtained from Apple, configure Merchant ID details.

### Certificate Renewal

- **Process:** Apple Pay certificates expire. You need to generate a new CSR via Fat Zebra, use it to issue a new certificate in your Apple Developer account, and upload the new certificate back to Fat Zebra before the old one expires.

### Get Apple Pay Session `[API_ENDPOINT:/apple_pay/session]`

- **Purpose:** For web integrations, before presenting the Apple Pay button, your server must get a valid session object from Fat Zebra by validating your merchant identity with Apple.
- **API Endpoint:** `POST /v1.0/apple_pay/sessions` (Example, confirm path)
- **Request Payload:** Contains the `validationURL` received from the Apple Pay JS API `onvalidatemerchant` event.
  ```json
  {
    "merchant_validation_url": "(URL from Apple Pay JS)",
    "display_name": "Your Store Name", // Optional: Your store name
    "domain_name": "yourstore.com" // Optional: Verified domain
  }
  ```
- **Response Payload:** Contains the session object to be passed back to the Apple Pay JS `completeMerchantValidation` method.
  ```json
  {
    // Opaque session object from Apple/Fat Zebra
    ...
  }
  ```

### Processing Payments (Web/JS)

1.  **Initiate:** User clicks Apple Pay button.
2.  **Validate Merchant:** `onvalidatemerchant` event -> Call FZ Get Session API -> `completeMerchantValidation`.
3.  **Authorize Payment:** `onpaymentauthorized` event provides an `ApplePayPaymentToken`.
4.  **Send to Server:** Send this token to your server.
5.  **Process with Fat Zebra:** Your server sends the token data (within a specific field, e.g., `apple_pay_token` or nested object) to the Fat Zebra [Purchase](./purchases.md) API endpoint instead of raw card details.

### Recurring & Installment Transactions

- **Process:** Usually involves performing an initial Apple Pay transaction and then using the `card.token` returned in the Fat Zebra purchase response for subsequent [Merchant Initiated Transactions](./card-on-file.md#merchant-initiated-transaction-mit).

## Google Pay™ `[WALLET:GOOGLE_PAY]`

_(Verify details against official Fat Zebra Google Pay documentation)_

Integrates Google Pay for payments on websites and within Android apps.

### Integration Methods

- **Android App Integration:** Use Google's Google Pay Android SDK. Configure allowed payment methods to include `CARD` with Fat Zebra as the gateway and provide your FZ gateway merchant ID.
- **Web Integration:** Use Google's Google Pay JavaScript library. Configure Fat Zebra as the gateway. The JS library returns an encrypted `PaymentData` object upon successful user authorization.
- **Hosted Payments Page Integration:** If using Fat Zebra's HPP, Google Pay may appear as a payment option automatically if configured correctly in the dashboard.

### Google Pay Merchant ID

- **Requirement:** You need your Fat Zebra **Gateway Merchant ID** (this is distinct from your Google Pay Merchant ID obtained from Google for direct integrations) to configure the Google Pay integration.

### Processing Google Pay Payments

- **Data Flow:** The encrypted `PaymentData` obtained from the Google Pay API (web or Android) needs to be sent to your server.
- **API Request:** Your server sends this data to the Fat Zebra [Purchase](./purchases.md) API endpoint. The `PaymentData` object (often Base64 encoded) is typically included in a specific field, e.g., `google_pay_token` or a nested `google_pay` object.
  ```json
  // Example Purchase request with Google Pay data (Confirm actual fields)
  {
    "amount": 3000,
    "currency": "AUD",
    "reference": "ORDER-GPAY-456",
    "customer_ip": "192.168.1.101",
    "payment_method": {
      "google_pay": {
        "token": "(Base64 encoded PaymentData JSON from Google Pay API)"
      }
    }
    // OR potentially "google_pay_token": "(Base64 encoded PaymentData...)"
  }
  ```
- **Tokenization:** Similar to Apple Pay, a successful Google Pay purchase via Fat Zebra usually returns a standard `card.token` in the response, which can be used for [Recurring Payments](./card-on-file.md#recurring--installment-payments) / [MIT](./card-on-file.md#merchant-initiated-transaction-mit).

---

_See also: [Purchases](./purchases.md), [Card On File](./card-on-file.md) (for tokenization), [SDKs](./sdk.md)_
