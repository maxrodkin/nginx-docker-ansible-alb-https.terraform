output "ssm_connect_command_nginx" {
  description = "The AWS CLI command to connect to the nginx instances using Session Manager"
  value       = [for i in module.ec2_nginx : join("\n", ["aws ssm start-session --target ${i.id} --region ${data.aws_region.current.name}"])]
}

output "ssm_connect_command_ansible" {
  description = "The AWS CLI command to connect to the ansible instance using Session Manager"
  value       = "aws ssm start-session --target ${module.ec2_ansible.id} --region ${data.aws_region.current.name}"
}

output "alb_connect_command" {
  description = "The curl command to connect to ALB"
  value = join("\n", [
    "curl http://${module.alb.lb_dns_name}/phrase",
    "curl  --insecure -I https://${module.alb.lb_dns_name}/phrase", ]
  )
}
