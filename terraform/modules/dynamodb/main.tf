resource "aws_dynamodb_table" "this" {
  name                        = var.table_name
  billing_mode                = var.billing_mode
  deletion_protection_enabled = var.deletion_protection

  hash_key  = "pk"
  range_key = "sk"

  # v5: capacities are top-level so we set to null when PAY_PER_REQUEST
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity  : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Table key attributes
  attribute { 
    name = "pk" 
    type = "S" 
    }

  attribute { 
    name = "sk" 
    type = "S" 
    }

  # GSI key attributes (only when enabled)
  dynamic "attribute" {
    for_each = var.gsi1_enabled ? [1] : []
    content { 
        name = "gsi1pk" 
        type = "S" 
    }
  }
  dynamic "attribute" {
    for_each = var.gsi1_enabled ? [1] : []
    content { 
        name = "gsi1sk" 
        type = "S" 
    }
  }

  # GSI definition (capacities also top-level inside the block)
  dynamic "global_secondary_index" {
    for_each = var.gsi1_enabled ? [1] : []
    content {
      name            = var.gsi1_name
      hash_key        = "gsi1pk"
      range_key       = "gsi1sk"
      projection_type = "ALL"

      read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity  : null
      write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
    }
  }

  server_side_encryption { enabled = true }

  ttl {
    enabled        = var.enable_ttl
    attribute_name = var.ttl_attribute
  }

  point_in_time_recovery { enabled = var.enable_pitr }

  stream_enabled   = var.enable_streams
  stream_view_type = var.stream_view_type

  tags = var.tags
}



