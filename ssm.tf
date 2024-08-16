# resource "aws_ssm_document" "suricata_setup" {
#   name            = "suricata-setup"
#   document_type   = "Command"
#   document_format = "YAML"
#   content         = file("path/to/ssm_document.yaml")
# }

# resource "aws_ssm_association" "suricata_setup" {
#   name = aws_ssm_document.suricata_setup.name

#   targets {
#     key    = "InstanceIds"
#     values = [aws_instance.suricata_vms.id]
#   }

#   parameters = {
#     CustomRulesPath = "s3://your-bucket/custom.rules"
#   }
# }
