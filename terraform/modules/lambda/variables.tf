variable "function_name"   { type = string }

variable "handler"         { type = string }

variable "runtime"         { 
    type = string  
    default = "nodejs20.x" 
}

variable "role_arn"        { type = string }

variable "source_dir"      { type = string } # path to folder with code

variable "memory_mb"       { 
    type = number  
    default = 128 
}

variable "timeout_seconds" { 
    type = number  
    default = 5 
}

variable "env_vars"        { 
    type = map(string) 
    default = {} 
}

variable "architecture"    { 
    type = string  
    default = "arm64" 
} # or "x86_64"

variable "tags"            { type = map(string) }

