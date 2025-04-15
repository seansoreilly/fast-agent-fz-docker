variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "anthropic_api_key" {
  description = "Anthropic API key for Claude model"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "fat_zebra_api_url" {
  description = "Fat Zebra API URL"
  type        = string
  default     = "https://gateway.sandbox.fatzebra.com.au/v1.0"
}

variable "fat_zebra_username" {
  description = "Fat Zebra username"
  type        = string
  default     = "TEST"
}

variable "fat_zebra_token" {
  description = "Fat Zebra token"
  type        = string
  default     = "TEST"
} 
