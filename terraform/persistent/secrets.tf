locals {
  envs = ["dev", "prod"]
  service_env = { for pair in setproduct(local.envs, local.services) :
    "${pair[0]}-${pair[1]}" => { env = pair[0], svc = pair[1] }
  }
}

resource "aws_secretsmanager_secret" "db" {
  for_each                = local.service_env
  name                    = "microservice/${each.value.env}/${each.value.svc}/db"
  recovery_window_in_days = 0

}

resource "aws_secretsmanager_secret" "postgres_exporter" {
  for_each                = toset(local.envs)
  name                    = "microservice/${each.value}/monitoring/postgres-exporter"
  recovery_window_in_days = 0
}
