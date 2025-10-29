variable "name"                 { type = string }

variable "assume_role_policy"   { type = string } # JSON

variable "inline_policies"      { 
    type = map(string)  
    default = {} 
} # name => JSON

variable "managed_policy_arns"  { 
    type = list(string) 
    default = [] 
}

variable "tags"                 { type = map(string) }