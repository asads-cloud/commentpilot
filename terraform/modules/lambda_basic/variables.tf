variable "name"        { type = string }

variable "entry_dir"   { type = string }          # e.g., "etl/fetch_instagram_dm"

variable "role_arn"    { type = string }

variable "env"         { 
    type = map(string) 
    default = {} 
}

variable "timeout"     { 
    type = number 
    default = 30 
}

variable "memory_size" { 
    type = number 
    default = 256 
}

