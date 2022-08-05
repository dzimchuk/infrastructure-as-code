module "app" {
  source = "./modules/app"
  project_name = var.project_name
  environment = var.environment
  location = var.location
}
