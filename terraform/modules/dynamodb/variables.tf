variable "table_name"           { type = string }

variable "read_capacity"        { 
    type = number  
    default = 5 
}

variable "write_capacity"       { 
    type = number  
    default = 5 
}

variable "billing_mode"         { 
    type = string  
    default = "PAY_PER_REQUEST" 
} # or "PROVISIONED"

variable "enable_streams"       { 
    type = bool    
    default = true 
}

variable "stream_view_type"     { 
    type = string  
    default = "NEW_AND_OLD_IMAGES" 
}

variable "enable_pitr"          { 
    type = bool    
    default = true 
}

variable "ttl_attribute"        { 
    type = string  
    default = "expiresAt" 
}

variable "enable_ttl"           { 
    type = bool    
    default = true 
}

variable "tags"                 { type = map(string) }

variable "gsi1_enabled"         { 
    type = bool    
    default = true 
}

variable "gsi1_name"            { 
    type = string  
    default = "gsi1" 
}

variable "deletion_protection"  { 
    type = bool    
    default = true 
}