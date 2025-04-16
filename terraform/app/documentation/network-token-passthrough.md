# Network Token Passthrough

This section explains the "Bring Your Own Network Token" (BYONT) feature.

## Overview

_(Verify details against official 'Bring Your Own Network Token' documentation)_

Network Token Passthrough (often called BYONT - Bring Your Own Network Token) allows merchants who have their own relationships with network token service providers (TSPs) like Visa (VTS) or Mastercard (MDES) to process transactions using these network tokens via Fat Zebra, instead of using Fat Zebra's PAN tokenization or raw PANs.

This is an advanced feature typically used by merchants with specific requirements or existing TSP relationships.

## Benefits

- **Potential Authorization Rate Uplift:** Network tokens can sometimes yield higher approval rates compared to PANs, especially for recurring/MIT transactions.
- **Reduced PCI Scope (Potentially):** While you still handle network tokens (which are sensitive in context), you avoid handling raw PANs directly in some flows.
- **Consistency Across PSPs:** Allows using the same network token vault across multiple payment service providers.
- **Network Lifecycle Management:** Benefits from automatic card updates (e.g., new expiry dates, PANs) managed by the card networks.

## API Integration

_(Verify specific field names and structure against official documentation)_

When processing a payment (e.g., via the [Purchase API](./purchases.md)), you submit the network token details instead of raw card details or a Fat Zebra token.

**Key Data Points:**

- **Network Token (DPAN/FPAN):** The token number itself.
- **Cryptogram:** A dynamic, transaction-specific value generated using the network token key (you need to obtain this from the TSP or your tokenization provider for each transaction).
- **ECI (Electronic Commerce Indicator):** Indicates the security level of the transaction (e.g., `05` for fully authenticated, `06` for attempted auth, `07` for non-3DS/merchant-initiated).
- **Token Expiry:** The expiry date associated with the network token.
- **Source Network:** Indication of whether it's a Visa (VTS) or Mastercard (MDES) token.

**Example Request Snippet (Illustrative - confirm actual fields/structure):**

```json
{
  "amount": 4200,
  "currency": "AUD",
  "reference": "BYONT-ORDER-789",
  "customer_ip": "192.168.1.102",
  "payment_method": {
    // Or potentially a top-level "network_token" object
    "network_token": {
      "token": "4111110000001234567", // The actual Network Token (DPAN)
      "cryptogram": "(Base64 or Hex encoded cryptogram value)",
      "eci_indicator": "05",
      "expiry_month": "12",
      "expiry_year": "2030",
      "source": "visa" // or "mastercard"
    }
  }
}
```

## Considerations

- **Enrollment & Setup:** Requires enrollment with network TSPs (Visa VTS / Mastercard MDES) and potentially specific configuration within Fat Zebra.
- **Cryptogram Generation:** You or your TSP partner are responsible for generating the transaction-specific cryptogram for each payment attempt.
- **ECI Handling:** Correctly setting the ECI based on the transaction context (e.g., customer-present vs. MIT, 3DS status) is crucial.
- **Token Lifecycle Management:** While networks handle some updates, you still need processes for managing token status and potential deactivations.
- **Complexity:** This integration method is significantly more complex than using standard PAN processing or Fat Zebra's built-in tokenization.

---

_See also: [Purchases](./purchases.md), [Card On File](./card-on-file.md), [Security](./security.md)_
