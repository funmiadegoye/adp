variable "domain" {
  default = "devopsnexus.net"
}
variable "region" {
  default = "eu-west-2"
}

variable "nr-key" {
  description = "New Relic License Key"
  type        = string
  default     = "NRAK-EALLCYVB0O491YGB6UW105ED8ZT"
}

variable "nr-acc-id" {
  description = "New Relic Account ID"
  type        = number
  default     = 7181908
}