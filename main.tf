##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Observability Instances (Sysdig + AT)
##############################################################################

locals {
  existing_at = var.existing_at_instance_crn != null ? true : false
  at_crn      = var.existing_at_instance_crn == null ? module.observability_instances.activity_tracker_crn : var.existing_at_instance_crn
}

module "observability_instances" {
  source  = "terraform-ibm-modules/observability-instances/ibm"
  version = "2.7.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region                         = var.region
  resource_group_id              = module.resource_group.resource_group_id
  sysdig_instance_name           = "${var.prefix}-sysdig"
  sysdig_plan                    = "graduated-tier"
  enable_platform_logs           = false
  enable_platform_metrics        = false
  logdna_provision               = false
  activity_tracker_instance_name = "${var.prefix}-at"
  activity_tracker_tags          = var.resource_tags
  activity_tracker_plan          = "7-day"
  activity_tracker_provision     = !local.existing_at
  logdna_tags                    = var.resource_tags
  sysdig_tags                    = var.resource_tags
}

##############################################################################
# Create Key Protect resources
##############################################################################

locals {
  key_ring_name = "cos-key-ring"
  key_name      = "cos-key"
}

module "key_protect_all_inclusive" {
  source                    = "terraform-ibm-modules/key-protect-all-inclusive/ibm"
  version                   = "4.2.0"
  key_protect_instance_name = "${var.prefix}-kp"
  resource_group_id         = module.resource_group.resource_group_id
  enable_metrics            = false
  region                    = var.region
  key_map = {
    (local.key_ring_name) = [local.key_name]
  }
  resource_tags = var.resource_tags
}

##############################################################################
# Get Cloud Account ID
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {
}

##############################################################################
# Create COS Instance and Bucket with:
# - Encryption
# - Monitoring
# - Activity Tracking
##############################################################################

module "cos_bucket1" {
  source                              = "terraform-ibm-modules/cos/ibm"
  version                             = "6.10.1"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  cross_region_location               = null
  cos_instance_name                   = "${var.prefix}-cos"
  cos_tags                            = var.resource_tags
  bucket_name                         = "${var.prefix}-bucket-1"
  access_tags                         = var.access_tags
  management_endpoint_type_for_bucket = var.management_endpoint_type_for_bucket
  existing_kms_instance_guid          = module.key_protect_all_inclusive.key_protect_guid
  kms_key_crn                         = module.key_protect_all_inclusive.keys["${local.key_ring_name}.${local.key_name}"].crn
  sysdig_crn                          = module.observability_instances.sysdig_crn
  # disable retention for test environments - enable for stage/prod
  retention_enabled    = false
  activity_tracker_crn = local.at_crn
}
