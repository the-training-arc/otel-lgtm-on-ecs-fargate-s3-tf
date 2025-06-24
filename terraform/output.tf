output "integration_service" {
  value = {
    aws : {
      ecs : module.ecs
    }
  }
}
