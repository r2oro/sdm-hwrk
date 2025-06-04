# SrrongDM roles 

resource "sdm_role" "private_access" {
    name         = "Private Access"
    access_rules = jsonencode([
        {
             "tags": {"strongdm:private": "true"}
        }
    ])
}
resource "sdm_role" "gateway_access" {
    name         = "Gateway Access"
    access_rules = jsonencode([
        {
            "tags": {"strongdm:gateway": "true"}
        }
    ])
}

resource "sdm_account_attachment" "private_users" {
    for_each = toset(var.private_user_list)
    account_id = each.value
    role_id    = sdm_role.private_access.id
}

resource "sdm_account_attachment" "gateway_users" {
    for_each = toset(var.gateway_user_list)
    account_id = each.value
    role_id    = sdm_role.gateway_access.id
}
