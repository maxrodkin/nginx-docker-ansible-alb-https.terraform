data "local_file" "nginx_conf" {
  filename = "${path.module}/nginx/default.conf"
}

data "cloudinit_config" "nginx" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/x-shellscript"
    filename     = "default.conf"
    content      = data.local_file.nginx_conf.content
  }

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config
package_update: true
bootcmd:
  - mkdir /opt/mydir 2>/dev/null
  - cp /var/lib/cloud/instances/$INSTANCE_ID/scripts/* /opt/mydir/
runcmd:
  - amazon-linux-extras install docker
  - systemctl start docker
  - systemctl enable docker
  - usermod -a -G docker ec2-user
  - [ sh, -c, " cd /opt/mydir/ ; docker run -d -p 80:80 --restart always --name nginx -v /opt/mydir/default.conf:/etc/nginx/conf.d/default.conf nginx" ]
  - docker ps
EOT
  }
}

locals {
  nginx_ips = join("\n", [for i in module.ec2_nginx : i.private_ip])
}

data "cloudinit_config" "ansible" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    filename     = "inventory"
    content      = <<EOT
[nginx]
${local.nginx_ips}
EOT
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "ansible.cfg"
    content      = <<EOT
[defaults]
inventory = inventory
remote_user = ec2-user
private_key_file = /opt/mydir/ansible.pem
host_key_checking = False
EOT
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "ansible.pem"
    content      = module.key_pair.private_key_pem
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "ansible-init.sh"
    content      = <<EOT
#!/bin/sh
cd /opt/mydir/ ;
chmod 666 ansible.cfg inventory
chown ssm-user:ssm-user ansible.pem
chmod 400 ansible.pem
ansible -i inventory nginx --key-file ansible.pem -m ping  > ansible-ping-test.txt
EOT
  }

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = <<EOT
package_update: true
bootcmd:
  - mkdir /opt/mydir 2>/dev/null
  - cp /var/lib/cloud/instances/$INSTANCE_ID/scripts/* /opt/mydir/

runcmd:
  - pip3 install ansible
  - [ sh, -c, " cd /opt/mydir/ ; /opt/mydir/ansible-init.sh" ]
EOT
  }
}
