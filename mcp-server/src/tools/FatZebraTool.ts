import { MCPTool } from "mcp-framework";
import { z } from "zod";
import fetch from "node-fetch";

interface FatZebraPaymentInput {
  amount: number;
  currency?: string;
  card_number: string;
  card_expiry: string;
  card_cvv: string;
  reference: string;
  card_holder?: string;
  customer_email?: string;
  customer_ip?: string;
  capture?: boolean;
}

// Define request body interface with all possible properties
interface PaymentRequestBody {
  amount: number;
  currency?: string;
  card_number: string;
  card_expiry: string;
  card_cvv: string;
  reference: string;
  customer_ip?: string;
  card_holder?: string;
  customer_email?: string;
  capture?: boolean;
}

// Define response interface
interface FatZebraPaymentResponse {
  successful: boolean;
  errors?: string[];
  response: {
    id: string;
    card_number: string;
    card_holder: string;
    card_expiry: string;
    card_token: string;
    card_type: string;
    card_category: string;
    card_subcategory: string;
    amount: number;
    decimal_amount: number;
    successful: boolean;
    message: string;
    reference: string;
    currency: string;
    transaction_id: string;
    settlement_date: string;
    transaction_date: string;
    response_code: string;
    captured: boolean;
    captured_amount: number;
    rrn: string;
    cvv_match: string;
    metadata: Record<string, string>;
    addendum_data: Record<string, any>;
  };
  test: boolean;
}

class FatZebraTool extends MCPTool<FatZebraPaymentInput> {
  name = "fat_zebra_payment";
  description = "Process a credit card payment using the Fat Zebra payment gateway";
  
  // Fat Zebra API configuration
  private baseUrl = process.env.FAT_ZEBRA_API_URL || "https://gateway.sandbox.fatzebra.com.au/v1.0";
  private username = process.env.FAT_ZEBRA_USERNAME || "TEST";
  private token = process.env.FAT_ZEBRA_TOKEN || "TEST";
  
  // Default test card that works with Fat Zebra - using the one reported to work consistently
  private defaultTestCard = "5123456789012346";
  private defaultExpiryDate = "05/2026";
  private defaultCVV = "123";
  private defaultCardHolder = "Test User";
  
  schema = {
    amount: {
      type: z.number().positive(),
      description: "The amount to charge in cents (e.g., 1000 for $10.00)",
    },
    currency: {
      type: z.string().default("AUD"),
      description: "The three-letter ISO currency code (default: AUD)",
    },
    card_number: {
      type: z.string(),
      description: "The customer's credit card number",
    },
    card_expiry: {
      type: z.string(),
      description: "The card expiry date in the format MM/YYYY (e.g., 05/2026)",
    },
    card_cvv: {
      type: z.string(),
      description: "The card verification value (CVV/CVC) code",
    },
    reference: {
      type: z.string(),
      description: "A unique reference for this transaction",
    },
    card_holder: {
      type: z.string().optional(),
      description: "The cardholder's name (optional)",
    },
    customer_email: {
      type: z.string().email().optional(),
      description: "The customer's email address (optional)",
    },
    customer_ip: {
      type: z.string().optional().default("127.0.0.1"),
      description: "The customer's IP address (optional, defaults to 127.0.0.1)",
    },
    capture: {
      type: z.boolean().default(true),
      description: "Whether to capture the payment immediately (default: true)",
    },
  };

  async execute(input: FatZebraPaymentInput) {
    try {
      // Use the successful test card if we're in test mode and no card is provided
      const cardNumber = this.username === "TEST" && !input.card_number ? 
        this.defaultTestCard : input.card_number;
      
      // Use the successful expiry date if we're in test mode and using the default test card
      const cardExpiry = this.username === "TEST" && cardNumber === this.defaultTestCard ? 
        this.defaultExpiryDate : input.card_expiry;
      
      // Always ensure CVV is provided - required by Fat Zebra
      const cardCVV = input.card_cvv || this.defaultCVV;
      
      // Always ensure card_holder is provided as Fat Zebra requires it
      const cardHolder = input.card_holder || this.defaultCardHolder;
      
      // Create a simple reference if none provided
      const reference = input.reference || `ref-${Date.now()}`;
      
      // Prepare the request body for the Fat Zebra API
      const requestBody: PaymentRequestBody = {
        amount: input.amount,
        card_number: cardNumber,
        card_expiry: cardExpiry,
        card_cvv: cardCVV,
        reference: reference,
        card_holder: cardHolder,
        currency: input.currency || "AUD",
      };

      // Add optional fields only if provided
      if (input.customer_ip) {
        requestBody.customer_ip = input.customer_ip;
      }
      
      if (input.customer_email) {
        requestBody.customer_email = input.customer_email;
      }
      
      if (input.capture !== undefined) {
        requestBody.capture = input.capture;
      }

      // Make the request to the Fat Zebra API
      const response = await fetch(`${this.baseUrl}/purchases`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${Buffer.from(`${this.username}:${this.token}`).toString('base64')}`,
        },
        body: JSON.stringify(requestBody),
      });

      const data = await response.json() as FatZebraPaymentResponse;

      // Check if the response was successful
      if (!data.successful) {
        // Return the error response directly instead of throwing
        return {
          successful: false,
          errors: data.errors || ["Unknown error from Fat Zebra API"]
        };
      }

      // Return the response from Fat Zebra
      return {
        successful: data.successful,
        transaction_id: data.response.transaction_id,
        card_token: data.response.card_token,
        amount: data.response.amount,
        reference: data.response.reference,
        message: data.response.message,
        authorization: data.response.response_code,
        currency: data.response.currency,
        timestamp: data.response.transaction_date,
      };
    } catch (error) {
      console.error('Error processing payment:', error);
      // Return error as a response instead of throwing
      return {
        successful: false,
        errors: [(error instanceof Error ? error.message : String(error))]
      };
    }
  }
}

export default FatZebraTool; 