# Testing `[TEST_DATA]`

This section provides resources for testing your Fat Zebra integration, primarily focusing on test card numbers for simulating various transaction scenarios.

## Test Card Numbers

_(Specific test card numbers and their expected outcomes should be verified against the official 'Test Card Numbers' page)_

Use the following card numbers in the **Sandbox Environment** (`[API_ENDPOINT]`) to simulate different responses. These are common test card patterns; Fat Zebra may have specific numbers for certain scenarios.

**Successful Transactions:**

- Visa: `4111111111111111` (or `400000...` series)
- Mastercard: `5100000000000000` (or `51-55...` series)
- AMEX: `370000000000000` (or `34...`, `37...` series)
- Discover: `6011000000000000`
- JCB: `3500000000000000`
- Diners Club: `36000000000000`

**Declined Transactions (Common Examples):**

- Generic Decline: Use a card number known to decline (e.g., ending in `...0005`, `...1004` - _check FZ docs_)
- Insufficient Funds: Use a card number known for this (e.g., ending in `...0031` - _check FZ docs_)
- Expired Card: Use any valid test card number with an expiry date in the past.
- Invalid CVV: Use a valid test card number and expiry, but an incorrect CVV format or a CVV known to fail (e.g., `999` - _check FZ docs_).
- Invalid Card Number: Use a number that fails Luhn validation or is not a valid scheme prefix.

**3D Secure Simulation:**

- _(Specific card numbers are usually required to trigger 3DS flows - Check FZ '3DS Cards for Testing' page. See also: [3DS2 Integration](./3ds2.md#3ds-cards-for-testing))_
  - Card requiring challenge: `(Specific Visa/MC number needed)`
  - Card resulting in frictionless success: `(Specific Visa/MC number needed)`
  - Card resulting in failure: `(Specific Visa/MC number needed)`

**AVS Simulation:**

- _(Requires specific address details submitted along with test cards - Check FZ 'AVS' page. See also: [Purchases](./purchases.md#avs))_
  - Card/Address for Full Match: `(Number + Address needed)`
  - Card/Address for Partial Match (Zip): `(Number + Address needed)`
  - Card/Address for No Match: `(Number + Address needed)`

**Other Scenarios:**

- _(Check FZ docs for cards related to specific currencies, velocity limits, etc.)_

**General Test Card Parameters:**

- **Expiry Date:** Use any valid future date (e.g., MM/YY like 12/29).
- **CVV:** Use any valid CVV (e.g., 123 for Visa/Mastercard, 1234 for AMEX), unless testing an invalid CVV scenario.

## Sandbox Environment Notes

- The Sandbox environment mirrors production functionality but uses test credentials and does not process real payments.
- Refer to [Getting Started](./getting-started.md#endpoint-base-urls) for the Sandbox Base URL.
- Refer to [Getting Started](./getting-started.md#authentication) for obtaining Sandbox API credentials.

---

_See also: [Getting Started](./getting-started.md), [Purchases](./purchases.md), [3DS2 Integration](./3ds2.md)_
