variable "name"        { type = string }                  # e.g., "cp-get-messages-dev"

variable "entry"       { type = string }                  # e.g., "getMessages"

variable "role_arn"    { type = string }                  # IAM role for Lambda

variable "env"         { 
    type = map(string) 
    default = {} 
}

variable "timeout"     { 
    type = number 
    default = 15 
}

variable "memory_size" { 
    type = number 
    default = 256 
}

variable "architecture"{ 
    type = string 
    default = "arm64" 
} # or "x86_64"

